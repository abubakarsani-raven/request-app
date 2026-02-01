import { Processor, Process } from '@nestjs/bull';
import { Job } from 'bull';
import { Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Notification, NotificationDocument } from '../schemas/notification.schema';
import { EmailService } from '../../email/email.service';
import { UsersService } from '../../users/users.service';
import { AppWebSocketGateway } from '../../websocket/websocket.gateway';

interface NotificationJobData {
  userId: string;
  type: string;
  title: string;
  message: string;
  requestId?: string;
  requestType?: string;
  sendEmail: boolean;
}

@Processor('notifications')
export class NotificationProcessor {
  private readonly logger = new Logger(NotificationProcessor.name);

  constructor(
    @InjectModel(Notification.name) private notificationModel: Model<NotificationDocument>,
    private emailService: EmailService,
    private usersService: UsersService,
    private webSocketGateway: AppWebSocketGateway,
  ) {}

  @Process({
    name: 'create-notification',
    concurrency: 5,
  })
  async handleNotificationCreation(job: Job<NotificationJobData>) {
    this.logger.log(`Processing notification job ${job.id} for user ${job.data.userId}`);

    try {
      // Validate userId format
      if (!job.data.userId || !/^[0-9a-fA-F]{24}$/.test(job.data.userId)) {
        throw new Error(`Invalid user ID format: ${job.data.userId}`);
      }

      // Check if notification already exists (to prevent duplicates from synchronous creation)
      // Look for a notification with the same userId, type, title, message, and requestId created in the last 10 seconds
      // Increased window to handle potential delays in database writes
      const tenSecondsAgo = new Date(Date.now() - 10000);
      const query: any = {
        userId: new Types.ObjectId(job.data.userId),
        type: job.data.type,
        title: job.data.title,
        message: job.data.message,
        createdAt: { $gte: tenSecondsAgo },
      };
      
      // Only include requestId in query if it's provided (null requestId should match null requestId)
      if (job.data.requestId) {
        query.requestId = new Types.ObjectId(job.data.requestId);
      } else {
        query.requestId = null;
      }
      
      const existingNotification = await this.notificationModel.findOne(query).sort({ createdAt: -1 });

      let savedNotification: NotificationDocument;

      if (existingNotification) {
        // Notification already exists (created synchronously), use it
        // DO NOT emit WebSocket here - it was already emitted synchronously
        savedNotification = existingNotification;
        this.logger.log(`Notification already exists (ID: ${savedNotification._id}), skipping creation and WebSocket emission. Only processing email.`);
      } else {
        // Create notification record (this should rarely happen - only if sync creation failed)
        const notification = new this.notificationModel({
          userId: new Types.ObjectId(job.data.userId),
          type: job.data.type,
          title: job.data.title,
          message: job.data.message,
          requestId: job.data.requestId ? new Types.ObjectId(job.data.requestId) : null,
          requestType: job.data.requestType || null,
          isRead: false,
        });

        savedNotification = await notification.save();
        this.logger.log(`Notification created by processor (ID: ${savedNotification._id}) - sync creation may have failed`);

        // Emit WebSocket notification only if we created it here (sync creation failed)
        try {
          this.webSocketGateway.emitToUser(job.data.userId, 'notification:new', {
            notificationId: savedNotification._id.toString(),
            userId: job.data.userId,
            type: job.data.type,
            title: job.data.title,
            message: job.data.message,
            requestId: job.data.requestId || undefined,
            requestType: job.data.requestType || undefined,
            timestamp: (savedNotification as any).createdAt || new Date(),
          });
          this.logger.log(`WebSocket notification emitted by processor for notification ${savedNotification._id}`);
        } catch (error) {
          this.logger.error('Error emitting WebSocket notification:', error);
          // Don't fail the job if WebSocket fails
        }
      }

      // Send email notification if requested
      if (job.data.sendEmail) {
        try {
          const user = await this.usersService.findOne(job.data.userId);
          if (user && user.email) {
            await this.emailService.sendEmail(
              user.email,
              job.data.title,
              `<h2>${job.data.title}</h2><p>Dear ${user.name},</p><p>${job.data.message}</p>`,
            );
            this.logger.log(`Email sent to ${user.email}`);
          }
        } catch (error) {
          this.logger.error('Error sending email notification:', error);
          // Don't fail the job if email fails
        }
      }

      return savedNotification;
    } catch (error: any) {
      // Log retry attempt
      const attemptNumber = (job.attemptsMade || 0) + 1;
      this.logger.error(
        `Error processing notification job ${job.id} (attempt ${attemptNumber}/${job.opts.attempts}):`,
        error,
      );

      // Don't retry for validation errors
      if (error.message?.includes('Invalid user ID format')) {
        this.logger.warn(`Skipping retry for validation error - job ${job.id}`);
        return; // Mark as completed to avoid infinite retries
      }

      // Re-throw to trigger retry for other errors
      throw error;
    }
  }
}
