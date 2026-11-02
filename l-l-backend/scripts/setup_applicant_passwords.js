import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

dotenv.config({ path: path.join(__dirname, '../.env') });

const MONGO_URI = process.env.DB_URL || process.env.MONGO_DB_URL || 'mongodb://mongo:27017/researchvia';

const TARGET_USERS = [
  {
    key: 'vikram',
    searchRegex: /vikram/i,
    defaultName: 'Vikram',
    defaultEmail: 'vikram@researchvia.in',
    passwordPlain: 'Vikram@2026'
  },
  {
    key: 'pradeep',
    searchRegex: /(pradeep|haldar)/i,
    defaultName: 'Pradeep Haldar',
    defaultEmail: 'pradeep.haldar@researchvia.in',
    passwordPlain: 'Pradeep@2026'
  },
  {
    key: 'deepak',
    searchRegex: /deepak/i,
    defaultName: 'Deepak',
    defaultEmail: 'deepak@researchvia.in',
    passwordPlain: 'Deepak@2026'
  }
];

async function run() {
  console.log('Connecting to MongoDB at:', MONGO_URI.replace(/:([^:@]+)@/, ':****@'));
  await mongoose.connect(MONGO_URI);
  console.log('Connected to MongoDB successfully.\n');

  const db = mongoose.connection.db;
  const staffCollection = db.collection('staffs');
  const applicantCollection = db.collection('applicants');

  const summary = [];

  for (const target of TARGET_USERS) {
    console.log(`\n======================================================`);
    console.log(`Searching for: ${target.defaultName} (${target.passwordPlain})`);
    console.log(`======================================================`);

    // 1. Search in Staff collection
    const staffMatches = await staffCollection.find({
      $or: [
        { fullName: target.searchRegex },
        { emailAddress: target.searchRegex },
        { name: target.searchRegex }
      ]
    }).toArray();

    // 2. Search in Applicant collection
    const applicantMatches = await applicantCollection.find({
      $or: [
        { fullName: target.searchRegex },
        { emailAddress: target.searchRegex },
        { firstName: target.searchRegex },
        { lastName: target.searchRegex }
      ]
    }).toArray();

    const hashedPassword = await bcrypt.hash(target.passwordPlain, 10);

    let resolvedEmail = null;
    let resolvedName = target.defaultName;
    let updatedStaffCount = 0;
    let updatedApplicantCount = 0;

    // Update Staff records
    if (staffMatches.length > 0) {
      console.log(`Found ${staffMatches.length} matching record(s) in 'staffs':`);
      for (const s of staffMatches) {
        const email = s.emailAddress || s.email;
        if (!resolvedEmail && email) resolvedEmail = email;
        resolvedName = s.fullName || s.name || resolvedName;

        console.log(`  - Staff ID: ${s.staffId || s._id} | Name: ${s.fullName || s.name} | Email: ${email} | Phone: ${s.mobileNumber || s.mobile || 'N/A'}`);

        await staffCollection.updateOne(
          { _id: s._id },
          {
            $set: {
              password: hashedPassword,
              status: s.status || 'Active',
              updatedAt: new Date()
            }
          }
        );
        updatedStaffCount++;
      }
    } else {
      console.log(`  No matching record found in 'staffs'.`);
    }

    // Update Applicant records
    if (applicantMatches.length > 0) {
      console.log(`Found ${applicantMatches.length} matching record(s) in 'applicants':`);
      for (const a of applicantMatches) {
        const email = a.emailAddress;
        if (!resolvedEmail && email) resolvedEmail = email;
        resolvedName = a.fullName || `${a.firstName || ''} ${a.lastName || ''}`.trim() || resolvedName;

        console.log(`  - Applicant ID: ${a.applicantId || a._id} | Name: ${a.fullName} | Email: ${email} | Stage: ${a.stage || 'N/A'}`);

        await applicantCollection.updateOne(
          { _id: a._id },
          {
            $set: {
              password: hashedPassword,
              isEmailVerified: true,
              isMobileVerified: true,
              updatedAt: new Date()
            }
          }
        );
        updatedApplicantCount++;
      }
    } else {
      console.log(`  No matching record found in 'applicants'.`);
    }

    // If candidate does NOT exist in applicantCollection, create an applicant record so they can log in to Job Application portal
    if (applicantMatches.length === 0) {
      const emailToUse = (resolvedEmail || target.defaultEmail).trim().toLowerCase();
      const applicantId = `APP-${Date.now()}-${Math.floor(100 + Math.random() * 900)}`;

      console.log(`  Creating new applicant profile for ${resolvedName} with Email: ${emailToUse}...`);
      await applicantCollection.insertOne({
        applicantId,
        fullName: resolvedName,
        emailAddress: emailToUse,
        password: hashedPassword,
        countryCode: '+91',
        isEmailVerified: true,
        isMobileVerified: true,
        isDraft: false,
        stage: 'APPLIED',
        currentStep: 1,
        createdAt: new Date(),
        updatedAt: new Date()
      });
      resolvedEmail = emailToUse;
      updatedApplicantCount++;
    }

    summary.push({
      name: resolvedName,
      loginId: resolvedEmail || target.defaultEmail,
      password: target.passwordPlain,
      hashedCode: hashedPassword.substring(0, 15) + '...',
      staffRecordsUpdated: updatedStaffCount,
      applicantRecordsUpdated: updatedApplicantCount
    });
  }

  console.log('\n\n======================================================');
  console.log('CREDENTIALS CONFIGURATION SUMMARY');
  console.log('======================================================');
  console.table(summary);
  console.log('\nAll passwords have been securely hashed (#code bcrypt 10 rounds) and saved to the database.');

  await mongoose.disconnect();
  console.log('Database connection closed.');
}

run().catch((err) => {
  console.error('Script Error:', err);
  process.exit(1);
});

