import mongoose from 'mongoose';
import dotenv from 'dotenv';

dotenv.config({ path: './.env' });

const MONGO_URI = process.env.DB_URL;

async function check() {
  await mongoose.connect(MONGO_URI);
  console.log('Connected to DB');

  const collections = await mongoose.connection.db.listCollections().toArray();
  for (const col of collections) {
    const doc = await mongoose.connection.db.collection(col.name).findOne({
      $or: [
        { phone: '9770784982' },
        { phone: 9770784982 },
        { phone: '+919770784982' },
        { phone: '919770784982' },
        { phone: 919770784982 },
        { mobile: '9770784982' },
        { mobile: 9770784982 },
        { mobile: '919770784982' },
        { mobile: 919770784982 },
        { mobileNumber: '9770784982' },
        { mobileNumber: 9770784982 },
        { mobileNumber: '919770784982' },
        { mobileNumber: 919770784982 },
      ]
    });
    if (doc) {
      console.log(`Found in collection: ${col.name}`);
      console.log(doc);
    }
  }

  await mongoose.disconnect();
}

check().catch(console.error);
