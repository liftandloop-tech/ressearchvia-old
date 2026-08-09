import cron from 'node-cron';
import segmentsController from '../controller/segmentsController.js';

const segmentCronJob = async () => {
    let job = null;
    let cronInterval = `0 */12 * * *`;
    if (job) {
        job.stop(); 0
    }
    job = cron.schedule(cronInterval, segmentsController.expireSegments);
};
export default segmentCronJob;