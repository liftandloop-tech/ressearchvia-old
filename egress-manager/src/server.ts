import * as http from 'http';
import * as url from 'url';
import * as crypto from 'crypto';
import { Pool } from 'pg';
import * as dotenv from 'dotenv';

dotenv.config();

const PORT = parseInt(process.env.EGRESS_MANAGER_PORT || '8080', 10);
const DATABASE_URL = process.env.DATABASE_URL || 'postgresql://postgres:postgres@postgres:5432/s8_autotrade?schema=public';
const PROXY_CONTROL_URL = process.env.EGRESS_PROXY_CONTROL_URL || 'http://host.docker.internal:8889';
const PROXY_DATA_HOST = process.env.EGRESS_PROXY_DATA_HOST || 'host.docker.internal';
const PROXY_DATA_PORT = parseInt(process.env.EGRESS_PROXY_DATA_PORT || '8888', 10);
const PROXY_CONTROL_SECRET = process.env.PROXY_CONTROL_SECRET || 's8_egress_super_secret_control_key_2026';
const IP_ECHO_ENDPOINT = process.env.IP_ECHO_ENDPOINT || 'http://api.ipify.org?format=json';

const pool = new Pool({
  connectionString: DATABASE_URL,
});

// ─────────────────────────────────────────────────────────────────────────────
// PROXY CLIENT SYNCHRONIZATION HELPERS
// ─────────────────────────────────────────────────────────────────────────────
async function pushMappingToProxy(mapping: {
  egressId: string;
  username: string;
  tokenHash: string;
  publicIp: string;
  version: number;
  status: 'ACTIVE' | 'RELEASING' | 'EXPIRED';
}): Promise<{ status: string; egressId?: string; version?: number }> {
  const targetUrl = `${PROXY_CONTROL_URL}/internal/proxy/mapping`;
  const res = await fetch(targetUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${PROXY_CONTROL_SECRET}`,
    },
    body: JSON.stringify(mapping),
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Proxy mapping push failed (${res.status}): ${text}`);
  }

  return (await res.json()) as any;
}

async function bulkReconcileToProxy(): Promise<void> {
  try {
    const client = await pool.connect();
    try {
      const res = await client.query(`
        SELECT u.id as "egressId", u."proxyUsername" as username, u."proxySecretHash" as "tokenHash",
               i."publicIp", u.version, u.status
        FROM "UserIpAssignment" u
        JOIN "IpPool" i ON u."ipPoolId" = i.id
        WHERE u.status = 'ACTIVE'
      `);

      const mappings = res.rows.map((r) => ({
        egressId: r.egressId,
        username: r.username,
        tokenHash: r.tokenHash,
        publicIp: r.publicIp,
        version: r.version,
        status: 'ACTIVE' as const,
      }));

      const targetUrl = `${PROXY_CONTROL_URL}/internal/proxy/reconcile`;
      const pushRes = await fetch(targetUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${PROXY_CONTROL_SECRET}`,
        },
        body: JSON.stringify({ mappings }),
      });

      if (pushRes.ok) {
        console.log(`[Egress Manager] Reconciled ${mappings.length} ACTIVE assignments with proxy.`);
      } else {
        console.warn(`[Egress Manager] Proxy reconcile returned status: ${pushRes.status}`);
      }
    } finally {
      client.release();
    }
  } catch (err: any) {
    console.error(`[Egress Manager] Startup reconciliation warning: ${err.message}`);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EXACT HEALTH CHECK VERIFICATION THROUGH PROXY
// ─────────────────────────────────────────────────────────────────────────────
async function verifyEgressThroughProxy(username: string, rawToken: string, expectedIp: string): Promise<{ success: boolean; observedIp?: string; error?: string }> {
  return new Promise((resolve) => {
    const authHeader = `Basic ${Buffer.from(`${username}:${rawToken}`).toString('base64')}`;
    const parsedTarget = url.parse(IP_ECHO_ENDPOINT);

    const reqOptions: http.RequestOptions = {
      hostname: PROXY_DATA_HOST,
      port: PROXY_DATA_PORT,
      path: IP_ECHO_ENDPOINT,
      method: 'GET',
      headers: {
        Host: parsedTarget.host || 'api.ipify.org',
        'Proxy-Authorization': authHeader,
        Accept: 'application/json',
      },
      timeout: 10000,
    };

    const req = http.request(reqOptions, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          const observedIp = parsed.ip;
          if (observedIp === expectedIp) {
            resolve({ success: true, observedIp });
          } else {
            resolve({
              success: false,
              observedIp,
              error: `Source IP mismatch: expected ${expectedIp}, observed ${observedIp}`,
            });
          }
        } catch (e: any) {
          resolve({ success: false, error: `Invalid response format from echo service: ${data}` });
        }
      });
    });

    req.on('error', (err) => {
      resolve({ success: false, error: `Verification request failed: ${err.message}` });
    });

    req.on('timeout', () => {
      req.destroy();
      resolve({ success: false, error: 'Verification request timed out' });
    });

    req.end();
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// HTTP SERVER & INTERNAL REST API
// ─────────────────────────────────────────────────────────────────────────────
const server = http.createServer(async (req, res) => {
  const parsedUrl = url.parse(req.url || '', true);
  res.setHeader('Content-Type', 'application/json');

  if (req.method === 'GET' && parsedUrl.pathname === '/health') {
    res.writeHead(200);
    res.end(JSON.stringify({ status: 'OK', service: 'egress-manager' }));
    return;
  }

  // 1. ALLOCATE EGRESS IP FOR USER (Concurrency-Safe)
  if (req.method === 'POST' && parsedUrl.pathname === '/internal/egress/allocate') {
    let body = '';
    req.on('data', (chunk) => (body += chunk));
    req.on('end', async () => {
      const dbClient = await pool.connect();
      try {
        const { userId } = JSON.parse(body || '{}');
        if (!userId) {
          res.writeHead(400);
          res.end(JSON.stringify({ success: false, message: 'Missing userId' }));
          return;
        }

        await dbClient.query('BEGIN');

        // Check if user already has an active or in-flight assignment
        const activeCheck = await dbClient.query(
          `SELECT id, status, "proxyUsername", "ipPoolId", version FROM "UserIpAssignment"
           WHERE "userId" = $1 AND status IN ('RESERVED', 'CONFIGURING', 'ACTIVE', 'RELEASING')
           LIMIT 1`,
          [userId]
        );

        if (activeCheck.rows.length > 0) {
          await dbClient.query('ROLLBACK');
          const existing = activeCheck.rows[0];
          res.writeHead(409);
          res.end(JSON.stringify({
            success: false,
            message: `User already has an active or pending egress assignment (${existing.status})`,
            assignmentId: existing.id,
          }));
          return;
        }

        // Concurrency-Safe IP Reservation with SKIP LOCKED
        const ipRes = await dbClient.query(
          `SELECT id, "publicIp", interface, status
           FROM "IpPool"
           WHERE status = 'AVAILABLE'
           LIMIT 1
           FOR UPDATE SKIP LOCKED`
        );

        if (ipRes.rows.length === 0) {
          await dbClient.query('ROLLBACK');
          res.writeHead(503);
          res.end(JSON.stringify({ success: false, message: 'No available egress IPs in pool' }));
          return;
        }

        const ipRow = ipRes.rows[0];
        const rawToken = crypto.randomBytes(32).toString('hex');
        const tokenHash = crypto.createHash('sha256').update(rawToken).digest('hex');
        const assignmentId = crypto.randomUUID();
        const proxyUsername = `egress_${assignmentId}`;
        const version = 1;

        // Create assignment record in CONFIGURING state
        await dbClient.query(
          `INSERT INTO "UserIpAssignment" (id, "userId", "ipPoolId", status, "proxyUsername", "proxySecretHash", version, "assignedAt", "updatedAt")
           VALUES ($1, $2, $3, 'CONFIGURING', $4, $5, $6, NOW(), NOW())`,
          [assignmentId, userId, ipRow.id, proxyUsername, tokenHash, version]
        );

        // Update IP pool status to CONFIGURING
        await dbClient.query(`UPDATE "IpPool" SET status = 'CONFIGURING', "updatedAt" = NOW() WHERE id = $1`, [ipRow.id]);

        await dbClient.query('COMMIT');

        // Push configuration mapping to Egress Proxy
        const ack = await pushMappingToProxy({
          egressId: assignmentId,
          username: proxyUsername,
          tokenHash,
          publicIp: ipRow.publicIp,
          version,
          status: 'ACTIVE',
        });

        if (ack.status !== 'ACK') {
          throw new Error('Egress proxy did not acknowledge mapping configuration');
        }

        // Execute external health verification through the proxy
        const healthResult = await verifyEgressThroughProxy(proxyUsername, rawToken, ipRow.publicIp);

        if (healthResult.success) {
          // Transition to ACTIVE
          await pool.query(
            `UPDATE "UserIpAssignment" SET status = 'ACTIVE', "updatedAt" = NOW() WHERE id = $1`,
            [assignmentId]
          );
          await pool.query(
            `UPDATE "IpPool" SET status = 'ACTIVE', "isHealthy" = true, "lastVerifiedAt" = NOW(), "observedSourceIp" = $1, "updatedAt" = NOW() WHERE id = $2`,
            [healthResult.observedIp || ipRow.publicIp, ipRow.id]
          );

          res.writeHead(200);
          res.end(JSON.stringify({
            success: true,
            assignmentId,
            publicIp: ipRow.publicIp,
            proxyUsername,
            token: rawToken, // Returned ONCE to client
            status: 'ACTIVE',
          }));
        } else {
          console.error(`[Egress Manager] IP Verification failed: ${healthResult.error}`);
          // Rollback proxy mapping
          await pushMappingToProxy({
            egressId: assignmentId,
            username: proxyUsername,
            tokenHash,
            publicIp: ipRow.publicIp,
            version: version + 1,
            status: 'EXPIRED',
          });

          await pool.query(`UPDATE "UserIpAssignment" SET status = 'EXPIRED', "releasedAt" = NOW() WHERE id = $1`, [assignmentId]);
          await pool.query(`UPDATE "IpPool" SET status = 'FAILED', "isHealthy" = false WHERE id = $1`, [ipRow.id]);

          res.writeHead(502);
          res.end(JSON.stringify({
            success: false,
            message: 'Egress source-IP verification failed',
            detail: healthResult.error,
          }));
        }
      } catch (err: any) {
        await dbClient.query('ROLLBACK');
        console.error(`[Egress Manager] Allocation error: ${err.message}`);
        res.writeHead(500);
        res.end(JSON.stringify({ success: false, error: err.message }));
      } finally {
        dbClient.release();
      }
    });
    return;
  }

  // 2. RESOLVE USER'S ACTIVE EGRESS IDENTITY
  if (req.method === 'POST' && parsedUrl.pathname === '/internal/egress/resolve') {
    let body = '';
    req.on('data', (chunk) => (body += chunk));
    req.on('end', async () => {
      try {
        const { userId } = JSON.parse(body || '{}');
        if (!userId) {
          res.writeHead(400);
          res.end(JSON.stringify({ success: false, message: 'Missing userId' }));
          return;
        }

        const result = await pool.query(
          `SELECT u.id as "assignmentId", u."proxyUsername", u.status, i."publicIp", u.version
           FROM "UserIpAssignment" u
           JOIN "IpPool" i ON u."ipPoolId" = i.id
           WHERE u."userId" = $1 AND u.status = 'ACTIVE'
           LIMIT 1`,
          [userId]
        );

        if (result.rows.length === 0) {
          res.writeHead(404);
          res.end(JSON.stringify({ success: false, message: 'No active egress assignment found for user' }));
          return;
        }

        const row = result.rows[0];
        res.writeHead(200);
        res.end(JSON.stringify({
          success: true,
          assignmentId: row.assignmentId,
          publicIp: row.publicIp,
          proxyUsername: row.proxyUsername,
          proxyEndpoint: `http://${PROXY_DATA_HOST}:${PROXY_DATA_PORT}`,
          status: row.status,
          version: row.version,
        }));
      } catch (err: any) {
        res.writeHead(500);
        res.end(JSON.stringify({ success: false, error: err.message }));
      }
    });
    return;
  }

  // 3. ROTATE / RE-AUTHENTICATE RUNTIME PROXY CREDENTIAL (Lifecycle Recovery)
  if (req.method === 'POST' && parsedUrl.pathname === '/internal/egress/rotate-token') {
    let body = '';
    req.on('data', (chunk) => (body += chunk));
    req.on('end', async () => {
      const dbClient = await pool.connect();
      try {
        const { userId } = JSON.parse(body || '{}');
        if (!userId) {
          res.writeHead(400);
          res.end(JSON.stringify({ success: false, message: 'Missing userId' }));
          return;
        }

        await dbClient.query('BEGIN');

        const activeCheck = await dbClient.query(
          `SELECT u.id as "assignmentId", u."proxyUsername", u.version, u."ipPoolId", i."publicIp"
           FROM "UserIpAssignment" u
           JOIN "IpPool" i ON u."ipPoolId" = i.id
           WHERE u."userId" = $1 AND u.status = 'ACTIVE'
           LIMIT 1
           FOR UPDATE`,
          [userId]
        );

        if (activeCheck.rows.length === 0) {
          await dbClient.query('ROLLBACK');
          res.writeHead(404);
          res.end(JSON.stringify({ success: false, message: 'No ACTIVE egress assignment found for user' }));
          return;
        }

        const row = activeCheck.rows[0];
        const nextVersion = row.version + 1;
        const rawToken = crypto.randomBytes(32).toString('hex');
        const tokenHash = crypto.createHash('sha256').update(rawToken).digest('hex');

        // Push new hash mapping immediately to proxy
        const ack = await pushMappingToProxy({
          egressId: row.assignmentId,
          username: row.proxyUsername,
          tokenHash,
          publicIp: row.publicIp,
          version: nextVersion,
          status: 'ACTIVE',
        });

        if (ack.status !== 'ACK') {
          throw new Error('Egress proxy rejected updated mapping during token rotation');
        }

        // Update hash in database within locked transaction
        await dbClient.query(
          `UPDATE "UserIpAssignment"
           SET "proxySecretHash" = $1, version = $2, "updatedAt" = NOW()
           WHERE id = $3`,
          [tokenHash, nextVersion, row.assignmentId]
        );

        await dbClient.query('COMMIT');

        res.writeHead(200);
        res.end(JSON.stringify({
          success: true,
          username: row.proxyUsername,
          token: rawToken,
          publicIp: row.publicIp,
          version: nextVersion,
        }));
      } catch (err: any) {
        await dbClient.query('ROLLBACK');
        console.error(`[Egress Manager] Token rotation error: ${err.message}`);
        res.writeHead(500);
        res.end(JSON.stringify({ success: false, error: err.message }));
      } finally {
        dbClient.release();
      }
    });
    return;
  }

  // 4. RELEASE USER EGRESS ASSIGNMENT (Return to pool)
  if (req.method === 'POST' && parsedUrl.pathname === '/internal/egress/release') {
    let body = '';
    req.on('data', (chunk) => (body += chunk));
    req.on('end', async () => {
      const dbClient = await pool.connect();
      try {
        const { userId, assignmentId } = JSON.parse(body || '{}');
        if (!userId && !assignmentId) {
          res.writeHead(400);
          res.end(JSON.stringify({ success: false, message: 'Missing userId or assignmentId' }));
          return;
        }

        await dbClient.query('BEGIN');

        const queryStr = userId
          ? `SELECT u.id, u."userId", u."ipPoolId", u."proxyUsername", u."proxySecretHash", u.version, i."publicIp"
             FROM "UserIpAssignment" u JOIN "IpPool" i ON u."ipPoolId" = i.id
             WHERE u."userId" = $1 AND u.status IN ('ACTIVE', 'CONFIGURING', 'RESERVED') LIMIT 1 FOR UPDATE`
          : `SELECT u.id, u."userId", u."ipPoolId", u."proxyUsername", u."proxySecretHash", u.version, i."publicIp"
             FROM "UserIpAssignment" u JOIN "IpPool" i ON u."ipPoolId" = i.id
             WHERE u.id = $1 AND u.status IN ('ACTIVE', 'CONFIGURING', 'RESERVED') LIMIT 1 FOR UPDATE`;

        const findRes = await dbClient.query(queryStr, [userId || assignmentId]);
        if (findRes.rows.length === 0) {
          await dbClient.query('ROLLBACK');
          res.writeHead(404);
          res.end(JSON.stringify({ success: false, message: 'No active assignment found to release' }));
          return;
        }

        const assignRow = findRes.rows[0];
        const nextVersion = assignRow.version + 1;

        // Set state to RELEASING
        await dbClient.query(
          `UPDATE "UserIpAssignment" SET status = 'RELEASING', version = $1, "updatedAt" = NOW() WHERE id = $2`,
          [nextVersion, assignRow.id]
        );

        // Revoke from proxy
        const ack = await pushMappingToProxy({
          egressId: assignRow.id,
          username: assignRow.proxyUsername,
          tokenHash: assignRow.proxySecretHash || '',
          publicIp: assignRow.publicIp,
          version: nextVersion,
          status: 'EXPIRED',
        });

        if (ack.status !== 'ACK') {
          throw new Error('Egress proxy did not acknowledge mapping revocation');
        }

        // Commit EXPIRED assignment and return IP to AVAILABLE
        await dbClient.query(
          `UPDATE "UserIpAssignment" SET status = 'EXPIRED', "releasedAt" = NOW(), "updatedAt" = NOW() WHERE id = $1`,
          [assignRow.id]
        );
        await dbClient.query(
          `UPDATE "IpPool" SET status = 'AVAILABLE', "updatedAt" = NOW() WHERE id = $1`,
          [assignRow.ipPoolId]
        );

        await dbClient.query('COMMIT');

        res.writeHead(200);
        res.end(JSON.stringify({
          success: true,
          message: 'Egress IP successfully released and returned to pool',
          releasedAssignmentId: assignRow.id,
        }));
      } catch (err: any) {
        await dbClient.query('ROLLBACK');
        console.error(`[Egress Manager] Release error: ${err.message}`);
        res.writeHead(500);
        res.end(JSON.stringify({ success: false, error: err.message }));
      } finally {
        dbClient.release();
      }
    });
    return;
  }

  // 4. MANUAL TRIGGER RECONCILIATION
  if (req.method === 'POST' && parsedUrl.pathname === '/internal/egress/reconcile') {
    await bulkReconcileToProxy();
    res.writeHead(200);
    res.end(JSON.stringify({ success: true, message: 'Reconciliation triggered' }));
    return;
  }

  res.writeHead(404);
  res.end(JSON.stringify({ error: 'Not Found' }));
});

server.listen(PORT, () => {
  console.log(`[Egress Manager] Control Plane listening on port ${PORT}`);
  // Run initial reconciliation with proxy after slight startup delay
  setTimeout(() => bulkReconcileToProxy(), 2000);
  // Periodic background heartbeat to ensure proxy always has fresh mappings even across proxy restarts
  setInterval(() => bulkReconcileToProxy(), 15000);
});
