import { Controller, Get, Put, Post, Body, Param, Query, UseGuards, BadRequestException, ForbiddenException } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { UsersService } from '../users/users.service';
import { FCMService } from '../fcm/fcm.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { AdminRoleService } from '../common/services/admin-role.service';
import { BroadcastNotificationDto } from './dto/broadcast-notification.dto';
import { TargetedNotificationDto } from './dto/targeted-notification.dto';
import { UserRole, RequestType } from '../shared/types';

@Controller('notifications')
@UseGuards(JwtAuthGuard)
export class NotificationsController {
  constructor(
    private readonly notificationsService: NotificationsService,
    private readonly usersService: UsersService,
    private readonly fcmService: FCMService,
    private readonly adminRoleService: AdminRoleService,
  ) {}

  // Helper to safely extract user ID as string
  private getUserId(user: any): string {
    if (!user) {
      throw new BadRequestException('User not found');
    }
    
    // If user is already a string
    if (typeof user === 'string') {
      const trimmed = user.trim();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        throw new BadRequestException('Invalid user ID: received stringified object instead of ID');
      }
      if (!/^[0-9a-fA-F]{24}$/.test(trimmed)) {
        throw new BadRequestException(`Invalid user ID format: ${trimmed.substring(0, 50)}`);
      }
      return trimmed;
    }
    
    // Handle ObjectId, string, or object with _id/id property
    if (user._id !== undefined && user._id !== null) {
      const id = user._id;
      if (typeof id === 'string') {
        if (!/^[0-9a-fA-F]{24}$/.test(id)) {
          throw new BadRequestException(`Invalid user ID format: ${id.substring(0, 50)}`);
        }
        return id;
      }
      // Handle ObjectId
      if (id && typeof id.toString === 'function') {
        const idStr = id.toString();
        if (!/^[0-9a-fA-F]{24}$/.test(idStr)) {
          throw new BadRequestException(`Invalid user ID format: ${idStr.substring(0, 50)}`);
        }
        return idStr;
      }
    }
    
    if (user.id !== undefined && user.id !== null) {
      const id = user.id;
      if (typeof id === 'string') {
        if (!/^[0-9a-fA-F]{24}$/.test(id)) {
          throw new BadRequestException(`Invalid user ID format: ${id.substring(0, 50)}`);
        }
        return id;
      }
      if (id && typeof id.toString === 'function') {
        const idStr = id.toString();
        if (!/^[0-9a-fA-F]{24}$/.test(idStr)) {
          throw new BadRequestException(`Invalid user ID format: ${idStr.substring(0, 50)}`);
        }
        return idStr;
      }
    }
    
    throw new BadRequestException('Could not extract user ID from user object');
  }

  @Get()
  findAll(
    @CurrentUser() user: any,
    @Query('unreadOnly') unreadOnly?: string,
  ) {
    const userId = this.getUserId(user);
    console.log('[NotificationsController] findAll - userId:', userId, 'unreadOnly:', unreadOnly);
    return this.notificationsService.findAllForUser(
      userId,
      unreadOnly === 'true',
    );
  }

  @Get('unread-count')
  getUnreadCount(@CurrentUser() user: any) {
    const userId = this.getUserId(user);
    console.log('[NotificationsController] getUnreadCount - userId:', userId);
    return this.notificationsService.getUnreadCount(userId);
  }

  @Put(':id/read')
  markAsRead(@Param('id') id: string, @CurrentUser() user: any) {
    const userId = this.getUserId(user);
    return this.notificationsService.markAsRead(id, userId);
  }

  @Put('read-all')
  markAllAsRead(@CurrentUser() user: any) {
    const userId = this.getUserId(user);
    return this.notificationsService.markAllAsRead(userId);
  }

  @Post('register-token')
  async registerToken(@CurrentUser() user: any, @Body() body: { fcmToken: string }) {
    const userId = this.getUserId(user);
    if (!body.fcmToken) {
      throw new BadRequestException('FCM token is required');
    }
    await this.usersService.updateFcmToken(userId, body.fcmToken);
    return { message: 'Token registered successfully' };
  }

  @Post('test-fcm')
  async testFCM(@CurrentUser() user: any) {
    const userId = this.getUserId(user);
    
    // Get user details
    const userDoc = await this.usersService.findOne(userId);
    if (!userDoc) {
      throw new BadRequestException('User not found');
    }

    const result: any = {
      success: false,
      fcmConfigured: false,
      userHasToken: false,
      token: null,
      message: '',
      error: null,
    };

    // Check if FCM is configured (check if firebaseApp exists)
    // We'll need to add a method to FCMService to check this
    try {
      // Try to send a test notification to check if FCM is initialized
      if (!userDoc.fcmToken) {
        result.message = 'User does not have an FCM token registered. Please login from the mobile app first.';
        return result;
      }

      result.userHasToken = true;
      result.token = userDoc.fcmToken.substring(0, 20) + '...'; // Show first 20 chars

      // Send test notification
      await this.fcmService.sendToDevice(userDoc.fcmToken, {
        title: '🧪 FCM Test Notification',
        body: 'This is a test notification to verify FCM is working correctly!',
        data: {
          type: 'test',
          timestamp: new Date().toISOString(),
        },
      });

      result.success = true;
      result.fcmConfigured = true;
      result.message = 'Test notification sent successfully! Check your mobile device.';
    } catch (error: any) {
      result.error = error.message || error.toString();
      
      if (error.message?.includes('Firebase not initialized') || 
          error.message?.includes('not configured')) {
        result.message = 'FCM is not configured. Please set FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY, and FIREBASE_CLIENT_EMAIL in backend/.env';
      } else if (error.code === 'messaging/invalid-registration-token' || 
                 error.code === 'messaging/registration-token-not-registered') {
        result.message = 'FCM token is invalid or expired. Please login again from the mobile app to refresh the token.';
      } else {
        result.message = `Failed to send test notification: ${error.message}`;
      }
    }

    return result;
  }

  @Get('fcm-status')
  async getFCMStatus(@CurrentUser() user: any) {
    const userId = this.getUserId(user);
    
    const userDoc = await this.usersService.findOne(userId);
    if (!userDoc) {
      throw new BadRequestException('User not found');
    }

    return {
      fcmConfigured: this.fcmService.isInitialized(),
      userHasToken: !!userDoc.fcmToken,
      tokenPreview: userDoc.fcmToken 
        ? `${userDoc.fcmToken.substring(0, 20)}...` 
        : null,
      message: !this.fcmService.isInitialized()
        ? 'FCM is not configured. Please set FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY, and FIREBASE_CLIENT_EMAIL in backend/.env'
        : !userDoc.fcmToken
        ? 'No FCM token registered. Please login from the mobile app to register your token.'
        : 'FCM token is registered. Use POST /notifications/test-fcm to send a test notification.',
    };
  }

  @Post('broadcast')
  async broadcastNotification(
    @CurrentUser() user: any,
    @Body() dto: BroadcastNotificationDto,
  ) {
    const userRoles = (user.roles || []) as UserRole[];
    
    // Only Main Admin can broadcast
    if (!this.adminRoleService.isMainAdmin(userRoles)) {
      throw new ForbiddenException('Unauthorized: Main Admin access required');
    }

    return this.notificationsService.broadcastNotification(
      dto.title,
      dto.message,
      dto.requestType as RequestType,
      dto.requestId,
      dto.type,
    );
  }

  @Post('targeted')
  async sendTargetedNotification(
    @CurrentUser() user: any,
    @Body() dto: TargetedNotificationDto,
  ) {
    const userRoles = (user.roles || []) as UserRole[];
    
    // Only Main Admin can send targeted notifications
    if (!this.adminRoleService.isMainAdmin(userRoles)) {
      throw new ForbiddenException('Unauthorized: Main Admin access required');
    }

    if (!dto.userIds && !dto.roles) {
      throw new BadRequestException('Either userIds or roles must be provided');
    }

    return this.notificationsService.sendTargetedNotification(
      dto.title,
      dto.message,
      dto.userIds,
      dto.roles as UserRole[],
      dto.requestType as RequestType,
      dto.requestId,
      dto.type,
    );
  }
}

