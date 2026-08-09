import mongoose from 'mongoose';
import bcrypt from 'bcrypt';
import userModel from './app/models/userModel.js';
import userDocUploadModel from './app/models/userDocUploadModel.js';
import paymentIntentModel from './app/models/paymentIntentModel.js';
import userKycModel from './app/models/userKycModel.js';

const determineNextStep = async ({ user, platform = 'android', context = 'LOGIN' }) => {
  if (user.userStatus === 'SUSPENDED') return { next: "DASHBOARD", intent: "SUSPENDED" };
  if (!user.mpinHash) return { next: "SET_MPIN" };
  if (user.mpinStatus === "TEMP" || user.mpinStatus === "RESET_REQUIRED") return { next: "RESET_MPIN" };

  const hasProfile = user.userObject && Object.keys(user.userObject).length > 0;
  const userDocs = await userDocUploadModel.findOne({ userId: user._id });
  const hasDocs = userDocs && userDocs.pancard?.fileName && userDocs.aadhaar?.front?.fileName && userDocs.aadhaar?.back?.fileName;

  console.log('--- DIAGNOSIS ---');
  console.log('User ID:', user._id);
  console.log('Full Name:', user.fullName);
  console.log('Registration Status:', user.registrationStatus);
  console.log('KYC Status:', user.kycStatus);
  console.log('Has Profile:', hasProfile);
  console.log('Has Docs (userDocumentUploads):', !!hasDocs);
  
  if (!hasProfile || !hasDocs) return { next: "KYC_DETAILS" };

  const docGateStatus = user.kycGates?.documents?.status ?? 'PENDING';
  const esignGateStatus = user.kycGates?.esign?.status ?? 'PENDING';
  const videoGateStatus = user.kycGates?.video?.status ?? 'PENDING';

  console.log('Gate Statuses - Docs:', docGateStatus, 'E-Sign:', esignGateStatus, 'Video:', videoGateStatus);

  if (docGateStatus === 'REJECTED') return { next: "KYC_DOCUMENT_REJECTED" };
  if (esignGateStatus === 'REJECTED') return { next: "DIGIO_ESIGN_REJECTED" };

  const userKyc = await userKycModel.findOne({ userId: user._id });
  if (esignGateStatus === 'PENDING' && (!userKyc || !userKyc.digioObject)) return { next: "DIGIO_ESIGN_FLOW" };

  if (videoGateStatus === 'REJECTED') return { next: "VIDEO_KYC_REJECTED" };

  const hasVideo = user.kycVideo || (user.kycDocs && user.kycDocs.video);
  if (videoGateStatus === 'PENDING' && !hasVideo) return { next: "VIDEO_KYC_INTRO" };

  const registrationActive = (
    user.registrationFeePaid === true ||
    user.registrationStatus === 'ACTIVE' ||
    user.registrationStatus === 'COMPLETE'
  );
  
  console.log('Registration Active:', registrationActive);

  if (!registrationActive) {
      const pendingPayment = await paymentIntentModel.findOne({ userId: user._id, purchaseType: "REGISTRATION" });
      if (!pendingPayment) return { next: "REGISTRATION_PAYMENT" };
  }

  if (docGateStatus === 'PENDING' || esignGateStatus === 'PENDING' || videoGateStatus === 'PENDING') {
    return { next: "KYC_IN_REVIEW" };
  }

  return { next: "DASHBOARD" };
};

async function diagnose() {
  const uri = "mongodb://root:Research%4028@72.60.221.95:27017/researchvia?authSource=admin";
  await mongoose.connect(uri);
  const user = await userModel.findOne({ phone: '+918085006523' });
  if (!user) {
    console.log('User not found');
    process.exit(0);
  }
  const result = await determineNextStep({ user });
  console.log('FINAL NEXT STEP:', result.next);
  process.exit(0);
}

diagnose();
