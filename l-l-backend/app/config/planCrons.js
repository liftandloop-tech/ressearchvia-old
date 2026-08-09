import cron from 'node-cron';
import planPurchaseController from '../controller/planPurchaseController.js';
const planCronJob = async () => {
    // Schedule for 12:00 AM and 12:00 PM
    cron.schedule('0 0,12 * * *', planPurchaseController.expirePlan);

    // Schedule for 08:30 AM
    cron.schedule('30 8 * * *', planPurchaseController.expirePlan);
}
export default planCronJob;