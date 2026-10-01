import { Test, TestingModule } from '@nestjs/testing';
import { ZebuWebSocketService } from './zebu-websocket.service';
import { OrderMonitoringService } from '../../trading/services/order-monitoring.service';
import { PrismaService } from '../../prisma.service';
import { mockPrismaService } from '../../../test/mocks/prisma.mock';
import WebSocket from 'ws';

jest.mock('ws');

describe('ZebuWebSocketService', () => {
  let service: ZebuWebSocketService;
  let orderMonitoringMock: any;
  let prismaMock: any;

  beforeEach(async () => {
    prismaMock = mockPrismaService();
    orderMonitoringMock = {
      processBrokerWebhookOrderUpdate: jest.fn().mockResolvedValue(undefined),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ZebuWebSocketService,
        { provide: OrderMonitoringService, useValue: orderMonitoringMock },
        { provide: PrismaService, useValue: prismaMock },
      ],
    }).compile();

    service = module.get<ZebuWebSocketService>(ZebuWebSocketService);
  });

  afterEach(() => {
    service.onModuleDestroy();
    jest.clearAllMocks();
  });

  describe('onApplicationBootstrap', () => {
    it('should find active Zebu sessions and initiate websocket connections', async () => {
      prismaMock.broker.findFirst.mockResolvedValue({
        id: 'broker-zebu-1',
        code: 'ZEBU',
      });
      prismaMock.userBroker.findMany.mockResolvedValue([
        {
          brokerClientId: 'ZB_CLI_1',
          accessToken: 'tok_1',
        },
      ]);

      const connectUserSpy = jest
        .spyOn(service, 'connectUser')
        .mockImplementation();

      await service.onApplicationBootstrap();

      expect(prismaMock.broker.findFirst).toHaveBeenCalledWith({
        where: { code: 'ZEBU' },
      });
      expect(connectUserSpy).toHaveBeenCalledWith('ZB_CLI_1', 'tok_1');
    });

    it('should do nothing if no ZEBU broker master record exists', async () => {
      prismaMock.broker.findFirst.mockResolvedValue(null);
      const connectUserSpy = jest
        .spyOn(service, 'connectUser')
        .mockImplementation();

      await service.onApplicationBootstrap();

      expect(connectUserSpy).not.toHaveBeenCalled();
    });
  });

  describe('WebSocket message parsing & order updates', () => {
    it('should process order updates (t: "om") and forward to OrderMonitoringService', async () => {
      let messageHandler: ((data: any) => void) | undefined;

      const mockWs = {
        on: jest.fn().mockImplementation((event: string, handler: any) => {
          if (event === 'message') {
            messageHandler = handler;
          }
        }),
        send: jest.fn(),
        close: jest.fn(),
        readyState: WebSocket.OPEN,
      };

      (WebSocket as unknown as jest.Mock).mockImplementation(() => mockWs);

      service.connectUser('ZB_CLI_1', 'tok_1');

      expect(messageHandler).toBeDefined();

      // Simulate Zebu order update event
      const orderUpdatePayload = JSON.stringify({
        t: 'om',
        norenordno: 'ZB_ORD_1001',
        status: 'COMPLETE',
        avgprc: '2450.50',
        fillshares: '25',
      });

      await messageHandler!(Buffer.from(orderUpdatePayload));

      expect(
        orderMonitoringMock.processBrokerWebhookOrderUpdate,
      ).toHaveBeenCalledWith({
        brokerOrderId: 'ZB_ORD_1001',
        status: 'COMPLETE',
        averagePrice: 2450.5,
        filledQuantity: 25,
        rejectionReason: undefined,
      });
    });

    it('should extract rejection reason for rejected orders', async () => {
      let messageHandler: ((data: any) => void) | undefined;

      const mockWs = {
        on: jest.fn().mockImplementation((event: string, handler: any) => {
          if (event === 'message') {
            messageHandler = handler;
          }
        }),
        send: jest.fn(),
        close: jest.fn(),
        readyState: WebSocket.OPEN,
      };

      (WebSocket as unknown as jest.Mock).mockImplementation(() => mockWs);

      service.connectUser('ZB_CLI_1', 'tok_1');

      const rejectionPayload = JSON.stringify({
        t: 'om',
        norenordno: 'ZB_ORD_1002',
        status: 'REJECTED',
        rejreason: 'Circuit limit reached for symbol',
      });

      await messageHandler!(Buffer.from(rejectionPayload));

      expect(
        orderMonitoringMock.processBrokerWebhookOrderUpdate,
      ).toHaveBeenCalledWith({
        brokerOrderId: 'ZB_ORD_1002',
        status: 'REJECTED',
        averagePrice: undefined,
        filledQuantity: undefined,
        rejectionReason: 'Circuit limit reached for symbol',
      });
    });
  });

  describe('disconnectUser', () => {
    it('should close socket and remove from active sockets and credentials', () => {
      const mockWs = {
        on: jest.fn(),
        send: jest.fn(),
        close: jest.fn(),
        readyState: WebSocket.OPEN,
      };
      (WebSocket as unknown as jest.Mock).mockImplementation(() => mockWs);

      service.connectUser('ZB_CLI_1', 'tok_1');
      service.disconnectUser('ZB_CLI_1');

      expect(mockWs.close).toHaveBeenCalled();
    });
  });
});
