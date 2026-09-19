import mongoose from "mongoose";
import * as dotenv from "dotenv";
dotenv.config();

async function run() {
  try {
    await mongoose.connect(process.env.DB_URL);
    console.log("Connected to MongoDB.");

    const pgCollection = mongoose.connection.db.collection('permissiongroups');
    const roleCollection = mongoose.connection.db.collection('roles');

    // 1. Update Director PG to include Notifications and Settings
    const dirPg = await pgCollection.findOne({ name: 'Director' });
    if (dirPg) {
      const existingFeatures = (dirPg.permissions || []).map(p => (p.feature || '').toLowerCase());
      const newPerms = [...(dirPg.permissions || [])];
      if (!existingFeatures.includes('notifications')) {
        newPerms.push({ feature: 'Notifications', actions: ['read', 'view'] });
      }
      if (!existingFeatures.includes('settings')) {
        newPerms.push({ feature: 'Settings', actions: ['read', 'view'] });
      }
      await pgCollection.updateOne({ _id: dirPg._id }, { $set: { permissions: newPerms } });
      console.log('✓ Updated Director permission group with Notifications and Settings.');
    }

    // 2. Create or find Manager PG
    let mgrPg = await pgCollection.findOne({ name: { $regex: /^manager$/i } });
    if (!mgrPg) {
      const insertRes = await pgCollection.insertOne({
        name: 'Manager',
        description: 'Manager Team Leadership & Operations',
        permissions: [
          { feature: 'Users', actions: ['read', 'view', 'update'] },
          { feature: 'Leads', actions: ['read', 'view', 'view_all', 'create', 'update'] },
          { feature: 'Reports', actions: ['read', 'view'] },
          { feature: 'KYC', actions: ['read', 'view'] },
          { feature: 'Payments', actions: ['read', 'view', 'payments.view_pending'] },
          { feature: 'Staff', actions: ['read', 'view'] },
          { feature: 'Notifications', actions: ['read', 'view'] }
        ],
        createdAt: new Date(),
        updatedAt: new Date()
      });
      mgrPg = { _id: insertRes.insertedId };
      console.log('✓ Created Manager permission group.');
    }

    // Link Manager PG to Manager role
    const mgrRole = await roleCollection.findOne({ name: { $regex: /^manager$/i } });
    if (mgrRole) {
      await roleCollection.updateOne({ _id: mgrRole._id }, { $addToSet: { permissionGroups: mgrPg._id } });
      console.log('✓ Linked Manager PG to Manager Role.');
    }

    // 3. Link Research Analyst main PG to Researcher and Research Analyst roles
    const resPg = await pgCollection.findOne({ name: 'Research Analyst main' });
    if (resPg) {
      const hasNotif = (resPg.permissions || []).some(p => (p.feature || '').toLowerCase() === 'notifications');
      if (!hasNotif) {
        await pgCollection.updateOne({ _id: resPg._id }, {
          $push: { permissions: { feature: 'Notifications', actions: ['read', 'view'] } }
        });
        console.log('✓ Added Notifications to Researcher permission group.');
      }

      const resRoles = await roleCollection.find({ name: { $in: ['Researcher', 'Research Analyst'] } }).toArray();
      for (const r of resRoles) {
        await roleCollection.updateOne({ _id: r._id }, { $addToSet: { permissionGroups: resPg._id } });
        console.log('✓ Linked Researcher PG to Role: ' + r.name);
      }
    }

    console.log('Done DB role/permission sync!');
    process.exit(0);
  } catch (e) {
    console.error(e);
    process.exit(1);
  }
}

run();
