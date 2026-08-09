import mongoose from 'mongoose';
import dotenv from 'dotenv';

dotenv.config({ path: './.env' });

const MONGO_URI = process.env.DB_URL;

async function check() {
  await mongoose.connect(MONGO_URI);
  console.log('Connected to DB');

  const signalId = '3fa5b71f-a59d-430b-8faa-9158932ef63f';
  
  const report = await mongoose.connection.db.collection('reports').findOne({
    automatedSignalId: signalId
  });
  console.log('Report in MongoDB:', report);

  if (report && report.userId) {
    const user = await mongoose.connection.db.collection('users').findOne({
      _id: report.userId
    });
    console.log('User associated with Report:', user ? { _id: user._id, fullName: user.fullName, phone: user.phone } : 'Not found');
  }

  await mongoose.disconnect();
}

check().catch(console.error);
