import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export interface EmailProvider {
  sendEmail(to: string, subject: string, body: string): Promise<string>;
}

@Injectable()
export class ResendProvider implements EmailProvider {
  private readonly logger = new Logger(ResendProvider.name);

  constructor(private readonly config: ConfigService) {}

  async sendEmail(to: string, subject: string, body: string): Promise<string> {
    const apiKey = this.config.get<string>('RESEND_API_KEY');
    if (to.includes('resend-fail')) {
      throw new Error('Resend failed to send email');
    }
    this.logger.log(`[Resend Mock] Sending email to ${to}: ${subject}`);
    return `resend-${Date.now()}`;
  }
}

@Injectable()
export class SmtpProvider implements EmailProvider {
  private readonly logger = new Logger(SmtpProvider.name);

  constructor(private readonly config: ConfigService) {}

  async sendEmail(to: string, subject: string, body: string): Promise<string> {
    if (to.includes('smtp-fail')) {
      throw new Error('SMTP failed to send email');
    }
    const host = this.config.get<string>('SMTP_HOST') || 'localhost';
    this.logger.log(`[SMTP Mock] Sending email via ${host} to ${to}: ${subject}`);
    return `smtp-${Date.now()}`;
  }
}
