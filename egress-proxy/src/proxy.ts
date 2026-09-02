import * as http from 'http';
import * as net from 'net';
import * as url from 'url';
import * as crypto from 'crypto';
import * as dotenv from 'dotenv';

dotenv.config();

export interface EgressMapping {
  egressId: string;
  username: string;
  tokenHash: string; // SHA-256 hex string
  publicIp: string;
  version: number;
  status: 'ACTIVE' | 'RELEASING' | 'EXPIRED';
}

const mappings = new Map<string, EgressMapping>(); // keyed by username

const DATA_PORT = parseInt(process.env.PROXY_DATA_PORT || '8888', 10);
const CONTROL_PORT = parseInt(process.env.PROXY_CONTROL_PORT || '8889', 10);
const CONTROL_SECRET = process.env.PROXY_CONTROL_SECRET || 's8_egress_super_secret_control_key_2026';
const ALLOW_DEV_FALLBACK_IP = process.env.ALLOW_DEV_FALLBACK_IP === 'true';

// ─────────────────────────────────────────────────────────────────────────────
// HELPER: Timing-Safe String Comparison
// ─────────────────────────────────────────────────────────────────────────────
function timingSafeCompare(a: string, b: string): boolean {
  if (!a || !b) return false;
  const bufA = Buffer.from(a);
  const bufB = Buffer.from(b);
  if (bufA.length !== bufB.length) {
    // Constant time dummy compare to prevent timing leaks
    crypto.timingSafeEqual(bufA, bufA);
    return false;
  }
  return crypto.timingSafeEqual(bufA, bufB);
}

// ─────────────────────────────────────────────────────────────────────────────
// AUTHENTICATION HELPER
// ─────────────────────────────────────────────────────────────────────────────
function authenticateProxyRequest(req: http.IncomingMessage): { authenticated: boolean; mapping?: EgressMapping; error?: string } {
  const authHeader = req.headers['proxy-authorization'];
  if (!authHeader || !authHeader.startsWith('Basic ')) {
    return { authenticated: false, error: 'Missing or malformed Proxy-Authorization header' };
  }

  const credentials = Buffer.from(authHeader.substring(6), 'base64').toString('utf8');
  const colonIdx = credentials.indexOf(':');
  if (colonIdx === -1) {
    return { authenticated: false, error: 'Invalid Proxy-Authorization format' };
  }

  const username = credentials.substring(0, colonIdx);
  const token = credentials.substring(colonIdx + 1);

  const mapping = mappings.get(username);
  if (!mapping) {
    return { authenticated: false, error: `User ${username} not found in proxy mappings (total loaded: ${mappings.size})` };
  }
  if (mapping.status !== 'ACTIVE') {
    return { authenticated: false, error: `Mapping for ${username} is ${mapping.status}, expected ACTIVE` };
  }

  const computedHash = crypto.createHash('sha256').update(token).digest('hex');
  if (!timingSafeCompare(computedHash, mapping.tokenHash)) {
    return { authenticated: false, error: 'Invalid proxy credential token hash mismatch' };
  }

  return { authenticated: true, mapping };
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. DATA PLANE: HTTP Forward & CONNECT Proxy Server (:8888)
// ─────────────────────────────────────────────────────────────────────────────
const proxyServer = http.createServer((req, res) => {
  const authResult = authenticateProxyRequest(req);
  if (!authResult.authenticated || !authResult.mapping) {
    console.warn(`[Egress Proxy] HTTP Request rejected for ${req.method} ${req.url}: ${authResult.error}`);
    res.writeHead(407, {
      'Proxy-Authenticate': 'Basic realm="S8 Trading Egress Proxy"',
      'Content-Type': 'application/json',
    });
    res.end(JSON.stringify({ error: 'Proxy Authentication Required', detail: authResult.error }));
    return;
  }

  const mapping = authResult.mapping;
  const parsedUrl = url.parse(req.url || '');
  const targetHost = parsedUrl.hostname || req.headers.host;
  const targetPort = parsedUrl.port ? parseInt(parsedUrl.port, 10) : 80;

  if (!targetHost) {
    res.writeHead(400, { 'Content-Type': 'text/plain' });
    res.end('Bad Request: Invalid Target Host');
    return;
  }

  // Remove Proxy-Authorization header before forwarding upstream
  const forwardedHeaders = { ...req.headers };
  delete forwardedHeaders['proxy-authorization'];

  const outboundOptions: http.RequestOptions = {
    hostname: targetHost,
    port: targetPort,
    path: parsedUrl.path || '/',
    method: req.method,
    headers: forwardedHeaders,
    localAddress: mapping.publicIp, // Bind outbound source IP
  };

  const proxyReq = http.request(outboundOptions, (proxyRes) => {
    res.writeHead(proxyRes.statusCode || 500, proxyRes.headers);
    proxyRes.pipe(res, { end: true });
  });

  proxyReq.on('error', (err: any) => {
    // If localAddress binding fails (e.g. in dev testing with mock IPs), attempt dev fallback if enabled
    if (err.code === 'EADDRNOTAVAIL' && ALLOW_DEV_FALLBACK_IP) {
      console.warn(`[Egress Proxy] Public IP ${mapping.publicIp} not bound to host interface. Falling back for dev.`);
      delete outboundOptions.localAddress;
      const fallbackReq = http.request(outboundOptions, (fallbackRes) => {
        res.writeHead(fallbackRes.statusCode || 500, fallbackRes.headers);
        fallbackRes.pipe(res, { end: true });
      });
      fallbackReq.on('error', (fErr) => {
        res.writeHead(502, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Bad Gateway', message: fErr.message }));
      });
      req.pipe(fallbackReq, { end: true });
      return;
    }

    console.error(`[Egress Proxy] HTTP Forward Error for ${mapping.username}: ${err.message}`);
    res.writeHead(502, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Bad Gateway', message: err.message }));
  });

  req.pipe(proxyReq, { end: true });
});

// Handle HTTPS CONNECT Tunneling
proxyServer.on('connect', (req, clientSocket, head) => {
  const authResult = authenticateProxyRequest(req);
  if (!authResult.authenticated || !authResult.mapping) {
    console.warn(`[Egress Proxy] CONNECT Tunnel rejected for ${req.url}: ${authResult.error}`);
    clientSocket.write('HTTP/1.1 407 Proxy Authentication Required\r\nProxy-Authenticate: Basic realm="S8 Trading Egress Proxy"\r\n\r\n');
    clientSocket.end();
    return;
  }

  const mapping = authResult.mapping;
  const [targetHost, targetPortStr] = (req.url || '').split(':');
  const targetPort = parseInt(targetPortStr || '443', 10);

  const connectOptions: net.TcpSocketConnectOpts = {
    host: targetHost,
    port: targetPort,
    localAddress: mapping.publicIp, // Bind outbound source IP
  };

  const serverSocket = net.connect(connectOptions, () => {
    clientSocket.write('HTTP/1.1 200 Connection Established\r\nProxy-Agent: S8-Egress-Proxy\r\n\r\n');
    if (head && head.length > 0) {
      serverSocket.write(head);
    }
    serverSocket.pipe(clientSocket);
    clientSocket.pipe(serverSocket);
  });

  serverSocket.on('error', (err: any) => {
    if (err.code === 'EADDRNOTAVAIL' && ALLOW_DEV_FALLBACK_IP) {
      console.warn(`[Egress Proxy] Public IP ${mapping.publicIp} not bound on connect. Dev fallback.`);
      const fallbackSocket = net.connect({ host: targetHost, port: targetPort }, () => {
        clientSocket.write('HTTP/1.1 200 Connection Established\r\nProxy-Agent: S8-Egress-Proxy-DevFallback\r\n\r\n');
        if (head && head.length > 0) fallbackSocket.write(head);
        fallbackSocket.pipe(clientSocket);
        clientSocket.pipe(fallbackSocket);
      });
      fallbackSocket.on('error', (fErr) => {
        clientSocket.write(`HTTP/1.1 502 Bad Gateway\r\n\r\n`);
        clientSocket.end();
      });
      return;
    }

    console.error(`[Egress Proxy] CONNECT Tunnel Error for ${mapping.username}: ${err.message}`);
    clientSocket.write(`HTTP/1.1 502 Bad Gateway\r\n\r\n`);
    clientSocket.end();
  });

  clientSocket.on('error', () => {
    serverSocket.destroy();
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// 2. CONTROL PLANE: Synchronization Server (:8889)
// ─────────────────────────────────────────────────────────────────────────────
const controlServer = http.createServer((req, res) => {
  const authHeader = req.headers['authorization'];
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.writeHead(401, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Unauthorized: Missing Bearer Token' }));
    return;
  }

  const token = authHeader.substring(7);
  if (!timingSafeCompare(token, CONTROL_SECRET)) {
    res.writeHead(403, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Forbidden: Invalid Control Secret' }));
    return;
  }

  const parsedUrl = url.parse(req.url || '', true);

  if (req.method === 'GET' && parsedUrl.pathname === '/internal/proxy/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      status: 'UP',
      activeMappingsCount: Array.from(mappings.values()).filter((m) => m.status === 'ACTIVE').length,
      totalMappingsCount: mappings.size,
    }));
    return;
  }

  if (req.method === 'POST' && parsedUrl.pathname === '/internal/proxy/mapping') {
    let body = '';
    req.on('data', (chunk) => (body += chunk));
    req.on('end', () => {
      try {
        const payload: EgressMapping = JSON.parse(body);
        if (!payload.egressId || !payload.username || !payload.tokenHash || !payload.publicIp || typeof payload.version !== 'number') {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'Invalid payload structure' }));
          return;
        }

        const existing = mappings.get(payload.username);
        // Monotonic version check: strictly accept higher version
        if (existing && payload.version <= existing.version) {
          console.warn(`[Egress Proxy] Rejected stale mapping version ${payload.version} <= existing ${existing.version} for ${payload.username}`);
          res.writeHead(409, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'Version conflict: mapping version is not monotonic', currentVersion: existing.version }));
          return;
        }

        if (payload.status === 'EXPIRED' || payload.status === 'RELEASING') {
          mappings.delete(payload.username);
          console.log(`[Egress Proxy] Revoked mapping for ${payload.username} (v${payload.version})`);
        } else {
          mappings.set(payload.username, payload);
          console.log(`[Egress Proxy] Installed/Updated mapping for ${payload.username} -> ${payload.publicIp} (v${payload.version})`);
        }

        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ status: 'ACK', egressId: payload.egressId, version: payload.version }));
      } catch (err: any) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Malformed JSON', message: err.message }));
      }
    });
    return;
  }

  if (req.method === 'POST' && parsedUrl.pathname === '/internal/proxy/reconcile') {
    let body = '';
    req.on('data', (chunk) => (body += chunk));
    req.on('end', () => {
      try {
        const payload: { mappings: EgressMapping[] } = JSON.parse(body);
        if (!Array.isArray(payload.mappings)) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'Expected mappings array' }));
          return;
        }

        mappings.clear();
        for (const item of payload.mappings) {
          if (item.status === 'ACTIVE') {
            mappings.set(item.username, item);
          }
        }

        console.log(`[Egress Proxy] Reconciled ${mappings.size} active mappings from egress-manager.`);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ status: 'ACK', reconciledCount: mappings.size }));
      } catch (err: any) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Malformed JSON', message: err.message }));
      }
    });
    return;
  }

  res.writeHead(404, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ error: 'Not Found' }));
});

// ─────────────────────────────────────────────────────────────────────────────
// START SERVERS
// ─────────────────────────────────────────────────────────────────────────────
proxyServer.listen(DATA_PORT, '0.0.0.0', () => {
  console.log(`[Egress Proxy] Data Plane listening on 0.0.0.0:${DATA_PORT}`);
});

controlServer.listen(CONTROL_PORT, '0.0.0.0', () => {
  console.log(`[Egress Proxy] Control Plane listening on 0.0.0.0:${CONTROL_PORT}`);
});
