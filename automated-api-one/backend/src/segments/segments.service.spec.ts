import { Test, TestingModule } from '@nestjs/testing';
import { SegmentsService } from './segments.service';
import { PrismaService } from '../prisma.service';
import { mockPrismaService } from '../../test/mocks/prisma.mock';
import { Segment, UserSegmentStatus } from '@prisma/client';
import { NotFoundException } from '@nestjs/common';

import { AuditService } from '../audit/audit.service';

describe('SegmentsService', () => {
  let service: SegmentsService;
  let prismaMock: any;
  let mockAuditService: any;

  beforeEach(async () => {
    prismaMock = mockPrismaService();
    mockAuditService = {
      logEvent: jest.fn().mockResolvedValue({}),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SegmentsService,
        { provide: PrismaService, useValue: prismaMock },
        { provide: AuditService, useValue: mockAuditService },
      ],
    }).compile();

    service = module.get<SegmentsService>(SegmentsService);
  });

  describe('onModuleInit', () => {
    it('should seed default segments using upsert', async () => {
      prismaMock.segmentMaster.upsert.mockResolvedValue({});

      await service.onModuleInit();
      expect(prismaMock.segmentMaster.upsert).toHaveBeenCalledTimes(7);
    });
  });

  describe('listSegments', () => {
    it('should query and return segments', async () => {
      prismaMock.segmentMaster.findMany.mockResolvedValue([
        { id: 'strategy-1', name: 'INTRADAY' },
      ]);

      const result = await service.listSegments();
      expect(result).toHaveLength(1);
      expect(result[0].name).toBe('INTRADAY');
    });
  });

  describe('activateSegment', () => {
    const mockDto = {
      segmentId: 'strategy-1',
      capital: 10000,
      backupCapital: 2000,
      baseLot: 1,
      maxMultiplier: 4,
      dailyLossLimit: 2000,
    };

    it('should throw NotFoundException if master segment does not exist', async () => {
      prismaMock.segmentMaster.findUnique.mockResolvedValue(null);
      await expect(service.activateSegment('user-1', mockDto)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should create segment subscription if it does not exist', async () => {
      prismaMock.segmentMaster.findUnique.mockResolvedValue({ id: 'strategy-1' });
      prismaMock.userSegment.findFirst.mockResolvedValue(null);
      prismaMock.userSegment.create.mockResolvedValue({
        id: 'us-1',
        status: UserSegmentStatus.ACTIVE,
      });

      const result = await service.activateSegment('user-1', mockDto);
      expect(result.status).toBe(UserSegmentStatus.ACTIVE);
      expect(prismaMock.userSegment.create).toHaveBeenCalled();
    });

    it('should update existing segment subscription if it exists', async () => {
      prismaMock.segmentMaster.findUnique.mockResolvedValue({ id: 'strategy-1' });
      prismaMock.userSegment.findFirst.mockResolvedValue({
        id: 'us-1',
        status: UserSegmentStatus.PAUSED,
      });
      prismaMock.userSegment.update.mockResolvedValue({
        id: 'us-1',
        status: UserSegmentStatus.ACTIVE,
      });

      const result = await service.activateSegment('user-1', mockDto);
      expect(result.status).toBe(UserSegmentStatus.ACTIVE);
      expect(prismaMock.userSegment.update).toHaveBeenCalled();
    });
  });

  describe('pauseSegment', () => {
    it('should throw NotFoundException if subscription is missing', async () => {
      prismaMock.userSegment.findFirst.mockResolvedValue(null);
      await expect(
        service.pauseSegment('user-1', 'strategy-1'),
      ).rejects.toThrow(NotFoundException);
    });

    it('should update status to PAUSED', async () => {
      prismaMock.userSegment.findFirst.mockResolvedValue({ id: 'us-1' });
      prismaMock.userSegment.update.mockResolvedValue({
        id: 'us-1',
        status: UserSegmentStatus.PAUSED,
      });

      const result = await service.pauseSegment('user-1', 'strategy-1');
      expect(result.status).toBe(UserSegmentStatus.PAUSED);
      expect(prismaMock.userSegment.update).toHaveBeenCalled();
    });
  });

  describe('getUserSegments', () => {
    it('should return configured segments for user', async () => {
      prismaMock.userSegment.findMany.mockResolvedValue([
        { id: 'us-1', userId: 'user-1', segmentId: 'strategy-1', capital: 10000 },
      ]);

      const result = await service.getUserSegments('user-1');
      expect(result).toHaveLength(1);
      expect(result[0].id).toBe('us-1');
      expect(prismaMock.userSegment.findMany).toHaveBeenCalledWith({
        where: { userId: 'user-1' },
        include: { segment: true },
      });
    });
  });
});
