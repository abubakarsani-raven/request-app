import {
  Controller,
  Get,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { VehiclesService } from '../vehicles/vehicles.service';
import { RequestStatus } from '../shared/types';

@Controller('trips')
@UseGuards(JwtAuthGuard)
export class TripsController {
  constructor(private readonly vehiclesService: VehiclesService) {}

  @Get('active')
  async getActiveTrips() {
    const allRequests = await this.vehiclesService.findAllRequests();
    // Filter for active trips: tripStarted = true, tripCompleted = false
    return allRequests.filter(
      (req: any) =>
        req.tripStarted === true &&
        req.tripCompleted === false &&
        req.status !== RequestStatus.REJECTED &&
        req.status !== RequestStatus.COMPLETED,
    );
  }
}

