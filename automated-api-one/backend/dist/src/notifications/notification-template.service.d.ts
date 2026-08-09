import { NotificationEvent } from '@prisma/client';
export declare class NotificationTemplateService {
    generateTemplate(event: NotificationEvent, data: any): {
        title: string;
        body: string;
    };
}
