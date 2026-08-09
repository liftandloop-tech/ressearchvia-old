import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import { firstValueFrom } from 'rxjs';

// The outer JWT (auth_token) received from AngelOne callback
const AUTH_TOKEN = 'eyJhbGciOiJIUzUxMiJ9.eyJ1c2VybmFtZSI6Ik0zMjA5NjciLCJyb2xlcyI6MCwidXNlcnR5cGUiOiJVU0VSIiwidG9rZW4iOiJleUpoYkdjaU9pSlNVekkxTmlJc0luUjVjQ0k2SWtwWFZDSjkuZXlKMWMyVnlYM1I1Y0dVaU9pSmpiR2xsYm5RaUxDSjBiMnRsYmw5MGVYQmxJam9pZEhKaFpHVmZZV05qWlhOelgzUnZhMlZ1SWl3aVoyMWZhV1FpT2pRc0luTnZkWEpqWlNJNklqTWlMQ0prWlhacFkyVmZhV1FpT2lJM04yRTRNVGcwTXkwNVpqSTVMVE5qTURBdE9URmlOQzB5Tnpsak16azVNakUwTUdVaUxDSnJhV1FpT2lJMC5oV3EwOVNsbTlwbGtJUWpQQ1Z4QjRPV0VYd3J6U2prZEhYbVVYRFYtWVprUVZUWEViMHk4OUJVeV9QQl9GTnFTS2lGWE5nZHBmQWhFNGtoVkh5YzFFc21Bdno0SUJZZVpVRE5TQm5YdkNVWjFfcUpvUnZjbFZKa0lQcEFyWEV0VlVTSG5tZkEwdkZUX1B4dVpobVdQVHhGVFFKTzlUaWJlbVN6MndZeUxUbTQiLCJBUEktS0VZIjoiZTB6dERnUkoiLCJpYXQiOjE3ODM5MjczMzUsImV4cCI6MTc4Mzk2NzQwMH0.zf5rho7vNMmF71vJSzFm-aVQEv8Wg_Kh_pOcNPXEIpCM7Dc6Gx3ypYGEZmd12Ab5Rl5HFr7EWPbif7Fi0abcsA';

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const httpService = app.get(HttpService);
  const configService = app.get(ConfigService);

  const apiKey = configService.get<string>('ANGEL_ONE_API_KEY') || '';

  console.log('\n=== TEST 1: Using the outer auth_token (wrapper JWT) directly ===');
  try {
    const r = await firstValueFrom(
      httpService.get('https://apiconnect.angelone.in/rest/secure/angelbroking/user/v1/getProfile', {
        headers: {
          'Content-Type': 'application/json',
          Accept: 'application/json',
          'X-UserType': 'USER',
          'X-SourceID': 'WEB',
          'X-PrivateKey': apiKey,
          'X-ClientLocalIP': '192.168.1.100',
          'X-ClientPublicIP': '110.227.56.55',
          'X-MACaddress': '02:00:00:00:00:00',
          Authorization: `Bearer ${AUTH_TOKEN}`,
        },
      })
    );
    console.log('Status:', r.status);
    console.log('Response:', JSON.stringify(r.data));
  } catch (err: any) {
    console.error('Error status:', err.response?.status);
    console.error('Error data:', JSON.stringify(err.response?.data));
  }

  // Decode the outer JWT to get the inner token
  const outerPayload = JSON.parse(Buffer.from(AUTH_TOKEN.split('.')[1], 'base64').toString());
  const innerToken = outerPayload.token; // This is the trade_access_token
  
  console.log('\n=== TEST 2: Using the inner trade_access_token ===');
  console.log('Inner token prefix:', innerToken.substring(0, 50));
  try {
    const r = await firstValueFrom(
      httpService.get('https://apiconnect.angelone.in/rest/secure/angelbroking/user/v1/getProfile', {
        headers: {
          'Content-Type': 'application/json',
          Accept: 'application/json',
          'X-UserType': 'USER',
          'X-SourceID': 'WEB',
          'X-PrivateKey': apiKey,
          'X-ClientLocalIP': '192.168.1.100',
          'X-ClientPublicIP': '110.227.56.55',
          'X-MACaddress': '02:00:00:00:00:00',
          Authorization: `Bearer ${innerToken}`,
        },
      })
    );
    console.log('Status:', r.status);
    console.log('Response:', JSON.stringify(r.data));
  } catch (err: any) {
    console.error('Error status:', err.response?.status);
    console.error('Error data:', JSON.stringify(err.response?.data));
  }

  await app.close();
}
bootstrap();
