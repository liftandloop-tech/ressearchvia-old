import {
  Injectable,
  Logger,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma.service';
import { BrokerFactory } from '../factory/broker.factory';
import { BrokerCode } from '@prisma/client';
import { BrokerType } from '../interfaces/broker-type.enum';
import { SessionResponse } from '../interfaces/broker-client.interface';
import { AuditService } from '../../audit/audit.service';
import { AuditEventType } from '../../audit/enums/audit-event.enum';
import { Cron, CronExpression } from '@nestjs/schedule';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { RedisKeys } from '../../infrastructure/redis/redis-keys';
import { Optional } from '@nestjs/common';
import { EgressService } from '../../egress/egress.service';

@Injectable()
export class BrokerSessionService {
  private readonly logger = new Logger(BrokerSessionService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly brokerFactory: BrokerFactory,
    private readonly auditService: AuditService,
    private readonly redisService: RedisService,
    @Optional() private readonly egressService?: EgressService,
  ) {}

  async storeSession(
    userId: string,
    brokerCode: BrokerCode,
    session: SessionResponse,
    userBrokerId: string,
  ): Promise<void> {
    // Persist to DB
    const updatedBroker = await this.prisma.userBroker.update({
      where: { id: userBrokerId },
      data: {
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        tokenExpiry: session.tokenExpiry,
      },
      select: { brokerId: true },
    });

    // Ensure Egress IP allocation is ready and cached
    let egressCreds: any = null;
    if (this.egressService) {
      try {
        egressCreds = await this.egressService.getOrCreateUserEgress(userId);
        this.logger.log(`[BrokerSession] Egress IP ${egressCreds.publicIp} verified for user ${userId}`);
      } catch (eErr: any) {
        this.logger.warn(`[BrokerSession] Egress preparation notice for user ${userId}: ${eErr.message}`);
      }
    }

    // Write to Redis so resolveBrokerToken finds the token immediately
    if (this.redisService.isHealthy() && session.accessToken) {
      try {
        const fullBroker = await this.prisma.userBroker.findUnique({
          where: { id: userBrokerId },
        });

        const sessionKey = RedisKeys.brokerSession(userId, updatedBroker.brokerId);
        const payload = JSON.stringify({
          accessToken: session.accessToken,
          proxyIp: egressCreds?.publicIp || fullBroker?.proxyIp || null,
          proxyPort: egressCreds?.proxyPort || fullBroker?.proxyPort || null,
          proxyUsername: egressCreds?.proxyUsername || fullBroker?.proxyUsername || null,
          proxyPassword: egressCreds?.token || fullBroker?.proxyPassword || null,
          proxyHostname: egressCreds?.proxyHost || fullBroker?.proxyHostname || null,
        });
        // TTL: seconds until midnight IST (expires with session)
        const midnightIst = new Date();
        midnightIst.setUTCHours(18, 30, 0, 0); // midnight IST = 18:30 UTC
        if (midnightIst < new Date()) midnightIst.setUTCDate(midnightIst.getUTCDate() + 1);
        const ttlSeconds = Math.floor((midnightIst.getTime() - Date.now()) / 1000);
        await this.redisService.getClient().set(sessionKey, payload, 'EX', ttlSeconds);
        this.logger.log(`[BrokerSession] Cached token and proxy credentials for user ${userId} in Redis (TTL: ${ttlSeconds}s)`);
      } catch (err) {
        this.logger.warn(`[BrokerSession] Redis write failed for user ${userId}: ${err.message}`);
      }
    }

    await this.auditService.logEvent(
      userId,
      AuditEventType.BROKER_CONNECTED,
      'UserBroker',
      userBrokerId,
      {
        brokerCode,
        userBrokerId,
        tokenExpiry: session.tokenExpiry,
      },
    );
  }

  async refreshSession(
    userId: string,
    brokerCode: BrokerCode,
  ): Promise<SessionResponse> {
    const broker = await this.prisma.broker.findFirst({
      where: { code: brokerCode },
    });
    if (!broker) {
      throw new NotFoundException(`Broker ${brokerCode} not found in database`);
    }

    const userBroker = await this.prisma.userBroker.findFirst({
      where: { userId, brokerId: broker.id },
    });

    if (!userBroker || !userBroker.accessToken || !userBroker.refreshToken) {
      throw new BadRequestException('No active broker session to refresh');
    }

    const brokerType = brokerCode as unknown as BrokerType;
    const adapter = this.brokerFactory.getAdapter(brokerType);

    try {
      const newSession = await adapter.refreshSession(
        userBroker.accessToken,
        userBroker.refreshToken,
      );

      await this.prisma.userBroker.update({
        where: { id: userBroker.id },
        data: {
          accessToken: newSession.accessToken,
          refreshToken: newSession.refreshToken,
          tokenExpiry: newSession.tokenExpiry,
        },
      });

      await this.auditService.logEvent(
        userId,
        AuditEventType.BROKER_SESSION_REFRESHED,
        'UserBroker',
        userBroker.id,
        {
          brokerCode,
          userBrokerId: userBroker.id,
          tokenExpiry: newSession.tokenExpiry,
        },
      );

      return newSession;
    } catch (error) {
      this.logger.error(
        `Broker session refresh failed for user ${userId}: ${error.message}`,
      );

      await this.auditService.logEvent(
        userId,
        AuditEventType.BROKER_SESSION_FAILED,
        'UserBroker',
        userBroker.id,
        {
          brokerCode,
          userBrokerId: userBroker.id,
          error: error.message,
        },
      );

      throw error;
    }
  }

  async invalidateSession(
    userId: string,
    brokerCode: BrokerCode,
  ): Promise<void> {
    const broker = await this.prisma.broker.findFirst({
      where: { code: brokerCode },
    });
    if (!broker) return;

    const userBroker = await this.prisma.userBroker.findFirst({
      where: { userId, brokerId: broker.id },
    });

    if (!userBroker) return;

    // Clear Redis cache so resolveBrokerToken immediately sees no session
    if (this.redisService.isHealthy()) {
      try {
        const sessionKey = RedisKeys.brokerSession(userId, broker.id);
        await this.redisService.getClient().del(sessionKey);
        this.logger.log(`[BrokerSession] Cleared Redis cache for user ${userId} broker ${brokerCode}`);
      } catch (err) {
        this.logger.warn(`[BrokerSession] Redis clear failed for user ${userId}: ${err.message}`);
      }
    }

    await this.prisma.userBroker.update({
      where: { id: userBroker.id },
      data: {
        accessToken: null,
        refreshToken: null,
        tokenExpiry: null,
      },
    });

    await this.auditService.logEvent(
      userId,
      AuditEventType.BROKER_DISCONNECTED,
      'UserBroker',
      userBroker.id,
      {
        brokerCode,
        userBrokerId: userBroker.id,
      },
    );
  }

  isSessionExpired(tokenExpiry: Date | null): boolean {
    if (!tokenExpiry) return true;
    return new Date() > tokenExpiry;
  }

  async validateSession(
    userId: string,
    brokerCode: BrokerCode,
  ): Promise<boolean> {
    const broker = await this.prisma.broker.findFirst({
      where: { code: brokerCode },
    });
    if (!broker) return false;

    const userBroker = await this.prisma.userBroker.findFirst({
      where: { userId, brokerId: broker.id },
    });

    if (!userBroker) return false;

    const isExpired = this.isSessionExpired(userBroker.tokenExpiry);

    if (isExpired && userBroker.accessToken) {
      // Invalidate in DB and log BROKER_SESSION_EXPIRED
      await this.prisma.userBroker.update({
        where: { id: userBroker.id },
        data: {
          accessToken: null,
          refreshToken: null,
          tokenExpiry: null,
        },
      });

      await this.auditService.logEvent(
        userId,
        AuditEventType.BROKER_SESSION_EXPIRED,
        'UserBroker',
        userBroker.id,
        {
          brokerCode,
          expiredAt: userBroker.tokenExpiry,
        },
      );

      return false;
    }

    if (!userBroker.accessToken) {
      return false;
    }

    const brokerType = brokerCode as unknown as BrokerType;
    const adapter = this.brokerFactory.getAdapter(brokerType);
    return adapter.validateSession(userBroker.accessToken);
  }

  @Cron(CronExpression.EVERY_HOUR)
  async cleanupExpiredAuthStates(): Promise<void> {
    this.logger.log('Cleaning up expired broker auth state records...');
    const result = await this.prisma.brokerAuthState.deleteMany({
      where: {
        expiresAt: {
          lt: new Date(),
        },
      },
    });
    if (result.count > 0) {
      this.logger.log(`Pruned ${result.count} expired auth state records.`);
    }
  }
}
