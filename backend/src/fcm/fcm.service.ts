import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';

interface PushNotificationPayload {
  title: string;
  body: string;
  data?: {
    requestId?: string;
    requestType?: string;
    type?: string;
    [key: string]: any;
  };
}

@Injectable()
export class FCMService implements OnModuleInit {
  private readonly logger = new Logger(FCMService.name);
  private firebaseApp: admin.app.App | null = null;
  private isConfigured: boolean = false;

  constructor(private configService: ConfigService) {}

  onModuleInit() {
    this.initializeFirebase();
  }

  /**
   * Check if Firebase is initialized and ready to send notifications
   */
  isInitialized(): boolean {
    return this.isConfigured && this.firebaseApp !== null;
  }

  private initializeFirebase() {
    try {
      const projectId = this.configService.get<string>('FIREBASE_PROJECT_ID');
      const privateKey = this.configService.get<string>('FIREBASE_PRIVATE_KEY');
      const clientEmail = this.configService.get<string>('FIREBASE_CLIENT_EMAIL');

      if (!projectId || !privateKey || !clientEmail) {
        this.logger.warn(
          'Firebase credentials not configured. Push notifications will be disabled. Set FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY, and FIREBASE_CLIENT_EMAIL environment variables.',
        );
        this.isConfigured = false;
        return;
      }

      // Initialize Firebase Admin SDK
      if (admin.apps.length === 0) {
        this.firebaseApp = admin.initializeApp({
          credential: admin.credential.cert({
            projectId,
            privateKey: privateKey.replace(/\\n/g, '\n'),
            clientEmail,
          }),
        });
        this.logger.log('Firebase Admin SDK initialized successfully');
        this.isConfigured = true;
      } else {
        this.firebaseApp = admin.app();
        this.logger.log('Using existing Firebase Admin SDK instance');
        this.isConfigured = true;
      }
    } catch (error) {
      this.logger.error('Failed to initialize Firebase Admin SDK:', error);
      this.isConfigured = false;
      this.firebaseApp = null;
    }
  }

  /**
   * Send push notification to a single device
   */
  async sendToDevice(token: string, payload: PushNotificationPayload): Promise<void> {
    if (!this.firebaseApp) {
      this.logger.warn('Firebase not initialized. Skipping push notification.');
      return;
    }

    if (!token) {
      this.logger.warn('FCM token is empty. Skipping push notification.');
      return;
    }

    try {
      const message: admin.messaging.Message = {
        token,
        notification: {
          title: payload.title,
          body: payload.body,
        },
        data: payload.data
          ? Object.entries(payload.data).reduce((acc, [key, value]) => {
              acc[key] = String(value || '');
              return acc;
            }, {} as Record<string, string>)
          : undefined,
        android: {
          priority: 'high' as const,
          notification: {
            channelId: 'request_channel',
            sound: 'default',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      const response = await admin.messaging().send(message);
      this.logger.log(`Successfully sent push notification to token ${token.substring(0, 20)}... Message ID: ${response}`);
    } catch (error: any) {
      this.logger.error(`Error sending push notification to token ${token.substring(0, 20)}...:`, error);
      
      // Re-throw to let processor handle retry logic
      throw error;
    }
  }

  /**
   * Send push notification to multiple devices
   */
  async sendToMultipleDevices(
    tokens: string[],
    payload: PushNotificationPayload,
  ): Promise<admin.messaging.BatchResponse> {
    if (!this.firebaseApp) {
      this.logger.warn('Firebase not initialized. Skipping push notification.');
      throw new Error('Firebase not initialized');
    }

    if (!tokens || tokens.length === 0) {
      this.logger.warn('No FCM tokens provided. Skipping push notification.');
      throw new Error('No FCM tokens provided');
    }

    try {
      const message: admin.messaging.MulticastMessage = {
        tokens: tokens.filter((t) => t && t.length > 0),
        notification: {
          title: payload.title,
          body: payload.body,
        },
        data: payload.data
          ? Object.entries(payload.data).reduce((acc, [key, value]) => {
              acc[key] = String(value || '');
              return acc;
            }, {} as Record<string, string>)
          : undefined,
        android: {
          priority: 'high' as const,
          notification: {
            channelId: 'request_channel',
            sound: 'default',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      const response = await admin.messaging().sendEachForMulticast(message);
      this.logger.log(
        `Successfully sent push notifications. Success: ${response.successCount}, Failure: ${response.failureCount}`,
      );

      // Log failed tokens
      if (response.failureCount > 0) {
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            this.logger.warn(`Failed to send to token ${tokens[idx]?.substring(0, 20)}...: ${resp.error?.message}`);
          }
        });
      }

      return response;
    } catch (error: any) {
      this.logger.error('Error sending multicast push notification:', error);
      throw error;
    }
  }

  /**
   * Send push notification to a topic (for broadcast)
   */
  async sendToTopic(topic: string, payload: PushNotificationPayload): Promise<void> {
    if (!this.firebaseApp) {
      this.logger.warn('Firebase not initialized. Skipping push notification.');
      return;
    }

    try {
      const message: admin.messaging.Message = {
        topic,
        notification: {
          title: payload.title,
          body: payload.body,
        },
        data: payload.data
          ? Object.entries(payload.data).reduce((acc, [key, value]) => {
              acc[key] = String(value || '');
              return acc;
            }, {} as Record<string, string>)
          : undefined,
        android: {
          priority: 'high' as const,
          notification: {
            channelId: 'request_channel',
            sound: 'default',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      const response = await admin.messaging().send(message);
      this.logger.log(`Successfully sent push notification to topic ${topic}. Message ID: ${response}`);
    } catch (error: any) {
      this.logger.error(`Error sending push notification to topic ${topic}:`, error);
      throw error;
    }
  }
}
