import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Settings, SettingsDocument } from './schemas/settings.schema';

@Injectable()
export class SettingsService {
  constructor(
    @InjectModel(Settings.name) private settingsModel: Model<SettingsDocument>,
  ) {
    this.initializeDefaultSettings();
  }

  private async initializeDefaultSettings() {
    const defaultSettings = [
      {
        key: 'email.from',
        value: process.env.EMAIL_FROM || 'noreply@requestapp.gov',
        description: 'Default sender email address',
        category: 'email',
      },
      {
        key: 'email.enabled',
        value: true,
        description: 'Enable email notifications',
        category: 'email',
      },
      {
        key: 'notification.push_enabled',
        value: true,
        description: 'Enable push notifications',
        category: 'notification',
      },
      {
        key: 'notification.email_enabled',
        value: true,
        description: 'Enable email notifications',
        category: 'notification',
      },
      {
        key: 'workflow.auto_approve',
        value: false,
        description: 'Auto-approve requests (for testing)',
        category: 'workflow',
      },
      {
        key: 'system.maintenance_mode',
        value: false,
        description: 'Enable maintenance mode',
        category: 'system',
      },
      {
        key: 'system.app_name',
        value: 'Government Request Management System',
        description: 'Application name',
        category: 'system',
      },
      {
        key: 'fuel_consumption_mpg',
        value: 14,
        description: 'Fuel consumption in MPG (Miles Per Gallon) for fuel estimation calculations',
        category: 'vehicle',
      },
    ];

    for (const setting of defaultSettings) {
      const exists = await this.settingsModel.findOne({ key: setting.key });
      if (!exists) {
        await this.settingsModel.create(setting);
      }
    }
  }

  async findAll(): Promise<Settings[]> {
    return this.settingsModel.find().sort({ category: 1, key: 1 }).exec();
  }

  async findByCategory(category: string): Promise<Settings[]> {
    return this.settingsModel.find({ category }).sort({ key: 1 }).exec();
  }

  async findOne(key: string): Promise<Settings> {
    const setting = await this.settingsModel.findOne({ key }).exec();
    if (!setting) {
      throw new NotFoundException(`Setting with key "${key}" not found`);
    }
    return setting;
  }

  async getValue<T = any>(key: string, defaultValue?: T): Promise<T> {
    try {
      const setting = await this.findOne(key);
      return setting.value as T;
    } catch (error) {
      if (defaultValue !== undefined) {
        return defaultValue;
      }
      throw error;
    }
  }

  async update(key: string, value: any, description?: string): Promise<Settings> {
    const setting = await this.settingsModel
      .findOneAndUpdate(
        { key },
        { value, description, updatedAt: new Date() },
        { new: true, upsert: true },
      )
      .exec();

    return setting;
  }

  async updateMany(settings: Array<{ key: string; value: any }>): Promise<void> {
    const bulkOps = settings.map(({ key, value }) => ({
      updateOne: {
        filter: { key },
        update: { $set: { value, updatedAt: new Date() } },
        upsert: true,
      },
    }));

    await this.settingsModel.bulkWrite(bulkOps);
  }

  async delete(key: string): Promise<void> {
    const result = await this.settingsModel.deleteOne({ key }).exec();
    if (result.deletedCount === 0) {
      throw new NotFoundException(`Setting with key "${key}" not found`);
    }
  }
}
