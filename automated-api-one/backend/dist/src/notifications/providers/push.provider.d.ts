import { ConfigService } from '@nestjs/config';
export interface PushProvider {
    sendPush(token: string, title: string, body: string): Promise<string>;
}
export declare class FcmProvider implements PushProvider {
    private readonly config;
    private readonly logger;
    constructor(config: ConfigService);
    sendPush(token: string, title: string, body: string): Promise<string>;
}
