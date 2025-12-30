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
import { RequestType, RequestStatus, WorkflowStage, UserRole } from '../shared/types';
import { AdminRoleService } from '../common/services/admin-role.service';

@Injectable()
export class AnalyticsService {
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
    private adminRoleService: AdminRoleService,
  ) {}

  /**
   * Get dashboard metrics based on user role
   */
  async getDashboardMetrics(userRoles: UserRole[]) {
    const isMainAdmin = this.adminRoleService.isMainAdmin(userRoles);
    const isICTAdmin = this.adminRoleService.isICTAdmin(userRoles);
    const isStoreAdmin = this.adminRoleService.isStoreAdmin(userRoles);
    const isTransportAdmin = this.adminRoleService.isTransportAdmin(userRoles);

    const metrics: any = {};

    // Main Admin or Transport Admin - Vehicle metrics
    if (isMainAdmin || isTransportAdmin) {
      metrics.vehicles = await this.getVehicleMetrics();
    }

    // Main Admin or Transport Admin - Driver metrics
    if (isMainAdmin || isTransportAdmin) {
      metrics.drivers = await this.getDriverMetrics();
    }

    // Main Admin or ICT Admin - ICT metrics
    if (isMainAdmin || isICTAdmin) {
      metrics.ict = await this.getICTMetrics();
    }

    // Main Admin or Store Admin - Store metrics
    if (isMainAdmin || isStoreAdmin) {
      metrics.store = await this.getStoreMetrics();
    }

    // All admins - Request metrics (filtered by role)
    metrics.requests = await this.getRequestMetrics(userRoles);

    return metrics;
  }

  /**
   * Get request statistics
   */
  async getRequestStatistics(filters?: {
    requestType?: RequestType;
    status?: RequestStatus;
    dateFrom?: Date;
    dateTo?: Date;
  }) {
    const { requestType, status, dateFrom, dateTo } = filters || {};

    const dateFilter: any = {};
    if (dateFrom) {
      dateFilter.$gte = dateFrom;
    }
    if (dateTo) {
      dateFilter.$lte = dateTo;
    }

    const results: any = {
      total: 0,
      byType: {},
      byStatus: {},
      byStage: {},
      pending: 0,
      approved: 0,
      rejected: 0,
      fulfilled: 0,
      activeTrips: 0,
    };

    // Vehicle requests
    if (!requestType || requestType === RequestType.VEHICLE) {
      const query: any = {};
      if (Object.keys(dateFilter).length > 0) {
        query.createdAt = dateFilter;
      }
      if (status) {
        query.status = status;
      }

      const vehicleRequests = await this.vehicleRequestModel.find(query).exec();
      results.total += vehicleRequests.length;
      results.byType.VEHICLE = vehicleRequests.length;
      results.pending += vehicleRequests.filter((r) => r.status === RequestStatus.PENDING).length;
      results.approved += vehicleRequests.filter((r) => r.status === RequestStatus.APPROVED).length;
      results.rejected += vehicleRequests.filter((r) => r.status === RequestStatus.REJECTED).length;
      results.activeTrips += vehicleRequests.filter((r) => r.status === RequestStatus.ASSIGNED).length;

      // Group by workflow stage
      vehicleRequests.forEach((r) => {
        results.byStage[r.workflowStage] = (results.byStage[r.workflowStage] || 0) + 1;
      });
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

      const ictRequests = await this.ictRequestModel.find(query).exec();
      results.total += ictRequests.length;
      results.byType.ICT = ictRequests.length;
      results.pending += ictRequests.filter((r) => r.status === RequestStatus.PENDING).length;
      results.approved += ictRequests.filter((r) => r.status === RequestStatus.APPROVED).length;
      results.rejected += ictRequests.filter((r) => r.status === RequestStatus.REJECTED).length;
      results.fulfilled += ictRequests.filter((r) => r.status === RequestStatus.FULFILLED).length;

      ictRequests.forEach((r) => {
        results.byStage[r.workflowStage] = (results.byStage[r.workflowStage] || 0) + 1;
      });
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

      const storeRequests = await this.storeRequestModel.find(query).exec();
      results.total += storeRequests.length;
      results.byType.STORE = storeRequests.length;
      results.pending += storeRequests.filter((r) => r.status === RequestStatus.PENDING).length;
      results.approved += storeRequests.filter((r) => r.status === RequestStatus.APPROVED).length;
      results.rejected += storeRequests.filter((r) => r.status === RequestStatus.REJECTED).length;
      results.fulfilled += storeRequests.filter((r) => r.status === RequestStatus.FULFILLED).length;

      storeRequests.forEach((r) => {
        results.byStage[r.workflowStage] = (results.byStage[r.workflowStage] || 0) + 1;
      });
    }

    // Calculate percentages
    results.byStatus = {
      PENDING: results.pending,
      APPROVED: results.approved,
      REJECTED: results.rejected,
      FULFILLED: results.fulfilled,
      ACTIVE_TRIPS: results.activeTrips,
    };

    return results;
  }

  /**
   * Get vehicle statistics
   */
  async getVehicleStatistics() {
    const vehicles = await this.vehicleModel.find().exec();
    const vehicleRequests = await this.vehicleRequestModel.find().exec();

    const totalVehicles = vehicles.length;
    const availableVehicles = vehicles.filter((v) => v.isAvailable).length;
    const totalTrips = vehicleRequests.length;
    const activeTrips = vehicleRequests.filter((r) => r.status === RequestStatus.ASSIGNED).length;
    const completedTrips = vehicleRequests.filter((r) => r.status === RequestStatus.COMPLETED).length;

    // Calculate utilization rate per vehicle
    const vehicleUtilization: any[] = [];
    for (const vehicle of vehicles) {
      const vehicleTrips = vehicleRequests.filter(
        (r) => r.vehicleId && (r.vehicleId as any).toString() === vehicle._id.toString(),
      );
      const utilization = vehicleTrips.length > 0
        ? ((vehicleTrips.filter((r) => r.status === RequestStatus.COMPLETED).length / vehicleTrips.length) * 100).toFixed(2)
        : '0';

      vehicleUtilization.push({
        vehicleId: vehicle._id,
        plateNumber: vehicle.plateNumber,
        make: vehicle.make,
        model: vehicle.model,
        totalTrips: vehicleTrips.length,
        utilizationRate: parseFloat(utilization),
      });
    }

    return {
      totalVehicles,
      availableVehicles,
      totalTrips,
      activeTrips,
      completedTrips,
      utilizationRate: totalTrips > 0 ? ((completedTrips / totalTrips) * 100).toFixed(2) : '0',
      vehicleUtilization,
    };
  }

  /**
   * Get driver statistics
   */
  async getDriverStatistics() {
    const drivers = await this.driverModel.find().exec();
    const driverRequests = await this.vehicleRequestModel.find().exec();

    const totalDrivers = drivers.length;
    const availableDrivers = drivers.filter((d) => d.isAvailable).length;
    const totalTrips = driverRequests.length;
    const activeTrips = driverRequests.filter((r) => r.status === RequestStatus.ASSIGNED).length;
    const completedTrips = driverRequests.filter((r) => r.status === RequestStatus.COMPLETED).length;

    // Calculate performance per driver
    const driverPerformance: any[] = [];
    for (const driver of drivers) {
      const driverTrips = driverRequests.filter(
        (r) => r.driverId && (r.driverId as any).toString() === driver._id.toString(),
      );
      const performance = driverTrips.length > 0
        ? ((driverTrips.filter((r) => r.status === RequestStatus.COMPLETED).length / driverTrips.length) * 100).toFixed(2)
        : '0';

      driverPerformance.push({
        driverId: driver._id,
        name: driver.name,
        phone: driver.phone,
        totalTrips: driverTrips.length,
        performanceRating: parseFloat(performance),
      });
    }

    return {
      totalDrivers,
      availableDrivers,
      totalTrips,
      activeTrips,
      completedTrips,
      averagePerformance: totalTrips > 0 ? ((completedTrips / totalTrips) * 100).toFixed(2) : '0',
      driverPerformance,
    };
  }

  /**
   * Get inventory statistics
   */
  async getInventoryStatistics(requestType?: RequestType) {
    const results: any = {
      totalItems: 0,
      lowStockItems: 0,
      byType: {},
      byCategory: {},
    };

    // ICT inventory
    if (!requestType || requestType === RequestType.ICT) {
      const ictItems = await this.ictItemModel.find().exec();
      results.totalItems += ictItems.length;
      results.byType.ICT = ictItems.length;
      results.lowStockItems += ictItems.filter((i) => i.quantity <= (i.lowStockThreshold || 0)).length;

      ictItems.forEach((item) => {
        results.byCategory[item.category] = (results.byCategory[item.category] || 0) + 1;
      });
    }

    // Store inventory
    if (!requestType || requestType === RequestType.STORE) {
      const storeItems = await this.storeItemModel.find().exec();
      results.totalItems += storeItems.length;
      results.byType.STORE = storeItems.length;
      results.lowStockItems += storeItems.filter((i) => i.quantity <= ((i as any).lowStockThreshold || 0)).length;

      storeItems.forEach((item) => {
        results.byCategory[item.category] = (results.byCategory[item.category] || 0) + 1;
      });
    }

    return results;
  }

  /**
   * Get fulfillment rates
   */
  async getFulfillmentRates(filters?: {
    requestType?: RequestType;
    dateFrom?: Date;
    dateTo?: Date;
  }) {
    const { requestType, dateFrom, dateTo } = filters || {};

    const dateFilter: any = {};
    if (dateFrom) {
      dateFilter.$gte = dateFrom;
    }
    if (dateTo) {
      dateFilter.$lte = dateTo;
    }

    const results: any = {
      totalRequests: 0,
      fulfilledRequests: 0,
      fulfillmentRate: 0,
      byType: {},
    };

    // ICT fulfillment
    if (!requestType || requestType === RequestType.ICT) {
      const query: any = {};
      if (Object.keys(dateFilter).length > 0) {
        query.createdAt = dateFilter;
      }

      const ictRequests = await this.ictRequestModel.find(query).exec();
      const fulfilled = ictRequests.filter((r) => r.status === RequestStatus.FULFILLED || r.status === RequestStatus.COMPLETED);
      results.totalRequests += ictRequests.length;
      results.fulfilledRequests += fulfilled.length;
      results.byType.ICT = {
        total: ictRequests.length,
        fulfilled: fulfilled.length,
        rate: ictRequests.length > 0 ? ((fulfilled.length / ictRequests.length) * 100).toFixed(2) : '0',
      };
    }

    // Store fulfillment
    if (!requestType || requestType === RequestType.STORE) {
      const query: any = {};
      if (Object.keys(dateFilter).length > 0) {
        query.createdAt = dateFilter;
      }

      const storeRequests = await this.storeRequestModel.find(query).exec();
      const fulfilled = storeRequests.filter((r) => r.status === RequestStatus.FULFILLED || r.status === RequestStatus.COMPLETED);
      results.totalRequests += storeRequests.length;
      results.fulfilledRequests += fulfilled.length;
      results.byType.STORE = {
        total: storeRequests.length,
        fulfilled: fulfilled.length,
        rate: storeRequests.length > 0 ? ((fulfilled.length / storeRequests.length) * 100).toFixed(2) : '0',
      };
    }

    results.fulfillmentRate = results.totalRequests > 0
      ? ((results.fulfilledRequests / results.totalRequests) * 100).toFixed(2)
      : '0';

    return results;
  }

  /**
   * Private helper methods
   */
  private async getVehicleMetrics() {
    const vehicles = await this.vehicleModel.find().exec();
    const activeTrips = await this.vehicleRequestModel.countDocuments({ status: RequestStatus.ASSIGNED }).exec();

    return {
      total: vehicles.length,
      available: vehicles.filter((v) => v.isAvailable).length,
      activeTrips,
    };
  }

  private async getDriverMetrics() {
    const drivers = await this.driverModel.find().exec();
    const activeTrips = await this.vehicleRequestModel.countDocuments({ status: RequestStatus.ASSIGNED }).exec();

    return {
      total: drivers.length,
      available: drivers.filter((d) => d.isAvailable).length,
      activeTrips,
    };
  }

  private async getICTMetrics() {
    const items = await this.ictItemModel.find().exec();
    const pendingRequests = await this.ictRequestModel.countDocuments({ status: RequestStatus.PENDING }).exec();
    const lowStockItems = items.filter((i) => i.quantity <= (i.lowStockThreshold || 0)).length;

    return {
      totalItems: items.length,
      pendingRequests,
      lowStockItems,
    };
  }

  private async getStoreMetrics() {
    const items = await this.storeItemModel.find().exec();
    const pendingRequests = await this.storeRequestModel.countDocuments({ status: RequestStatus.PENDING }).exec();
    const lowStockItems = items.filter((i) => i.quantity <= ((i as any).lowStockThreshold || 0)).length;

    return {
      totalItems: items.length,
      pendingRequests,
      lowStockItems,
    };
  }

  private async getRequestMetrics(userRoles: UserRole[]) {
    const isMainAdmin = this.adminRoleService.isMainAdmin(userRoles);
    const isICTAdmin = this.adminRoleService.isICTAdmin(userRoles);
    const isStoreAdmin = this.adminRoleService.isStoreAdmin(userRoles);
    const isTransportAdmin = this.adminRoleService.isTransportAdmin(userRoles);

    const metrics: any = {
      total: 0,
      pending: 0,
      byType: {},
    };

    // Vehicle requests
    if (isMainAdmin || isTransportAdmin) {
      const vehiclePending = await this.vehicleRequestModel.countDocuments({ status: RequestStatus.PENDING }).exec();
      const vehicleTotal = await this.vehicleRequestModel.countDocuments().exec();
      metrics.total += vehicleTotal;
      metrics.pending += vehiclePending;
      metrics.byType.VEHICLE = { total: vehicleTotal, pending: vehiclePending };
    }

    // ICT requests
    if (isMainAdmin || isICTAdmin) {
      const ictPending = await this.ictRequestModel.countDocuments({ status: RequestStatus.PENDING }).exec();
      const ictTotal = await this.ictRequestModel.countDocuments().exec();
      metrics.total += ictTotal;
      metrics.pending += ictPending;
      metrics.byType.ICT = { total: ictTotal, pending: ictPending };
    }

    // Store requests
    if (isMainAdmin || isStoreAdmin) {
      const storePending = await this.storeRequestModel.countDocuments({ status: RequestStatus.PENDING }).exec();
      const storeTotal = await this.storeRequestModel.countDocuments().exec();
      metrics.total += storeTotal;
      metrics.pending += storePending;
      metrics.byType.STORE = { total: storeTotal, pending: storePending };
    }

    return metrics;
  }
}
