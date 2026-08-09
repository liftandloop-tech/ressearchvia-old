import mongoose from 'mongoose';
import 'dotenv/config';
import { getRegistrationDetails } from './app/services/acquisitionService.js';
import User from './app/models/userModel.js';

async function testServiceCall() {
    try {
        await mongoose.connect(process.env.DB_URL);
        const userId = '69a919792fd274e236d3f01e';

        console.log('--- Calling getRegistrationDetails for Rajkumar Parihar ---');
        const details = await getRegistrationDetails(userId);
        console.log(JSON.stringify(details, null, 2));

        // Now simulate a suspension
        console.log('\n--- Simulating Suspension ---');
        await User.findByIdAndUpdate(userId, { userStatus: 'SUSPENDED', suspensionReason: 'Test Suspension' });

        const detailsAfterSuspension = await getRegistrationDetails(userId);
        console.log('Details After Suspension:');
        console.log(JSON.stringify(detailsAfterSuspension, null, 2));

        // Move it back to ACTIVE after test
        await User.findByIdAndUpdate(userId, { userStatus: 'ACTIVE', suspensionReason: null });
        console.log('\nRestored user to ACTIVE.');

    } catch (error) {
        console.error('Test Failed:', error);
    } finally {
        await mongoose.disconnect();
    }
}

testServiceCall();
