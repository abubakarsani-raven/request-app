import { Injectable } from '@nestjs/common';
import * as QRCode from 'qrcode';
import { RequestType } from '../shared/types';

@Injectable()
export class QRService {
  async generateQRCode(data: string): Promise<string> {
    try {
      // Generate QR code as data URL
      const qrDataUrl = await QRCode.toDataURL(data);
      return qrDataUrl;
    } catch (error) {
      console.error('Error generating QR code:', error);
      throw error;
    }
  }

  async generateQRCodeForRequest(
    requestId: string,
    requestType: RequestType,
  ): Promise<string> {
    const data = `${requestType}-${requestId}-${Date.now()}`;
    return this.generateQRCode(data);
  }

  async verifyQRCode(qrCode: string): Promise<{ valid: boolean; data?: any }> {
    try {
      // Parse QR code data
      // Format: REQUESTTYPE-REQUESTID-TIMESTAMP
      const parts = qrCode.split('-');
      if (parts.length < 2) {
        return { valid: false };
      }

      const requestType = parts[0];
      const requestId = parts[1];

      return {
        valid: true,
        data: {
          requestType,
          requestId,
        },
      };
    } catch (error) {
      return { valid: false };
    }
  }
}

