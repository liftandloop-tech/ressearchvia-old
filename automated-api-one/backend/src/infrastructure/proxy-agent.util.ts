import { HttpsProxyAgent } from 'https-proxy-agent';

export interface ProxyConfig {
  proxyIp: string | null;
  proxyPort: number | null;
  proxyHostname: string | null;
  proxyUsername: string | null;
  proxyPassword: string | null;
}

/**
 * Creates an HttpsProxyAgent configured with user proxy details.
 * Returns undefined if no proxy is configured.
 */
export function createProxyAgent(config: ProxyConfig): HttpsProxyAgent<string> | undefined {
  if (!config.proxyIp || !config.proxyPort) {
    return undefined;
  }

  // Construct auth if credentials exist
  let auth = '';
  if (config.proxyUsername && config.proxyPassword) {
    auth = `${encodeURIComponent(config.proxyUsername)}:${encodeURIComponent(config.proxyPassword)}@`;
  }

  // Target proxy connection string: http://[username:password@]ip:port
  const proxyUrl = `http://${auth}${config.proxyIp}:${config.proxyPort}`;
  return new HttpsProxyAgent(proxyUrl);
}
