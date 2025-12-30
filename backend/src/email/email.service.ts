import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as sgMail from '@sendgrid/mail';
import { NotificationType, RequestType } from '../shared/types';

@Injectable()
export class EmailService {
  constructor(private configService: ConfigService) {
    const apiKey = this.configService.get<string>('SENDGRID_API_KEY');
    if (apiKey) {
      sgMail.setApiKey(apiKey);
    }
  }

  async sendEmail(to: string, subject: string, html: string): Promise<void> {
    const msg = {
      to,
      from: this.configService.get<string>('SENDGRID_FROM_EMAIL') || 'noreply@request-app.com',
      subject,
      html,
    };

    try {
      await sgMail.send(msg);
    } catch (error) {
      console.error('Error sending email:', error);
      // Don't throw - email failures shouldn't break the app
    }
  }

  async sendRequestSubmittedEmail(
    userEmail: string,
    userName: string,
    requestType: RequestType,
    requestId: string,
  ): Promise<void> {
    const subject = `${requestType} Request Submitted`;
    const html = this.getRequestSubmittedTemplate(userName, requestType, requestId);
    await this.sendEmail(userEmail, subject, html);
  }

  async sendApprovalRequiredEmail(
    approverEmail: string,
    approverName: string,
    requesterName: string,
    requestType: RequestType,
    requestId: string,
  ): Promise<void> {
    const subject = `Approval Required: ${requestType} Request`;
    const html = this.getApprovalRequiredTemplate(
      approverName,
      requesterName,
      requestType,
      requestId,
    );
    await this.sendEmail(approverEmail, subject, html);
  }

  async sendRequestApprovedEmail(
    userEmail: string,
    userName: string,
    requestType: RequestType,
    requestId: string,
  ): Promise<void> {
    const subject = `${requestType} Request Approved`;
    const html = this.getRequestApprovedTemplate(userName, requestType, requestId);
    await this.sendEmail(userEmail, subject, html);
  }

  async sendRequestRejectedEmail(
    userEmail: string,
    userName: string,
    requestType: RequestType,
    requestId: string,
    comment: string,
  ): Promise<void> {
    const subject = `${requestType} Request Rejected`;
    const html = this.getRequestRejectedTemplate(userName, requestType, requestId, comment);
    await this.sendEmail(userEmail, subject, html);
  }

  async sendCorrectionRequiredEmail(
    userEmail: string,
    userName: string,
    requestType: RequestType,
    requestId: string,
    comment: string,
  ): Promise<void> {
    const subject = `Correction Required: ${requestType} Request`;
    const html = this.getCorrectionRequiredTemplate(userName, requestType, requestId, comment);
    await this.sendEmail(userEmail, subject, html);
  }

  async sendAssignmentEmail(
    userEmail: string,
    userName: string,
    requestType: RequestType,
    requestId: string,
    details: string,
  ): Promise<void> {
    const subject = `${requestType} Request Assigned`;
    const html = this.getAssignmentTemplate(userName, requestType, requestId, details);
    await this.sendEmail(userEmail, subject, html);
  }

  // Email Templates
  private getRequestSubmittedTemplate(
    userName: string,
    requestType: RequestType,
    requestId: string,
  ): string {
    return `
      <h2>Request Submitted Successfully</h2>
      <p>Dear ${userName},</p>
      <p>Your ${requestType} request (ID: ${requestId}) has been submitted successfully.</p>
      <p>You will be notified once it has been reviewed.</p>
      <p>Thank you.</p>
    `;
  }

  private getApprovalRequiredTemplate(
    approverName: string,
    requesterName: string,
    requestType: RequestType,
    requestId: string,
  ): string {
    return `
      <h2>Approval Required</h2>
      <p>Dear ${approverName},</p>
      <p>You have a pending ${requestType} request from ${requesterName} (ID: ${requestId}) that requires your approval.</p>
      <p>Please log in to review and take action.</p>
      <p>Thank you.</p>
    `;
  }

  private getRequestApprovedTemplate(
    userName: string,
    requestType: RequestType,
    requestId: string,
  ): string {
    return `
      <h2>Request Approved</h2>
      <p>Dear ${userName},</p>
      <p>Your ${requestType} request (ID: ${requestId}) has been approved.</p>
      <p>You will be notified of any further updates.</p>
      <p>Thank you.</p>
    `;
  }

  private getRequestRejectedTemplate(
    userName: string,
    requestType: RequestType,
    requestId: string,
    comment: string,
  ): string {
    return `
      <h2>Request Rejected</h2>
      <p>Dear ${userName},</p>
      <p>Your ${requestType} request (ID: ${requestId}) has been rejected.</p>
      <p><strong>Reason:</strong> ${comment}</p>
      <p>Thank you.</p>
    `;
  }

  private getCorrectionRequiredTemplate(
    userName: string,
    requestType: RequestType,
    requestId: string,
    comment: string,
  ): string {
    return `
      <h2>Correction Required</h2>
      <p>Dear ${userName},</p>
      <p>Your ${requestType} request (ID: ${requestId}) requires corrections.</p>
      <p><strong>Comments:</strong> ${comment}</p>
      <p>Please log in to make the necessary corrections.</p>
      <p>Thank you.</p>
    `;
  }

  private getAssignmentTemplate(
    userName: string,
    requestType: RequestType,
    requestId: string,
    details: string,
  ): string {
    return `
      <h2>Request Assigned</h2>
      <p>Dear ${userName},</p>
      <p>Your ${requestType} request (ID: ${requestId}) has been assigned.</p>
      <p><strong>Details:</strong> ${details}</p>
      <p>Thank you.</p>
    `;
  }
}

