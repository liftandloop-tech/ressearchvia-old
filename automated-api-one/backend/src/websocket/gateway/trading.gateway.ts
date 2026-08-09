import {
  WebSocketGateway,
  WebSocketServer,
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Logger, UseGuards } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { PrismaService } from '../../prisma.service';
import { MetricsService } from '../../infrastructure/metrics/metrics.service';
import { UserSegmentStatus } from '@prisma/client';

@WebSocketGateway({
  cors: {
    origin: '*',
  },
})
export class TradingGateway implements OnGatewayConnection, OnGatewayDisconnect {
  private readonly logger = new Logger(TradingGateway.name);

  @WebSocketServer()
  server!: Server;

  constructor(
    private readonly jwtService: JwtService,
    private readonly redisService: RedisService,
    private readonly prisma: PrismaService,
    private readonly metrics: MetricsService,
  ) {}

  /**
   * Handshake authentication, connection rate limiting, and presence tracking.
   */
  async handleConnection(socket: Socket) {
    const ip = socket.handshake.address || socket.conn.remoteAddress || 'unknown';

    // 1. Connection Rate Limiting
    const isAllowed = await this.checkConnectionRateLimit(ip);
    if (!isAllowed) {
      this.logger.warn(`Connection rejected due to rate limit: IP=${ip}`);
      socket.disconnect(true);
      return;
    }

    // 2. JWT Handshake Authentication
    const token = this.extractToken(socket);
    if (!token) {
      this.logger.warn(`Authentication failed: No token provided from IP=${ip}`);
      socket.disconnect(true);
      return;
    }

    try {
      const payload = await this.jwtService.verifyAsync(token);
      socket.data = {
        userId: payload.userId || payload.sub,
        role: payload.role,
        ip,
        appVersion: socket.handshake.query.appVersion || '1.0.0',
        platform: socket.handshake.query.platform || 'web',
      };

      const userId = socket.data.userId;

      // 3. User Room Join
      await socket.join(`user:${userId}`);

      // If user is Admin, join admin room automatically (or allow it)
      if (socket.data.role === 'SUPERADMIN' || socket.data.role === 'ADMIN') {
        await socket.join('admin');
      }

      // 4. Redis Presence Tracking
      await this.addPresence(userId, socket.id, socket.data.appVersion, socket.data.platform);

      this.metrics.incrementWsConnections();
      this.updateMetricsGauges();

      this.logger.log(`Client connected: Socket=${socket.id} User=${userId} IP=${ip}`);
    } catch (err: any) {
      this.logger.warn(`Authentication failed for IP=${ip}: ${err.message}`);
      socket.disconnect(true);
    }
  }

  /**
   * Presence cleanup and metric updates on client disconnect.
   */
  async handleDisconnect(socket: Socket) {
    const userId = socket.data?.userId;
    if (userId) {
      await this.removePresence(userId, socket.id);
      this.metrics.incrementWsDisconnects();
      this.updateMetricsGauges();
      this.logger.log(`Client disconnected: Socket=${socket.id} User=${userId}`);
    }
  }

  /**
   * Heartbeat handler: client calls this periodically to keep session alive.
   */
  @SubscribeMessage('heartbeat')
  async handleHeartbeat(@ConnectedSocket() socket: Socket) {
    const userId = socket.data?.userId;
    if (userId) {
      await this.refreshPresenceTTL(userId);
      socket.emit('heartbeat_ack', { timestamp: new Date().toISOString() });
    }
  }

  /**
   * Secure Segment Room joining. Verification of user segment entitlement is required.
   */
  @SubscribeMessage('join_segment')
  async handleJoinSegment(
    @ConnectedSocket() socket: Socket,
    @MessageBody() data: { segmentId: string },
  ) {
    const userId = socket.data?.userId;
    if (!userId) {
      socket.emit('error', { message: 'Unauthorized' });
      return;
    }

    const { segmentId } = data;

    // Verify user is allocated to segment and status is ACTIVE
    const userSegment = await this.prisma.userSegment.findUnique({
      where: {
        userId_segmentId: {
          userId,
          segmentId,
        },
      },
    });

    if (!userSegment || userSegment.status !== UserSegmentStatus.ACTIVE) {
      this.logger.warn(`Unauthorized segment join attempt: User=${userId} Segment=${segmentId}`);
      socket.emit('error', { message: 'Unauthorized to join segment room' });
      return;
    }

    const roomName = `segment:${segmentId}`;
    await socket.join(roomName);
    this.logger.log(`User ${userId} joined room ${roomName}`);
    socket.emit('joined_segment', { segmentId });
    this.updateMetricsGauges();
  }

  // ==========================================
  // Helper Methods
  // ==========================================

  private extractToken(socket: Socket): string | null {
    const authHeader = socket.handshake.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      return authHeader.split(' ')[1];
    }
    const tokenQuery = socket.handshake.query.token;
    if (tokenQuery) {
      return Array.isArray(tokenQuery) ? tokenQuery[0] : tokenQuery;
    }
    return null;
  }

  private async checkConnectionRateLimit(ip: string): Promise<boolean> {
    if (!this.redisService.isHealthy()) return true; // Fail open for rate limiting if Redis is down

    const redisKey = `ws:ratelimit:${ip}`;
    try {
      const client = this.redisService.getClient();
      const current = await client.incr(redisKey);
      if (current === 1) {
        await client.expire(redisKey, 60); // 1 minute window
      }
      return current <= 20; // 20 connections per minute
    } catch (err: any) {
      this.logger.error(`Failed to execute rate limit check for IP ${ip}: ${err.message}`);
      return true;
    }
  }

  private async addPresence(userId: string, socketId: string, appVersion: string, platform: string) {
    if (!this.redisService.isHealthy()) return;

    const redisKey = `ws:user:${userId}`;
    try {
      const client = this.redisService.getClient();
      const existing = await client.get(redisKey);

      let presence = {
        connections: 0,
        connectedAt: new Date().toISOString(),
        lastSeen: new Date().toISOString(),
        socketIds: [] as string[],
        appVersion,
        platform,
      };

      if (existing) {
        try {
          presence = JSON.parse(existing);
        } catch {
          // Reset malformed json
        }
      }

      presence.connections++;
      presence.lastSeen = new Date().toISOString();
      if (!presence.socketIds.includes(socketId)) {
        presence.socketIds.push(socketId);
      }

      await client.set(redisKey, JSON.stringify(presence), 'EX', 120); // 2 minutes TTL
    } catch (err: any) {
      this.logger.error(`Presence tracking error for User ${userId}: ${err.message}`);
    }
  }

  private async removePresence(userId: string, socketId: string) {
    if (!this.redisService.isHealthy()) return;

    const redisKey = `ws:user:${userId}`;
    try {
      const client = this.redisService.getClient();
      const existing = await client.get(redisKey);
      if (!existing) return;

      const presence = JSON.parse(existing);
      presence.connections = Math.max(0, presence.connections - 1);
      presence.socketIds = presence.socketIds.filter((id: string) => id !== socketId);
      presence.lastSeen = new Date().toISOString();

      if (presence.connections === 0 || presence.socketIds.length === 0) {
        await client.del(redisKey);
      } else {
        await client.set(redisKey, JSON.stringify(presence), 'EX', 120);
      }
    } catch (err: any) {
      this.logger.error(`Presence removal error for User ${userId}: ${err.message}`);
    }
  }

  private async refreshPresenceTTL(userId: string) {
    if (!this.redisService.isHealthy()) return;

    const redisKey = `ws:user:${userId}`;
    try {
      const client = this.redisService.getClient();
      const existing = await client.get(redisKey);
      if (existing) {
        const presence = JSON.parse(existing);
        presence.lastSeen = new Date().toISOString();
        await client.set(redisKey, JSON.stringify(presence), 'EX', 120);
      }
    } catch (err: any) {
      this.logger.error(`Presence refresh error for User ${userId}: ${err.message}`);
    }
  }

  private updateMetricsGauges() {
    try {
      const adapter = this.server?.sockets?.adapter;
      if (!adapter) return;

      const roomMap = adapter.rooms;
      let userCount = 0;
      let segmentCount = 0;
      let adminCount = 0;

      for (const [roomName, socketsSet] of roomMap.entries()) {
        if (roomName.startsWith('user:')) {
          userCount++;
        } else if (roomName.startsWith('segment:')) {
          segmentCount++;
        } else if (roomName === 'admin') {
          adminCount = socketsSet.size;
        }
      }

      const activeConns = this.server?.engine?.clientsCount || 0;

      this.metrics.setWsActiveConnections(activeConns);
      this.metrics.setWsRoomUsers(userCount);
      this.metrics.setWsRoomSegments(segmentCount);
      this.metrics.setWsRoomAdmin(adminCount);
    } catch (err: any) {
      this.logger.error(`Failed to update socket room gauges: ${err.message}`);
    }
  }
}
