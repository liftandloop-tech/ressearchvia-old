import mongoose from 'mongoose';
import userModel from './app/models/userModel.js';

async function fixUser() {
  const uri = "mongodb://root:Research%4028@72.60.221.95:27017/researchvia?authSource=admin";
  await mongoose.connect(uri);
  const user = await userModel.findOne({ phone: '+918085006523' });
  if (!user) {
    console.log('User not found');
    process.exit(0);
  }
  
  console.log('Old KYC status:', user.kycStatus);
  console.log('Old Gates:', JSON.stringify(user.kycGates));

  user.kycGates = {
    documents: { status: 'VERIFIED', reviewedAt: new Date() },
    esign: { status: 'VERIFIED', reviewedAt: new Date() },
    video: { status: 'VERIFIED', reviewedAt: new Date() }
  };
  user.kycStatus = 'VERIFIED';
  user.markModified('kycGates');
  await user.save();

  console.log('User fixed successfully');
  process.exit(0);
}

fixUser();
