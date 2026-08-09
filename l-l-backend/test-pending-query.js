// Test script to verify the pending payments query
// Run with: node test-pending-query.js

import mongoose from 'mongoose';
import dotenv from 'dotenv';
import PaymentIntent from './app/models/paymentIntentModel.js';

dotenv.config();

const testQuery = async () => {
    try {
        await mongoose.connect(process.env.DB_URL);
        console.log('Connected to MongoDB');

        const queryArgs = {
            status: { $in: ['PENDING_BANK_TRANSFER', 'VERIFICATION_PENDING'] },
            $or: [
                { proofImage: { $ne: null, $exists: true } },
                { 'partialPaymentsHistory.0': { $exists: true } }
            ]
        };

        console.log('\n=== QUERY ===');
        console.log(JSON.stringify(queryArgs, null, 2));

        const intents = await PaymentIntent.find(queryArgs).sort({ createdAt: -1 });

        console.log(`\n=== RESULTS: ${intents.length} intents found ===\n`);

        intents.forEach((intent, idx) => {
            console.log(`${idx + 1}. Intent ID: ${intent._id}`);
            console.log(`   Purchase Type: ${intent.purchaseType}`);
            console.log(`   Status: ${intent.status}`);
            console.log(`   Has ProofImage: ${!!intent.proofImage}`);
            console.log(`   ProofImage: ${intent.proofImage || 'null'}`);
            console.log(`   Is Partial: ${intent.isPartial}`);
            console.log(`   Partial History Count: ${intent.partialPaymentsHistory?.length || 0}`);
            console.log(`   Created: ${intent.createdAt}`);
            console.log('');
        });

        // Also check intents that DON'T match
        const allPending = await PaymentIntent.find({
            status: { $in: ['PENDING_BANK_TRANSFER', 'VERIFICATION_PENDING'] }
        }).sort({ createdAt: -1 });

        const excluded = allPending.filter(intent => {
            const hasProof = intent.proofImage != null;
            const hasHistory = intent.partialPaymentsHistory?.length > 0;
            return !hasProof && !hasHistory;
        });

        console.log(`\n=== EXCLUDED INTENTS: ${excluded.length} ===\n`);
        excluded.forEach((intent, idx) => {
            console.log(`${idx + 1}. Intent ID: ${intent._id}`);
            console.log(`   Purchase Type: ${intent.purchaseType}`);
            console.log(`   Status: ${intent.status}`);
            console.log(`   Created: ${intent.createdAt}`);
            console.log('   ✅ Correctly excluded (no proof uploaded)');
            console.log('');
        });

        await mongoose.disconnect();
        console.log('Disconnected from MongoDB');
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
};

testQuery();
