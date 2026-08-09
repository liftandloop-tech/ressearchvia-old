import { Test, TestingModule } from '@nestjs/testing';
import { AnalyticsController } from './analytics.controller';
import { AnalyticsService } from './analytics.service';

describe('AnalyticsController', () => {
  let controller: AnalyticsController;
  let serviceMock: any;

  beforeEach(async () => {
    serviceMock = {
      getPortfolioPerformance: jest.fn(),
      getSegmentPerformance: jest.fn(),
      getBrokerPerformance: jest.fn(),
      enqueueRecalculation: jest.fn(),
      handleNightlyAnalyticsRecalculation: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [AnalyticsController],
      providers: [
        {
          provide: AnalyticsService,
          useValue: serviceMock,
        },
      ],
    }).compile();

    controller = module.get<AnalyticsController>(AnalyticsController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  describe('getPortfolio', () => {
    it('should call getPortfolioPerformance with user id', async () => {
      const req = { user: { userId: 'user-id-123' } };
      serviceMock.getPortfolioPerformance.mockResolvedValue({ status: 'success' });

      const result = await controller.getPortfolio(req);
      expect(result).toEqual({ status: 'success' });
      expect(serviceMock.getPortfolioPerformance).toHaveBeenCalledWith('user-id-123');
    });
  });

  describe('getSegments', () => {
    it('should call getSegmentPerformance with user id', async () => {
      const req = { user: { userId: 'user-id-123' } };
      serviceMock.getSegmentPerformance.mockResolvedValue([]);

      const result = await controller.getSegments(req);
      expect(result).toEqual([]);
      expect(serviceMock.getSegmentPerformance).toHaveBeenCalledWith('user-id-123');
    });
  });

  describe('getBrokers', () => {
    it('should call getBrokerPerformance with user id', async () => {
      const req = { user: { userId: 'user-id-123' } };
      serviceMock.getBrokerPerformance.mockResolvedValue([]);

      const result = await controller.getBrokers(req);
      expect(result).toEqual([]);
      expect(serviceMock.getBrokerPerformance).toHaveBeenCalledWith('user-id-123');
    });
  });

  describe('forceRecalculate', () => {
    it('should call enqueueRecalculation if userId is passed', async () => {
      serviceMock.enqueueRecalculation.mockResolvedValue(undefined);

      const result = await controller.forceRecalculate({ userId: 'user-id-123', rebuildHistory: true });
      expect(result).toEqual({ message: 'Recalculation enqueued for user user-id-123' });
      expect(serviceMock.enqueueRecalculation).toHaveBeenCalledWith('user-id-123', true);
    });

    it('should call handleNightlyAnalyticsRecalculation if no userId is passed', async () => {
      serviceMock.handleNightlyAnalyticsRecalculation.mockResolvedValue(undefined);

      const result = await controller.forceRecalculate({});
      expect(result).toEqual({ message: 'Nightly analytics recalculation triggered for all active users' });
      expect(serviceMock.handleNightlyAnalyticsRecalculation).toHaveBeenCalled();
    });
  });
});
