import { AnalyticsService } from './analytics.service';
export declare class AnalyticsController {
    private readonly analyticsService;
    constructor(analyticsService: AnalyticsService);
    getPortfolio(req: any): Promise<any>;
    getSegments(req: any): Promise<any>;
    getBrokers(req: any): Promise<any>;
    forceRecalculate(dto: {
        userId?: string;
        rebuildHistory?: boolean;
    }): Promise<{
        message: string;
    }>;
}
