
import mongoose from "mongoose";
import dotenv from "dotenv";
import path from "path";
import { fileURLToPath } from 'url';

// Models
import PaymentIntent from "./app/models/paymentIntentModel.js";
import PlanPurchase from "./app/models/planPurchaseModel.js";
import PaymentModel from "./app/models/paymentModel.js";
import SegmentsPlan from "./app/models/segmentsPlansModel.js";
import User from "./app/models/userModel.js";

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const connectDB = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI || process.env.DB_URL);
        console.log("MongoDB Connected");
    } catch (err) {
        console.error("DB Connection Error:", err.message);
        process.exit(1);
    }
};

const syncLegacy = async () => {
    await connectDB();

    try {
        const paidIntents = await PaymentIntent.find({ status: 'PAID' });
        console.log(`Found ${paidIntents.length} PAID intents. Checking for legacy sync...`);

        for (const intent of paidIntents) {
            // Check if Legacy Payment exists
            const exists = await PaymentModel.findOne({ razorpayOrderId: intent.razorpayOrderId });
            if (exists) {
                // console.log(`Skipping ${intent.razorpayOrderId}: Already synced.`);
                continue;
            }

            console.log(`Syncing ${intent.razorpayOrderId}...`);

            const currentDate = intent.updatedAt || new Date(); // Use actual payment date
            let planPurchase = null;

            if (intent.purchaseType === 'REGISTRATION') {
                const isLifetime = intent.baseAmount >= 2; // Logic check
                const endDate = new Date(currentDate);
                if (isLifetime) endDate.setDate(endDate.getDate() + 3652);
                else endDate.setDate(endDate.getDate() + 365);

                planPurchase = new PlanPurchase({
                    userId: intent.userId,
                    packageName: isLifetime ? 'Lifetime Registration' : 'Yearly Registration',
                    validity: isLifetime ? 3652 : 365,
                    startDate: currentDate,
                    endDate: endDate,
                    status: 'active',
                    basicAmount: intent.baseAmount,
                    cgstAmount: intent.gstAmount / 2,
                    sgstAmount: intent.gstAmount / 2,
                    paymentMethod: 'ONLINE',
                    expiryReminder: true,
                    createdAt: currentDate
                });
            } else if (intent.purchaseType === 'PLAN') {
                const plan = await SegmentsPlan.findById(intent.planId);
                let days = 30;
                if (plan) {
                    if (plan.planName && plan.planName.toLowerCase().includes('lifetime')) {
                        days = 3652;
                    } else {
                        // Robust parsing
                        const d1 = parseInt(plan.duration);
                        const d2 = parseInt(plan.day);
                        if (!isNaN(d1) && d1 > 0) days = d1;
                        else if (!isNaN(d2) && d2 > 0) days = d2;
                    }
                }
                const endDate = new Date(currentDate);
                endDate.setDate(endDate.getDate() + days);

                planPurchase = new PlanPurchase({
                    userId: intent.userId,
                    packageName: plan ? plan.planName : "Unknown Plan",
                    validity: days,
                    startDate: currentDate,
                    endDate: endDate,
                    status: 'active',
                    basicAmount: intent.baseAmount,
                    cgstAmount: intent.gstAmount / 2,
                    sgstAmount: intent.gstAmount / 2,
                    paymentMethod: 'ONLINE',
                    expiryReminder: true,
                    createdAt: currentDate
                });
            }

            if (planPurchase) {
                await planPurchase.save();

                await PaymentModel.create({
                    userId: intent.userId,
                    packageId: planPurchase._id,
                    razorpayOrderId: intent.razorpayOrderId,
                    razorpayPaymentId: intent.paymentId || `LEGACY_SYNC_${Date.now()}`,
                    razorpaySignature: 'SYNCED',
                    razorpayReceipt: intent.razorpayOrderId,
                    amount: intent.totalAmount,
                    razorpayCurrency: 'INR',
                    paymentMethod: 'ONLINE',
                    status: 'paid',
                    createdAt: currentDate
                });
                console.log(`Synced ${intent.razorpayOrderId} success.`);
            }
        }
        console.log("Sync Complete.");
        process.exit(0);
    } catch (error) {
        console.error("Error:", error);
        process.exit(1);
    }
};

syncLegacy();
