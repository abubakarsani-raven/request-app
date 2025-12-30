import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UsersService } from '../users/users.service';
import * as bcrypt from 'bcrypt';
import { LoginDto } from './dto/login.dto';

@Injectable()
export class AuthService {
  constructor(
    private usersService: UsersService,
    private jwtService: JwtService,
  ) {}

  async validateUser(email: string, password: string): Promise<any> {
    const user = await this.usersService.findByEmail(email);
    if (!user) {
      console.log(`[AuthService] User not found: ${email}`);
      return null;
    }

    if (!user.password) {
      console.log(`[AuthService] User has no password: ${email}`);
      return null;
    }

    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      console.log(`[AuthService] Password mismatch for: ${email}`);
      console.log(`[AuthService] Provided password length: ${password.length}`);
      console.log(`[AuthService] Stored hash length: ${user.password.length}`);
      return null;
    }

    const { password: _, ...result } = user.toObject();
    return result;
  }

  async login(loginDto: LoginDto) {
    const user = await this.validateUser(loginDto.email, loginDto.password);
    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const payload = {
      email: user.email,
      sub: user._id.toString(),
      roles: user.roles,
      departmentId: user.departmentId,
      level: user.level,
    };

    return {
      access_token: this.jwtService.sign(payload),
      user: {
        _id: user._id,
        email: user.email,
        name: user.name,
        departmentId: user.departmentId,
        level: user.level,
        roles: user.roles,
        supervisorId: user.supervisorId,
      },
    };
  }

  async refreshToken(user: any) {
    const payload = {
      email: user.email,
      sub: user._id.toString(),
      roles: user.roles,
      departmentId: user.departmentId,
      level: user.level,
    };

    return {
      access_token: this.jwtService.sign(payload),
    };
  }
}

