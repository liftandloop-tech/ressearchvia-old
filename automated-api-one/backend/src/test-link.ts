import axios from 'axios';

async function main() {
  try {
    const jwt = require('jsonwebtoken');
    // Try signing with the truncated secret 'no_1$32@4'
    const token = jwt.sign({
      _id: '65d49a71b12d3c001f3e792c',
      phone: '+919770784982',
      type: 'ACCESS'
    }, 'no_1$32@4');

    console.log('Using token:', token);

    const response = await axios.post('http://localhost:3000/brokers/link', {
      brokerCode: 'ANGEL_ONE',
      brokerClientId: 'M320967'
    }, {
      headers: {
        Authorization: `Bearer ${token}`
      }
    });

    console.log('Response status:', response.status);
    console.log('Response data:', response.data);
  } catch (error: any) {
    if (error.response) {
      console.log('Error Response status:', error.response.status);
      console.log('Error Response data:', error.response.data);
    } else {
      console.error('Error:', error.message);
    }
  }
}

main();
