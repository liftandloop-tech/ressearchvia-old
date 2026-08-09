import mongoose from 'mongoose';
import dotenv from 'dotenv';
dotenv.config();

const MONGO_URI = process.env.MONGO_URI || "mongodb://localhost:27017/research_via_db";

async function checkYoutubeUrls() {
    try {
        await mongoose.connect(MONGO_URI);
        console.log("Connected to DB");

        const Report = mongoose.model('reports', new mongoose.Schema({}, { strict: false }));

        const reportsWithYoutube = await Report.find({ youtubeUrl: { $ne: null, $exists: true } });

        console.log(`Found ${reportsWithYoutube.length} reports with youtubeUrl`);
        reportsWithYoutube.forEach(r => {
            console.log(`- ID: ${r._id}, Title: ${r.title}, youtubeUrl: ${r.youtubeUrl}`);
        });

        process.exit(0);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}

checkYoutubeUrls();
