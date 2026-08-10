import { createProxyAgent, ProxyConfig } from './proxy-agent.util';

describe('createProxyAgent', () => {
  const fullConfig: ProxyConfig = {
    proxyIp: '203.0.113.50',
    proxyPort: 3128,
    proxyHostname: 'proxy.staticip.in',
    proxyUsername: 'user_abc',
    proxyPassword: 'pass_xyz',
  };

  it('should return an HttpsProxyAgent when all proxy fields are present', () => {
    const agent = createProxyAgent(fullConfig);
    expect(agent).toBeDefined();
    const proxy = (agent as any).proxy;
    expect(proxy.hostname).toBe('203.0.113.50');
    expect(proxy.port).toBe('3128');
  });

  it('should embed credentials in the proxy URL when username and password are provided', () => {
    const agent = createProxyAgent(fullConfig);
    expect(agent).toBeDefined();
    const proxy = (agent as any).proxy;
    expect(proxy.username).toBe('user_abc');
    expect(proxy.password).toBe('pass_xyz');
  });

  it('should return undefined when proxyIp is null', () => {
    const agent = createProxyAgent({ ...fullConfig, proxyIp: null });
    expect(agent).toBeUndefined();
  });

  it('should return undefined when proxyPort is null', () => {
    const agent = createProxyAgent({ ...fullConfig, proxyPort: null });
    expect(agent).toBeUndefined();
  });

  it('should return undefined when both proxyIp and proxyPort are null', () => {
    const agent = createProxyAgent({
      proxyIp: null,
      proxyPort: null,
      proxyHostname: null,
      proxyUsername: null,
      proxyPassword: null,
    });
    expect(agent).toBeUndefined();
  });

  it('should create agent without auth when username/password are null', () => {
    const agent = createProxyAgent({
      ...fullConfig,
      proxyUsername: null,
      proxyPassword: null,
    });
    expect(agent).toBeDefined();
    const proxy = (agent as any).proxy;
    expect(proxy.hostname).toBe('203.0.113.50');
    // No auth embedded — username should be empty string
    expect(proxy.username).toBe('');
  });

  it('should URL-encode special characters in username and password', () => {
    const agent = createProxyAgent({
      ...fullConfig,
      proxyUsername: 'user@name',
      proxyPassword: 'p@ss:word',
    });
    expect(agent).toBeDefined();
    const proxy = (agent as any).proxy;
    expect(proxy.username).toBe('user%40name');
    expect(proxy.password).toBe('p%40ss%3Aword');
  });
});
