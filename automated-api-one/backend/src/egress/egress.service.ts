import {
  Injectable,
  Logger,
  NotFoundException,
  BadRequestException,
  InternalServerErrorException,
} from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma.service';
import { RedisService } from '../infrastructure/redis/redis.service';
import { RedisKeys } from '../infrastructure/redis/redis-keys';
import { firstValueFrom } from 'rxjs';
import { HttpsProxyAgent } from 'https-proxy-agent';
import axios from 'axios';

export interface UserEgressCredentials {
  assignmentId?: string;
  proxyUsername: string;
  token: string;
  publicIp: string;
  proxyHost: string;
  proxyPort: number;
}

export interface EgressTestResult {
  userId: string;
  publicIp: string;
  observedIp: string | null;
  match: boolean;
  latencyMs: number;
  status: 'PASS' | 'FAIL';
  message: string;
}

@Injectable()
export class EgressService {
  private readonly logger = new Logger(EgressService.name);
  private readonly egressManagerUrl: string;
  private readonly proxyHost: string;
  private readonly proxyPort: number;
  private readonly controlSecret: string;

  constructor(
    private readonly httpService: HttpService,
    private readonly configService: ConfigService,
    private readonly prisma: PrismaService,
    private readonly redisService: RedisService,
  ) {
    this.egressManagerUrl =
      this.configService.get<string>('EGRESS_MANAGER_URL') || 'http://localhost:8080';
    this.proxyHost =
      this.configService.get<string>('EGRESS_PROXY_HOST') || 'localhost';
    this.proxyPort =
      this.configService.get<number>('EGRESS_PROXY_PORT') || 8888;
    this.controlSecret =
      this.configService.get<string>('PROXY_CONTROL_SECRET') ||
      's8_egress_super_secret_control_key_2026';
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. ALLOCATE EGRESS IP FOR USER
  // ─────────────────────────────────────────────────────────────────────────────
  async allocateEgress(userId: string): Promise<UserEgressCredentials> {
    this.logger.log(`[EgressService] Requesting IP allocation for user ${userId} from ${this.egressManagerUrl}`);

    try {
      const response = await firstValueFrom(
        this.httpService.post(
          `${this.egressManagerUrl}/internal/egress/allocate`,
          { userId },
          {
            headers: { 'Content-Type': 'application/json' },
            timeout: 15000,
          },
        ),
      );

      const data = response.data;
      if (!data.success) {
        throw new Error(data.message || 'Allocation failed on Egress Manager');
      }

      const credentials: UserEgressCredentials = {
        assignmentId: data.assignmentId,
        proxyUsername: data.proxyUsername,
        token: data.token,
        publicIp: data.publicIp,
        proxyHost: this.proxyHost,
        proxyPort: this.proxyPort,
      };

      await this.cacheCredentialsInRedis(userId, credentials);
      this.logger.log(`[EgressService] Successfully allocated IP ${credentials.publicIp} for user ${userId} (username: ${credentials.proxyUsername})`);
      return credentials;
    } catch (err: any) {
      // If user already has an active assignment (409 Conflict), rotate token to recover credentials
      if (err.response?.status === 409) {
        this.logger.log(`[EgressService] User ${userId} already has active assignment. Rotating token to recover.`);
        return this.rotateToken(userId);
      }

      const errorMsg = err.response?.data?.message || err.message;
      this.logger.error(`[EgressService] Allocation failed for user ${userId}: ${errorMsg}`);
      throw new InternalServerErrorException(`Egress allocation failed: ${errorMsg}`);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. RESOLVE USER'S ACTIVE EGRESS IDENTITY
  // ─────────────────────────────────────────────────────────────────────────────
  async resolveEgress(userId: string): Promise<any> {
    try {
      const response = await firstValueFrom(
        this.httpService.post(
          `${this.egressManagerUrl}/internal/egress/resolve`,
          { userId },
          {
            headers: { 'Content-Type': 'application/json' },
            timeout: 5000,
          },
        ),
      );
      return response.data;
    } catch (err: any) {
      if (err.response?.status === 404) {
        throw new NotFoundException(`No active egress assignment found for user ${userId}`);
      }
      throw new InternalServerErrorException(`Egress resolution failed: ${err.message}`);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. ROTATE RUNTIME PROXY CREDENTIAL
  // ─────────────────────────────────────────────────────────────────────────────
  async rotateToken(userId: string): Promise<UserEgressCredentials> {
    this.logger.log(`[EgressService] Rotating token for user ${userId}`);

    try {
      const response = await firstValueFrom(
        this.httpService.post(
          `${this.egressManagerUrl}/internal/egress/rotate-token`,
          { userId },
          {
            headers: { 'Content-Type': 'application/json' },
            timeout: 10000,
          },
        ),
      );

      const data = response.data;
      if (!data.success) {
        throw new Error(data.message || 'Token rotation failed on Egress Manager');
      }

      const credentials: UserEgressCredentials = {
        proxyUsername: data.username,
        token: data.token,
        publicIp: data.publicIp,
        proxyHost: this.proxyHost,
        proxyPort: this.proxyPort,
      };

      await this.cacheCredentialsInRedis(userId, credentials);
      this.logger.log(`[EgressService] Successfully rotated token for user ${userId} -> IP ${credentials.publicIp}`);
      return credentials;
    } catch (err: any) {
      if (err.response?.status === 404) {
        // If no assignment exists, allocate fresh
        this.logger.log(`[EgressService] No active assignment to rotate for user ${userId}. Allocating fresh.`);
        return this.allocateEgress(userId);
      }
      throw new InternalServerErrorException(`Token rotation failed: ${err.message}`);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. RELEASE USER EGRESS ASSIGNMENT
  // ─────────────────────────────────────────────────────────────────────────────
  async releaseEgress(userId: string): Promise<boolean> {
    this.logger.log(`[EgressService] Releasing egress IP for user ${userId}`);

    try {
      const response = await firstValueFrom(
        this.httpService.post(
          `${this.egressManagerUrl}/internal/egress/release`,
          { userId },
          {
            headers: { 'Content-Type': 'application/json' },
            timeout: 10000,
          },
        ),
      );

      // Clear from Redis cache
      if (this.redisService.isHealthy()) {
        try {
          await this.redisService.getClient().del(RedisKeys.userEgress(userId));
        } catch (rErr: any) {
          this.logger.warn(`[EgressService] Redis cache del failed on release: ${rErr.message}`);
        }
      }

      return response.data?.success === true;
    } catch (err: any) {
      this.logger.error(`[EgressService] Release failed for user ${userId}: ${err.message}`);
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 5. TRIGGER MANUAL PROXY RECONCILIATION
  // ─────────────────────────────────────────────────────────────────────────────
  async reconcileProxy(): Promise<boolean> {
    try {
      const response = await firstValueFrom(
        this.httpService.post(
          `${this.egressManagerUrl}/internal/egress/reconcile`,
          {},
          { timeout: 5000 },
        ),
      );
      return response.data?.success === true;
    } catch (err: any) {
      this.logger.error(`[EgressService] Reconciliation trigger failed: ${err.message}`);
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 6. HIGH-PERFORMANCE GET OR CREATE (W/ REDIS CACHE & SELF-HEALING)
  // ─────────────────────────────────────────────────────────────────────────────
  async getOrCreateUserEgress(userId: string): Promise<UserEgressCredentials> {
    // 1. Fast path: Check Redis cache
    if (this.redisService.isHealthy()) {
      try {
        const cachedRaw = await this.redisService.getClient().get(RedisKeys.userEgress(userId));
        if (cachedRaw) {
          const cached = JSON.parse(cachedRaw) as UserEgressCredentials;
          if (cached.proxyUsername && cached.token && cached.publicIp) {
            return cached;
          }
        }
      } catch (rErr: any) {
        this.logger.warn(`[EgressService] Redis read failed for user ${userId}: ${rErr.message}`);
      }
    }

    // 2. Slow path: Check PostgreSQL UserIpAssignment
    const activeAssignment = await this.prisma.userIpAssignment.findFirst({
      where: { userId, status: 'ACTIVE' },
      include: { ipPool: true },
    });

    if (activeAssignment && activeAssignment.ipPool) {
      // Active in DB but missing from Redis: rotate token to get fresh raw token & sync
      return this.rotateToken(userId);
    }

    // 3. No active assignment: allocate new IP from pool
    return this.allocateEgress(userId);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 7. GET CONFIGURED HTTPS PROXY AGENT FOR USER BROKER CALLS
  // ─────────────────────────────────────────────────────────────────────────────
  async getProxyAgentForUser(userId: string): Promise<HttpsProxyAgent<string> | undefined> {
    try {
      const credentials = await this.getOrCreateUserEgress(userId);
      if (!credentials.proxyHost || !credentials.proxyPort || !credentials.proxyUsername || !credentials.token) {
        return undefined;
      }

      const auth = `${encodeURIComponent(credentials.proxyUsername)}:${encodeURIComponent(credentials.token)}`;
      const proxyUrl = `http://${auth}@${credentials.proxyHost}:${credentials.proxyPort}`;
      return new HttpsProxyAgent(proxyUrl);
    } catch (err: any) {
      this.logger.error(`[EgressService] Failed to create proxy agent for user ${userId}: ${err.message}`);
      return undefined;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 8. DIAGNOSTIC CONNECTIVITY TEST THROUGH PROXY TUNNEL
  // ─────────────────────────────────────────────────────────────────────────────
  async testEgressConnectivity(userId: string): Promise<EgressTestResult> {
    const start = Date.now();
    try {
      const credentials = await this.getOrCreateUserEgress(userId);
      const agent = await this.getProxyAgentForUser(userId);

      if (!agent) {
        return {
          userId,
          publicIp: credentials.publicIp,
          observedIp: null,
          match: false,
          latencyMs: Date.now() - start,
          status: 'FAIL',
          message: 'Failed to construct HttpsProxyAgent for user egress',
        };
      }

      const res = await axios.get('https://api.ipify.org?format=json', {
        httpsAgent: agent,
        proxy: false,
        timeout: 10000,
      });

      const latencyMs = Date.now() - start;
      const observedIp = res.data?.ip || null;
      const match = observedIp === credentials.publicIp;

      return {
        userId,
        publicIp: credentials.publicIp,
        observedIp,
        match,
        latencyMs,
        status: match ? 'PASS' : 'FAIL',
        message: match
          ? `Verified! Outbound traffic emerges from assigned Static IP ${observedIp} (${latencyMs}ms)`
          : `IP Mismatch! Expected ${credentials.publicIp}, observed ${observedIp}`,
      };
    } catch (err: any) {
      return {
        userId,
        publicIp: 'UNKNOWN',
        observedIp: null,
        match: false,
        latencyMs: Date.now() - start,
        status: 'FAIL',
        message: `Proxy connection test failed: ${err.message}`,
      };
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 9. POOL STATUS SUMMARY
  // ─────────────────────────────────────────────────────────────────────────────
  async getPoolStatus(): Promise<any> {
    const [totalIps, availableIps, activeAssignments, poolList] = await Promise.all([
      this.prisma.ipPool.count(),
      this.prisma.ipPool.count({ where: { status: 'AVAILABLE' } }),
      this.prisma.userIpAssignment.count({ where: { status: 'ACTIVE' } }),
      this.prisma.ipPool.findMany({
        take: 50,
        orderBy: { createdAt: 'desc' },
      }),
    ]);

    return {
      totalIps,
      availableIps,
      activeAssignments,
      pool: poolList,
    };
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // REDIS CACHE HELPER
  // ─────────────────────────────────────────────────────────────────────────────
  private async cacheCredentialsInRedis(userId: string, creds: UserEgressCredentials): Promise<void> {
    if (this.redisService.isHealthy()) {
      try {
        const key = RedisKeys.userEgress(userId);
        // Cache for 24 hours
        await this.redisService.getClient().set(key, JSON.stringify(creds), 'EX', 86400);
        this.logger.debug(`[EgressService] Cached egress credentials in Redis for user ${userId}`);
      } catch (err: any) {
        this.logger.warn(`[EgressService] Failed to cache credentials in Redis for user ${userId}: ${err.message}`);
      }
    }
  }
}
