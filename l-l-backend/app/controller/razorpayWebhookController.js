import crypto from 'crypto';
import * as acquisitionService from '../services/acquisitionService.js';
import PaymentIntent from '../models/paymentIntentModel.js';
import { getRazorpay } from '../services/razorpayClient.js';

export const handleRazorpayWebhook = async (req, res) => {
    try {
        const signature = req.headers['x-razorpay-signature'];
        const webhookSecret = process.env.RAZORPAY_WEBHOOK_SECRET;

        // 1. Signature Verification (if secret configured)
        if (webhookSecret && signature) {
            const body = req.rawBody || JSON.stringify(req.body);
            const expectedSignature = crypto
                .createHmac('sha256', webhookSecret)
                .update(body)
                .digest('hex');

            if (expectedSignature !== signature) {
                console.error('[Razorpay Webhook] Invalid signature from:', req.ip);
                return res.status(400).json({ status: 400, message: 'Invalid webhook signature' });
            }
        }

        const event = req.body.event;
        const payload = req.body.payload;

        console.log(`[Razorpay Webhook] Received event: ${event}`);

        // Handle payment.captured or order.paid
        if (event === 'payment.captured' || event === 'order.paid') {
            const payment = payload?.payment?.entity;
            const orderId = payment?.order_id || payload?.order?.entity?.id;
            const paymentId = payment?.id;

            if (!orderId) {
                console.warn('[Razorpay Webhook] Missing order_id in webhook payload, skipping.');
                return res.status(200).json({ status: 200, message: 'Skipped - no order_id' });
            }

            console.log(`[Razorpay Webhook] Processing captured payment ${paymentId} for Order ${orderId}...`);

            // Check if intent exists for this order
            let intent = await PaymentIntent.findOne({ razorpayOrderId: orderId });

            // If intent is already PAID, return idempotently
            if (intent && intent.status === 'PAID') {
                console.log(`[Razorpay Webhook] Order ${orderId} is already marked PAID.`);
                return res.status(200).json({ status: 200, message: 'Already processed' });
            }

            // Verify and activate via acquisitionService
            try {
                await acquisitionService.verifyPayment(orderId, paymentId, null);
                console.log(`[Razorpay Webhook] Successfully auto-verified and granted services for Order ${orderId}`);
            } catch (verifyErr) {
                console.error(`[Razorpay Webhook] Error during auto-verification of ${orderId}:`, verifyErr.message);
            }
        }

        return res.status(200).json({ status: 200, message: 'Webhook processed successfully' });
    } catch (error) {
        console.error('[Razorpay Webhook] Fatal webhook handler error:', error);
        return res.status(500).json({ status: 500, message: 'Internal server error' });
    }
};

export default {
    handleRazorpayWebhook
};
