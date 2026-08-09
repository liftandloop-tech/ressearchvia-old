import { Test, TestingModule } from '@nestjs/testing';
import { SubscriptionsController } from './subscriptions.controller';
import { SubscriptionsService } from './subscriptions.service';
import { PLANS } from './plans.constants';

describe('SubscriptionsController', () => {
  let controller: SubscriptionsController;
  let serviceMock: any;

  beforeEach(async () => {
    serviceMock = {
      getCurrentSubscription: jest.fn(),
      validateSubscription: jest.fn(),
      getSubscriptionHistory: jest.fn(),
      subscribe: jest.fn(),
      cancelSubscription: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [SubscriptionsController],
      providers: [
        {
          provide: SubscriptionsService,
          useValue: serviceMock,
        },
      ],
    }).compile();

    controller = module.get<SubscriptionsController>(SubscriptionsController);
  });

  describe('getPlans', () => {
    it('should return available plans from seed constants', () => {
      const plans = controller.getPlans();
      expect(plans).toHaveLength(2);
      expect(plans[0].id).toBe(PLANS.SPARK.id);
      expect(plans[1].id).toBe(PLANS.SPLENDID.id);
    });
  });

  describe('getCurrent', () => {
    it('should retrieve active subscription of the user', async () => {
      const req = { user: { userId: 'user-id' } };
      serviceMock.getCurrentSubscription.mockResolvedValue({ id: 'sub-id' });

      const result = await controller.getCurrent(req);
      expect(result).toEqual({ id: 'sub-id' });
      expect(serviceMock.getCurrentSubscription).toHaveBeenCalledWith(
        'user-id',
      );
    });
  });

  describe('getStatus', () => {
    it('should retrieve status check validation payload', async () => {
      const req = { user: { userId: 'user-id' } };
      serviceMock.validateSubscription.mockResolvedValue({
        active: true,
        plan: 'SPARK',
      });

      const result = await controller.getStatus(req);
      expect(result).toEqual({ active: true, plan: 'SPARK' });
      expect(serviceMock.validateSubscription).toHaveBeenCalledWith('user-id');
    });
  });

  describe('getHistory', () => {
    it('should fetch paginated subscription history', async () => {
      const req = { user: { userId: 'user-id' } };
      serviceMock.getSubscriptionHistory.mockResolvedValue({ data: [] });

      const result = await controller.getHistory(req, { page: 2, limit: 10 });
      expect(result).toEqual({ data: [] });
      expect(serviceMock.getSubscriptionHistory).toHaveBeenCalledWith(
        'user-id',
        2,
        10,
      );
    });
  });

  describe('subscribeBase', () => {
    it('should create a new subscription', async () => {
      const req = { user: { userId: 'user-id' } };
      serviceMock.subscribe.mockResolvedValue({ id: 'sub-id' });

      const result = await controller.subscribeBase(req, { planId: 'plan-id' });
      expect(result).toEqual({ id: 'sub-id' });
      expect(serviceMock.subscribe).toHaveBeenCalledWith('user-id', 'plan-id');
    });
  });

  describe('subscribeLegacy', () => {
    it('should support legacy /subscribe route', async () => {
      const req = { user: { userId: 'user-id' } };
      serviceMock.subscribe.mockResolvedValue({ id: 'sub-id' });

      const result = await controller.subscribeLegacy(req, {
        planId: 'plan-id',
      });
      expect(result).toEqual({ id: 'sub-id' });
      expect(serviceMock.subscribe).toHaveBeenCalledWith('user-id', 'plan-id');
    });
  });

  describe('cancel', () => {
    it('should cancel subscription after verifying ownership', async () => {
      const req = { user: { userId: 'user-id' } };
      serviceMock.cancelSubscription.mockResolvedValue({
        id: 'sub-id',
        status: 'CANCELLED',
      });

      const result = await controller.cancel(req, 'sub-id');
      expect(result).toEqual({ id: 'sub-id', status: 'CANCELLED' });
      expect(serviceMock.cancelSubscription).toHaveBeenCalledWith(
        'sub-id',
        'user-id',
      );
    });
  });
});
