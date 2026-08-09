import { ConfigService } from '@nestjs/config';
export interface WhatsAppProvider {
    sendWhatsApp(to: string, templateName: string, parameters: string[]): Promise<string>;
}
export declare class WhatsAppCloudProvider implements WhatsAppProvider {
    private readonly config;
    private readonly logger;
    constructor(config: ConfigService);
    sendWhatsApp(to: string, templateName: string, parameters: string[]): Promise<string>;
}
