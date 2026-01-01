import {
  Controller,
  Get,
  Put,
  Param,
  Body,
  Query,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { VehiclesService } from '../vehicles/vehicles.service';
import { ICTService } from '../ict/ict.service';
import { StoreService } from '../store/store.service';
import { ApproveRequestDto } from '../vehicles/dto/approve-request.dto';
import { RejectRequestDto } from '../vehicles/dto/reject-request.dto';
import { CorrectRequestDto } from '../vehicles/dto/correct-request.dto';

@Controller('requests')
@UseGuards(JwtAuthGuard)
export class RequestsController {
  constructor(
    private readonly vehiclesService: VehiclesService,
    private readonly ictService: ICTService,
    private readonly storeService: StoreService,
  ) {}

  // Vehicle Requests
  @Get('vehicle')
  async getVehicleRequests(
    @CurrentUser() user: any,
    @Query('myRequests') myRequests?: string,
    @Query('pending') pending?: string,
  ) {
    if (myRequests === 'true') {
      return this.vehiclesService.findAllRequests(user._id || user.id);
    }
    if (pending === 'true') {
      return this.vehiclesService.findPendingApprovals(user._id || user.id, user.roles);
    }
    return this.vehiclesService.findAllRequests();
  }

  @Put('vehicle/:id/approve')
  async approveVehicleRequest(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body() approveDto: ApproveRequestDto,
  ) {
    return this.vehiclesService.approveRequest(id, user._id || user.id, user.roles, approveDto);
  }

  @Put('vehicle/:id/reject')
  async rejectVehicleRequest(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body() rejectDto: RejectRequestDto,
  ) {
    return this.vehiclesService.rejectRequest(id, user._id || user.id, user.roles, rejectDto);
  }

  @Put('vehicle/:id/send-back-for-correction')
  async sendBackVehicleRequest(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body() correctDto: CorrectRequestDto,
  ) {
    return this.vehiclesService.correctRequest(id, user._id || user.id, user.roles, correctDto);
  }

  @Put('vehicle/:id/cancel')
  async cancelVehicleRequest(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body() body: { reason?: string },
  ) {
    return this.vehiclesService.cancelRequest(id, user._id || user.id, user.roles, body);
  }

  @Get('vehicle/:id')
  async getVehicleRequest(@Param('id') id: string) {
    return this.vehiclesService.findOneRequest(id);
  }

  // ICT Requests
  @Get('ict')
  async getICTRequests(
    @CurrentUser() user: any,
    @Query('myRequests') myRequests?: string,
    @Query('pending') pending?: string,
  ) {
    if (myRequests === 'true') {
      return this.ictService.findAllRequests(user._id || user.id);
    }
    if (pending === 'true') {
      return this.ictService.findPendingApprovals(user._id || user.id, user.roles);
    }
    return this.ictService.findAllRequests();
  }

  @Put('ict/:id/approve')
  async approveICTRequest(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body() approveDto: ApproveRequestDto,
  ) {
    return this.ictService.approveRequest(id, user._id || user.id, user.roles, approveDto);
  }

  @Put('ict/:id/reject')
  async rejectICTRequest(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body() rejectDto: RejectRequestDto,
  ) {
    return this.ictService.rejectRequest(id, user._id || user.id, user.roles, rejectDto);
  }

  @Put('ict/:id/send-back-for-correction')
  async sendBackICTRequest(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body() correctDto: CorrectRequestDto,
  ) {
    // ICT service doesn't have correctRequest, use reject with correction status
    // This will need to be implemented in ICT service if needed
    const rejectDto: RejectRequestDto = {
      comment: correctDto.comment || 'Request sent back for correction',
    };
    return this.ictService.rejectRequest(id, user._id || user.id, user.roles, rejectDto);
  }

  @Put('ict/:id/cancel')
  async cancelICTRequest(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body() body: { reason?: string },
  ) {
    return this.ictService.cancelRequest(id, user._id || user.id, user.roles, body);
  }

  @Get('ict/:id')
  async getICTRequest(@Param('id') id: string) {
    return this.ictService.findOneRequest(id);
  }

  // Store Requests
  @Get('store')
  async getStoreRequests(
    @CurrentUser() user: any,
    @Query('myRequests') myRequests?: string,
    @Query('pending') pending?: string,
  ) {
    if (myRequests === 'true') {
      return this.storeService.findAllRequests(user._id || user.id);
    }
    if (pending === 'true') {
      return this.storeService.findPendingApprovals(user._id || user.id, user.roles);
    }
    return this.storeService.findAllRequests();
  }

  @Put('store/:id/approve')
  async approveStoreRequest(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body() approveDto: ApproveRequestDto,
  ) {
    return this.storeService.approveRequest(id, user._id || user.id, user.roles, approveDto);
  }

  @Put('store/:id/reject')
  async rejectStoreRequest(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body() rejectDto: RejectRequestDto,
  ) {
    return this.storeService.rejectRequest(id, user._id || user.id, user.roles, rejectDto);
  }

  @Put('store/:id/send-back-for-correction')
  async sendBackStoreRequest(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body() correctDto: CorrectRequestDto,
  ) {
    // Store service doesn't have correctRequest, use reject with correction status
    // This will need to be implemented in Store service if needed
    const rejectDto: RejectRequestDto = {
      comment: correctDto.comment || 'Request sent back for correction',
    };
    return this.storeService.rejectRequest(id, user._id || user.id, user.roles, rejectDto);
  }

  @Put('store/:id/cancel')
  async cancelStoreRequest(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body() body: { reason?: string },
  ) {
    return this.storeService.cancelRequest(id, user._id || user.id, user.roles, body);
  }

  @Get('store/:id')
  async getStoreRequest(@Param('id') id: string) {
    return this.storeService.findOneRequest(id);
  }
}

