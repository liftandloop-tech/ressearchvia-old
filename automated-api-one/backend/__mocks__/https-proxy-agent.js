/**
 * Manual Jest mock for https-proxy-agent (v9 is pure ESM — not compatible with
 * ts-jest's CommonJS transform). This mock gives tests a predictable object
 * that mirrors the shape the production code inspects (.proxy URL).
 */

class HttpsProxyAgent {
  proxy;
  options;

  constructor(proxyUrl) {
    const url = new URL(proxyUrl);
    this.proxy = url;
    this.options = {
      href: proxyUrl,
      hostname: url.hostname,
      port: url.port,
      host: url.host,
    };
  }
}

module.exports = { HttpsProxyAgent };
