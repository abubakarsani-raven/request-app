import { Injectable, Inject, forwardRef } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { InjectQueue } from '@nestjs/bull';
import { Queue } from 'bull';
import { Model, Types } from 'mongoose';
import { Notification, NotificationDocument } from './schemas/notification.schema';
import { NotificationType, RequestType, UserRole } from '../shared/types';
import { EmailService } from '../email/email.service';
import { UsersService } from '../users/users.service';
import { AppWebSocketGateway } from '../websocket/websocket.gateway';

@Injectable()
export class NotificationsService {
  constructor(
    @InjectModel(Notification.name) private notificationModel: Model<NotificationDocument>,
    @InjectQueue('notifications') private notificationsQueue: Queue,
    @InjectQueue('push-notifications') private pushNotificationsQueue: Queue,
    private emailService: EmailService,
    private usersService: UsersService,
    @Inject(forwardRef(() => AppWebSocketGateway))
    private webSocketGateway: AppWebSocketGateway,
  ) {}

  async createNotification(
    userId: string,
    type: NotificationType,
    title: string,
    message: string,
    requestId?: string,
    requestType?: RequestType,
    sendEmail: boolean = true,
  ): Promise<Notification> {
    console.log('[NotificationsService] createNotification - userId:', userId, 'type:', type, 'title:', title);
    
    // Validate userId format
    if (!userId || !/^[0-9a-fA-F]{24}$/.test(userId)) {
      console.error('[NotificationsService] Invalid userId format:', userId);
      throw new Error(`Invalid user ID format: ${userId}`);
    }

    // Queue notification job for async processing
    await this.notificationsQueue.add(
      'create-notification',
      {
        userId,
        type,
        title,
        message,
        requestId,
        requestType,
        sendEmail,
      },
      {
        attempts: 3,
        backoff: {
          type: 'exponential',
          delay: 2000,
        },
        removeOnComplete: true,
        removeOnFail: false,
      },
    );

    // Also queue push notification
    await this.pushNotificationsQueue.add(
      'send-push',
      {
        userId,
        title,
        body: message,
        data: {
          requestId,
          requestType,
          type,
        },
      },
      {
        attempts: 5,
        backoff: {
          type: 'exponential',
          delay: 2000,
        },
        removeOnComplete: true,
        removeOnFail: false,
      },
    );

    // Return a placeholder notification object (actual notification will be created by processor)
    // For backward compatibility, we'll still create it synchronously but queue the heavy work
    const notification = new this.notificationModel({
      userId: new Types.ObjectId(userId),
      type,
      title,
      message,
      requestId: requestId ? new Types.ObjectId(requestId) : null,
      requestType: requestType || null,
      isRead: false,
    });

    const savedNotification = await notification.save();
    console.log('[NotificationsService] createNotification - saved notification ID:', savedNotification._id);

    // Emit WebSocket notification immediately (low latency)
    try {
      this.emitNotificationViaWebSocket(userId, {
        notificationId: savedNotification._id.toString(),
        userId,
        type,
        title,
        message,
        requestId: requestId || undefined,
        requestType: requestType || undefined,
        timestamp: (savedNotification as any).createdAt || new Date(),
      });
    } catch (error) {
      console.error('Error emitting WebSocket notification:', error);
    }

    // Email and push notifications are handled by queue processors

    return savedNotification;
  }

  /**
   * Emit notification via WebSocket to specific user
   */
  private emitNotificationViaWebSocket(
    userId: string,
    notificationData: {
      notificationId: string;
      userId: string;
      type: NotificationType;
      title: string;
      message: string;
      requestId?: string;
      requestType?: RequestType;
      timestamp: Date;
    },
  ): void {
    try {
      this.webSocketGateway.emitToUser(userId, 'notification:new', notificationData);
    } catch (error) {
      console.error('Error emitting WebSocket notification:', error);
    }
  }

  /**
   * Emit workflow progress update to all participants
   */
  async emitWorkflowProgress(
    participants: string[],
    progressData: {
      requestId: string;
      requestType: RequestType;
      workflowStage: string;
      status: string;
      action: 'approved' | 'rejected' | 'corrected' | 'assigned' | 'submitted' | 'fulfilled';
      actionBy: {
        userId: string;
        name: string;
        role: string;
      };
      participants: Array<{
        userId: string;
        name: string;
        role: string;
        action: string;
        timestamp: Date;
      }>;
      message: string;
    },
  ): Promise<void> {
    try {
      // Emit to all participants
      participants.forEach((participantId) => {
        this.webSocketGateway.emitToUser(participantId, 'request:progress', progressData);
      });

      // Also emit to request room for real-time updates
      this.webSocketGateway.emitToRequest(progressData.requestId, 'request:progress', progressData);
    } catch (error) {
      console.error('Error emitting workflow progress:', error);
    }
  }

  async findAllForUser(userId: string, unreadOnly: boolean = false): Promise<Notification[]> {
    console.log('[NotificationsService] findAllForUser - userId:', userId, 'unreadOnly:', unreadOnly);
    
    // Validate userId format
    if (!userId || !/^[0-9a-fA-F]{24}$/.test(userId)) {
      console.error('[NotificationsService] Invalid userId format:', userId);
      throw new Error(`Invalid user ID format: ${userId}`);
    }
    
    const query: any = { userId: new Types.ObjectId(userId) };
    if (unreadOnly) {
      query.isRead = false;
    }

    const notifications = await this.notificationModel
      .find(query)
      .sort({ createdAt: -1 })
      .limit(50)
      .exec();
    
    console.log('[NotificationsService] findAllForUser - found', notifications.length, 'notifications');
    return notifications;
  }

  async markAsRead(notificationId: string, userId: string): Promise<Notification> {
    const notification = await this.notificationModel.findOne({
      _id: notificationId,
      userId: new Types.ObjectId(userId),
    });

    if (!notification) {
      throw new Error('Notification not found');
    }

    notification.isRead = true;
    return notification.save();
  }

  async markAllAsRead(userId: string): Promise<void> {
    await this.notificationModel.updateMany(
      { userId: new Types.ObjectId(userId), isRead: false },
      { isRead: true },
    );
  }

  async getUnreadCount(userId: string): Promise<number> {
    return this.notificationModel.countDocuments({
      userId: new Types.ObjectId(userId),
      isRead: false,
    });
  }

  // Notification creation helpers for different events
  async notifyRequestSubmitted(
    userId: string,
    requestType: RequestType,
    requestId: string,
  ): Promise<void> {
    const user = await this.usersService.findOne(userId);
    await this.createNotification(
      userId,
      NotificationType.REQUEST_SUBMITTED,
      `${requestType} Request Submitted`,
      `Your ${requestType} request has been submitted successfully.`,
      requestId,
      requestType,
    );
  }

  async notifyApprovalRequired(
    approverId: string,
    requesterName: string,
    requestType: RequestType,
    requestId: string,
  ): Promise<void> {
    await this.createNotification(
      approverId,
      NotificationType.APPROVAL_REQUIRED,
      `Approval Required: ${requestType} Request`,
      `You have a pending ${requestType} request from ${requesterName} that requires your approval.`,
      requestId,
      requestType,
    );
  }

  async notifyRequestApproved(
    userId: string,
    requestType: RequestType,
    requestId: string,
  ): Promise<void> {
    await this.createNotification(
      userId,
      NotificationType.REQUEST_APPROVED,
      `${requestType} Request Approved`,
      `Your ${requestType} request has been approved.`,
      requestId,
      requestType,
    );
  }

  async notifyRequestRejected(
    userId: string,
    requestType: RequestType,
    requestId: string,
    comment: string,
  ): Promise<void> {
    await this.createNotification(
      userId,
      NotificationType.REQUEST_REJECTED,
      `${requestType} Request Rejected`,
      `Your ${requestType} request has been rejected. Reason: ${comment}`,
      requestId,
      requestType,
    );
  }

  async notifyCorrectionRequired(
    userId: string,
    requestType: RequestType,
    requestId: string,
    comment: string,
  ): Promise<void> {
    await this.createNotification(
      userId,
      NotificationType.REQUEST_CORRECTED,
      `Correction Required: ${requestType} Request`,
      `Your ${requestType} request requires corrections. ${comment}`,
      requestId,
      requestType,
    );
  }

  async notifyRequestAssigned(
    userId: string,
    requestType: RequestType,
    requestId: string,
    details: string,
  ): Promise<void> {
    await this.createNotification(
      userId,
      NotificationType.REQUEST_ASSIGNED,
      `${requestType} Request Assigned`,
      `Your ${requestType} request has been assigned. ${details}`,
      requestId,
      requestType,
    );
  }

  async notifyRequestFulfilled(
    userId: string,
    requestType: RequestType,
    requestId: string,
  ): Promise<void> {
    await this.createNotification(
      userId,
      NotificationType.REQUEST_FULFILLED,
      `${requestType} Request Fulfilled`,
      `Your ${requestType} request has been fulfilled and is ready for collection.`,
      requestId,
      requestType,
    );
  }

  private async sendEmailForNotification(
    email: string,
    name: string,
    type: NotificationType,
    title: string,
    message: string,
  ): Promise<void> {
    // Send generic email notification
    await this.emailService.sendEmail(
      email,
      title,
      `<h2>${title}</h2><p>Dear ${name},</p><p>${message}</p>`,
    );
  }

  /**
   * Broadcast notification to all users
   */
  async broadcastNotification(
    title: string,
    message: string,
    requestType?: RequestType,
    requestId?: string,
  ): Promise<{ sent: number; failed: number }> {
    const users = await this.usersService.findAll();
    let sent = 0;
    let failed = 0;

    for (const user of users) {
      try {
        const userId = (user as any)._id?.toString() || (user as any).id?.toString();
        if (!userId) {
          failed++;
          continue;
        }

        await this.createNotification(
          userId,
          NotificationType.REQUEST_UPDATED,
          title,
          message,
          requestId,
          requestType,
          true, // Send email
        );
        sent++;
      } catch (error) {
        console.error(`Error broadcasting notification to user ${(user as any)._id}:`, error);
        failed++;
      }
    }

    return { sent, failed };
  }

  /**
   * Send targeted notification to specific users or roles
   */
  async sendTargetedNotification(
    title: string,
    message: string,
    userIds?: string[],
    roles?: UserRole[],
    requestType?: RequestType,
    requestId?: string,
  ): Promise<{ sent: number; failed: number }> {
    const users = await this.usersService.findAll();
    let sent = 0;
    let failed = 0;

    // Filter users based on userIds or roles
    const targetUsers = users.filter((user) => {
      if (userIds && userIds.length > 0) {
        const userId = (user as any)._id?.toString() || (user as any).id?.toString();
        return userId && userIds.includes(userId);
      }
      if (roles && roles.length > 0) {
        return user.roles.some((role) => roles.includes(role));
      }
      return false;
    });

    for (const user of targetUsers) {
      try {
        const userId = (user as any)._id?.toString() || (user as any).id?.toString();
        if (!userId) {
          failed++;
          continue;
        }

        await this.createNotification(
          userId,
          NotificationType.REQUEST_UPDATED,
          title,
          message,
          requestId,
          requestType,
          true, // Send email
        );
        sent++;
      } catch (error) {
        console.error(`Error sending targeted notification to user ${(user as any)._id}:`, error);
        failed++;
      }
    }

    return { sent, failed };
  }
}

