import cron from 'node-cron';
import TokenBlacklist from '../models/tokenBlacklistModel.js';

const logoutCronJob = async () => {
    const cronInterval = `0 0 */3 * *`;
    cron.schedule(cronInterval, async () => {
        try {
            console.log('[CRON] Running TokenBlacklist cleanup...');
            const result = await TokenBlacklist.deleteMany({
                expiresAt: { $lte: new Date() }
            });
            console.log(`[CRON] Cleaned up ${result.deletedCount || 0} expired blacklisted tokens.`);
        } catch (error) {
            console.error('[CRON] Error during TokenBlacklist cleanup:', error.message);
        }
    });
};
export default logoutCronJob;

