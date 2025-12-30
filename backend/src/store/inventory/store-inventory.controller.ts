import {
  Controller,
  Get,
  Post,
  Body,
  Put,
  Delete,
  Param,
  Patch,
  UseGuards,
  Query,
} from '@nestjs/common';
import { StoreInventoryService } from './store-inventory.service';
import { CreateStoreItemDto } from './dto/create-store-item.dto';
import { UpdateStoreItemDto } from './dto/update-store-item.dto';
import { UpdateQuantityDto } from './dto/update-quantity.dto';
import { BulkImportDto } from './dto/bulk-import.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { UserRole } from '../../shared/types';
import { AdminRoleService } from '../../common/services/admin-role.service';

@Controller('store/inventory')
@UseGuards(JwtAuthGuard)
export class StoreInventoryController {
  constructor(
    private readonly storeInventoryService: StoreInventoryService,
    private readonly adminRoleService: AdminRoleService,
  ) {}

  @Post()
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.STORE_ADMIN, UserRole.SO, UserRole.DGS)
  createItem(@Body() createStoreItemDto: CreateStoreItemDto) {
    return this.storeInventoryService.createItem(createStoreItemDto);
  }

  @Get()
  findAllItems(
    @Query('available') available?: string,
    @Query('category') category?: string,
    @CurrentUser() user?: any,
  ) {
    const userRoles = (user?.roles || []) as UserRole[];
    
    // Check if user has permission (any admin or SO can view)
    const canView = this.adminRoleService.canManageStore(userRoles) || 
                    userRoles.includes(UserRole.SO) || 
                    userRoles.includes(UserRole.DGS);
    
    if (!canView) {
      throw new Error('Unauthorized: Store Admin or SO access required');
    }

    if (available === 'true') {
      return this.storeInventoryService.findAvailableItems(category);
    }
    return this.storeInventoryService.findAllItems(category);
  }

  @Get('categories')
  getCategories(@CurrentUser() user?: any) {
    const userRoles = (user?.roles || []) as UserRole[];
    
    const canView = this.adminRoleService.canManageStore(userRoles) || 
                    userRoles.includes(UserRole.SO) || 
                    userRoles.includes(UserRole.DGS);
    
    if (!canView) {
      throw new Error('Unauthorized: Store Admin or SO access required');
    }

    return this.storeInventoryService.getCategories();
  }

  @Get(':id')
  findOneItem(@Param('id') id: string) {
    return this.storeInventoryService.findOneItem(id);
  }

  @Put(':id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.STORE_ADMIN, UserRole.SO, UserRole.DGS)
  updateItem(
    @Param('id') id: string,
    @Body() updateDto: UpdateStoreItemDto,
  ) {
    return this.storeInventoryService.updateItem(id, updateDto);
  }

  @Put(':id/availability')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.STORE_ADMIN, UserRole.SO)
  updateItemAvailability(
    @Param('id') id: string,
    @Body() body: { isAvailable: boolean },
  ) {
    return this.storeInventoryService.updateItemAvailability(id, body.isAvailable);
  }

  @Patch(':id/quantity')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.STORE_ADMIN, UserRole.SO, UserRole.DGS)
  updateItemQuantity(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body() updateQuantityDto: UpdateQuantityDto,
  ) {
    const userId = user._id?.toString() || user.id?.toString() || user._id || user.id;
    return this.storeInventoryService.updateItemQuantity(id, updateQuantityDto, userId);
  }

  @Get(':id/history')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.STORE_ADMIN, UserRole.SO, UserRole.DGS)
  getStockHistory(@Param('id') id: string) {
    return this.storeInventoryService.getStockHistory(id);
  }

  @Get('low-stock/all')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.STORE_ADMIN, UserRole.SO, UserRole.DGS)
  getLowStockItems() {
    return this.storeInventoryService.getLowStockItems();
  }

  @Post('bulk-import')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.STORE_ADMIN, UserRole.SO, UserRole.DGS)
  bulkImport(@Body() bulkImportDto: BulkImportDto) {
    return this.storeInventoryService.bulkImport(bulkImportDto);
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.STORE_ADMIN, UserRole.SO, UserRole.DGS)
  deleteItem(@Param('id') id: string) {
    return this.storeInventoryService.deleteItem(id);
  }
}
