import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export interface WhatsAppProvider {
  sendWhatsApp(to: string, templateName: string, parameters: string[]): Promise<string>;
}

@Injectable()
export class WhatsAppCloudProvider implements WhatsAppProvider {
  private readonly logger = new Logger(WhatsAppCloudProvider.name);

  constructor(private readonly config: ConfigService) {}

  async sendWhatsApp(to: string, templateName: string, parameters: string[]): Promise<string> {
    if (to.includes('whatsapp-fail')) {
      throw new Error('WhatsApp Cloud API failed to send message');
    }
    this.logger.log(`[WhatsApp Mock] Sending to ${to} using template ${templateName} with params: ${parameters.join(', ')}`);
    return `whatsapp-${Date.now()}`;
  }
}
