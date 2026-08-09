import { Test, TestingModule } from '@nestjs/testing';
import { PositionsService } from './positions.service';
import { PrismaService } from '../prisma.service';
import { mockPrismaService } from '../../test/mocks/prisma.mock';
import {
  PositionStatus,
  OrderType,
  TradeStatus,
  OrderStatus,
} from '@prisma/client';
import { NotFoundException, BadRequestException } from '@nestjs/common';

describe('PositionsService', () => {
  let service: PositionsService;
  let prismaMock: any;

  beforeEach(async () => {
    prismaMock = mockPrismaService();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PositionsService,
        { provide: PrismaService, useValue: prismaMock },
      ],
    }).compile();

    service = module.get<PositionsService>(PositionsService);
  });

  describe('getActivePositions', () => {
    it('should query, drift prices, update and return open positions', async () => {
      const mockPosList = [
        {
          id: 'pos-1',
          avgPrice: 100,
          currentPrice: 100,
          quantity: 10,
          trade: {
            userId: 'user-1',
            signal: { side: 'BUY' },
          },
        },
      ];

      prismaMock.position.findMany.mockResolvedValue(mockPosList);
      prismaMock.position.update.mockResolvedValue({
        id: 'pos-1',
        avgPrice: 100,
        currentPrice: 101.5,
        unrealizedPnl: 15,
        trade: mockPosList[0].trade,
      });

      const result = await service.getActivePositions('user-1');
      expect(result).toHaveLength(1);
      expect(result[0].currentPrice).toBe(101.5);
      expect(result[0].unrealizedPnl).toBe(15);
      expect(prismaMock.position.findMany).toHaveBeenCalled();
      expect(prismaMock.position.update).toHaveBeenCalled();
    });
  });

  describe('exitPosition', () => {
    const mockPos = {
      id: 'pos-1',
      tradeId: 't-1',
      status: PositionStatus.OPEN,
      avgPrice: 100,
      currentPrice: 110,
      quantity: 5,
      trade: {
        userId: 'user-1',
        signal: { side: 'BUY' },
      },
    };

    it('should throw NotFoundException if position is missing or user does not own it', async () => {
      prismaMock.position.findUnique.mockResolvedValue(null);
      await expect(service.exitPosition('user-1', 'pos-1')).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should throw BadRequestException if position is already closed', async () => {
      prismaMock.position.findUnique.mockResolvedValue({
        ...mockPos,
        status: PositionStatus.CLOSED,
      });
      await expect(service.exitPosition('user-1', 'pos-1')).rejects.toThrow(
        BadRequestException,
      );
    });

    it('should successfully execute closing transactions', async () => {
      prismaMock.position.findUnique.mockResolvedValue(mockPos);

      // Prisma transaction mock helper
      const txMock = {
        position: {
          update: jest
            .fn()
            .mockResolvedValue({ id: 'pos-1', status: PositionStatus.CLOSED }),
        },
        trade: {
          update: jest
            .fn()
            .mockResolvedValue({ id: 't-1', status: TradeStatus.CLOSED }),
        },
        order: { create: jest.fn().mockResolvedValue({ id: 'o-1' }) },
      };

      prismaMock.$transaction.mockImplementation(async (callback) => {
        return callback(txMock);
      });

      const result = await service.exitPosition('user-1', 'pos-1');
      expect(result.status).toBe(PositionStatus.CLOSED);
      expect(txMock.position.update).toHaveBeenCalled();
      expect(txMock.trade.update).toHaveBeenCalled();
      expect(txMock.order.create).toHaveBeenCalled();
    });
  });
});
