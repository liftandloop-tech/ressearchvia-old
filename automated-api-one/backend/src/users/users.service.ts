import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { User, UserDevice, UserStatus, SubscriptionStatus } from '@prisma/client';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async findByMobile(mobile: string): Promise<User | null> {
    return this.prisma.user.findFirst({
      where: {
        mobile,
        deletedAt: null,
      },
    });
  }

  async findById(id: string): Promise<User | null> {
    return this.prisma.user.findUnique({
      where: { id },
    });
  }

  async createOrUpdateUser(mobile: string): Promise<User> {
    const existing = await this.findByMobile(mobile);
    if (existing) {
      return existing;
    }

    // Default MPIN hash represents an empty string initially until configured
    const user = await this.prisma.user.create({
      data: {
        mobile,
        mpinHash: '',
        status: UserStatus.ACTIVE,
      },
    });

    // Create a default SPLENDID subscription so they can trade
    await this.prisma.subscription.create({
      data: {
        userId: user.id,
        planId: '22222222-e29b-41d4-a716-446655440002', // SPLENDID
        startDate: new Date(Date.now() - 24 * 60 * 60 * 1000), // yesterday
        endDate: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000), // 1 year from now
        status: SubscriptionStatus.ACTIVE,
      },
    });

    return user;
  }

  async updateMpin(userId: string, mpinHash: string): Promise<User> {
    return this.prisma.user.update({
      where: { id: userId },
      data: { mpinHash },
    });
  }

  async findDevice(
    userId: string,
    deviceId: string,
  ): Promise<UserDevice | null> {
    return this.prisma.userDevice.findFirst({
      where: {
        userId,
        deviceId,
      },
    });
  }

  async trackDevice(
    userId: string,
    deviceId: string,
    deviceName?: string,
    platform?: string,
  ): Promise<UserDevice> {
    const existing = await this.findDevice(userId, deviceId);
    if (existing) {
      return this.prisma.userDevice.update({
        where: { id: existing.id },
        data: {
          lastLoginAt: new Date(),
          deviceName,
          platform,
        },
      });
    }

    return this.prisma.userDevice.create({
      data: {
        userId,
        deviceId,
        deviceName,
        platform,
      },
    });
  }
}
