import cron from 'node-cron';
import * as acquisitionService from '../services/acquisitionService.js';

/**
 * Phase 3: Completion & Automation (The Overflow Trigger)
 * Checks for expired partial plans with a wallet balance and initiates renewals.
 */
const partialCronJob = async () => {
    // Run every 12 hours like other crons
    const cronInterval = `0 */12 * * *`;

    cron.schedule(cronInterval, async () => {
        console.log("CRON: Starting handleExpiredPartials...");
        try {
            await acquisitionService.handleExpiredPartials();
        } catch (error) {
            console.error("CRON: Error in handleExpiredPartials:", error);
        }
    });

    console.log("CRON: Registered partialCronJob (every 12 hours)");

    // Expiry Warning Cron - runs daily at 10 AM
    cron.schedule('0 10 * * *', async () => {
        console.log("CRON: Starting sendPartialExpiryWarnings...");
        try {
            await acquisitionService.sendPartialExpiryWarnings();
        } catch (error) {
            console.error("CRON: Error in sendPartialExpiryWarnings:", error);
        }
    });

    console.log("CRON: Registered partialExpiryWarnings (daily at 10 AM)");

    // Abandoned Intent Expiry Cron — runs every 10 minutes
    // Marks CREATED PaymentIntents with amountPaid=0 older than 10 minutes as FAILED.
    cron.schedule('*/10 * * * *', async () => {
        console.log("CRON: Starting expireAbandonedIntents...");
        try {
            await acquisitionService.expireAbandonedIntents(10);
        } catch (error) {
            console.error("CRON: Error in expireAbandonedIntents:", error);
        }
    });

    console.log("CRON: Registered expireAbandonedIntents (every 10 minutes)");
};

export default partialCronJob;

