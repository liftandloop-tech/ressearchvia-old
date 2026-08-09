"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const core_1 = require("@nestjs/core");
const app_module_1 = require("../src/app.module");
const axios_1 = require("@nestjs/axios");
const config_1 = require("@nestjs/config");
const rxjs_1 = require("rxjs");
const AUTH_TOKEN = 'eyJhbGciOiJIUzUxMiJ9.eyJ1c2VybmFtZSI6Ik0zMjA5NjciLCJyb2xlcyI6MCwidXNlcnR5cGUiOiJVU0VSIiwidG9rZW4iOiJleUpoYkdjaU9pSlNVekkxTmlJc0luUjVjQ0k2SWtwWFZDSjkuZXlKMWMyVnlYM1I1Y0dVaU9pSmpiR2xsYm5RaUxDSjBiMnRsYmw5MGVYQmxJam9pZEhKaFpHVmZZV05qWlhOelgzUnZhMlZ1SWl3aVoyMWZhV1FpT2pRc0luTnZkWEpqWlNJNklqTWlMQ0prWlhacFkyVmZhV1FpT2lJM04yRTRNVGcwTXkwNVpqSTVMVE5qTURBdE9URmlOQzB5Tnpsak16azVNakUwTUdVaUxDSnJhV1FpT2lJMC5oV3EwOVNsbTlwbGtJUWpQQ1Z4QjRPV0VYd3J6U2prZEhYbVVYRFYtWVprUVZUWEViMHk4OUJVeV9QQl9GTnFTS2lGWE5nZHBmQWhFNGtoVkh5YzFFc21Bdno0SUJZZVpVRE5TQm5YdkNVWjFfcUpvUnZjbFZKa0lQcEFyWEV0VlVTSG5tZkEwdkZUX1B4dVpobVdQVHhGVFFKTzlUaWJlbVN6MndZeUxUbTQiLCJBUEktS0VZIjoiZTB6dERnUkoiLCJpYXQiOjE3ODM5MjczMzUsImV4cCI6MTc4Mzk2NzQwMH0.zf5rho7vNMmF71vJSzFm-aVQEv8Wg_Kh_pOcNPXEIpCM7Dc6Gx3ypYGEZmd12Ab5Rl5HFr7EWPbif7Fi0abcsA';
async function bootstrap() {
    const app = await core_1.NestFactory.createApplicationContext(app_module_1.AppModule);
    const httpService = app.get(axios_1.HttpService);
    const configService = app.get(config_1.ConfigService);
    const apiKey = configService.get('ANGEL_ONE_API_KEY') || '';
    console.log('\n=== TEST 1: Using the outer auth_token (wrapper JWT) directly ===');
    try {
        const r = await (0, rxjs_1.firstValueFrom)(httpService.get('https://apiconnect.angelone.in/rest/secure/angelbroking/user/v1/getProfile', {
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
        }));
        console.log('Status:', r.status);
        console.log('Response:', JSON.stringify(r.data));
    }
    catch (err) {
        console.error('Error status:', err.response?.status);
        console.error('Error data:', JSON.stringify(err.response?.data));
    }
    const outerPayload = JSON.parse(Buffer.from(AUTH_TOKEN.split('.')[1], 'base64').toString());
    const innerToken = outerPayload.token;
    console.log('\n=== TEST 2: Using the inner trade_access_token ===');
    console.log('Inner token prefix:', innerToken.substring(0, 50));
    try {
        const r = await (0, rxjs_1.firstValueFrom)(httpService.get('https://apiconnect.angelone.in/rest/secure/angelbroking/user/v1/getProfile', {
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
        }));
        console.log('Status:', r.status);
        console.log('Response:', JSON.stringify(r.data));
    }
    catch (err) {
        console.error('Error status:', err.response?.status);
        console.error('Error data:', JSON.stringify(err.response?.data));
    }
    await app.close();
}
bootstrap();
//# sourceMappingURL=test-prisma.js.map