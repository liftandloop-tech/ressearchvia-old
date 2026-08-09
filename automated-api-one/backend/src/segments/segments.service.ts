import { Injectable, OnModuleInit, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import {
  SegmentMaster,
  UserSegment,
  Segment,
  UserSegmentStatus,
} from '@prisma/client';
import { SEED_SEGMENTS } from '../common/constants/seed.constants';
import { AuditService } from '../audit/audit.service';
import { AuditEventType } from '../audit/enums/audit-event.enum';

@Injectable()
export class SegmentsService implements OnModuleInit {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditService: AuditService,
  ) {}

  async onModuleInit() {
    await this.seedDefaultSegments();
  }

  private async seedDefaultSegments() {
    console.log('Seeding default master segments into database...');
    const segmentsToSeed = Object.values(SEED_SEGMENTS).map((seg) => ({
      id: seg.id,
      name: seg.name,
      description: seg.description,
      segment: seg.segment as Segment,
      status: UserSegmentStatus.ACTIVE,
    }));

    for (const data of segmentsToSeed) {
      await this.prisma.segmentMaster.upsert({
        where: { id: data.id },
        update: {
          name: data.name,
          description: data.description,
          segment: data.segment,
          status: data.status,
        },
        create: data,
      });
    }
  }

  async listSegments(): Promise<any[]> {
    const segments = await this.prisma.segmentMaster.findMany({
      where: {
        deletedAt: null,
      },
    });

    return segments.map((seg) => ({
      ...seg,
      sizingType: seg.name?.toUpperCase() === 'EQUITY CASH' ? 'AMOUNT' : 'LOT',
    }));
  }

  async activateSegment(
    userId: string,
    data: {
      segmentId: string;
      capital: number;
      backupCapital: number;
      baseLot: number;
      maxMultiplier: number;
      dailyLossLimit: number;
    },
  ): Promise<UserSegment> {
    // Verify strategy (master segment) exists
    const segment = await this.prisma.segmentMaster.findUnique({
      where: { id: data.segmentId },
    });

    if (!segment) {
      throw new NotFoundException('Segment not found');
    }

    const existing = await this.prisma.userSegment.findFirst({
      where: {
        userId,
        segmentId: data.segmentId,
      },
    });

    const res = await (existing
      ? this.prisma.userSegment.update({
          where: { id: existing.id },
          data: {
            capital: data.capital,
            backupCapital: data.backupCapital,
            baseLot: data.baseLot,
            maxMultiplier: data.maxMultiplier,
            dailyLossLimit: data.dailyLossLimit,
            status: UserSegmentStatus.ACTIVE,
            activatedAt: new Date(),
          },
        })
      : this.prisma.userSegment.create({
          data: {
            userId,
            segmentId: data.segmentId,
            capital: data.capital,
            backupCapital: data.backupCapital,
            baseLot: data.baseLot,
            maxMultiplier: data.maxMultiplier,
            dailyLossLimit: data.dailyLossLimit,
            status: UserSegmentStatus.ACTIVE,
            activatedAt: new Date(),
          },
        }));

    await this.auditService.logEvent(
      userId,
      AuditEventType.SEGMENT_ACTIVATED,
      'UserSegment',
      res.id,
      {
        segmentId: data.segmentId,
        capital: data.capital,
        backupCapital: data.backupCapital,
        baseLot: data.baseLot,
        maxMultiplier: data.maxMultiplier,
        dailyLossLimit: data.dailyLossLimit,
      },
    );

    return res;
  }

  async pauseSegment(userId: string, segmentId: string): Promise<UserSegment> {
    const existing = await this.prisma.userSegment.findFirst({
      where: {
        userId,
        segmentId,
      },
    });

    if (!existing) {
      throw new NotFoundException('You are not subscribed to this segment');
    }

    const res = await this.prisma.userSegment.update({
      where: { id: existing.id },
      data: {
        status: UserSegmentStatus.PAUSED,
        pausedAt: new Date(),
      },
    });

    await this.auditService.logEvent(
      userId,
      AuditEventType.SEGMENT_PAUSED,
      'UserSegment',
      res.id,
      {
        segmentId,
      },
    );

    return res;
  }

  async getUserSegments(userId: string): Promise<UserSegment[]> {
    return this.prisma.userSegment.findMany({
      where: { userId },
      include: {
        segment: true,
      },
    });
  }
}
