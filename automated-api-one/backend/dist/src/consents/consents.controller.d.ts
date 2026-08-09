import { ConsentsService } from './consents.service';
export declare class ConsentsController {
    private readonly consentsService;
    constructor(consentsService: ConsentsService);
    grantConsent(req: any, brokerId: string): Promise<{
        status: import("@prisma/client").$Enums.ConsentStatus;
        consentDate: string;
    }>;
    getConsentStatusToday(req: any): Promise<{
        active: boolean;
        broker: string | null;
        consentDate: string | null;
        status: string;
    }>;
    getConsentStatusDashboard(req: any): Promise<{
        active: boolean;
        broker: string | null;
        consentDate: string | null;
        status: string;
    }>;
    revokeConsent(req: any): Promise<{
        status: string;
    }>;
}
