import { Injectable, NotFoundException, ConflictException, BadRequestException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import * as bcrypt from 'bcrypt';
import { User, UserDocument } from './schemas/user.schema';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { DepartmentsService } from '../departments/departments.service';
import { OfficesService } from '../offices/offices.service';
import { UserRole } from '../shared/types';
import { BulkUserOperationDto, BulkOperationType } from './dto/bulk-user-operation.dto';

@Injectable()
export class UsersService {
  constructor(
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    private departmentsService: DepartmentsService,
    private officesService: OfficesService,
  ) {}

  async create(createUserDto: CreateUserDto): Promise<User> {
    // Check if user already exists
    const existingUser = await this.userModel.findOne({ email: createUserDto.email });
    if (existingUser) {
      throw new ConflictException('User with this email already exists');
    }

    // Verify department exists
    const department = await this.departmentsService.findOne(createUserDto.departmentId);
    if (!department) {
      throw new NotFoundException('Department not found');
    }

    // Verify supervisor if provided
    if (createUserDto.supervisorId) {
      const supervisor = await this.userModel.findById(createUserDto.supervisorId);
      if (!supervisor) {
        throw new NotFoundException('Supervisor not found');
      }
      // Verify supervisor is in same department
      if (supervisor.departmentId.toString() !== createUserDto.departmentId) {
        throw new ConflictException('Supervisor must be from the same department');
      }
    }

    // Verify office if provided
    if (createUserDto.officeId) {
      const office = await this.officesService.findOne(createUserDto.officeId);
      if (!office) {
        throw new NotFoundException('Office not found');
      }
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(createUserDto.password, 10);

    const createdUser = new this.userModel({
      ...createUserDto,
      password: hashedPassword,
    });
    return createdUser.save();
  }

  async findAll(): Promise<User[]> {
    return this.userModel.find().select('-password').populate('departmentId').populate('officeId').populate('supervisorId').exec();
  }

  async findOne(id: string): Promise<User> {
    // Validate that id is a valid string and not a stringified object
    if (!id || typeof id !== 'string') {
      throw new BadRequestException('Invalid user ID: must be a string');
    }
    
    // Check if id looks like a JSON stringified object
    const trimmedId = id.trim();
    if (trimmedId.startsWith('{') || trimmedId.startsWith('[')) {
      throw new BadRequestException('Invalid user ID: received object instead of ID. Please ensure user ID is extracted correctly.');
    }
    
    // Validate ObjectId format (24 hex characters)
    if (!/^[0-9a-fA-F]{24}$/.test(trimmedId)) {
      throw new BadRequestException(`Invalid user ID format: ${trimmedId.substring(0, 50)}...`);
    }
    
    const user = await this.userModel.findById(trimmedId).select('-password').populate('departmentId').populate('officeId').populate('supervisorId').exec();
    if (!user) {
      throw new NotFoundException('User not found');
    }
    return user;
  }

  async findByEmail(email: string): Promise<UserDocument | null> {
    return this.userModel.findOne({ email }).populate('departmentId').populate('supervisorId').exec();
  }

  async update(id: string, updateUserDto: UpdateUserDto): Promise<User> {
    // If password is being updated, hash it
    if (updateUserDto.password) {
      updateUserDto.password = await bcrypt.hash(updateUserDto.password, 10);
    }

    // If department is being updated, verify it exists
    if (updateUserDto.departmentId) {
      const department = await this.departmentsService.findOne(updateUserDto.departmentId);
      if (!department) {
        throw new NotFoundException('Department not found');
      }
    }

    // If supervisor is being updated, verify it
    if (updateUserDto.supervisorId !== undefined) {
      if (updateUserDto.supervisorId) {
        const supervisor = await this.userModel.findById(updateUserDto.supervisorId);
        if (!supervisor) {
          throw new NotFoundException('Supervisor not found');
        }
        const user = await this.userModel.findById(id);
        if (supervisor.departmentId.toString() !== (updateUserDto.departmentId || user.departmentId.toString())) {
          throw new ConflictException('Supervisor must be from the same department');
        }
      }
    }

    const updatedUser = await this.userModel
      .findByIdAndUpdate(id, updateUserDto, { new: true })
      .select('-password')
      .populate('departmentId')
      .populate('supervisorId')
      .exec();

    if (!updatedUser) {
      throw new NotFoundException('User not found');
    }

    return updatedUser;
  }

  async remove(id: string): Promise<void> {
    const result = await this.userModel.findByIdAndDelete(id).exec();
    if (!result) {
      throw new NotFoundException('User not found');
    }
  }

  async updateFcmToken(userId: string, fcmToken: string): Promise<User> {
    return this.userModel
      .findByIdAndUpdate(userId, { fcmToken }, { new: true })
      .select('-password')
      .exec();
  }

  async getDashboard(userId: string) {
    const user = await this.findOne(userId);
    // This will be expanded later with actual request counts
    return {
      user,
      pendingApprovals: 0,
      myRequests: 0,
    };
  }

  async findByRoleAndDepartment(role: UserRole, departmentId: string): Promise<UserDocument[]> {
    return this.userModel
      .find({
        roles: role,
        departmentId: new Types.ObjectId(departmentId),
      })
      .select('-password')
      .exec();
  }

  /**
   * Find supervisors in a department
   * A supervisor is someone with level 14 and above in the same department
   */
  async findSupervisorsByDepartment(departmentId: string): Promise<UserDocument[]> {
    return this.userModel
      .find({
        level: { $gte: 14 },
        departmentId: new Types.ObjectId(departmentId),
      })
      .select('-password')
      .exec();
  }

  /**
   * Reset user password (Main Admin only)
   */
  async resetPassword(userId: string, newPassword: string): Promise<User> {
    const user = await this.userModel.findById(userId).exec();
    if (!user) {
      throw new NotFoundException('User not found');
    }
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    
    user.password = hashedPassword;
    const savedUser = await user.save();
    return savedUser.toObject();
  }

  /**
   * Assign roles to user (Main Admin only)
   */
  async assignRoles(userId: string, roles: UserRole[]): Promise<User> {
    const user = await this.userModel.findById(userId).exec();
    if (!user) {
      throw new NotFoundException('User not found');
    }
    user.roles = roles;
    const savedUser = await user.save();
    return savedUser.toObject();
  }

  /**
   * Perform bulk user operations (Main Admin only)
   */
  async bulkOperation(bulkOperationDto: BulkUserOperationDto): Promise<{
    success: number;
    failed: number;
    errors: any[];
  }> {
    const { operation, userIds, users, roles } = bulkOperationDto;
    let success = 0;
    let failed = 0;
    const errors: any[] = [];

    switch (operation) {
      case BulkOperationType.CREATE:
        if (!users || users.length === 0) {
          throw new BadRequestException('Users array is required for CREATE operation');
        }
        for (let i = 0; i < users.length; i++) {
          try {
            await this.create(users[i]);
            success++;
          } catch (error: any) {
            failed++;
            errors.push({
              index: i,
              user: users[i],
              error: error.message,
            });
          }
        }
        break;

      case BulkOperationType.UPDATE:
        if (!userIds || userIds.length === 0 || !users || users.length === 0) {
          throw new BadRequestException('UserIds and users arrays are required for UPDATE operation');
        }
        if (userIds.length !== users.length) {
          throw new BadRequestException('UserIds and users arrays must have the same length');
        }
        for (let i = 0; i < userIds.length; i++) {
          try {
            await this.update(userIds[i], users[i]);
            success++;
          } catch (error: any) {
            failed++;
            errors.push({
              userId: userIds[i],
              error: error.message,
            });
          }
        }
        break;

      case BulkOperationType.DELETE:
        if (!userIds || userIds.length === 0) {
          throw new BadRequestException('UserIds array is required for DELETE operation');
        }
        for (const userId of userIds) {
          try {
            await this.remove(userId);
            success++;
          } catch (error: any) {
            failed++;
            errors.push({
              userId,
              error: error.message,
            });
          }
        }
        break;

      case BulkOperationType.ASSIGN_ROLES:
        if (!userIds || userIds.length === 0 || !roles || roles.length === 0) {
          throw new BadRequestException('UserIds and roles arrays are required for ASSIGN_ROLES operation');
        }
        for (const userId of userIds) {
          try {
            await this.assignRoles(userId, roles as UserRole[]);
            success++;
          } catch (error: any) {
            failed++;
            errors.push({
              userId,
              error: error.message,
            });
          }
        }
        break;

      default:
        throw new BadRequestException(`Unknown operation: ${operation}`);
    }

    return { success, failed, errors };
  }
}

