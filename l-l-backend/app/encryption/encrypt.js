const crypto = require('crypto');
const { getKeyBytes, base64UrlEncode } = require('./shared');

function encryptAES(data) {
  let encryptedText = null;

  const keyBytes = getKeyBytes();

  // Generate a 16-byte IV
  const iv = crypto.randomBytes(16);

  // Create a Cipher object using AES-192-CBC
  const cipher = crypto.createCipheriv('aes-192-cbc', keyBytes, iv);

  // Encrypt the data
  let encrypted = cipher.update(data, 'utf8', 'base64');
  encrypted += cipher.final('base64');

  // URL encode the IV (base64url: replace + with -, / with _, remove padding)
  const ivEncoded = base64UrlEncode(iv);
  encryptedText = ivEncoded + ":" + encrypted;
  return encryptedText;
}

// Keep backward compatibility
function encryptString(plaintext, { iv, keyBytes } = {}) {
  const resolvedKey = keyBytes || getKeyBytes();
  const resolvedIv = iv || crypto.randomBytes(16);

  const cipher = crypto.createCipheriv('aes-192-cbc', resolvedKey, resolvedIv);
  const payload = typeof plaintext === 'string' ? plaintext : JSON.stringify(plaintext);

  let encrypted = cipher.update(payload, 'utf8', 'base64');
  encrypted += cipher.final('base64');

  const ivEncoded = base64UrlEncode(resolvedIv);

  return {
    iv: resolvedIv,
    ivBase64: resolvedIv.toString('base64'),
    ciphertext: encrypted,
    payload: `${ivEncoded}:${encrypted}`,
  };
}

function generateIV() {
  return crypto.randomBytes(16);
}

module.exports = Object.assign(encryptAES, {
  generateIV,
  encryptString,
});

