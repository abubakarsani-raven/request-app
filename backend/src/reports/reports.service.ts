import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { VehicleRequest, VehicleRequestDocument } from '../vehicles/schemas/vehicle-request.schema';
import { ICTRequest, ICTRequestDocument } from '../ict/schemas/ict-request.schema';
import { StoreRequest, StoreRequestDocument } from '../store/schemas/store-request.schema';
import { Vehicle, VehicleDocument } from '../vehicles/schemas/vehicle.schema';
import { Driver, DriverDocument } from '../vehicles/schemas/driver.schema';
import { ICTItem, ICTItemDocument } from '../ict/schemas/ict-item.schema';
import { StoreItem, StoreItemDocument } from '../store/schemas/store-item.schema';
import { RequestType, RequestStatus, WorkflowStage } from '../shared/types';
import { GenerateReportDto, ReportType } from './dto/generate-report.dto';
import { ExportFormat } from './dto/export-report.dto';
// Dynamic imports for report export dependencies
// Packages: exceljs, pdfkit (installed)
// @ts-ignore - Using require() for dynamic loading
const ExcelJS = require('exceljs');
// @ts-ignore - Using require() for dynamic loading
const PDFDocument = require('pdfkit');

@Injectable()
export class ReportsService {
  constructor(
    @InjectModel(VehicleRequest.name)
    private vehicleRequestModel: Model<VehicleRequestDocument>,
    @InjectModel(ICTRequest.name)
    private ictRequestModel: Model<ICTRequestDocument>,
    @InjectModel(StoreRequest.name)
    private storeRequestModel: Model<StoreRequestDocument>,
    @InjectModel(Vehicle.name)
    private vehicleModel: Model<VehicleDocument>,
    @InjectModel(Driver.name)
    private driverModel: Model<DriverDocument>,
    @InjectModel(ICTItem.name)
    private ictItemModel: Model<ICTItemDocument>,
    @InjectModel(StoreItem.name)
    private storeItemModel: Model<StoreItemDocument>,
  ) {}

  /**
   * Generate report data based on filters
   */
  async generateReport(dto: GenerateReportDto, userRoles: string[]) {
    const { reportType, startDate, endDate, requestType, status, departmentId, userId, vehicleIds, driverIds } = dto;

    const dateFilter: any = {};
    if (startDate) {
      dateFilter.$gte = new Date(startDate);
    }
    if (endDate) {
      dateFilter.$lte = new Date(endDate);
    }

    switch (reportType) {
      case ReportType.REQUESTS:
        return this.generateRequestsReport({
          dateFilter,
          requestType,
          status,
          departmentId,
          userId,
        });

      case ReportType.VEHICLES:
        return this.generateVehiclesReport({
          dateFilter,
          vehicleIds,
        });

      case ReportType.DRIVERS:
        return this.generateDriversReport({
          dateFilter,
          driverIds,
        });

      case ReportType.FULFILLMENT:
        return this.generateFulfillmentReport({
          dateFilter,
          requestType,
          departmentId,
        });

      case ReportType.APPROVALS:
        return this.generateApprovalsReport({
          dateFilter,
          requestType,
          departmentId,
        });

      case ReportType.INVENTORY:
        return this.generateInventoryReport({
          dateFilter,
          requestType,
        });

      default:
        throw new Error(`Unknown report type: ${reportType}`);
    }
  }

  /**
   * Generate requests report
   */
  private async generateRequestsReport(filters: {
    dateFilter: any;
    requestType?: RequestType;
    status?: RequestStatus;
    departmentId?: string;
    userId?: string;
  }) {
    const { dateFilter, requestType, status, departmentId, userId } = filters;

    const results: any[] = [];

    // Vehicle requests
    if (!requestType || requestType === RequestType.VEHICLE) {
      const query: any = {};
      if (Object.keys(dateFilter).length > 0) {
        query.createdAt = dateFilter;
      }
      if (status) {
        query.status = status;
      }
      if (userId) {
        query.requesterId = new Types.ObjectId(userId);
      }

      const vehicleRequests = await this.vehicleRequestModel
        .find(query)
        .populate({
          path: 'requesterId',
          select: 'name email departmentId',
          populate: {
            path: 'departmentId',
            select: 'name',
          },
        })
        .populate('vehicleId', 'plateNumber make model')
        .populate('driverId', 'name phone')
        .sort({ createdAt: -1 })
        .exec();

      for (const request of vehicleRequests) {
        if (departmentId && request.requesterId && (request.requesterId as any).departmentId?.toString() !== departmentId) {
          continue;
        }

        results.push({
          id: request._id,
          type: 'VEHICLE',
          requester: (request.requesterId as any)?.name || 'N/A',
          requesterEmail: (request.requesterId as any)?.email || 'N/A',
          department: (request.requesterId as any)?.departmentId?.name || 'N/A',
          tripDate: request.tripDate,
          destination: request.destination,
          status: request.status,
          workflowStage: request.workflowStage,
          vehicle: request.vehicleId ? `${(request.vehicleId as any).plateNumber} - ${(request.vehicleId as any).make} ${(request.vehicleId as any).model}` : 'N/A',
          driver: request.driverId ? (request.driverId as any).name : 'N/A',
          createdAt: (request as any).createdAt,
          updatedAt: (request as any).updatedAt,
        });
      }
    }

    // ICT requests
    if (!requestType || requestType === RequestType.ICT) {
      const query: any = {};
      if (Object.keys(dateFilter).length > 0) {
        query.createdAt = dateFilter;
      }
      if (status) {
        query.status = status;
      }
      if (userId) {
        query.requesterId = new Types.ObjectId(userId);
      }

      const ictRequests = await this.ictRequestModel
        .find(query)
        .populate({
          path: 'requesterId',
          select: 'name email departmentId',
          populate: {
            path: 'departmentId',
            select: 'name',
          },
        })
        .populate('items.itemId', 'name category')
        .sort({ createdAt: -1 })
        .exec();

      for (const request of ictRequests) {
        if (departmentId && request.requesterId && (request.requesterId as any).departmentId?.toString() !== departmentId) {
          continue;
        }

        const itemsSummary = request.items
          .map((item: any) => `${item.itemId?.name || 'N/A'} (Qty: ${item.quantity})`)
          .join(', ');

        results.push({
          id: request._id,
          type: 'ICT',
          requester: (request.requesterId as any)?.name || 'N/A',
          requesterEmail: (request.requesterId as any)?.email || 'N/A',
          department: (request.requesterId as any)?.departmentId?.name || 'N/A',
          items: itemsSummary,
          status: request.status,
          workflowStage: request.workflowStage,
          createdAt: (request as any).createdAt,
          updatedAt: (request as any).updatedAt,
        });
      }
    }

    // Store requests
    if (!requestType || requestType === RequestType.STORE) {
      const query: any = {};
      if (Object.keys(dateFilter).length > 0) {
        query.createdAt = dateFilter;
      }
      if (status) {
        query.status = status;
      }
      if (userId) {
        query.requesterId = new Types.ObjectId(userId);
      }

      const storeRequests = await this.storeRequestModel
        .find(query)
        .populate({
          path: 'requesterId',
          select: 'name email departmentId',
          populate: {
            path: 'departmentId',
            select: 'name',
          },
        })
        .populate('items.itemId', 'name category')
        .sort({ createdAt: -1 })
        .exec();

      for (const request of storeRequests) {
        if (departmentId && request.requesterId && (request.requesterId as any).departmentId?.toString() !== departmentId) {
          continue;
        }

        const itemsSummary = request.items
          .map((item: any) => `${item.itemId?.name || 'N/A'} (Qty: ${item.quantity})`)
          .join(', ');

        results.push({
          id: request._id,
          type: 'STORE',
          requester: (request.requesterId as any)?.name || 'N/A',
          requesterEmail: (request.requesterId as any)?.email || 'N/A',
          department: (request.requesterId as any)?.departmentId?.name || 'N/A',
          items: itemsSummary,
          status: request.status,
          workflowStage: request.workflowStage,
          createdAt: (request as any).createdAt,
          updatedAt: (request as any).updatedAt,
        });
      }
    }

    return {
      reportType: ReportType.REQUESTS,
      total: results.length,
      data: results,
      summary: {
        byType: this.groupBy(results, 'type'),
        byStatus: this.groupBy(results, 'status'),
        byDepartment: this.groupBy(results, 'department'),
      },
    };
  }

  /**
   * Generate vehicles report
   */
  private async generateVehiclesReport(filters: {
    dateFilter: any;
    vehicleIds?: string[];
  }) {
    const { dateFilter, vehicleIds } = filters;

    const query: any = {};
    if (vehicleIds && vehicleIds.length > 0) {
      query._id = { $in: vehicleIds.map((id) => new Types.ObjectId(id)) };
    }

    const vehicles = await this.vehicleModel
      .find(query)
      .populate('assignedToUserId', 'name email')
      .populate('officeId', 'name')
      .sort({ createdAt: -1 })
      .exec();

    // Get vehicle usage statistics
    const vehicleUsageQuery: any = {};
    if (Object.keys(dateFilter).length > 0) {
      vehicleUsageQuery.tripDate = dateFilter;
    }

    const vehicleRequests = await this.vehicleRequestModel
      .find(vehicleUsageQuery)
      .populate('vehicleId')
      .exec();

    const results = vehicles.map((vehicle) => {
      const requests = vehicleRequests.filter(
        (req) => req.vehicleId && (req.vehicleId as any)._id.toString() === vehicle._id.toString(),
      );

      const totalTrips = requests.length;
      const activeTrips = requests.filter((req) => req.status === RequestStatus.ASSIGNED).length;
      const completedTrips = requests.filter((req) => req.status === RequestStatus.COMPLETED).length;

      return {
        id: vehicle._id,
        plateNumber: vehicle.plateNumber,
        make: vehicle.make,
        model: vehicle.model,
        type: vehicle.type,
        year: vehicle.year,
        isAvailable: vehicle.isAvailable,
        assignedTo: vehicle.assignedToUserId ? (vehicle.assignedToUserId as any).name : 'N/A',
        office: vehicle.officeId ? (vehicle.officeId as any).name : 'N/A',
        totalTrips,
        activeTrips,
        completedTrips,
        utilizationRate: totalTrips > 0 ? ((completedTrips / totalTrips) * 100).toFixed(2) + '%' : '0%',
      };
    });

    return {
      reportType: ReportType.VEHICLES,
      total: results.length,
      data: results,
      summary: {
        totalVehicles: results.length,
        availableVehicles: results.filter((v) => v.isAvailable).length,
        totalTrips: results.reduce((sum, v) => sum + v.totalTrips, 0),
        averageUtilization: results.length > 0
          ? (results.reduce((sum, v) => sum + parseFloat(v.utilizationRate), 0) / results.length).toFixed(2) + '%'
          : '0%',
      },
    };
  }

  /**
   * Generate drivers report
   */
  private async generateDriversReport(filters: {
    dateFilter: any;
    driverIds?: string[];
  }) {
    const { dateFilter, driverIds } = filters;

    const query: any = {};
    if (driverIds && driverIds.length > 0) {
      query._id = { $in: driverIds.map((id) => new Types.ObjectId(id)) };
    }

    const drivers = await this.driverModel.find(query).sort({ createdAt: -1 }).exec();

    // Get driver assignment statistics
    const driverUsageQuery: any = {};
    if (Object.keys(dateFilter).length > 0) {
      driverUsageQuery.tripDate = dateFilter;
    }

    const driverRequests = await this.vehicleRequestModel
      .find(driverUsageQuery)
      .populate('driverId')
      .exec();

    const results = drivers.map((driver) => {
      const requests = driverRequests.filter(
        (req) => req.driverId && (req.driverId as any)._id.toString() === driver._id.toString(),
      );

      const totalTrips = requests.length;
      const activeTrips = requests.filter((req) => req.status === RequestStatus.ASSIGNED).length;
      const completedTrips = requests.filter((req) => req.status === RequestStatus.COMPLETED).length;

      return {
        id: driver._id,
        name: driver.name,
        phone: driver.phone,
        licenseNumber: driver.licenseNumber,
        isAvailable: driver.isAvailable,
        totalTrips,
        activeTrips,
        completedTrips,
        performanceRating: totalTrips > 0 ? ((completedTrips / totalTrips) * 100).toFixed(2) + '%' : '0%',
      };
    });

    return {
      reportType: ReportType.DRIVERS,
      total: results.length,
      data: results,
      summary: {
        totalDrivers: results.length,
        availableDrivers: results.filter((d) => d.isAvailable).length,
        totalTrips: results.reduce((sum, d) => sum + d.totalTrips, 0),
        averagePerformance: results.length > 0
          ? (results.reduce((sum, d) => sum + parseFloat(d.performanceRating), 0) / results.length).toFixed(2) + '%'
          : '0%',
      },
    };
  }

  /**
   * Generate fulfillment report
   */
  private async generateFulfillmentReport(filters: {
    dateFilter: any;
    requestType?: RequestType;
    departmentId?: string;
  }) {
    const { dateFilter, requestType, departmentId } = filters;

    const results: any[] = [];

    // ICT fulfillment
    if (!requestType || requestType === RequestType.ICT) {
      const query: any = {};
      if (Object.keys(dateFilter).length > 0) {
        query.createdAt = dateFilter;
      }
      query.status = { $in: [RequestStatus.FULFILLED, RequestStatus.COMPLETED] };

      const ictRequests = await this.ictRequestModel
        .find(query)
        .populate('requesterId', 'name email departmentId')
        .populate('items.itemId', 'name')
        .exec();

      for (const request of ictRequests) {
        if (departmentId && request.requesterId && (request.requesterId as any).departmentId?.toString() !== departmentId) {
          continue;
        }

        const totalItems = request.items.length;
        const fulfilledItems = request.items.filter((item: any) => item.fulfilledQuantity > 0).length;
        const fulfillmentRate = totalItems > 0 ? ((fulfilledItems / totalItems) * 100).toFixed(2) + '%' : '0%';

        results.push({
          id: request._id,
          type: 'ICT',
          requester: (request.requesterId as any)?.name || 'N/A',
          totalItems,
          fulfilledItems,
          fulfillmentRate,
          status: request.status,
          fulfilledAt: (request as any).updatedAt,
        });
      }
    }

    // Store fulfillment
    if (!requestType || requestType === RequestType.STORE) {
      const query: any = {};
      if (Object.keys(dateFilter).length > 0) {
        query.createdAt = dateFilter;
      }
      query.status = { $in: [RequestStatus.FULFILLED, RequestStatus.COMPLETED] };

      const storeRequests = await this.storeRequestModel
        .find(query)
        .populate('requesterId', 'name email departmentId')
        .populate('items.itemId', 'name')
        .exec();

      for (const request of storeRequests) {
        if (departmentId && request.requesterId && (request.requesterId as any).departmentId?.toString() !== departmentId) {
          continue;
        }

        const totalItems = request.items.length;
        const fulfilledItems = request.items.filter((item: any) => item.fulfilledQuantity > 0).length;
        const fulfillmentRate = totalItems > 0 ? ((fulfilledItems / totalItems) * 100).toFixed(2) + '%' : '0%';

        results.push({
          id: request._id,
          type: 'STORE',
          requester: (request.requesterId as any)?.name || 'N/A',
          totalItems,
          fulfilledItems,
          fulfillmentRate,
          status: request.status,
          fulfilledAt: (request as any).updatedAt,
        });
      }
    }

    return {
      reportType: ReportType.FULFILLMENT,
      total: results.length,
      data: results,
      summary: {
        totalRequests: results.length,
        averageFulfillmentRate: results.length > 0
          ? (results.reduce((sum, r) => sum + parseFloat(r.fulfillmentRate), 0) / results.length).toFixed(2) + '%'
          : '0%',
        byType: this.groupBy(results, 'type'),
      },
    };
  }

  /**
   * Generate approvals report
   */
  private async generateApprovalsReport(filters: {
    dateFilter: any;
    requestType?: RequestType;
    departmentId?: string;
  }) {
    const { dateFilter, requestType, departmentId } = filters;

    const results: any[] = [];

    // Get all requests with approvals
    const requestTypes: RequestType[] = requestType ? [requestType] : [RequestType.VEHICLE, RequestType.ICT, RequestType.STORE];

    for (const type of requestTypes) {
      let requests: any[] = [];

      if (type === RequestType.VEHICLE) {
        const query: any = {};
        if (Object.keys(dateFilter).length > 0) {
          query.createdAt = dateFilter;
        }
        requests = await this.vehicleRequestModel.find(query).populate('requesterId', 'departmentId').exec();
      } else if (type === RequestType.ICT) {
        const query: any = {};
        if (Object.keys(dateFilter).length > 0) {
          query.createdAt = dateFilter;
        }
        requests = await this.ictRequestModel.find(query).populate('requesterId', 'departmentId').exec();
      } else if (type === RequestType.STORE) {
        const query: any = {};
        if (Object.keys(dateFilter).length > 0) {
          query.createdAt = dateFilter;
        }
        requests = await this.storeRequestModel.find(query).populate('requesterId', 'departmentId').exec();
      }

      for (const request of requests) {
        if (departmentId && request.requesterId && (request.requesterId as any).departmentId?.toString() !== departmentId) {
          continue;
        }

        if (request.approvals && request.approvals.length > 0) {
          for (const approval of request.approvals) {
            const approvalTime = approval.timestamp;
            const requestTime = request.createdAt;
            const timeToApprove = approvalTime.getTime() - requestTime.getTime();
            const hoursToApprove = (timeToApprove / (1000 * 60 * 60)).toFixed(2);

            results.push({
              id: request._id,
              type,
              workflowStage: request.workflowStage,
              approvalStatus: approval.status,
              approverRole: approval.role,
              hoursToApprove: parseFloat(hoursToApprove),
              approvedAt: approval.timestamp,
            });
          }
        }
      }
    }

    return {
      reportType: ReportType.APPROVALS,
      total: results.length,
      data: results,
      summary: {
        totalApprovals: results.length,
        averageTimeToApprove: results.length > 0
          ? (results.reduce((sum, r) => sum + r.hoursToApprove, 0) / results.length).toFixed(2) + ' hours'
          : '0 hours',
        byStatus: this.groupBy(results, 'approvalStatus'),
        byRole: this.groupBy(results, 'approverRole'),
      },
    };
  }

  /**
   * Generate inventory report
   */
  private async generateInventoryReport(filters: {
    dateFilter: any;
    requestType?: RequestType;
  }) {
    const { dateFilter, requestType } = filters;

    const results: any[] = [];

    // ICT inventory
    if (!requestType || requestType === RequestType.ICT) {
      const ictItems = await this.ictItemModel.find().sort({ createdAt: -1 }).exec();

      for (const item of ictItems) {
        // Get movement history within date range
        const query: any = { itemId: item._id };
        if (Object.keys(dateFilter).length > 0) {
          query.createdAt = dateFilter;
        }

        results.push({
          id: item._id,
          type: 'ICT',
          name: item.name,
          category: item.category,
          quantity: item.quantity,
          isAvailable: item.isAvailable,
          lowStockThreshold: (item as any).lowStockThreshold || 0,
          isLowStock: item.quantity <= ((item as any).lowStockThreshold || 0),
        });
      }
    }

    // Store inventory
    if (!requestType || requestType === RequestType.STORE) {
      const storeItems = await this.storeItemModel.find().sort({ createdAt: -1 }).exec();

      for (const item of storeItems) {
        results.push({
          id: item._id,
          type: 'STORE',
          name: item.name,
          category: item.category,
          quantity: item.quantity,
          isAvailable: item.isAvailable,
          lowStockThreshold: (item as any).lowStockThreshold || 0,
          isLowStock: item.quantity <= ((item as any).lowStockThreshold || 0),
        });
      }
    }

    return {
      reportType: ReportType.INVENTORY,
      total: results.length,
      data: results,
      summary: {
        totalItems: results.length,
        lowStockItems: results.filter((i) => i.isLowStock).length,
        byType: this.groupBy(results, 'type'),
        byCategory: this.groupBy(results, 'category'),
      },
    };
  }

  /**
   * Export report to Excel
   */
  async exportToExcel(reportData: any, format: ExportFormat): Promise<Buffer> {
    try {
      const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet('Report');

    // Add headers based on report type
    const headers = this.getHeadersForReportType(reportData.reportType);
    worksheet.addRow(headers);

    // Style header row
    worksheet.getRow(1).font = { bold: true };
    worksheet.getRow(1).fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FFE0E0E0' },
    };

    // Add data rows
    for (const row of reportData.data) {
      const values = headers.map((header) => {
        const key = this.getKeyForHeader(header);
        return row[key] || '';
      });
      worksheet.addRow(values);
    }

    // Auto-fit columns
    worksheet.columns.forEach((column) => {
      column.width = 15;
    });

      // Generate buffer
      const buffer = await workbook.xlsx.writeBuffer();
      return Buffer.from(buffer);
    } catch (error: any) {
      if (error.code === 'MODULE_NOT_FOUND' || error.message?.includes('Cannot find module') || !ExcelJS) {
        throw new Error('exceljs package is not installed. Please run: npm install exceljs');
      }
      throw error;
    }
  }

  /**
   * Export report to PDF
   */
  async exportToPDF(reportData: any, format: ExportFormat): Promise<Buffer> {
    try {
      return new Promise((resolve, reject) => {
        const doc = new PDFDocument();
        const chunks: Buffer[] = [];

        doc.on('data', (chunk) => chunks.push(chunk));
        doc.on('end', () => resolve(Buffer.concat(chunks)));
        doc.on('error', reject);

        // Add title
        doc.fontSize(20).text(`Report: ${reportData.reportType}`, { align: 'center' });
        doc.moveDown();

        // Add summary
        doc.fontSize(14).text('Summary', { underline: true });
        doc.moveDown(0.5);
        doc.fontSize(12).text(`Total Records: ${reportData.total}`);
        if (reportData.summary) {
          for (const [key, value] of Object.entries(reportData.summary)) {
            doc.text(`${key}: ${JSON.stringify(value)}`);
          }
        }
        doc.moveDown();

        // Add data table
        doc.fontSize(14).text('Data', { underline: true });
        doc.moveDown(0.5);

        const headers = this.getHeadersForReportType(reportData.reportType);
        doc.fontSize(10).text(headers.join(' | '));
        doc.moveDown(0.3);

        for (const row of reportData.data.slice(0, 100)) { // Limit to 100 rows for PDF
          const values = headers.map((header) => {
            const key = this.getKeyForHeader(header);
            return String(row[key] || '');
          });
          doc.text(values.join(' | '), { fontSize: 8 });
        }

        doc.end();
      });
    } catch (error: any) {
      if (error.code === 'MODULE_NOT_FOUND' || error.message?.includes('Cannot find module')) {
        throw new Error('pdfkit package is not installed. Please run: npm install pdfkit');
      }
      throw error;
    }
  }

  /**
   * Get headers for report type
   */
  private getHeadersForReportType(reportType: ReportType): string[] {
    switch (reportType) {
      case ReportType.REQUESTS:
        return ['ID', 'Type', 'Requester', 'Email', 'Department', 'Status', 'Workflow Stage', 'Created At'];
      case ReportType.VEHICLES:
        return ['ID', 'Plate Number', 'Make', 'Model', 'Type', 'Total Trips', 'Active Trips', 'Utilization Rate'];
      case ReportType.DRIVERS:
        return ['ID', 'Name', 'Phone', 'License', 'Total Trips', 'Active Trips', 'Performance Rating'];
      case ReportType.FULFILLMENT:
        return ['ID', 'Type', 'Requester', 'Total Items', 'Fulfilled Items', 'Fulfillment Rate', 'Status'];
      case ReportType.APPROVALS:
        return ['ID', 'Type', 'Workflow Stage', 'Approval Status', 'Approver Role', 'Hours to Approve', 'Approved At'];
      case ReportType.INVENTORY:
        return ['ID', 'Type', 'Name', 'Category', 'Quantity', 'Low Stock Threshold', 'Is Low Stock'];
      default:
        return [];
    }
  }

  /**
   * Get key for header
   */
  private getKeyForHeader(header: string): string {
    const mapping: { [key: string]: string } = {
      'ID': 'id',
      'Type': 'type',
      'Requester': 'requester',
      'Email': 'requesterEmail',
      'Department': 'department',
      'Status': 'status',
      'Workflow Stage': 'workflowStage',
      'Created At': 'createdAt',
      'Plate Number': 'plateNumber',
      'Make': 'make',
      'Model': 'model',
      'Total Trips': 'totalTrips',
      'Active Trips': 'activeTrips',
      'Utilization Rate': 'utilizationRate',
      'Name': 'name',
      'Phone': 'phone',
      'License': 'licenseNumber',
      'Performance Rating': 'performanceRating',
      'Total Items': 'totalItems',
      'Fulfilled Items': 'fulfilledItems',
      'Fulfillment Rate': 'fulfillmentRate',
      'Approval Status': 'approvalStatus',
      'Approver Role': 'approverRole',
      'Hours to Approve': 'hoursToApprove',
      'Approved At': 'approvedAt',
      'Category': 'category',
      'Quantity': 'quantity',
      'Low Stock Threshold': 'lowStockThreshold',
      'Is Low Stock': 'isLowStock',
    };
    return mapping[header] || header.toLowerCase().replace(/\s+/g, '');
  }

  /**
   * Group array by key
   */
  private groupBy(array: any[], key: string): { [key: string]: number } {
    return array.reduce((result, item) => {
      const value = item[key] || 'N/A';
      result[value] = (result[value] || 0) + 1;
      return result;
    }, {});
  }
}
