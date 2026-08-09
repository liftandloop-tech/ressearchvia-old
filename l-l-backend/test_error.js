import mongoose from 'mongoose';
import dotenv from 'dotenv';
dotenv.config();

import PaymentIntent from './app/models/paymentIntentModel.js';
import { approvePartialPayment } from './app/services/acquisitionService.js';

async function run() {
    await mongoose.connect(process.env.DB_URL || 'mongodb://localhost:27017/spresearchvia');
    
    // find a pending partial payment intent
    const intent = await PaymentIntent.findOne({ isPartial: true, "partialPaymentsHistory.status": "PENDING" });
    if (!intent) {
        console.log("No pending partial payment intent found.");
        process.exit(0);
    }
    
    const historyItem = intent.partialPaymentsHistory.find(h => h.status === 'PENDING');
    
    console.log(`Found Intent: ${intent._id}, History: ${historyItem._id}`);
    
    try {
        await approvePartialPayment(intent._id, historyItem._id, null, "Test approval");
        console.log("Approval succeeded!");
    } catch (e) {
        console.error("Error during approval:", e.message);
        console.error(e.stack);
    }
    process.exit(0);
}
run();
