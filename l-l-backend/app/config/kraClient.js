// -------------------- IMPORTS --------------------
import crypto from 'crypto';
import fetch from 'node-fetch';  // If using Node 18+, remove this line (fetch is built-in)

// -------------------- DEFAULT CONFIG --------------------
const DEFAULT_CONFIG = {
  baseUrl: process.env.CVL_API_BASE_URL || 'https://api.kracvl.com/int/api',
  apiKey: process.env.CVL_API_KEY || 'b6d916d25d7e4c26ad37e5d5edc3fd42',
  aesKey: process.env.CVL_AES_KEY || '4c8c98585cfb425bb8ee3a003d535c8c',
  aesKeyEncoding: process.env.CVL_AES_KEY_ENCODING,
  username: process.env.CVL_USERNAME || 'SPRESEARCHVIA',
  posCode: process.env.CVL_POS_CODE || '2500015808',
  rtaCode: process.env.CVL_RTA_CODE || '2500015808',
  userAgent: process.env.CVL_USER_AGENT || 'SPRESEARCHVIA-KRA-Client/1.0',
  tokenValidTime: process.env.CVL_TOKEN_VALIDITY,
};

// -------------------- HELPERS --------------------
function decodeAesKey(rawKey, encodingPreference) {
  if (!rawKey) throw new Error("CVL AES key is missing.");
  const trimmed = rawKey.trim();
  const normalized = trimmed.replace(/-/g, '+').replace(/_/g, '/');

  function tryHex() {
    if (!/^[0-9a-fA-F]+$/u.test(trimmed) || trimmed.length % 2 !== 0) return null;
    return Buffer.from(trimmed, 'hex');
  }

  function tryBase64() {
    return Buffer.from(normalized, 'base64');
  }

  function tryAscii() {
    return Buffer.from(trimmed, 'utf8');
  }

  function valid(b) {
    return b && [16, 24, 32].includes(b.length);
  }

  const methods = [];
  if (encodingPreference) methods.push(encodingPreference.toLowerCase());
  methods.push('base64', 'hex', 'ascii');

  const tried = new Set();

  for (const m of methods) {
    const key = m === 'base64url' ? 'base64' : m;
    if (tried.has(key)) continue;
    tried.add(key);

    let buf = null;
    try {
      if (key === 'hex') buf = tryHex();
      else if (key === 'ascii') buf = tryAscii();
      else buf = tryBase64();
    } catch {
      buf = null;
    }

    if (valid(buf)) return buf;
  }

  throw new Error('Unable to decode AES key.');
}

function selectAlgorithm(keyBytes) {
  if (keyBytes.length === 16) return 'aes-128-cbc';
  if (keyBytes.length === 24) return 'aes-192-cbc';
  if (keyBytes.length === 32) return 'aes-256-cbc';
  throw new Error("Invalid AES key length");
}

function base64UrlEncode(buf) {
  return buf.toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/u, '');
}

function base64UrlDecode(text) {
  let n = text.replace(/-/g, '+').replace(/_/g, '/');
  while (n.length % 4 !== 0) n += '=';
  return Buffer.from(n, 'base64');
}

// -------------------- MAIN CIPHER SUITE --------------------
function createCipherSuite(configOverrides = {}) {
  const config = { ...DEFAULT_CONFIG, ...configOverrides };
  const keyBytes = decodeAesKey(config.aesKey, config.aesKeyEncoding);
  const algo = selectAlgorithm(keyBytes);

  function encryptPayload(payload) {
    const text = typeof payload === 'string' ? payload : JSON.stringify(payload);
    const iv = crypto.randomBytes(16);
    const cipher = crypto.createCipheriv(algo, keyBytes, iv);
    const enc = Buffer.concat([cipher.update(text, 'utf8'), cipher.final()]);
    return `${base64UrlEncode(iv)}:${base64UrlEncode(enc)}`;
  }

  function decryptPayload(packed) {
    const [ivStr, encStr] = packed.split(':');
    if (!ivStr || !encStr) throw new Error("Invalid encrypted payload format");

    const decipher = crypto.createDecipheriv(algo, keyBytes, base64UrlDecode(ivStr));
    const dec = Buffer.concat([
      decipher.update(base64UrlDecode(encStr)),
      decipher.final(),
    ]);
    return dec.toString('utf8');
  }

  function buildEncryptedBody(payload) {
    return JSON.stringify(encryptPayload(payload));
  }

  return { config, encryptPayload, decryptPayload, buildEncryptedBody };
}

// -------------------- GET TOKEN --------------------
async function getToken(configOverrides = {}) {
  const { config, buildEncryptedBody, decryptPayload } = createCipherSuite(configOverrides);
  const password = configOverrides.password || process.env.CVL_PASSWORD;
  if (!password) throw new Error("CVL password missing");

  const headers = {
    'content-type': 'application/json',
    'user-agent': config.userAgent,
    api_key: config.apiKey
  };

  if (config.tokenValidTime) headers.tokenvalidtime = config.tokenValidTime;

  const body = buildEncryptedBody({
    username: config.username,
    poscode: config.posCode,
    password
  });

  const res = await fetch(`${config.baseUrl}/GetToken`, { method: 'POST', headers, body });
  const raw = (await res.text()).trim();

  let data = attemptJsonParse(raw);

  if ((!data || typeof data !== 'object') && raw.includes(':')) {
    try {
      const dec = decryptPayload(raw);
      data = attemptJsonParse(dec);
    } catch { }
  }

  if (!res.ok) throw new Error(`GetToken failed: ${res.status}`);

  return data?.token || data?.Token || data?.TOKEN;
}

async function solicitPanDetails(params, configOverrides = {}) {
  const { config, buildEncryptedBody, decryptPayload } = createCipherSuite(configOverrides);

  const {
    pan,
    dobOrIncorp,
    fetchType = 'E',
    posCode = config.posCode,
    rtaCode = config.rtaCode,
    kraCode = 'CVLKRA',
  } = params;

  if (!pan || !dobOrIncorp) throw new Error("pan & dobOrIncorp required");

  const token = await getToken(configOverrides);


  const payload = {
    APP_REQ_ROOT: {
      APP_PAN_INQ: {
        APP_PAN_NO: pan.toUpperCase(),
        APP_DOB_INCORP: dobOrIncorp,
        APP_POS_CODE: posCode,
        APP_RTA_CODE: rtaCode,
        APP_KRA_CODE: kraCode,
        FETCH_TYPE: fetchType
      }
    }
  };

  const res = await fetch(`${config.baseUrl}/SolicitPANDetailsFetchALLKRA`, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      'user-agent': config.userAgent,
      Token: token,
    },
    body: buildEncryptedBody(payload),
  });

  const data = await res.json();
  if (typeof data.resdtls === 'string' && data.resdtls.includes(':')) {
    try {
      const dec = decryptPayload(data.resdtls);
      data.resdtlsDecrypted = attemptJsonParse(dec);
    } catch {
      data.resdtlsDecrypted = { error: "Unable to decrypt" };
    }
  }

  return {
    request: payload,
    raw: data,
    decrypted: data.resdtlsDecrypted || null,
  };
}

function attemptJsonParse(text) {
  try {
    return JSON.parse(text);
  } catch {
    return text;
  }
}

export default {
  getToken,
  solicitPanDetails,
  createCipherSuite,
};

export { getToken, solicitPanDetails, createCipherSuite };
