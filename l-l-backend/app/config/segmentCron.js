import cron from 'node-cron';
import segmentsService from '../services/segmentsServices.js';

const segmentCronJob = async () => {
    const cronInterval = `0 */12 * * *`;
    cron.schedule(cronInterval, async () => {
        try {
            console.log('[CRON] Running expireSegments...');
            await segmentsService.expireSegments();
            console.log('[CRON] expireSegments completed successfully.');
        } catch (error) {
            console.error('[CRON] Error expiring segments:', error.message);
        }
    });
};
export default segmentCronJob;