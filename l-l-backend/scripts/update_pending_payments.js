import mongoose from 'mongoose';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

dotenv.config({ path: path.join(__dirname, '../.env') });

const MONGO_URI = process.env.DB_URL || process.env.MONGO_DB_URL;

// Target users and their payment specifications
const PAYMENTS_TO_UPDATE = [
  {
    name: 'VINA DILIP RATHOD',
    userId: '6aa8ec7fd6229005db6be9cd',
    phone: '+918983646381',
    intentId: '6aabde09a7c8aeb848b0623a',
    orderId: 'BANK_bank_reg_partial_db6be9cd_1789648393240',
    planType: 'LIFETIME',
    packageName: 'Gold Registration',
    totalAmount: 11800,
    baseAmount: 10000,
    gstAmount: 1800,
    trialDays: 7,
    durationDays: 3652,
    defaultPaymentId: 'pay_rzp_vina_11800',
    defaultUtr: 'UTR_RAZORPAY_VINA_1789648393',
    transactionDate: new Date('2026-09-17T12:33:13.247Z'),
  },
  {
    name: 'yashraj Vishwakarma',
    userId: '6a7084d2cdb31b4e61100072',
    phone: '+917415528107',
    intentId: '6a7085e4cdb31b4e6110024e',
    orderId: 'BANK_bank_reg_partial_61100072_1785759204307',
    planType: 'YEARLY',
    packageName: 'Silver Registration',
    totalAmount: 5900,
    baseAmount: 5000,
    gstAmount: 900,
    trialDays: 5,
    durationDays: 365,
    defaultPaymentId: 'pay_rzp_yashraj_5900',
    defaultUtr: 'UTR_RAZORPAY_YASHRAJ_1785759204',
    transactionDate: new Date('2026-08-03T12:13:24.308Z'),
  }
];

function getCliArg(prefix) {
  const match = process.argv.find(a => a.startsWith(prefix));
  return match ? match.split('=')[1] : null;
}

async function run() {
  const isExecute = process.argv.includes('--execute');
  
  // CLI Overrides if provided
  const vinaUtr = getCliArg('--vina-utr');
  const vinaPayId = getCliArg('--vina-payid');
  const yashrajUtr = getCliArg('--yashraj-utr');
  const yashrajPayId = getCliArg('--yashraj-payid');

  if (vinaUtr) PAYMENTS_TO_UPDATE[0].defaultUtr = vinaUtr;
  if (vinaPayId) PAYMENTS_TO_UPDATE[0].defaultPaymentId = vinaPayId;
  if (yashrajUtr) PAYMENTS_TO_UPDATE[1].defaultUtr = yashrajUtr;
  if (yashrajPayId) PAYMENTS_TO_UPDATE[1].defaultPaymentId = yashrajPayId;

  console.log(`\n===============================================================`);
  console.log(`MODE: ${isExecute ? '🔴 LIVE EXECUTION (WRITING TO DB)' : '🟡 DRY RUN (READ ONLY - PASS --execute TO APPLY)'}`);
  console.log(`DATABASE: researchvia-1305`);
  console.log(`===============================================================\n`);

  await mongoose.connect(MONGO_URI, { serverSelectionTimeoutMS: 10000 });
  const db = mongoose.connection.db;

  for (const item of PAYMENTS_TO_UPDATE) {
    console.log(`---------------------------------------------------------------`);
    console.log(`Processing: ${item.name} (${item.phone})`);
    console.log(`Target Intent: ${item.intentId} | Order: ${item.orderId}`);

    const userObjectId = new mongoose.Types.ObjectId(item.userId);
    const intentObjectId = new mongoose.Types.ObjectId(item.intentId);

    // 1. Fetch current intent
    const intent = await db.collection('paymentintents').findOne({ _id: intentObjectId });
    if (!intent) {
      console.error(`❌ PaymentIntent ${item.intentId} not found!`);
      continue;
    }
    console.log(`Current Intent Status: ${intent.status}, Method: ${intent.paymentMethod}, Amount: ${intent.totalAmount}`);

    // 2. Fetch user
    const user = await db.collection('users').findOne({ _id: userObjectId });
    if (!user) {
      console.error(`❌ User ${item.userId} not found!`);
      continue;
    }
    console.log(`Current User Reg Status: ${user.registrationStatus}, FeePaid: ${user.registrationFeePaid}`);

    const expiryDate = item.planType === 'LIFETIME'
      ? new Date(Date.now() + 10 * 365.25 * 24 * 60 * 60 * 1000)
      : new Date(Date.now() + 365 * 24 * 60 * 60 * 1000);

    const trialExpiry = new Date(Date.now() + item.trialDays * 24 * 60 * 60 * 1000);

    if (!isExecute) {
      console.log(`[DRY-RUN] Would update PaymentIntent:`);
      console.log(`  - status: 'PAID'`);
      console.log(`  - paymentMethod: 'RAZORPAY'`);
      console.log(`  - paymentId: '${item.defaultPaymentId}'`);
      console.log(`  - utrNumber: '${item.defaultUtr}'`);
      console.log(`  - amountPaid: ${item.totalAmount}`);
      console.log(`  - serviceStartDate: ${item.transactionDate.toISOString()}`);
      console.log(`  - currentExpiryDate: ${expiryDate.toISOString()}`);
      console.log(`[DRY-RUN] Would update User:`);
      console.log(`  - registrationStatus: 'ACTIVE'`);
      console.log(`  - registrationFeePaid: true`);
      console.log(`  - registrationType: '${item.planType}'`);
      console.log(`  - registrationExpiry: ${expiryDate.toISOString()}`);
      console.log(`[DRY-RUN] Would create/update Entitlements:`);
      console.log(`  - REGISTRATION: type='REGISTRATION', days=${item.durationDays}, isLifetime=${item.planType === 'LIFETIME'}`);
      if (intent.preferredPlanId) {
        console.log(`  - PLAN TRIAL: segmentId='${intent.preferredSegmentId}', planId='${intent.preferredPlanId}', days=${item.trialDays}`);
      }
      console.log(`[DRY-RUN] Would create PlanPurchase & Payment records for Admin Panel & Invoice history`);
      continue;
    }

    // --- EXECUTE UPDATES ---
    // A. Update PaymentIntent
    await db.collection('paymentintents').updateOne(
      { _id: intentObjectId },
      {
        $set: {
          status: 'PAID',
          paymentMethod: 'RAZORPAY',
          paymentId: item.defaultPaymentId,
          utrNumber: item.defaultUtr,
          amountPaid: item.totalAmount,
          remainingAmount: 0,
          transactionDate: item.transactionDate,
          serviceStartDate: item.transactionDate,
          currentExpiryDate: item.planType === 'LIFETIME' ? null : expiryDate,
          updatedAt: new Date()
        }
      }
    );
    console.log(`✅ Updated PaymentIntent to PAID`);

    // B. Update User
    await db.collection('users').updateOne(
      { _id: userObjectId },
      {
        $set: {
          registrationStatus: 'ACTIVE',
          registrationFeePaid: true,
          registrationType: item.planType,
          registrationExpiry: expiryDate,
          updatedAt: new Date()
        }
      }
    );
    console.log(`✅ Updated User registration status to ACTIVE`);

    // C. Grant REGISTRATION Entitlement
    await db.collection('entitlements').updateOne(
      { userId: userObjectId, type: 'REGISTRATION' },
      {
        $set: {
          userId: userObjectId,
          type: 'REGISTRATION',
          status: 'ACTIVE',
          startDate: item.transactionDate,
          endDate: item.planType === 'LIFETIME' ? null : expiryDate,
          isLifetime: item.planType === 'LIFETIME',
          grantedBy: 'ADMIN',
          grantReason: 'ONLINE_PAYMENT',
          jobTitle: 'SCRIPT_RECOVERY',
          sourceRefId: intent._id.toString(),
          remarks: `Auto-verified from Razorpay payment (${item.defaultUtr})`,
          updatedAt: new Date()
        },
        $setOnInsert: {
          createdAt: new Date()
        }
      },
      { upsert: true }
    );
    console.log(`✅ Granted REGISTRATION Entitlement`);

    // D. Grant Bundled Trial Plan Entitlement if preferredPlanId exists
    if (intent.preferredPlanId) {
      await db.collection('entitlements').updateOne(
        {
          userId: userObjectId,
          type: 'PLAN',
          resourceId: intent.preferredPlanId,
          sourceRefId: intent._id.toString()
        },
        {
          $set: {
            userId: userObjectId,
            type: 'PLAN',
            resourceId: intent.preferredPlanId,
            segmentId: intent.preferredSegmentId,
            status: 'ACTIVE',
            startDate: item.transactionDate,
            endDate: trialExpiry,
            isLifetime: false,
            grantedBy: 'ADMIN',
            grantReason: 'REGISTRATION_TRIAL',
            sourceRefId: intent._id.toString(),
            remarks: `Bundled Trial with Registration`,
            updatedAt: new Date()
          },
          $setOnInsert: {
            createdAt: new Date()
          }
        },
        { upsert: true }
      );
      console.log(`✅ Granted Bundled Plan Trial Entitlement`);
    }

    // E. Create or Update PlanPurchase (Legacy Sync)
    const existingPurchase = await db.collection('planpurchases').findOne({
      userId: userObjectId,
      packageName: { $regex: 'Registration', $options: 'i' }
    });

    let planPurchaseId = existingPurchase?._id;
    if (!existingPurchase) {
      const insRes = await db.collection('planpurchases').insertOne({
        userId: userObjectId,
        packageName: item.packageName,
        validity: item.durationDays,
        startDate: item.transactionDate,
        endDate: expiryDate,
        status: 'active',
        basicAmount: item.baseAmount,
        cgstAmount: item.gstAmount / 2,
        sgstAmount: item.gstAmount / 2,
        paymentMethod: 'ONLINE',
        expiryReminder: true,
        createdAt: item.transactionDate,
        updatedAt: new Date()
      });
      planPurchaseId = insRes.insertedId;
      console.log(`✅ Created PlanPurchase record`);
    }

    // F. Create or Update Payment record
    const existingPayment = await db.collection('payments').findOne({
      userId: userObjectId,
      amount: item.totalAmount
    });

    if (!existingPayment) {
      await db.collection('payments').insertOne({
        userId: userObjectId,
        packageId: planPurchaseId,
        razorpayOrderId: intent.razorpayOrderId,
        razorpayPaymentId: item.defaultPaymentId,
        razorpayReceipt: intent.razorpayOrderId,
        amount: item.totalAmount,
        razorpayCurrency: 'INR',
        paymentMethod: 'ONLINE',
        status: 'paid',
        createdAt: item.transactionDate,
        updatedAt: new Date()
      });
      console.log(`✅ Created Payment record`);
    }
  }

  await mongoose.disconnect();
  console.log(`\n===============================================================`);
  console.log(`Completed successfully.`);
  console.log(`===============================================================\n`);
}

run().catch(err => {
  console.error('Fatal execution error:', err);
  process.exit(1);
});
