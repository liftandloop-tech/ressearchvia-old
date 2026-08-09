import crypto from 'crypto';
import { getKeyBytes } from './shared.js';

function decryptAES(data) {
  const keyBytes = getKeyBytes();
  const keys = data.split(":");
  if (keys.length !== 2) {
    throw new Error('Invalid encrypted data format. Expected IV:ciphertext');
  }

  let ivBase64 = keys[0].replace(/-/g, '+').replace(/_/g, '/');
  const padding = (4 - (ivBase64.length % 4)) % 4;
  ivBase64 = ivBase64 + '='.repeat(padding);
  const iv = Buffer.from(ivBase64, 'base64');

  // Decrypt using AES-192-CBC
  const decipher = crypto.createDecipheriv('aes-192-cbc', keyBytes, iv);
  let decrypted = decipher.update(keys[1], 'base64', 'utf8');
  decrypted += decipher.final('utf8');
  return decrypted;
}

export default decryptAES;


