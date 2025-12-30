import {
  Controller,
  Get,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { VehiclesService } from '../vehicles/vehicles.service';

@Controller('assignments')
@UseGuards(JwtAuthGuard)
export class AssignmentsController {
  constructor(private readonly vehiclesService: VehiclesService) {}

  @Get('available-vehicles')
  async getAvailableVehicles() {
    return this.vehiclesService.findAvailableVehicles();
  }

  @Get('available-drivers')
  async getAvailableDrivers() {
    return this.vehiclesService.findAvailableDrivers();
  }
}

