import axios from 'axios';
import * as crypto from 'crypto';

const BASE_URL = 'https://go.mynt.in/NorenWClientTP';

function buildBody(data: Record<string, unknown>, susertoken: string): string {
  return `jData=${JSON.stringify(data)}&jKey=${susertoken}`;
}

function sha256(str: string): string {
  return crypto.createHash('sha256').update(str).digest('hex');
}

async function post(endpoint: string, body: string): Promise<any> {
  const url = `${BASE_URL}${endpoint}`;
  const response = await axios.post(url, body, {
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
  });
  return response.data;
}

async function main() {
  // === Credentials ===
  const uid = 'Z67017';
  const password = 'Raj@2003';
  const factor2 = 'GOOPM3532M'; // PAN card number
  const apiKey = 'ndTaFrT46gDk8nSBX4C4kAe3cc49aF88'; // Full secret key
  const vendorCode = 'Z67017'; // Vendor Code

  console.log('Step 1: Logging in...');
  const hashedPwd = sha256(password);
  const hashedAppkey = sha256(`${uid}|${apiKey}`);

  const loginData = {
    apkversion: '1.0',
    uid,
    pwd: hashedPwd,
    factor2: factor2,
    vc: vendorCode,
    appkey: hashedAppkey,
    imei: 'abc1234',
    source: 'API',
  };

  const loginBody = `jData=${JSON.stringify(loginData)}`;
  const loginResp = await post('/QuickAuth', loginBody);
  console.log('Login response:', JSON.stringify(loginResp, null, 2));

  if (!loginResp.susertoken) {
    console.error('FAILED TO LOGIN:', loginResp.emsg);
    return;
  }

  const token = loginResp.susertoken;
  console.log('\nToken obtained:', token);

  // Step 2: Place SBIN BUY order (1 qty, MIS, Market)
  console.log('\nStep 2: Placing SBIN BUY order (1 qty, MIS, Market)...');
  const orderData = {
    uid,
    actid: uid,
    exch: 'NSE',
    tsym: 'SBIN-EQ',
    qty: '1',
    prc: '0',
    trgprc: '0',
    dscqty: '0',
    prd: 'I',         // MIS (intraday)
    trantype: 'B',    // BUY
    prctyp: 'MKT',   // Market order
    ret: 'DAY',
    remarks: 'DirectTest',
    ordersource: 'API',
  };

  const orderBody = buildBody(orderData, token);
  console.log('Order body being sent:', orderBody);

  const orderResp = await post('/PlaceOrder', orderBody);
  console.log('\nOrder response:', JSON.stringify(orderResp, null, 2));
}

main().catch(console.error);
