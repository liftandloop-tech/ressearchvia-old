import mongoose from 'mongoose';
import 'dotenv/config';
import User from './app/models/userModel.js';
import PaymentIntent from './app/models/paymentIntentModel.js';
import Entitlement from './app/models/entitlementModel.js';
import { getRegistrationDetails } from './app/services/acquisitionService.js';

async function runDiagnostic() {
    try {
        console.log('Connecting to DB...');
        await mongoose.connect(process.env.DB_URL);
        console.log('Connected.');

        // 1. Create a mock user
        const mockUser = await User.create({
            fullName: 'Test Suspended User',
            phone: '9999999999',
            email: 'test@example.com',
            userStatus: 'SUSPENDED',
            registrationStatus: 'ACTIVE',
            registrationType: 'YEARLY',
            userObject: { APP_NAME: 'Test User' }
        });
        console.log('Mock User Created:', mockUser._id);

        // 2. Create a mock REJECTED payment intent
        const mockIntent = await PaymentIntent.create({
            userId: mockUser._id,
            purchaseType: 'REGISTRATION',
            status: 'REJECTED',
            totalAmount: 5900,
            baseAmount: 5000,
            gstAmount: 900,
            razorpayOrderId: 'TEST_ORDER_123',
            paymentMethod: 'BANK_TRANSFER'
        });
        console.log('Mock Rejected Intent Created:', mockIntent._id);

        // 3. Call getRegistrationDetails
        console.log('\n--- Calling getRegistrationDetails ---');
        const details = await getRegistrationDetails(mockUser._id);
        console.log('Result:', JSON.stringify(details, null, 2));

        // 4. Verification
        const returnedIntentId = details.paymentStatus.paymentIntentId;
        if (!returnedIntentId) {
            console.log('\n[CONFIRMED] paymentIntentId is NULL for REJECTED intent.');
            console.log('This causes "Invalid Payment ID" in mobile app because Profile Screen passes null to BankTransferUploadScreen.');
        } else {
            console.log('\n[NOT REPRODUCED] paymentIntentId was found:', returnedIntentId);
        }

        // 5. Cleanup
        console.log('\nCleaning up...');
        await User.findByIdAndDelete(mockUser._id);
        await PaymentIntent.findByIdAndDelete(mockIntent._id);
        console.log('Cleanup done.');

    } catch (error) {
        console.error('Diagnostic Failed:', error);
    } finally {
        await mongoose.disconnect();
    }
}

runDiagnostic();
