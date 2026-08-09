import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export interface PushProvider {
  sendPush(token: string, title: string, body: string): Promise<string>;
}

@Injectable()
export class FcmProvider implements PushProvider {
  private readonly logger = new Logger(FcmProvider.name);

  constructor(private readonly config: ConfigService) {}

  async sendPush(token: string, title: string, body: string): Promise<string> {
    if (token.includes('push-fail')) {
      throw new Error('FCM failed to send push notification');
    }
    this.logger.log(`[Fcm Mock] Sending push to token ${token}: ${title} - ${body}`);
    return `fcm-${Date.now()}`;
  }
}
