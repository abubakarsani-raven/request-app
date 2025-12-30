import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { StoreItem, StoreItemDocument } from '../schemas/store-item.schema';
import { StoreRequest, StoreRequestDocument } from '../schemas/store-request.schema';
import { StoreStockHistory, StoreStockHistoryDocument, StoreStockOperation } from './schemas/store-stock-history.schema';
import { CreateStoreItemDto } from './dto/create-store-item.dto';
import { UpdateStoreItemDto } from './dto/update-store-item.dto';
import { UpdateQuantityDto, QuantityOperation } from './dto/update-quantity.dto';
import { BulkImportDto } from './dto/bulk-import.dto';
import { RequestStatus, RequestType, UserRole, NotificationType } from '../../shared/types';
import { NotificationsService } from '../../notifications/notifications.service';
import { UsersService } from '../../users/users.service';

@Injectable()
export class StoreInventoryService {
  constructor(
    @InjectModel(StoreItem.name) private storeItemModel: Model<StoreItemDocument>,
    @InjectModel(StoreRequest.name) private storeRequestModel: Model<StoreRequestDocument>,
    @InjectModel(StoreStockHistory.name) private stockHistoryModel: Model<StoreStockHistoryDocument>,
    private notificationsService: NotificationsService,
    private usersService: UsersService,
  ) {}

  /**
   * Create a new store item
   */
  async createItem(createStoreItemDto: CreateStoreItemDto): Promise<StoreItem> {
    const item = new this.storeItemModel({
      ...createStoreItemDto,
      quantity: createStoreItemDto.quantity || 0,
      isAvailable: createStoreItemDto.isAvailable !== undefined ? createStoreItemDto.isAvailable : true,
      lowStockThreshold: createStoreItemDto.lowStockThreshold || 5,
    });
    return item.save();
  }

  /**
   * Find all store items
   */
  async findAllItems(category?: string): Promise<StoreItem[]> {
    const query: any = {};
    if (category) {
      query.category = category;
    }
    return this.storeItemModel.find(query).exec();
  }

  /**
   * Find available store items
   */
  async findAvailableItems(category?: string): Promise<StoreItem[]> {
    const query: any = { isAvailable: true, quantity: { $gt: 0 } };
    if (category) {
      query.category = category;
    }
    return this.storeItemModel.find(query).exec();
  }

  /**
   * Find one store item by ID
   */
  async findOneItem(id: string): Promise<StoreItemDocument> {
    const item = await this.storeItemModel.findById(id).exec();
    if (!item) {
      throw new NotFoundException('Store item not found');
    }
    return item;
  }

  /**
   * Update store item
   */
  async updateItem(id: string, updateDto: UpdateStoreItemDto): Promise<StoreItem> {
    const item = await this.findOneItem(id);
    Object.assign(item, updateDto);
    return item.save();
  }

  /**
   * Update item availability
   */
  async updateItemAvailability(id: string, isAvailable: boolean): Promise<StoreItem> {
    const item = await this.findOneItem(id);
    item.isAvailable = isAvailable;
    return item.save();
  }

  /**
   * Update item quantity with history tracking
   */
  async updateItemQuantity(
    id: string,
    updateQuantityDto: UpdateQuantityDto,
    userId: string,
  ): Promise<StoreItem> {
    const item = await this.findOneItem(id);
    const previousQuantity = item.quantity;
    let newQuantity: number;

    switch (updateQuantityDto.operation) {
      case QuantityOperation.ADD:
        newQuantity = previousQuantity + updateQuantityDto.quantity;
        break;
      case QuantityOperation.REMOVE:
        newQuantity = previousQuantity - updateQuantityDto.quantity;
        if (newQuantity < 0) {
          throw new BadRequestException('Insufficient quantity. Cannot remove more than available.');
        }
        break;
      case QuantityOperation.ADJUST:
        newQuantity = updateQuantityDto.quantity;
        if (newQuantity < 0) {
          throw new BadRequestException('Quantity cannot be negative.');
        }
        break;
      default:
        throw new BadRequestException('Invalid operation');
    }

    const changeAmount = newQuantity - previousQuantity;
    item.quantity = newQuantity;

    // Update availability based on quantity
    if (newQuantity === 0) {
      item.isAvailable = false;
    } else if (previousQuantity === 0 && newQuantity > 0) {
      item.isAvailable = true;
    }

    await item.save();

    // Create stock history entry
    const stockHistory = new this.stockHistoryModel({
      itemId: new Types.ObjectId(id),
      previousQuantity,
      newQuantity,
      changeAmount,
      operation: this.mapQuantityOperationToStockOperation(updateQuantityDto.operation),
      reason: updateQuantityDto.reason,
      performedBy: new Types.ObjectId(userId),
    });
    await stockHistory.save();

    // Check for low stock and send notification if needed
    await this.checkAndNotifyLowStock(item);

    return item;
  }

  /**
   * Map quantity operation to stock operation
   */
  private mapQuantityOperationToStockOperation(
    operation: QuantityOperation,
  ): StoreStockOperation {
    switch (operation) {
      case QuantityOperation.ADD:
        return StoreStockOperation.ADD;
      case QuantityOperation.REMOVE:
        return StoreStockOperation.REMOVE;
      case QuantityOperation.ADJUST:
        return StoreStockOperation.ADJUST;
      default:
        return StoreStockOperation.ADJUST;
    }
  }

  /**
   * Get stock history for an item
   */
  async getStockHistory(itemId: string): Promise<StoreStockHistory[]> {
    return this.stockHistoryModel
      .find({ itemId: new Types.ObjectId(itemId) })
      .populate('performedBy', 'name email')
      .populate('requestId', '_id')
      .sort({ createdAt: -1 })
      .exec();
  }

  /**
   * Get low stock items
   */
  async getLowStockItems(): Promise<StoreItem[]> {
    return this.storeItemModel
      .find({
        $expr: {
          $lte: ['$quantity', { $ifNull: ['$lowStockThreshold', 5] }],
        },
        isAvailable: true,
      })
      .exec();
  }

  /**
   * Bulk create items
   */
  async bulkCreateItems(items: CreateStoreItemDto[]): Promise<{ created: number; errors: any[] }> {
    const errors: any[] = [];
    let created = 0;

    for (let i = 0; i < items.length; i++) {
      try {
        await this.createItem(items[i]);
        created++;
      } catch (error: any) {
        errors.push({
          index: i,
          item: items[i],
          error: error.message,
        });
      }
    }

    return { created, errors };
  }

  /**
   * Bulk import items
   */
  async bulkImport(bulkImportDto: BulkImportDto): Promise<{ created: number; errors: any[] }> {
    return this.bulkCreateItems(bulkImportDto.items);
  }

  /**
   * Delete item (soft delete)
   */
  async deleteItem(id: string): Promise<void> {
    const item = await this.findOneItem(id);

    // Check if item is referenced in any active requests
    const activeRequests = await this.storeRequestModel.find({
      'items.itemId': new Types.ObjectId(id),
      status: { $in: [RequestStatus.PENDING, RequestStatus.APPROVED] },
    }).exec();

    if (activeRequests.length > 0) {
      throw new BadRequestException(
        `Cannot delete item. It is referenced in ${activeRequests.length} active request(s).`,
      );
    }

    // Soft delete by setting isAvailable to false and quantity to 0
    item.isAvailable = false;
    item.quantity = 0;
    await item.save();
  }

  /**
   * Get all categories
   */
  async getCategories(): Promise<string[]> {
    const items = await this.storeItemModel.find().distinct('category').exec();
    return items;
  }

  /**
   * Check and notify low stock
   */
  private async checkAndNotifyLowStock(item: StoreItemDocument): Promise<void> {
    const lowStockThreshold = (item as any).lowStockThreshold || 5;
    if (item.quantity <= lowStockThreshold && item.isAvailable) {
      // Get users who should be notified (SO, DGS, Store Admin)
      const users = await this.usersService.findAll();
      const notifiedUsers = users.filter((user) =>
        user.roles.some((role) =>
          [UserRole.SO, UserRole.DGS, UserRole.STORE_ADMIN, UserRole.ADMIN].includes(role),
        ),
      );

      for (const user of notifiedUsers) {
        try {
          const userId = (user as any)._id?.toString() || (user as any).id?.toString();
          if (!userId) continue;
          
          await this.notificationsService.createNotification(
            userId,
            NotificationType.LOW_STOCK,
            'Low Stock Alert',
            `Store item "${item.name}" is running low. Current quantity: ${item.quantity}, Threshold: ${lowStockThreshold}`,
            undefined,
            RequestType.STORE,
            true,
          );
        } catch (error) {
          const userId = (user as any)._id?.toString() || (user as any).id?.toString();
          console.error(`Error sending low stock notification to user ${userId}:`, error);
        }
      }
    }
  }
}
