import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { QRService } from './qr.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../shared/types';

@Controller('qr')
@UseGuards(JwtAuthGuard)
export class QRController {
  constructor(private readonly qrService: QRService) {}

  @Get(':code/verify')
  @UseGuards(RolesGuard)
  @Roles(UserRole.SO)
  async verifyQRCode(@Param('code') code: string) {
    return this.qrService.verifyQRCode(code);
  }
}

