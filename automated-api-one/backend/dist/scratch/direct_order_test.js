"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const axios_1 = __importDefault(require("axios"));
const crypto = __importStar(require("crypto"));
const BASE_URL = 'https://go.mynt.in/NorenWClientTP';
function buildBody(data, susertoken) {
    return `jData=${JSON.stringify(data)}&jKey=${susertoken}`;
}
function sha256(str) {
    return crypto.createHash('sha256').update(str).digest('hex');
}
async function post(endpoint, body) {
    const url = `${BASE_URL}${endpoint}`;
    const response = await axios_1.default.post(url, body, {
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    });
    return response.data;
}
async function main() {
    const uid = 'Z67017';
    const password = 'Raj@2003';
    const factor2 = 'GOOPM3532M';
    const apiKey = 'ndTaFrT46gDk8nSBX4C4kAe3cc49aF88';
    const vendorCode = 'Z67017';
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
        prd: 'I',
        trantype: 'B',
        prctyp: 'MKT',
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
//# sourceMappingURL=direct_order_test.js.map