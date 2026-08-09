import { PrismaService } from '../prisma.service';
import { ConfigService } from '@nestjs/config';
import { MetricsService } from '../infrastructure/metrics/metrics.service';
import { NotificationEvent, AlertSeverity } from '@prisma/client';
import { CircuitBreakerService } from '../infrastructure/circuit-breaker/circuit-breaker.service';
export declare class AlertingService {
    private readonly prisma;
    private readonly config;
    private readonly metrics;
    private readonly circuitBreaker;
    private readonly logger;
    constructor(prisma: PrismaService, config: ConfigService, metrics: MetricsService, circuitBreaker: CircuitBreakerService);
    triggerAlert(event: NotificationEvent, fingerprint: string, details: any, severity?: AlertSeverity): Promise<any>;
    acknowledgeAlert(alertId: string): Promise<any>;
    resolveAlert(alertId: string): Promise<any>;
    private getAlertCountByStatus;
    escalateOpenAlerts(): Promise<void>;
    private dispatchSlackAlert;
    private dispatchEmailAlert;
    private dispatchSmsAlert;
    private dispatchPagerDutyAlert;
}
