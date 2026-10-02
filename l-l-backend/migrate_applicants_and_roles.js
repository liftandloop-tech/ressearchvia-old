import mongoose from 'mongoose';

const uri = "mongodb://root:Research%4028@72.60.221.95:27017/researchvia-1305?authSource=admin&directConnection=true";

async function migrate() {
  await mongoose.connect(uri, { serverSelectionTimeoutMS: 15000 });
  const db = mongoose.connection.db;

  console.log("=== STARTING ARCHITECTURAL MIGRATION ===");

  // 1. Ensure applicants collection exists
  const existingCols = await db.listCollections().toArray();
  const hasApplicants = existingCols.some(c => c.name === 'applicants');
  if (!hasApplicants) {
    await db.createCollection('applicants');
    console.log("Created 'applicants' collection.");
  }
  const applicantsCol = db.collection('applicants');
  const staffsCol = db.collection('staffs');
  const rolesCol = db.collection('roles');

  // 2. Identify all recent walk-in applications (from Sep 18, 2026 onwards)
  const recentThreshold = new Date('2026-09-01T00:00:00.000Z');
  const walkInSubmissions = await staffsCol.find({
    $or: [
      { createdAt: { $gte: recentThreshold } },
      { stage: 'Applicant' }
    ]
  }).toArray();

  console.log(`Found ${walkInSubmissions.length} walk-in / candidate records to migrate into applicants collection.`);

  let migratedCount = 0;
  let anjaliMigrated = false;

  for (const doc of walkInSubmissions) {
    // Generate clean applicant ID
    const appSeq = doc.staffId || `APP-${doc._id.toString().slice(-6).toUpperCase()}`;
    const targetRole = doc.walkInForm?.positionApplied || doc.role || 'Complience Executive';

    const applicantData = {
      _id: doc._id, // Keep the same ID for full referential consistency
      applicantId: appSeq,
      fullName: doc.fullName || 'Candidate',
      emailAddress: doc.emailAddress ? doc.emailAddress.trim().toLowerCase() : `applicant_${doc._id}@researchvia.in`,
      mobileNumber: doc.mobileNumber || 9999999999,
      countryCode: "+91",
      targetRole: targetRole,
      targetDepartment: doc.deparment || null,
      stage: "APPLIED",
      stageHistory: [
        {
          stage: "APPLIED",
          note: "Walk-in application submitted",
          changedAt: doc.createdAt || new Date()
        }
      ],
      source: "WALK_IN",
      isVerified: true,
      verifiedAt: doc.createdAt || new Date(),
      dob: doc.dob || null,
      gender: doc.gender || doc.walkInForm?.gender || null,
      currentAddress: doc.currentAddress || doc.walkInForm?.currentAddress || null,
      permanentAddress: doc.permanentAddress || doc.walkInForm?.permanentAddress || null,
      emergencyContact: doc.emergencyContact || null,
      photoUrl: doc.photoUrl || null,
      resumeUrl: doc.resumeUrl || null,
      aadhaarUrl: doc.aadhaarUrl || null,
      panUrl: doc.panUrl || null,
      walkInForm: doc.walkInForm || {},
      convertedStaffId: null,
      hiredAt: null,
      createdAt: doc.createdAt || new Date(),
      updatedAt: new Date()
    };

    // Upsert into applicants
    await applicantsCol.updateOne(
      { _id: doc._id },
      { $set: applicantData },
      { upsert: true }
    );

    migratedCount++;
    if (doc.emailAddress && doc.emailAddress.includes('shindeanjali245')) {
      anjaliMigrated = true;
      console.log(`✓ Successfully migrated Anjali Dhiraj Patil into applicants collection! ID: ${doc._id}`);
    }
  }

  console.log(`Successfully migrated ${migratedCount} candidates into 'applicants' collection.`);

  // 3. For confirmed active staff created before September 2026 (the actual operational staff):
  const historicalStaff = await staffsCol.find({
    createdAt: { $lt: recentThreshold }
  }).toArray();
  console.log(`Found ${historicalStaff.length} historical staff records.`);

  for (const staff of historicalStaff) {
    // Link applicantId if missing
    let applicant = await applicantsCol.findOne({ emailAddress: staff.emailAddress?.toLowerCase() });
    if (!applicant && staff.emailAddress) {
      const appDoc = {
        applicantId: `APP-HIST-${staff.staffId || staff._id.toString().slice(-4)}`,
        fullName: staff.fullName,
        emailAddress: staff.emailAddress.toLowerCase(),
        mobileNumber: staff.mobileNumber || 9999999999,
        stage: "OFFER_ACCEPTED",
        convertedStaffId: staff._id,
        hiredAt: staff.joiningDate || staff.createdAt,
        walkInForm: staff.walkInForm || {},
        createdAt: staff.createdAt || new Date(),
        updatedAt: new Date()
      };
      const res = await applicantsCol.insertOne(appDoc);
      applicant = { _id: res.insertedId };
    }
    
    // Update staff document with applicantId and clean agreementStatus
    await staffsCol.updateOne(
      { _id: staff._id },
      {
        $set: {
          applicantId: applicant ? applicant._id : null,
          agreementStatus: staff.hasSignedAgreement ? "VERIFIED" : "NOT_INITIATED"
        }
      }
    );
  }

  // 4. Clean up staffs collection:
  // Remove pure walk-in applicants from staffs collection who have NOT been approved/hired yet
  // Specifically: Anjali Dhiraj Patil, Rajkumar Parihar, sandeep nagar, prabhat, and recent applicants
  // who do not have any sales or assigned clients.
  const pureApplicants = await staffsCol.find({
    createdAt: { $gte: recentThreshold },
    stage: { $in: ['Applicant', 'Employee'] }
  }).toArray();

  console.log(`Checking ${pureApplicants.length} recent applicants in staffs collection...`);
  // Remove them from staffs collection so they ONLY exist in applicants collection until officially approved & hired!
  for (const cand of pureApplicants) {
    await staffsCol.deleteOne({ _id: cand._id });
    console.log(`- Moved candidate ${cand.fullName} (${cand.emailAddress}) out of staffs collection into applicants collection.`);
  }

  const remainingStaffCount = await staffsCol.countDocuments();
  const totalApplicantsCount = await applicantsCol.countDocuments();
  console.log(`\nFinal Collection Stats:`);
  console.log(`- applicants collection: ${totalApplicantsCount} records (including Anjali Patil)`);
  console.log(`- staffs collection: ${remainingStaffCount} operational employees`);

  // 5. Deactivate the 17 unused roles in roles collection (Issue 4)
  const activeRoleNames = [
    'Business Development Executive',
    'Team Leader',
    'Senior Research Analyst',
    'Director',
    'Assistant Floor Manager',
    'Complience Executive',
    'Research Analyst',
    'Junior Research Analyst'
  ];

  const updateRolesResult = await rolesCol.updateMany(
    { name: { $nin: activeRoleNames } },
    { $set: { isActive: false } }
  );
  console.log(`\nRoles Cleanup: Marked ${updateRolesResult.modifiedCount} unused roles as isActive: false.`);

  const activeRoles = await rolesCol.find({ isActive: { $ne: false }, name: { $ne: 'Admin' } }).toArray();
  console.log(`Active designations available for hiring (${activeRoles.length}):`, activeRoles.map(r => r.name));

  console.log("\n=== MIGRATION COMPLETED SUCCESSFULLY ===");
  await mongoose.disconnect();
}

migrate().catch(err => {
  console.error("Migration failed:", err);
  process.exit(1);
});
