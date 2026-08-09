import mongoose from 'mongoose';
import dotenv from 'dotenv';
import userModel from './app/models/userModel.js';
import paymentIntentModel from './app/models/paymentIntentModel.js';

dotenv.config();

async function checkUsers() {
    try {
        const dbUrl = process.env.DB_URL;
        if (!dbUrl) {
            throw new Error('DB_URL not found in .env');
        }
        await mongoose.connect(dbUrl);
        console.log('Connected to MongoDB');

        const recentUsers = await userModel.find({
            registrationStatus: 'ACTIVE'
        }).sort({ updatedAt: -1 }).limit(10);

        if (recentUsers.length === 0) {
            console.log('No ACTIVE users found.');
        }

        for (const user of recentUsers) {
            console.log('--- User ---');
            console.log('ID:', user._id);
            console.log('Phone:', user.phone);
            console.log('Registration Status:', user.registrationStatus);
            console.log('Registration Fee Paid:', user.registrationFeePaid);
            console.log('KYC Status:', user.kycStatus);
            console.log('Updated At:', user.updatedAt);

            const pendingReg = await paymentIntentModel.findOne({
                userId: user._id,
                purchaseType: "REGISTRATION",
                status: { $in: ["VERIFICATION_PENDING", "PENDING_ADMIN_APPROVAL", "PENDING_BANK_TRANSFER"] }
            });
            console.log('Pending Registration Intent:', pendingReg ? 'FOUND' : 'NOT FOUND');
            if (pendingReg) {
                console.log('Pending Intent Status:', pendingReg.status);
            }
        }

        await mongoose.disconnect();
    } catch (error) {
        console.error('Error:', error);
    }
}

checkUsers();
