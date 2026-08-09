import { Test, TestingModule } from '@nestjs/testing';
import { WebsocketService } from './websocket.service';
import { TradingGateway } from '../gateway/trading.gateway';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { MetricsService } from '../../infrastructure/metrics/metrics.service';
import { WebsocketEvent } from '../enums/websocket-event.enum';

describe('WebsocketService', () => {
  let service: WebsocketService;
  let gatewayMock: any;
  let redisServiceMock: any;
  let redisClientMock: any;
  let metricsMock: any;

  beforeEach(async () => {
    gatewayMock = {
      server: {
        to: jest.fn().mockReturnThis(),
        emit: jest.fn(),
      },
    };

    redisClientMock = {
      set: jest.fn(),
    };

    redisServiceMock = {
      isHealthy: jest.fn().mockReturnValue(true),
      getClient: jest.fn().mockReturnValue(redisClientMock),
    };

    metricsMock = {
      incrementWsMessagesSent: jest.fn(),
      incrementWsMessagesFailed: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        WebsocketService,
        { provide: TradingGateway, useValue: gatewayMock },
        { provide: RedisService, useValue: redisServiceMock },
        { provide: MetricsService, useValue: metricsMock },
      ],
    }).compile();

    service = module.get<WebsocketService>(WebsocketService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('broadcast', () => {
    it('should reject non-whitelisted events sent to the admin room', async () => {
      const result = await service.broadcast(
        'event-123',
        WebsocketEvent.ORDER_EXECUTED, // Not in admin whitelist
        'admin',
        { orderId: 'ord-1' },
      );

      expect(result).toBe(false);
      expect(gatewayMock.server.emit).not.toHaveBeenCalled();
      expect(metricsMock.incrementWsMessagesFailed).toHaveBeenCalled();
    });

    it('should accept whitelisted events sent to the admin room', async () => {
      redisClientMock.set.mockResolvedValue('OK'); // Idempotency check pass
      const result = await service.broadcast(
        'event-123',
        'segment.risk.locked' as any, // Whitelisted
        'admin',
        { reason: 'loss threshold' },
      );

      expect(result).toBe(true);
      expect(gatewayMock.server.to).toHaveBeenCalledWith('admin');
      expect(gatewayMock.server.emit).toHaveBeenCalled();
    });

    it('should apply idempotency key checking', async () => {
      redisClientMock.set.mockResolvedValue(null); // Already exists

      const result = await service.broadcast(
        'event-123',
        WebsocketEvent.ORDER_EXECUTED,
        'user:user-1',
        { orderId: 'ord-1' },
      );

      expect(result).toBe(false);
      expect(gatewayMock.server.emit).not.toHaveBeenCalled();
    });
  });
});
