"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var AlertingService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.AlertingService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma.service");
const config_1 = require("@nestjs/config");
const metrics_service_1 = require("../infrastructure/metrics/metrics.service");
const client_1 = require("@prisma/client");
const schedule_1 = require("@nestjs/schedule");
const circuit_breaker_service_1 = require("../infrastructure/circuit-breaker/circuit-breaker.service");
let AlertingService = AlertingService_1 = class AlertingService {
    prisma;
    config;
    metrics;
    circuitBreaker;
    logger = new common_1.Logger(AlertingService_1.name);
    constructor(prisma, config, metrics, circuitBreaker) {
        this.prisma = prisma;
        this.config = config;
        this.metrics = metrics;
        this.circuitBreaker = circuitBreaker;
    }
    async triggerAlert(event, fingerprint, details, severity = client_1.AlertSeverity.WARNING) {
        try {
            const openAlert = await this.prisma.sreAlert.findFirst({
                where: {
                    fingerprint,
                    status: client_1.AlertStatus.OPEN,
                },
            });
            if (openAlert) {
                const updated = await this.prisma.sreAlert.update({
                    where: { id: openAlert.id },
                    data: {
                        occurrenceCount: { increment: 1 },
                        details: details || {},
                        updatedAt: new Date(),
                    },
                });
                this.logger.log(`Incremented alert occurrence: ${fingerprint} (${updated.occurrenceCount})`);
                return updated;
            }
            const created = await this.prisma.sreAlert.create({
                data: {
                    event,
                    fingerprint,
                    details: details || {},
                    severity,
                    status: client_1.AlertStatus.OPEN,
                    occurrenceCount: 1,
                    escalationLevel: 0,
                },
            });
            this.metrics.setSreAlertOpen(await this.getAlertCountByStatus(client_1.AlertStatus.OPEN));
            await this.dispatchSlackAlert(created);
            return created;
        }
        catch (err) {
            this.logger.error(`Failed to trigger alert for ${fingerprint}: ${err.message}`);
        }
    }
    async acknowledgeAlert(alertId) {
        const updated = await this.prisma.sreAlert.update({
            where: { id: alertId },
            data: {
                status: client_1.AlertStatus.ACKNOWLEDGED,
                updatedAt: new Date(),
            },
        });
        const openCount = await this.getAlertCountByStatus(client_1.AlertStatus.OPEN);
        const ackCount = await this.getAlertCountByStatus(client_1.AlertStatus.ACKNOWLEDGED);
        this.metrics.setSreAlertOpen(openCount);
        this.metrics.setSreAlertAcknowledged(ackCount);
        this.logger.log(`Alert acknowledged: ${alertId}`);
        return updated;
    }
    async resolveAlert(alertId) {
        const updated = await this.prisma.sreAlert.update({
            where: { id: alertId },
            data: {
                status: client_1.AlertStatus.RESOLVED,
                resolvedAt: new Date(),
                updatedAt: new Date(),
            },
        });
        const openCount = await this.getAlertCountByStatus(client_1.AlertStatus.OPEN);
        const ackCount = await this.getAlertCountByStatus(client_1.AlertStatus.ACKNOWLEDGED);
        const resolvedCount = await this.getAlertCountByStatus(client_1.AlertStatus.RESOLVED);
        this.metrics.setSreAlertOpen(openCount);
        this.metrics.setSreAlertAcknowledged(ackCount);
        this.metrics.setSreAlertResolved(resolvedCount);
        this.logger.log(`Alert resolved: ${alertId}`);
        return updated;
    }
    async getAlertCountByStatus(status) {
        return this.prisma.sreAlert.count({ where: { status } });
    }
    async escalateOpenAlerts() {
        const openAlerts = await this.prisma.sreAlert.findMany({
            where: {
                status: client_1.AlertStatus.OPEN,
            },
        });
        const now = Date.now();
        for (const alert of openAlerts) {
            const elapsedMins = (now - alert.createdAt.getTime()) / 60000;
            let targetLevel = 0;
            if (elapsedMins >= 30) {
                targetLevel = 3;
            }
            else if (elapsedMins >= 15) {
                targetLevel = 2;
            }
            else if (elapsedMins >= 5) {
                targetLevel = 1;
            }
            if (targetLevel > alert.escalationLevel) {
                await this.prisma.sreAlert.update({
                    where: { id: alert.id },
                    data: {
                        escalationLevel: targetLevel,
                        lastEscalatedAt: new Date(),
                    },
                });
                this.logger.log(`Escalating alert ${alert.id} to level ${targetLevel}`);
                if (targetLevel === 1) {
                    await this.dispatchEmailAlert(alert);
                }
                else if (targetLevel === 2) {
                    await this.dispatchSmsAlert(alert);
                }
                else if (targetLevel === 3) {
                    await this.dispatchPagerDutyAlert(alert);
                }
            }
        }
    }
    async dispatchSlackAlert(alert) {
        const webhookUrl = this.config.get('SLACK_WEBHOOK_URL');
        this.logger.log(`[Slack Mock] Dispatching SRE alert ${alert.fingerprint} to webhook ${webhookUrl || 'not configured'}`);
    }
    async dispatchEmailAlert(alert) {
        this.logger.log(`[Email Mock] Dispatching SRE alert escalation ${alert.fingerprint} to on-call email`);
    }
    async dispatchSmsAlert(alert) {
        this.logger.log(`[SMS Mock] Dispatching SRE alert escalation ${alert.fingerprint} to on-call mobile`);
    }
    async dispatchPagerDutyAlert(alert) {
        try {
            await this.circuitBreaker.execute('pagerduty-alerts', async () => {
                const pdRoutingKey = this.config.get('PAGERDUTY_ROUTING_KEY');
                this.logger.log(`[PagerDuty Mock] Dispatching SRE alert escalation ${alert.fingerprint} to PagerDuty with routing key ${pdRoutingKey || 'not configured'}`);
            });
        }
        catch (err) {
            this.logger.error(`PagerDuty dispatch failed or circuit open: ${err.message}`);
        }
    }
};
exports.AlertingService = AlertingService;
__decorate([
    (0, schedule_1.Cron)(schedule_1.CronExpression.EVERY_MINUTE),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], AlertingService.prototype, "escalateOpenAlerts", null);
exports.AlertingService = AlertingService = AlertingService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        config_1.ConfigService,
        metrics_service_1.MetricsService,
        circuit_breaker_service_1.CircuitBreakerService])
], AlertingService);
//# sourceMappingURL=alerting.service.js.map