export function getKeyBytes() {
  const AES_KEY_BASE64 = "4c8c98585cfb425bb8ee3a003d535c8c";
  let keyBytes = Buffer.from(AES_KEY_BASE64, "base64");
  if (keyBytes.length !== 24) {
    const paddedKey = Buffer.alloc(24);
    keyBytes.copy(paddedKey, 0, 0, Math.min(keyBytes.length, 24));
    keyBytes = paddedKey;
  }
  return keyBytes;
}
export default {
  getKeyBytes,
};
