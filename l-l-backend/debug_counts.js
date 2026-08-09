
import mongoose from 'mongoose';
import segmentsPaymentModel from './app/models/segmentsPaymentModel.js';
import segmentsModel from './app/models/segmentsModel.js';
import entitlementModel from './app/models/entitlementModel.js';
import userActiveSegmentModel from './app/models/userActiveSegmentsModel.js';
import dotenv from 'dotenv';

dotenv.config();

const mongoUri = process.env.DB_URL;
if (!mongoUri) {
    console.error('DB_URL not found in .env');
    process.exit(1);
}

async function debugData() {
    try {
        await mongoose.connect(mongoUri);
        console.log('Connected to MongoDB');

        const totalPayments = await segmentsPaymentModel.countDocuments({});
        console.log('Total Segments Payments:', totalPayments);

        const paidPayments = await segmentsPaymentModel.countDocuments({ paymentStatus: 'paid' });
        console.log('Paid Segments Payments (lowercase):', paidPayments);

        const paidPaymentsCaps = await segmentsPaymentModel.countDocuments({ paymentStatus: 'PAID' });
        console.log('Paid Segments Payments (uppercase):', paidPaymentsCaps);

        const activeEntitlements = await entitlementModel.countDocuments({ status: 'ACTIVE', type: 'PLAN' });
        console.log('Active Plan Entitlements:', activeEntitlements);

        const userActiveSegments = await userActiveSegmentModel.countDocuments({ isActive: true });
        console.log('User Active Segments (isActive: true):', userActiveSegments);

        const segments = await segmentsModel.find({}).select('_id segmentName');
        console.log('Calculating counts per segment...');

        for (const segment of segments) {
            const pmts = await segmentsPaymentModel.countDocuments({
                segmentId: segment._id,
                paymentStatus: { $in: ['paid', 'PAID'] },
                expiryDate: { $gt: new Date() }
            });
            const ents = await entitlementModel.countDocuments({
                segmentId: segment._id,
                status: 'ACTIVE',
                type: 'PLAN',
                $or: [
                    { endDate: null },
                    { endDate: { $gt: new Date() } }
                ]
            });
            const uas = await userActiveSegmentModel.countDocuments({
                segmentId: segment._id,
                isActive: true,
                expiryDate: { $gt: new Date() }
            });
            console.log(`${segment.segmentName}: PaymentCount=${pmts}, EntitlementCount=${ents}, UserActiveSegmentCount=${uas}`);
        }

        process.exit(0);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}

debugData();
