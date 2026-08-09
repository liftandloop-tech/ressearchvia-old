import mongoose from 'mongoose';
import userModel from './app/models/userModel.js';
import entitlementModel from './app/models/entitlementModel.js';
import reportModel from './app/models/reportsModel.js';
import { hasActiveRegistration } from './app/services/entitlementService.js';

async function diagnose() {
  await mongoose.connect('mongodb://root:Research%4028@72.60.221.95:27017/researchvia-1305?authSource=admin');
  
  const userId = '6a04456a2ab321678952554b'; // Rajesh Shah
  const user = await userModel.findById(userId);
  
  console.log('--- USER ---');
  console.log('Name:', user.fullName);
  console.log('RegStatus:', user.registrationStatus);
  console.log('RegFeePaid:', user.registrationFeePaid);
  
  const hasReg = await hasActiveRegistration(userId);
  console.log('Has Active Registration Entitlement:', hasReg);
  
  const today = new Date();
  const activeEntitlements = await entitlementModel.find({
    userId,
    status: 'ACTIVE',
    startDate: { $lte: today },
    $or: [{ endDate: null }, { endDate: { $gte: today } }]
  });
  
  console.log('Active Entitlements Count:', activeEntitlements.length);
  
  const orConditions = [];
  activeEntitlements.forEach(ent => {
    if (ent.type === 'PLAN') {
      const cond = { segment: ent.segmentId };
      if (ent.resourceId) {
        cond.planArray = ent.resourceId.toString();
      }
      orConditions.push(cond);
    }
  });
  
  console.log('OR Conditions:', JSON.stringify(orConditions, null, 2));
  
  if (orConditions.length === 0) {
    console.log('No plan entitlements found for query');
  } else {
    const query = {
      publishedStatus: 'published',
      $or: orConditions
    };
    const reports = await reportModel.find(query).limit(5);
    console.log('Matching Reports Found:', reports.length);
  }
  
  process.exit(0);
}

diagnose();
