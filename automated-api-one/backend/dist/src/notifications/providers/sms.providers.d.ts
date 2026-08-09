import { ConfigService } from '@nestjs/config';
export interface SmsProvider {
    sendSms(to: string, message: string): Promise<string>;
}
export declare class TwilioProvider implements SmsProvider {
    private readonly config;
    private readonly logger;
    constructor(config: ConfigService);
    sendSms(to: string, message: string): Promise<string>;
}
export declare class Msg91Provider implements SmsProvider {
    private readonly config;
    private readonly logger;
    constructor(config: ConfigService);
    sendSms(to: string, message: string): Promise<string>;
}
