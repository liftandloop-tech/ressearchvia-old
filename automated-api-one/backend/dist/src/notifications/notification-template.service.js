"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.NotificationTemplateService = void 0;
const common_1 = require("@nestjs/common");
const client_1 = require("@prisma/client");
let NotificationTemplateService = class NotificationTemplateService {
    generateTemplate(event, data) {
        let title = '';
        let body = '';
        switch (event) {
            case client_1.NotificationEvent.ORDER_PLACED:
                title = 'Order Placed';
                body = `Your order for ${data.symbol || 'N/A'} (${data.quantity || 0} units) has been placed.`;
                break;
            case client_1.NotificationEvent.ORDER_FILLED:
                title = 'Order Filled';
                body = `Your order for ${data.symbol || 'N/A'} (${data.quantity || 0} units) was filled.`;
                break;
            case client_1.NotificationEvent.ORDER_REJECTED:
                title = 'Order Rejected';
                body = `Your order for ${data.symbol || 'N/A'} was rejected. Reason: ${data.reason || 'Unknown'}.`;
                break;
            case client_1.NotificationEvent.RISK_BLOCKED:
                title = 'Risk Violation Enforced';
                body = `A trading lock has been triggered. Reason: ${data.reason || 'Risk threshold exceeded'}.`;
                break;
            case client_1.NotificationEvent.TARGET_HIT:
                title = 'Target Price Hit';
                body = `Target price hit for ${data.symbol || 'N/A'}. PnL: ${data.pnl || 0}.`;
                break;
            case client_1.NotificationEvent.STOP_LOSS_HIT:
                title = 'Stop Loss Hit';
                body = `Stop loss hit for ${data.symbol || 'N/A'}. PnL: ${data.pnl || 0}.`;
                break;
            case client_1.NotificationEvent.PAYMENT_RECEIVED:
                title = 'Payment Successful';
                body = `We received your payment of ${data.amount || 0} for subscription.`;
                break;
            case client_1.NotificationEvent.SUBSCRIPTION_EXPIRED:
                title = 'Subscription Expired';
                body = 'Your subscription plan has expired. Please renew to continue trading.';
                break;
            case client_1.NotificationEvent.BROKER_DISCONNECTED:
                title = 'Broker Connection Disconnected';
                body = `Your broker session for ${data.broker || 'broker'} has expired or disconnected.`;
                break;
            case client_1.NotificationEvent.RECONCILIATION_CRITICAL:
                title = 'Critical Reconciliation Alert';
                body = `Reconciliation mismatch found on broker ${data.broker || 'broker'}. Details: ${data.details || 'mismatch'}.`;
                break;
            case client_1.NotificationEvent.SYSTEM_ALERT:
                title = 'System Operational Alert';
                body = `SRE Alert: ${data.message || 'System health warning'}`;
                break;
            default:
                title = 'Notification';
                body = data.message || 'An update has occurred.';
        }
        return { title, body };
    }
};
exports.NotificationTemplateService = NotificationTemplateService;
exports.NotificationTemplateService = NotificationTemplateService = __decorate([
    (0, common_1.Injectable)()
], NotificationTemplateService);
//# sourceMappingURL=notification-template.service.js.map