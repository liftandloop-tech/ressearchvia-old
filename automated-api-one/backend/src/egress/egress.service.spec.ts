import { Test, TestingModule } from '@nestjs/testing';
import { EgressService } from './egress.service';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma.service';
import { RedisService } from '../infrastructure/redis/redis.service';
import { of, throwError } from 'rxjs';

describe('EgressService', () => {
  let service: EgressService;
  let httpService: jest.Mocked<HttpService>;
  let prismaService: any;
  let redisService: any;
  let mockRedisClient: any;

  beforeEach(async () => {
    mockRedisClient = {
      get: jest.fn().mockResolvedValue(null),
      set: jest.fn().mockResolvedValue('OK'),
      del: jest.fn().mockResolvedValue(1),
    };

    httpService = {
      post: jest.fn(),
      get: jest.fn(),
    } as any;

    prismaService = {
      userIpAssignment: {
        findFirst: jest.fn().mockResolvedValue(null),
        count: jest.fn().mockResolvedValue(2),
      },
      ipPool: {
        count: jest.fn().mockResolvedValue(10),
        findMany: jest.fn().mockResolvedValue([]),
      },
    };

    redisService = {
      isHealthy: jest.fn().mockReturnValue(true),
      getClient: jest.fn().mockReturnValue(mockRedisClient),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        EgressService,
        { provide: HttpService, useValue: httpService },
        {
          provide: ConfigService,
          useValue: {
            get: jest.fn((key: string, defaultVal?: any) => {
              if (key === 'EGRESS_MANAGER_URL') return 'http://localhost:8080';
              if (key === 'EGRESS_PROXY_HOST') return 'localhost';
              if (key === 'EGRESS_PROXY_PORT') return 8888;
              return defaultVal;
            }),
          },
        },
        { provide: PrismaService, useValue: prismaService },
        { provide: RedisService, useValue: redisService },
      ],
    }).compile();

    service = module.get<EgressService>(EgressService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('allocateEgress', () => {
    it('should successfully allocate egress and cache in Redis', async () => {
      const mockResponse = {
        data: {
          success: true,
          assignmentId: 'assign-123',
          proxyUsername: 'egress_assign-123',
          token: 'token_abc_123',
          publicIp: '103.10.10.1',
        },
      };
      httpService.post.mockReturnValue(of(mockResponse as any));

      const res = await service.allocateEgress('user-1');

      expect(res.publicIp).toBe('103.10.10.1');
      expect(res.proxyUsername).toBe('egress_assign-123');
      expect(res.token).toBe('token_abc_123');
      expect(mockRedisClient.set).toHaveBeenCalledWith(
        'egress:user:user-1',
        expect.stringContaining('103.10.10.1'),
        'EX',
        86400,
      );
    });

    it('should rotate token if user already has assignment (409 conflict)', async () => {
      const conflictErr = {
        response: { status: 409, data: { message: 'User already has assignment' } },
      };
      const rotateResponse = {
        data: {
          success: true,
          username: 'egress_assign-123',
          token: 'rotated_token',
          publicIp: '103.10.10.1',
        },
      };

      httpService.post
        .mockReturnValueOnce(throwError(() => conflictErr))
        .mockReturnValueOnce(of(rotateResponse as any));

      const res = await service.allocateEgress('user-1');

      expect(res.publicIp).toBe('103.10.10.1');
      expect(res.token).toBe('rotated_token');
    });
  });

  describe('getOrCreateUserEgress', () => {
    it('should return cached credentials from Redis when present', async () => {
      const cached = {
        assignmentId: 'assign-123',
        proxyUsername: 'egress_assign-123',
        token: 'token_from_redis',
        publicIp: '103.10.10.1',
        proxyHost: 'localhost',
        proxyPort: 8888,
      };
      mockRedisClient.get.mockResolvedValue(JSON.stringify(cached));

      const res = await service.getOrCreateUserEgress('user-1');

      expect(res.token).toBe('token_from_redis');
      expect(httpService.post).not.toHaveBeenCalled();
    });

    it('should rotate token if active in DB but missing from Redis', async () => {
      mockRedisClient.get.mockResolvedValue(null);
      prismaService.userIpAssignment.findFirst.mockResolvedValue({
        id: 'assign-123',
        status: 'ACTIVE',
        ipPool: { publicIp: '103.10.10.1' },
      });

      const rotateResponse = {
        data: {
          success: true,
          username: 'egress_assign-123',
          token: 'new_token',
          publicIp: '103.10.10.1',
        },
      };
      httpService.post.mockReturnValue(of(rotateResponse as any));

      const res = await service.getOrCreateUserEgress('user-1');

      expect(res.token).toBe('new_token');
      expect(httpService.post).toHaveBeenCalledWith(
        'http://localhost:8080/internal/egress/rotate-token',
        { userId: 'user-1' },
        expect.any(Object),
      );
    });
  });

  describe('getProxyAgentForUser', () => {
    it('should return an HttpsProxyAgent configured with user proxy credentials', async () => {
      const cached = {
        proxyUsername: 'egress_user1',
        token: 'secret_token_123',
        publicIp: '103.10.10.1',
        proxyHost: 'localhost',
        proxyPort: 8888,
      };
      mockRedisClient.get.mockResolvedValue(JSON.stringify(cached));

      const agent = await service.getProxyAgentForUser('user-1');

      expect(agent).toBeDefined();
      expect(agent?.proxy?.hostname).toBe('localhost');
      expect(agent?.proxy?.port).toBe('8888');
      expect(agent?.proxy?.username).toBe('egress_user1');
      expect(agent?.proxy?.password).toBe('secret_token_123');
    });
  });

  describe('releaseEgress', () => {
    it('should call egress-manager release endpoint and clear Redis cache', async () => {
      httpService.post.mockReturnValue(of({ data: { success: true } } as any));

      const res = await service.releaseEgress('user-1');

      expect(res).toBe(true);
      expect(mockRedisClient.del).toHaveBeenCalledWith('egress:user:user-1');
    });
  });
});
