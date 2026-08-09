import mongoose from 'mongoose';
import segmentsService from './app/services/segmentsServices.js';

async function test() {
  await mongoose.connect('mongodb://root:Research%4028@72.60.221.95:27017/researchvia-1305?authSource=admin');
  
  const userId = '6a04456a2ab321678952554b'; // Rajesh Shah
  const result = await segmentsService.getUserActiveSegment({ query: { userId } });
  
  console.log('Result for /user-active-segment:');
  console.log(JSON.stringify(result, null, 2));
  
  process.exit(0);
}

test();
