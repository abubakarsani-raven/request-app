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

      // Create notification record
      const notification = new this.notificationModel({
        userId: new Types.ObjectId(job.data.userId),
        type: job.data.type,
        title: job.data.title,
        message: job.data.message,
        requestId: job.data.requestId ? new Types.ObjectId(job.data.requestId) : null,
        requestType: job.data.requestType || null,
        isRead: false,
      });

      const savedNotification = await notification.save();
      this.logger.log(`Notification created: ${savedNotification._id}`);

      // Emit WebSocket notification
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
      } catch (error) {
        this.logger.error('Error emitting WebSocket notification:', error);
        // Don't fail the job if WebSocket fails
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
