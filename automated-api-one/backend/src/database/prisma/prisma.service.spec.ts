import { Test, TestingModule } from '@nestjs/testing';
import { PrismaService } from './prisma.service';

jest.mock('@prisma/client', () => {
  const mockUser = {
    findActive: jest.fn().mockResolvedValue([]),
  };
  const mockTrade = {
    findMany: jest.fn().mockResolvedValue([]),
  };
  return {
    PrismaClient: jest.fn().mockImplementation(() => {
      return {
        $connect: jest.fn().mockResolvedValue(undefined),
        $disconnect: jest.fn().mockResolvedValue(undefined),
        $extends: jest.fn().mockReturnValue({
          user: mockUser,
          segmentMaster: {},
          userSegment: {},
          userBroker: {},
          userDevice: {},
          broker: {},
          subscription: {},
          consent: {},
          signal: {},
          trade: mockTrade,
          order: {},
          position: {},
          segmentMultiplier: {},
          riskEvent: {},
          notification: {},
          auditLog: {},
          adminUser: {},
          analyst: {},
          report: {},
          outboxEvent: {},
          brokerSession: {},
          idempotencyKey: {},
          queueJob: {},
          segmentExecution: {},
          $transaction: jest.fn(),
          $executeRaw: jest.fn(),
          $queryRaw: jest.fn(),
        }),
      };
    }),
  };
});

describe('PrismaService', () => {
  let service: PrismaService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [PrismaService],
    }).compile();

    service = module.get<PrismaService>(PrismaService);
  });

  it('should be defined and expose model getters', () => {
    expect(service).toBeDefined();
    expect(service.user).toBeDefined();
    expect(service.segmentMaster).toBeDefined();
    expect(service.userSegment).toBeDefined();
    expect(service.userBroker).toBeDefined();
    expect(service.userDevice).toBeDefined();
    expect(service.broker).toBeDefined();
    expect(service.subscription).toBeDefined();
    expect(service.consent).toBeDefined();
    expect(service.signal).toBeDefined();
    expect(service.trade).toBeDefined();
    expect(service.order).toBeDefined();
    expect(service.position).toBeDefined();
    expect(service.segmentMultiplier).toBeDefined();
    expect(service.riskEvent).toBeDefined();
    expect(service.notification).toBeDefined();
    expect(service.auditLog).toBeDefined();
    expect(service.adminUser).toBeDefined();
    expect(service.analyst).toBeDefined();
    expect(service.report).toBeDefined();
    expect(service.outboxEvent).toBeDefined();
    expect(service.brokerSession).toBeDefined();
    expect(service.idempotencyKey).toBeDefined();
    expect(service.queueJob).toBeDefined();
    expect(service.segmentExecution).toBeDefined();
    expect(service.baseClient).toBeDefined();
    expect(service.$transaction).toBeDefined();
    expect(service.$executeRaw).toBeDefined();
    expect(service.$queryRaw).toBeDefined();
  });

  describe('onModuleInit and onModuleDestroy', () => {
    it('should connect and disconnect from DB', async () => {
      const connectSpy = jest.spyOn(service.baseClient, '$connect');
      const disconnectSpy = jest.spyOn(service.baseClient, '$disconnect');

      await service.onModuleInit();
      expect(connectSpy).toHaveBeenCalled();

      await service.onModuleDestroy();
      expect(disconnectSpy).toHaveBeenCalled();
    });
  });

  describe('helper methods', () => {
    it('should query findActiveUsers and findTradesByUser', async () => {
      const findActiveSpy = jest.spyOn(
        service.client.user as any,
        'findActive',
      );
      const findManySpy = jest.spyOn(service.client.trade as any, 'findMany');

      await service.findActiveUsers();
      expect(findActiveSpy).toHaveBeenCalled();

      await service.findTradesByUser('user-1');
      expect(findManySpy).toHaveBeenCalledWith({ where: { userId: 'user-1' } });
    });
  });
});
