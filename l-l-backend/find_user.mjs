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
      _id: new mongoose.Types.ObjectId('69a90dcb856bc416e0043560')
    });
    if (doc) {
      console.log(`Found in collection: ${col.name}`);
      console.log(doc);
    }
  }

  await mongoose.disconnect();
}

check().catch(console.error);
