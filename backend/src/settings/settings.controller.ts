import {
  Controller,
  Get,
  Put,
  Body,
  Param,
  UseGuards,
  Query,
  BadRequestException,
} from '@nestjs/common';
import { SettingsService } from './settings.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../shared/types';

@Controller('settings')
@UseGuards(JwtAuthGuard)
export class SettingsController {
  constructor(private readonly settingsService: SettingsService) {}

  @Get()
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  findAll(@Query('category') category?: string) {
    if (category) {
      return this.settingsService.findByCategory(category);
    }
    return this.settingsService.findAll();
  }

  @Get(':key')
  getOne(@Param('key') key: string) {
    return this.settingsService.findOne(key);
  }

  @Put(':key')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  update(
    @Param('key') key: string,
    @Body() body: { value: any; description?: string },
  ) {
    if (body.value === undefined) {
      throw new BadRequestException('Value is required');
    }
    return this.settingsService.update(key, body.value, body.description);
  }

  @Put()
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  updateMany(@Body() body: { settings: Array<{ key: string; value: any }> }) {
    if (!body.settings || !Array.isArray(body.settings)) {
      throw new BadRequestException('Settings array is required');
    }
    return this.settingsService.updateMany(body.settings);
  }
}
