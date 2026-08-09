import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export interface SmsProvider {
  sendSms(to: string, message: string): Promise<string>;
}

@Injectable()
export class TwilioProvider implements SmsProvider {
  private readonly logger = new Logger(TwilioProvider.name);

  constructor(private readonly config: ConfigService) {}

  async sendSms(to: string, message: string): Promise<string> {
    if (to.includes('twilio-fail')) {
      throw new Error('Twilio failed to send SMS');
    }
    this.logger.log(`[Twilio Mock] Sending SMS to ${to}: ${message}`);
    return `twilio-${Date.now()}`;
  }
}

@Injectable()
export class Msg91Provider implements SmsProvider {
  private readonly logger = new Logger(Msg91Provider.name);

  constructor(private readonly config: ConfigService) {}

  async sendSms(to: string, message: string): Promise<string> {
    if (to.includes('msg91-fail')) {
      throw new Error('Msg91 failed to send SMS');
    }
    this.logger.log(`[Msg91 Mock] Sending SMS to ${to}: ${message}`);
    return `msg91-${Date.now()}`;
  }
}
