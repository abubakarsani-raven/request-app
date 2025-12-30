import { IsEnum, IsOptional, IsString, IsDateString, IsArray } from 'class-validator';
import { RequestType, RequestStatus } from '../../shared/types';

export enum ReportType {
  REQUESTS = 'REQUESTS',
  VEHICLES = 'VEHICLES',
  DRIVERS = 'DRIVERS',
  FULFILLMENT = 'FULFILLMENT',
  APPROVALS = 'APPROVALS',
  INVENTORY = 'INVENTORY',
}

export class GenerateReportDto {
  @IsEnum(ReportType)
  reportType: ReportType;

  @IsOptional()
  @IsDateString()
  startDate?: string;

  @IsOptional()
  @IsDateString()
  endDate?: string;

  @IsOptional()
  @IsEnum(RequestType)
  requestType?: RequestType;

  @IsOptional()
  @IsEnum(RequestStatus)
  status?: RequestStatus;

  @IsOptional()
  @IsString()
  departmentId?: string;

  @IsOptional()
  @IsString()
  userId?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  vehicleIds?: string[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  driverIds?: string[];
}
