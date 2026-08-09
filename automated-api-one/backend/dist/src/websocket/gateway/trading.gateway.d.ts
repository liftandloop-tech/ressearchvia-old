import { OnGatewayConnection, OnGatewayDisconnect } from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { PrismaService } from '../../prisma.service';
import { MetricsService } from '../../infrastructure/metrics/metrics.service';
export declare class TradingGateway implements OnGatewayConnection, OnGatewayDisconnect {
    private readonly jwtService;
    private readonly redisService;
    private readonly prisma;
    private readonly metrics;
    private readonly logger;
    server: Server;
    constructor(jwtService: JwtService, redisService: RedisService, prisma: PrismaService, metrics: MetricsService);
    handleConnection(socket: Socket): Promise<void>;
    handleDisconnect(socket: Socket): Promise<void>;
    handleHeartbeat(socket: Socket): Promise<void>;
    handleJoinSegment(socket: Socket, data: {
        segmentId: string;
    }): Promise<void>;
    private extractToken;
    private checkConnectionRateLimit;
    private addPresence;
    private removePresence;
    private refreshPresenceTTL;
    private updateMetricsGauges;
}
