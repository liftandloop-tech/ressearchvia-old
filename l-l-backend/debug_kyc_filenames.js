
import mongoose from 'mongoose';
import userModel from './app/models/userModel.js';
import dotenv from 'dotenv';
dotenv.config();

const MONGO_URI = process.env.DB_URL;

async function checkUserKyc() {
    try {
        await mongoose.connect(MONGO_URI);
        console.log('Connected to DB');

        const userWithDocs = await userModel.findOne({
            $or: [
                { "kycDocs.aadhaarFront": { $exists: true, $ne: null } },
                { "kycDocs.panImage": { $exists: true, $ne: null } }
            ]
        });

        if (userWithDocs) {
            console.log('Found user with docs:', userWithDocs._id);
            console.log('kycDocs:', JSON.stringify(userWithDocs.kycDocs, null, 2));
            console.log('legacy Video:', userWithDocs.kycVideo);
        } else {
            console.log('No user with KYC docs found.');
        }

    } catch (error) {
        console.error('Error:', error);
    } finally {
        await mongoose.disconnect();
    }
}

checkUserKyc();
