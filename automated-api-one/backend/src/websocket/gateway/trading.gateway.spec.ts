import { Test, TestingModule } from '@nestjs/testing';
import { TradingGateway } from './trading.gateway';
import { JwtService } from '@nestjs/jwt';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { PrismaService } from '../../prisma.service';
import { MetricsService } from '../../infrastructure/metrics/metrics.service';
import { UserSegmentStatus } from '@prisma/client';

describe('TradingGateway', () => {
  let gateway: TradingGateway;
  let jwtServiceMock: any;
  let redisServiceMock: any;
  let prismaMock: any;
  let metricsMock: any;
  let socketMock: any;
  let redisClientMock: any;

  beforeEach(async () => {
    jwtServiceMock = {
      verifyAsync: jest.fn(),
    };

    redisClientMock = {
      incr: jest.fn(),
      expire: jest.fn(),
      get: jest.fn(),
      set: jest.fn(),
      del: jest.fn(),
    };

    redisServiceMock = {
      isHealthy: jest.fn().mockReturnValue(true),
      getClient: jest.fn().mockReturnValue(redisClientMock),
    };

    prismaMock = {
      userSegment: {
        findUnique: jest.fn(),
      },
    };

    metricsMock = {
      incrementWsConnections: jest.fn(),
      incrementWsDisconnects: jest.fn(),
      setWsActiveConnections: jest.fn(),
      setWsRoomUsers: jest.fn(),
      setWsRoomSegments: jest.fn(),
      setWsRoomAdmin: jest.fn(),
    };

    socketMock = {
      id: 'socket-123',
      handshake: {
        address: '127.0.0.1',
        headers: {},
        query: {},
      },
      data: {},
      disconnect: jest.fn(),
      join: jest.fn(),
      emit: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        TradingGateway,
        { provide: JwtService, useValue: jwtServiceMock },
        { provide: RedisService, useValue: redisServiceMock },
        { provide: PrismaService, useValue: prismaMock },
        { provide: MetricsService, useValue: metricsMock },
      ],
    }).compile();

    gateway = module.get<TradingGateway>(TradingGateway);
    gateway.server = {
      engine: { clientsCount: 1 },
      sockets: {
        adapter: {
          rooms: new Map(),
        },
      },
    } as any;
  });

  it('should be defined', () => {
    expect(gateway).toBeDefined();
  });

  describe('handleConnection', () => {
    it('should reject connection if rate limit is exceeded', async () => {
      redisClientMock.incr.mockResolvedValue(25); // rate limit 20 exceeded
      await gateway.handleConnection(socketMock);
      expect(socketMock.disconnect).toHaveBeenCalledWith(true);
    });

    it('should reject connection if token is missing', async () => {
      redisClientMock.incr.mockResolvedValue(1);
      await gateway.handleConnection(socketMock);
      expect(socketMock.disconnect).toHaveBeenCalledWith(true);
    });

    it('should authenticate, join rooms, and update presence on successful connection', async () => {
      redisClientMock.incr.mockResolvedValue(1);
      socketMock.handshake.query.token = 'valid-token';
      jwtServiceMock.verifyAsync.mockResolvedValue({ userId: 'user-456', role: 'ADMIN' });

      await gateway.handleConnection(socketMock);

      expect(socketMock.join).toHaveBeenCalledWith('user:user-456');
      expect(socketMock.join).toHaveBeenCalledWith('admin');
      expect(redisClientMock.set).toHaveBeenCalled();
      expect(metricsMock.incrementWsConnections).toHaveBeenCalled();
    });
  });

  describe('handleJoinSegment', () => {
    it('should join the segment room if user is authorized', async () => {
      socketMock.data = { userId: 'user-123' };
      prismaMock.userSegment.findUnique.mockResolvedValue({
        userId: 'user-123',
        segmentId: 'seg-1',
        status: UserSegmentStatus.ACTIVE,
      });

      await gateway.handleJoinSegment(socketMock, { segmentId: 'seg-1' });

      expect(socketMock.join).toHaveBeenCalledWith('segment:seg-1');
      expect(socketMock.emit).toHaveBeenCalledWith('joined_segment', { segmentId: 'seg-1' });
    });

    it('should emit error and reject if segment status is not ACTIVE', async () => {
      socketMock.data = { userId: 'user-123' };
      prismaMock.userSegment.findUnique.mockResolvedValue({
        userId: 'user-123',
        segmentId: 'seg-1',
        status: UserSegmentStatus.INACTIVE,
      });

      await gateway.handleJoinSegment(socketMock, { segmentId: 'seg-1' });

      expect(socketMock.join).not.toHaveBeenCalled();
      expect(socketMock.emit).toHaveBeenCalledWith('error', expect.any(Object));
    });
  });
});
