import { Injectable } from '@nestjs/common';
import { NotificationEvent } from '@prisma/client';

@Injectable()
export class NotificationTemplateService {
  /**
   * Generates email/SMS/WhatsApp subject, body, or formatted template parameters based on event type.
   */
  generateTemplate(event: NotificationEvent, data: any): { title: string; body: string } {
    let title = '';
    let body = '';

    switch (event) {
      case NotificationEvent.ORDER_PLACED:
        title = 'Order Placed';
        body = `Your order for ${data.symbol || 'N/A'} (${data.quantity || 0} units) has been placed.`;
        break;
      case NotificationEvent.ORDER_FILLED:
        title = 'Order Filled';
        body = `Your order for ${data.symbol || 'N/A'} (${data.quantity || 0} units) was filled.`;
        break;
      case NotificationEvent.ORDER_REJECTED:
        title = 'Order Rejected';
        body = `Your order for ${data.symbol || 'N/A'} was rejected. Reason: ${data.reason || 'Unknown'}.`;
        break;
      case NotificationEvent.RISK_BLOCKED:
        title = 'Risk Violation Enforced';
        body = `A trading lock has been triggered. Reason: ${data.reason || 'Risk threshold exceeded'}.`;
        break;
      case NotificationEvent.TARGET_HIT:
        title = 'Target Price Hit';
        body = `Target price hit for ${data.symbol || 'N/A'}. PnL: ${data.pnl || 0}.`;
        break;
      case NotificationEvent.STOP_LOSS_HIT:
        title = 'Stop Loss Hit';
        body = `Stop loss hit for ${data.symbol || 'N/A'}. PnL: ${data.pnl || 0}.`;
        break;
      case NotificationEvent.PAYMENT_RECEIVED:
        title = 'Payment Successful';
        body = `We received your payment of ${data.amount || 0} for subscription.`;
        break;
      case NotificationEvent.SUBSCRIPTION_EXPIRED:
        title = 'Subscription Expired';
        body = 'Your subscription plan has expired. Please renew to continue trading.';
        break;
      case NotificationEvent.BROKER_DISCONNECTED:
        title = 'Broker Connection Disconnected';
        body = `Your broker session for ${data.broker || 'broker'} has expired or disconnected.`;
        break;
      case NotificationEvent.RECONCILIATION_CRITICAL:
        title = 'Critical Reconciliation Alert';
        body = `Reconciliation mismatch found on broker ${data.broker || 'broker'}. Details: ${data.details || 'mismatch'}.`;
        break;
      case NotificationEvent.SYSTEM_ALERT:
        title = 'System Operational Alert';
        body = `SRE Alert: ${data.message || 'System health warning'}`;
        break;
      default:
        title = 'Notification';
        body = data.message || 'An update has occurred.';
    }

    return { title, body };
  }
}
