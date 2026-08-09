import cron from 'node-cron';
import usersController from '../controller/userController.js';

const logoutCronJob = async () => {
    let job = null;
    let croneDay = 3;
    let cronInterval = `0 0 */${croneDay} * *`;
    if (job) {
        job.stop();0
    }
    if (croneDay > 0)
        job = cron.schedule(cronInterval, usersController.logOutUser);
};
export default logoutCronJob;

