import mongoose from 'mongoose';
import userModel from './app/models/userModel.js';
import KycService from './app/services/kycService.js';
import dotenv from 'dotenv';
dotenv.config();

async function fixKycStatuses() {
    console.log("Connecting to database...");
    await mongoose.connect(process.env.DB_URL);

    // Find users who have at least one gate verified but might be stuck in IN_PROGRESS
    const filter = {
        kycStatus: { $in: ['IN_PROGRESS', 'NOT_STARTED', 'REJECTED', 'WAITING_FOR_REVIEW'] },
        kycGates: { $exists: true }
    };

    const users = await userModel.find(filter);
    console.log(`Found ${users.length} users to potentially sync.`);

    let updatedCount = 0;

    for (const user of users) {
        const oldStatus = user.kycStatus;
        try {
            const updatedUser = await KycService.syncOverallStatus(user._id, { type: 'SYSTEM', id: 'BULK_SYNC' });
            if (updatedUser.kycStatus !== oldStatus) {
                console.log(`Synced User ${user.email || user.phone}: ${oldStatus} -> ${updatedUser.kycStatus}`);
                updatedCount++;
            }
        } catch (e) {
            console.error(`Error syncing user ${user._id}: ${e.message}`);
        }
    }

    // Double check our specific user: pankajkumawat6354@gmail.com
    const specificUser = await userModel.findOne({ email: 'pankajkumawat6354@gmail.com' });
    if (specificUser) {
        console.log(`\nSpecific User Status: ${specificUser.kycStatus}`);
    }

    console.log(`Successfully updated ${updatedCount} users.`);
    console.log("Done.");
    process.exit(0);
}

fixKycStatuses().catch(console.error);
