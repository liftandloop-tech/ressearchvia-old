import mongoose from 'mongoose';
import userModel from './app/models/userModel.js';
import entitlementModel from './app/models/entitlementModel.js';
import paymentIntentModel from './app/models/paymentIntentModel.js';
import planPurchaseModel from './app/models/planPurchaseModel.js';

async function diagnoseRajesh() {
  const uri = "mongodb://root:Research%4028@72.60.221.95:27017/researchvia?authSource=admin";
  await mongoose.connect(uri);
  
  const firstUsers = await userModel.find().limit(5);
  console.log('Sample Users:', firstUsers.map(u => ({ name: u.fullName, phone: u.phone })));

  const rajeshs = await userModel.find({ fullName: { $regex: 'Rajesh', $options: 'i' } });
  console.log('All Rajeshs:', rajeshs.map(u => ({ name: u.fullName, phone: u.phone, regStatus: u.registrationStatus })));

  const user = rajeshs.find(u => u.fullName.toLowerCase().includes('shah')) || rajeshs[0];
  if (!user) {
    console.log('User Rajesh not found');
    process.exit(0);
  }

  console.log('--- USER DATA ---');
  console.log('ID:', user._id);
  console.log('Name:', user.fullName);
  console.log('Phone:', user.phone);
  console.log('Registration Status:', user.registrationStatus);
  console.log('Registration Fee Paid:', user.registrationFeePaid);
  console.log('KYC Status:', user.kycStatus);
  console.log('User Status:', user.userStatus);

  console.log('\n--- ENTITLEMENTS ---');
  const entitlements = await entitlementModel.find({ userId: user._id });
  console.log(JSON.stringify(entitlements, null, 2));

  console.log('\n--- PAYMENT INTENTS ---');
  const intents = await paymentIntentModel.find({ userId: user._id });
  console.log(JSON.stringify(intents, null, 2));

  console.log('\n--- PLAN PURCHASES ---');
  const purchases = await planPurchaseModel.find({ userId: user._id });
  console.log(JSON.stringify(purchases, null, 2));

  process.exit(0);
}

diagnoseRajesh();
