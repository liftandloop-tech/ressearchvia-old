import mongoose from 'mongoose';
import 'dotenv/config';
import { initiateRegistrationPurchase } from './app/services/acquisitionService.js';
import User from './app/models/userModel.js';
import PaymentIntent from './app/models/paymentIntentModel.js';

async function testSuspensionBlock() {
    try {
        await mongoose.connect(process.env.DB_URL);
        const userId = '69a919792fd274e236d3f01e';

        // 1. Suspend the user
        await User.findByIdAndUpdate(userId, { userStatus: 'SUSPENDED' });
        console.log('User Suspended.');

        // 2. Try to initiate a new registration purchase via service (simulating API call)
        console.log('Attempting to initiate registration purchase...');
        try {
            const result = await initiateRegistrationPurchase(userId, 'YEARLY', 'BANK_TRANSFER', null, null, true);
            console.log('Purchase Initiated Successfully:', result.paymentIntentId);
        } catch (e) {
            console.log('Purchase Blocked with Error:', e.message);
        }

        // Restore user status
        await User.findByIdAndUpdate(userId, { userStatus: 'ACTIVE' });
        console.log('User restored to ACTIVE.');

    } catch (error) {
        console.error('Test Failed:', error);
    } finally {
        await mongoose.disconnect();
    }
}

testSuspensionBlock();
