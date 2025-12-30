import { Processor, Process } from '@nestjs/bull';
import { Job } from 'bull';
import { Logger } from '@nestjs/common';
import { UsersService } from '../../users/users.service';
import { FCMService } from '../../fcm/fcm.service';

interface PushNotificationJobData {
  userId: string;
  title: string;
  body: string;
  data?: {
    requestId?: string;
    requestType?: string;
    type?: string;
  };
}

@Processor('push-notifications')
export class PushNotificationProcessor {
  private readonly logger = new Logger(PushNotificationProcessor.name);

  constructor(
    private usersService: UsersService,
    private fcmService: FCMService,
  ) {}

  @Process({
    name: 'send-push',
    concurrency: 10,
  })
  async handlePushNotification(job: Job<PushNotificationJobData>) {
    this.logger.log(`Processing push notification job ${job.id} for user ${job.data.userId}`);

    try {
      // Get user to retrieve FCM token
      const user = await this.usersService.findOne(job.data.userId);
      
      if (!user) {
        this.logger.warn(`User ${job.data.userId} not found`);
        return;
      }

      if (!user.fcmToken) {
        this.logger.warn(`User ${job.data.userId} has no FCM token`);
        return;
      }

      // Send push notification via FCM
      await this.fcmService.sendToDevice(user.fcmToken, {
        title: job.data.title,
        body: job.data.body,
        data: job.data.data,
      });

      this.logger.log(`Push notification sent successfully for user ${job.data.userId}`);
    } catch (error: any) {
      this.logger.error(`Error processing push notification job ${job.id}:`, error);
      
      // Handle specific FCM errors
      if (error?.code === 'messaging/invalid-registration-token' || 
          error?.code === 'messaging/registration-token-not-registered') {
        // Remove invalid token
        this.logger.warn(`Removing invalid FCM token for user ${job.data.userId}`);
        await this.usersService.updateFcmToken(job.data.userId, '');
        // Don't retry for invalid tokens - mark as completed
        this.logger.log(`Skipping retry for invalid token - job ${job.id} marked as completed`);
        return;
      }

      // Log retry attempt
      const attemptNumber = (job.attemptsMade || 0) + 1;
      this.logger.warn(
        `Push notification failed (attempt ${attemptNumber}/${job.opts.attempts}) for user ${job.data.userId}: ${error.message}`,
      );
      
      // Re-throw to trigger retry for other errors
      throw error;
    }
  }
}
