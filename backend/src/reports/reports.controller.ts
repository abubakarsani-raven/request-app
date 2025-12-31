import { Controller, Get, Post, Query, Body, UseGuards, Res, HttpStatus, BadRequestException } from '@nestjs/common';
import { Response } from 'express';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { ReportsService } from './reports.service';
import { GenerateReportDto } from './dto/generate-report.dto';
import { ExportReportDto, ExportFormat } from './dto/export-report.dto';
import { AdminRoleService } from '../common/services/admin-role.service';
import { UserRole } from '../shared/types';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';

@Controller('reports')
@UseGuards(JwtAuthGuard)
export class ReportsController {
  constructor(
    private readonly reportsService: ReportsService,
    private readonly adminRoleService: AdminRoleService,
  ) {}

  @Get('requests')
  async getRequestsReport(
    @CurrentUser() user: any,
    @Query() query: any,
  ) {
    const userRoles = (user.roles || []) as UserRole[];
    
    // Check if user has permission (any admin can view reports)
    if (!this.adminRoleService.isAnyAdmin(userRoles)) {
      throw new Error('Unauthorized: Admin access required');
    }

    const dto: GenerateReportDto = {
      reportType: (query.reportType || 'REQUESTS') as any,
      startDate: query.startDate,
      endDate: query.endDate,
      requestType: query.requestType as any,
      status: query.status as any,
      departmentId: query.departmentId,
      userId: query.userId,
    };

    return this.reportsService.generateReport(dto, userRoles);
  }

  @Get('vehicles')
  async getVehiclesReport(
    @CurrentUser() user: any,
    @Query() query: GenerateReportDto,
  ) {
    const userRoles = (user.roles || []) as UserRole[];
    
    if (!this.adminRoleService.isAnyAdmin(userRoles)) {
      throw new Error('Unauthorized: Admin access required');
    }

    const dto: GenerateReportDto = {
      reportType: query.reportType as any,
      startDate: query.startDate,
      endDate: query.endDate,
      vehicleIds: query.vehicleIds,
    };

    return this.reportsService.generateReport(dto, userRoles);
  }

  @Get('drivers')
  async getDriversReport(
    @CurrentUser() user: any,
    @Query() query: GenerateReportDto,
  ) {
    const userRoles = (user.roles || []) as UserRole[];
    
    if (!this.adminRoleService.isAnyAdmin(userRoles)) {
      throw new Error('Unauthorized: Admin access required');
    }

    const dto: GenerateReportDto = {
      reportType: query.reportType as any,
      startDate: query.startDate,
      endDate: query.endDate,
      driverIds: query.driverIds,
    };

    return this.reportsService.generateReport(dto, userRoles);
  }

  @Get('fulfillment')
  async getFulfillmentReport(
    @CurrentUser() user: any,
    @Query() query: GenerateReportDto,
  ) {
    const userRoles = (user.roles || []) as UserRole[];
    
    if (!this.adminRoleService.isAnyAdmin(userRoles)) {
      throw new Error('Unauthorized: Admin access required');
    }

    const dto: GenerateReportDto = {
      reportType: query.reportType as any,
      startDate: query.startDate,
      endDate: query.endDate,
      requestType: query.requestType as any,
      departmentId: query.departmentId,
    };

    return this.reportsService.generateReport(dto, userRoles);
  }

  @Get('approvals')
  async getApprovalsReport(
    @CurrentUser() user: any,
    @Query() query: GenerateReportDto,
  ) {
    const userRoles = (user.roles || []) as UserRole[];
    
    if (!this.adminRoleService.isAnyAdmin(userRoles)) {
      throw new Error('Unauthorized: Admin access required');
    }

    const dto: GenerateReportDto = {
      reportType: query.reportType as any,
      startDate: query.startDate,
      endDate: query.endDate,
      requestType: query.requestType as any,
      departmentId: query.departmentId,
    };

    return this.reportsService.generateReport(dto, userRoles);
  }

  @Get('inventory')
  async getInventoryReport(
    @CurrentUser() user: any,
    @Query() query: GenerateReportDto,
  ) {
    const userRoles = (user.roles || []) as UserRole[];
    
    if (!this.adminRoleService.isAnyAdmin(userRoles)) {
      throw new Error('Unauthorized: Admin access required');
    }

    const dto: GenerateReportDto = {
      reportType: query.reportType as any,
      startDate: query.startDate,
      endDate: query.endDate,
      requestType: query.requestType as any,
    };

    return this.reportsService.generateReport(dto, userRoles);
  }

  @Post('export')
  async exportReport(
    @CurrentUser() user: any,
    @Body() body: any,
    @Query() query: any,
    @Res() res: Response,
  ) {
    const userRoles = (user.roles || []) as UserRole[];
    
    if (!this.adminRoleService.isAnyAdmin(userRoles)) {
      return res.status(HttpStatus.FORBIDDEN).json({ message: 'Unauthorized: Admin access required' });
    }

    try {
      // Merge query parameters with body (query params take precedence)
      const mergedData: any = {
        reportType: query.reportType || body.reportType,
        format: query.format || body.format,
        startDate: query.startDate || body.startDate,
        endDate: query.endDate || body.endDate,
        requestType: query.requestType || body.requestType,
        status: query.status || body.status,
        departmentId: query.departmentId || body.departmentId,
        userId: query.userId || body.userId,
      };

      // Validate required fields
      if (!mergedData.reportType) {
        return res.status(HttpStatus.BAD_REQUEST).json({
          message: 'Validation failed',
          errors: [{ property: 'reportType', constraints: { isEnum: 'reportType is required' } }],
        });
      }

      if (!mergedData.format) {
        return res.status(HttpStatus.BAD_REQUEST).json({
          message: 'Validation failed',
          errors: [{ property: 'format', constraints: { isEnum: 'format is required' } }],
        });
      }

      // Validate the DTO
      const dto = plainToInstance(ExportReportDto, mergedData);
      const errors = await validate(dto, { skipMissingProperties: false });
      
      if (errors.length > 0) {
        return res.status(HttpStatus.BAD_REQUEST).json({
          message: 'Validation failed',
          errors: errors,
        });
      }

      // Generate report data
      const reportData = await this.reportsService.generateReport(dto, userRoles);

      // Export based on format
      let buffer: Buffer;
      let contentType: string;
      let filename: string;

      if (dto.format === ExportFormat.EXCEL) {
        buffer = await this.reportsService.exportToExcel(reportData, dto.format);
        contentType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
        filename = `report_${dto.reportType}_${new Date().toISOString().split('T')[0]}.xlsx`;
      } else {
        buffer = await this.reportsService.exportToPDF(reportData, dto.format);
        contentType = 'application/pdf';
        filename = `report_${dto.reportType}_${new Date().toISOString().split('T')[0]}.pdf`;
      }

      res.setHeader('Content-Type', contentType);
      res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
      res.send(buffer);
    } catch (error) {
      res.status(HttpStatus.INTERNAL_SERVER_ERROR).json({
        message: 'Error exporting report',
        error: error.message,
      });
    }
  }
}
