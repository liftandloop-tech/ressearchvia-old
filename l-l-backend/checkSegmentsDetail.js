import mongoose from 'mongoose';
import dotenv from 'dotenv';
import segmentsModel from './app/models/segmentsModel.js';

dotenv.config();

async function checkSegments() {
    try {
        const dbUrl = process.env.DB_URL;
        if (!dbUrl) {
            throw new Error('DB_URL not found in .env');
        }
        await mongoose.connect(dbUrl);
        console.log('Connected to MongoDB');

        const segments = await segmentsModel.find({});
        console.log('Total Segments:', segments.length);
        for (const segment of segments) {
            console.log(`- Name: ${segment.segmentName}`);
            console.log(`  ID: ${segment._id}`);
            console.log(`  Status: ${segment.segmentStatus}`);
            console.log(`  Data: ${JSON.stringify(segment)}`);
        }

        await mongoose.disconnect();
    } catch (error) {
        console.error('Error:', error);
    }
}

checkSegments();
