import mongoose from 'mongoose';
import dotenv from 'dotenv';
import userModel from './app/models/userModel.js';

dotenv.config();

async function checkUserStatus() {
    try {
        const dbUrl = process.env.DB_URL;
        await mongoose.connect(dbUrl);
        console.log('Connected to MongoDB');

        const user = await userModel.findOne({ phone: '+916265423859' });
        if (!user) {
            console.log('User not found');
            await mongoose.disconnect();
            return;
        }

        console.log('--- User Status Check ---');
        console.log('ID:', user._id);
        console.log('userStatus:', user.userStatus);
        console.log('registrationStatus:', user.registrationStatus);
        console.log('kycStatus:', user.kycStatus);
        console.log('account_type:', user.account_type);

        await mongoose.disconnect();
    } catch (error) {
        console.error('Error:', error);
    }
}

checkUserStatus();
