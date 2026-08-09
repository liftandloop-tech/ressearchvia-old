import mongoose from 'mongoose';
import dotenv from 'dotenv';
import userModel from './app/models/userModel.js';
import paymentIntentModel from './app/models/paymentIntentModel.js';

dotenv.config();

async function checkSpecificUser() {
    try {
        const dbUrl = process.env.DB_URL;
        await mongoose.connect(dbUrl);
        console.log('Connected to MongoDB');

        const user = await userModel.findOne({ phone: '+916265423859' });
        if (!user) {
            console.log('User +916265423859 not found');
            await mongoose.disconnect();
            return;
        }

        console.log('--- User Info ---');
        console.log('ID:', user._id);
        console.log('Registration Status:', user.registrationStatus);
        console.log('KYC Status:', user.kycStatus);

        const intents = await paymentIntentModel.find({ userId: user._id }).sort({ createdAt: -1 });
        console.log('--- Payment Intents ---');
        intents.forEach(i => {
            console.log(`Type: ${i.purchaseType}, Status: ${i.status}, Amount: ${i.totalAmount}, Created: ${i.createdAt}`);
        });

        await mongoose.disconnect();
    } catch (error) {
        console.error('Error:', error);
    }
}

checkSpecificUser();
