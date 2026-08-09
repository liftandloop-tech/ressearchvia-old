import { ConfigService } from '@nestjs/config';
export interface EmailProvider {
    sendEmail(to: string, subject: string, body: string): Promise<string>;
}
export declare class ResendProvider implements EmailProvider {
    private readonly config;
    private readonly logger;
    constructor(config: ConfigService);
    sendEmail(to: string, subject: string, body: string): Promise<string>;
}
export declare class SmtpProvider implements EmailProvider {
    private readonly config;
    private readonly logger;
    constructor(config: ConfigService);
    sendEmail(to: string, subject: string, body: string): Promise<string>;
}
