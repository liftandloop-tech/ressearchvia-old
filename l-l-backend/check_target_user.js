import mongoose from 'mongoose';
import 'dotenv/config';
import User from './app/models/userModel.js';
import PaymentIntent from './app/models/paymentIntentModel.js';
import Entitlement from './app/models/entitlementModel.js';

async function checkUserState() {
    try {
        console.log('Connecting to DB...');
        await mongoose.connect(process.env.DB_URL);
        console.log('Connected.\n');

        const phone = '9770784982';
        console.log(`Searching for user with phone: ${phone}`);

        // Find user by phone (checking multiple formats as per userService logic)
        const cleanPhone = phone.toString().replace(/\D/g, "").slice(-10);
        const user = await User.findOne({
            $or: [
                { phone: cleanPhone },
                { phone: "91" + cleanPhone },
                { phone: "+91" + cleanPhone },
            ],
        });

        if (!user) {
            console.log('User not found.');
            return;
        }

        console.log('--- User Details ---');
        console.log('ID:', user._id);
        console.log('Name:', user.fullName);
        console.log('Status:', user.userStatus);
        console.log('Registration Status:', user.registrationStatus);
        console.log('Registration Type:', user.registrationType);
        console.log('Registration Fee Paid:', user.registrationFeePaid);
        console.log('Suspension Reason:', user.suspensionReason || 'N/A');

        console.log('\n--- Payment Intents ---');
        const intents = await PaymentIntent.find({ userId: user._id }).sort({ createdAt: -1 });
        if (intents.length === 0) {
            console.log('No payment intents found.');
        } else {
            intents.forEach((intent, i) => {
                console.log(`[${i + 1}] ID: ${intent._id}, Type: ${intent.purchaseType}, Status: ${intent.status}, Method: ${intent.paymentMethod}, Amount: ${intent.totalAmount}, isPartial: ${intent.isPartial}`);
            });
        }

        console.log('\n--- Entitlements ---');
        const entitlements = await Entitlement.find({ userId: user._id });
        if (entitlements.length === 0) {
            console.log('No entitlements found.');
        } else {
            entitlements.forEach((ent, i) => {
                console.log(`[${i + 1}] Type: ${ent.type}, Status: ${ent.status}, GrantedBy: ${ent.grantedBy}, Reason: ${ent.grantReason}`);
            });
        }

    } catch (error) {
        console.error('Check Failed:', error);
    } finally {
        await mongoose.disconnect();
    }
}

checkUserState();
