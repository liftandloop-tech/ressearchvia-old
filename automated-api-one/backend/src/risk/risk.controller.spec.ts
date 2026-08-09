import { Test, TestingModule } from '@nestjs/testing';
import { RiskController } from './risk.controller';
import { RiskService } from './risk.service';

describe('RiskController', () => {
  let controller: RiskController;
  let serviceMock: any;

  beforeEach(async () => {
    serviceMock = {
      getRiskStatusForSegment: jest.fn(),
      getRiskEventsForSegment: jest.fn(),
      unlockSegment: jest.fn(),
      getRiskEvents: jest.fn(),
      getRiskStatus: jest.fn(),
      resetRiskLock: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [RiskController],
      providers: [
        {
          provide: RiskService,
          useValue: serviceMock,
        },
      ],
    }).compile();

    controller = module.get<RiskController>(RiskController);
  });

  describe('getStatusForSegment', () => {
    it('should fetch status check payload for a specific segment', async () => {
      const req = { user: { userId: 'user-id' } };
      serviceMock.getRiskStatusForSegment.mockResolvedValue({ locked: false });

      const result = await controller.getStatusForSegment(req, 'strat-123');
      expect(result).toEqual({ locked: false });
      expect(serviceMock.getRiskStatusForSegment).toHaveBeenCalledWith(
        'user-id',
        'strat-123',
      );
    });
  });

  describe('getEventsForSegment', () => {
    it('should fetch paginated events for a specific segment', async () => {
      const req = { user: { userId: 'user-id' } };
      serviceMock.getRiskEventsForSegment.mockResolvedValue({ data: [] });

      const result = await controller.getEventsForSegment(req, 'strat-123', {
        page: 2,
        limit: 10,
      });
      expect(result).toEqual({ data: [] });
      expect(serviceMock.getRiskEventsForSegment).toHaveBeenCalledWith(
        'user-id',
        'strat-123',
        2,
        10,
      );
    });
  });

  describe('unlockSegment', () => {
    it('should unlock strategy and pass owner flags if user is owner', async () => {
      const req = { user: { userId: 'user-id', role: 'USER' } };
      serviceMock.unlockSegment.mockResolvedValue({ status: 'ACTIVE' });

      const result = await controller.unlockSegment(req, 'strat-123', {});
      expect(result).toEqual({ status: 'ACTIVE' });
      expect(serviceMock.unlockSegment).toHaveBeenCalledWith(
        'user-id',
        'strat-123',
        undefined,
        false,
      );
    });

    it('should pass targetUserId and isAdmin flag if user is admin', async () => {
      const req = { user: { userId: 'admin-id', role: 'ADMIN' } };
      serviceMock.unlockSegment.mockResolvedValue({ status: 'ACTIVE' });

      const result = await controller.unlockSegment(req, 'strat-123', {
        targetUserId: 'target-user',
      });
      expect(result).toEqual({ status: 'ACTIVE' });
      expect(serviceMock.unlockSegment).toHaveBeenCalledWith(
        'admin-id',
        'strat-123',
        'target-user',
        true,
      );
    });
  });

  describe('Legacy Endpoints', () => {
    it('should call getRiskEvents on GET /events', async () => {
      const req = { user: { userId: 'user-id' } };
      serviceMock.getRiskEvents.mockResolvedValue({ data: [] });

      const result = await controller.getEvents(req, { limit: 10, offset: 0 });
      expect(result).toEqual({ data: [] });
      expect(serviceMock.getRiskEvents).toHaveBeenCalledWith('user-id', 10, 0);
    });

    it('should call getRiskStatus on GET /status', async () => {
      const req = { user: { userId: 'user-id' } };
      serviceMock.getRiskStatus.mockResolvedValue([]);

      const result = await controller.getStatus(req);
      expect(result).toEqual([]);
      expect(serviceMock.getRiskStatus).toHaveBeenCalledWith('user-id');
    });

    it('should call resetRiskLock on POST /reset', async () => {
      const req = { user: { userId: 'user-id' } };
      serviceMock.resetRiskLock.mockResolvedValue({});

      const result = await controller.resetLock(req, {
        segmentId: 'strat-123',
      });
      expect(result).toEqual({});
      expect(serviceMock.resetRiskLock).toHaveBeenCalledWith(
        'user-id',
        'strat-123',
      );
    });
  });
});
