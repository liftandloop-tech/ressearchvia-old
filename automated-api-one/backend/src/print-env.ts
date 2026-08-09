import * as dotenv from 'dotenv';
dotenv.config();

console.log('JWT_SECRET from .env:', process.env.JWT_SECRET);
console.log('JWT_REFRESH_SECRET:', process.env.JWT_REFRESH_SECRET);
