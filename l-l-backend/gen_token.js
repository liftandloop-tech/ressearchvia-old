const jwt = require('jsonwebtoken');
console.log(jwt.sign({ _id: '697b31f3a010e491c162b01f', email: 'test@test.com' }, 'no_1$32@4#43'));
