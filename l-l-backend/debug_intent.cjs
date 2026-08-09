const mongoose = require('mongoose');
require('dotenv').config();

async function checkIntent() {
  await mongoose.connect(process.env.DB_URL);
  const PaymentIntent = mongoose.model('PaymentIntent', new mongoose.Schema({}, { strict: false }));
  
  const intent = await PaymentIntent.findOne({ _id: '69b0f5b86b123edffea89181' });
  console.log(JSON.stringify(intent, null, 2));
  
  mongoose.disconnect();
}

checkIntent();
