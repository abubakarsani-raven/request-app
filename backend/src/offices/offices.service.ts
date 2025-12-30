import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Office, OfficeDocument } from './schemas/office.schema';
import { CreateOfficeDto } from './dto/create-office.dto';
import { UpdateOfficeDto } from './dto/update-office.dto';

@Injectable()
export class OfficesService {
  constructor(
    @InjectModel(Office.name) private officeModel: Model<OfficeDocument>,
  ) {}

  async create(createOfficeDto: CreateOfficeDto): Promise<Office> {
    const createdOffice = new this.officeModel(createOfficeDto);
    return createdOffice.save();
  }

  async findAll(): Promise<Office[]> {
    return this.officeModel.find().exec();
  }

  async findOne(id: string): Promise<Office> {
    const office = await this.officeModel.findById(id).exec();
    if (!office) {
      throw new NotFoundException('Office not found');
    }
    return office;
  }

  async update(id: string, updateOfficeDto: UpdateOfficeDto): Promise<Office> {
    const office = await this.officeModel
      .findByIdAndUpdate(id, updateOfficeDto, { new: true })
      .exec();
    if (!office) {
      throw new NotFoundException('Office not found');
    }
    return office;
  }

  async remove(id: string): Promise<Office> {
    const office = await this.officeModel.findByIdAndDelete(id).exec();
    if (!office) {
      throw new NotFoundException('Office not found');
    }
    return office;
  }

  async findHeadOffice(): Promise<OfficeDocument | null> {
    return this.officeModel.findOne({ isHeadOffice: true }).exec();
  }
}


