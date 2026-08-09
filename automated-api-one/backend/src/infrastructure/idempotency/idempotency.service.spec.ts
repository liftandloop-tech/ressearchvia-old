import { Test, TestingModule } from '@nestjs/testing';
import { IdempotencyService } from './idempotency.service';
import { RedisService } from '../redis/redis.service';
import { PrismaService } from '../../prisma.service';
import { IdempotencyStatus } from '@prisma/client';

describe('IdempotencyService', () => {
  let service: IdempotencyService;
  let redisService: RedisService;
  let prismaService: PrismaService;
  let clientMock: any;

  beforeEach(async () => {
    clientMock = {
      set: jest.fn(),
      del: jest.fn().mockResolvedValue(1),
    };

    const mockPrisma = {
      idempotencyKey: {
        create: jest.fn(),
        update: jest.fn(),
      },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        IdempotencyService,
        {
          provide: RedisService,
          useValue: {
            assertHealthy: jest.fn(),
            isHealthy: jest.fn().mockReturnValue(true),
            getClient: jest.fn().mockReturnValue(clientMock),
          },
        },
        {
          provide: PrismaService,
          useValue: mockPrisma,
        },
      ],
    }).compile();

    service = module.get<IdempotencyService>(IdempotencyService);
    redisService = module.get<RedisService>(RedisService);
    prismaService = module.get<PrismaService>(PrismaService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('checkAndLock', () => {
    it('should lock in Redis and save in DB on success', async () => {
      clientMock.set.mockResolvedValue('OK');
      const createSpy = jest.spyOn(prismaService.idempotencyKey, 'create').mockResolvedValue({} as any);

      const res = await service.checkAndLock('signal_123', 'SIGNAL', 86400);

      expect(res).toBe(true);
      expect(clientMock.set).toHaveBeenCalledWith('trade:idempotency:signal_123', '1', 'EX', 86400, 'NX');
      expect(createSpy).toHaveBeenCalledWith({
        data: {
          key: 'signal_123',
          type: 'SIGNAL',
          status: IdempotencyStatus.PENDING,
        },
      });
    });

    it('should return false if Redis SETNX returns null', async () => {
      clientMock.set.mockResolvedValue(null);

      const res = await service.checkAndLock('signal_123', 'SIGNAL', 86400);

      expect(res).toBe(false);
      expect(prismaService.idempotencyKey.create).not.toHaveBeenCalled();
    });

    it('should rollback Redis lock and return false on DB P2002 unique constraint failure', async () => {
      clientMock.set.mockResolvedValue('OK');
      const error: any = new Error('Unique constraint failed');
      error.code = 'P2002';
      jest.spyOn(prismaService.idempotencyKey, 'create').mockRejectedValue(error);

      const res = await service.checkAndLock('signal_123', 'SIGNAL', 86400);

      expect(res).toBe(false);
      expect(clientMock.del).toHaveBeenCalledWith('trade:idempotency:signal_123');
    });

    it('should rethrow other DB errors', async () => {
      clientMock.set.mockResolvedValue('OK');
      const error = new Error('Database down');
      jest.spyOn(prismaService.idempotencyKey, 'create').mockRejectedValue(error);

      await expect(service.checkAndLock('signal_123', 'SIGNAL', 86400)).rejects.toThrow('Database down');
    });
  });

  describe('updateStatus', () => {
    it('should update status in DB', async () => {
      const updateSpy = jest.spyOn(prismaService.idempotencyKey, 'update').mockResolvedValue({} as any);
      await service.updateStatus('signal_123', IdempotencyStatus.SUCCESS);
      expect(updateSpy).toHaveBeenCalledWith({
        where: { key: 'signal_123' },
        data: { status: IdempotencyStatus.SUCCESS },
      });
    });
  });
});
