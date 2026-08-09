import { Test, TestingModule } from '@nestjs/testing';
import { UsersService } from './users.service';
import { PrismaService } from '../prisma.service';
import { mockPrismaService } from '../../test/mocks/prisma.mock';
import { UserStatus } from '@prisma/client';

describe('UsersService', () => {
  let service: UsersService;
  let prismaMock: any;

  beforeEach(async () => {
    prismaMock = mockPrismaService();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UsersService,
        { provide: PrismaService, useValue: prismaMock },
      ],
    }).compile();

    service = module.get<UsersService>(UsersService);
  });

  describe('findByMobile', () => {
    it('should find user by mobile', async () => {
      const mockUser = { id: 'user-1', mobile: '9876543210' };
      prismaMock.user.findFirst.mockResolvedValue(mockUser);

      const result = await service.findByMobile('9876543210');
      expect(result).toEqual(mockUser);
      expect(prismaMock.user.findFirst).toHaveBeenCalledWith({
        where: { mobile: '9876543210', deletedAt: null },
      });
    });
  });

  describe('findById', () => {
    it('should find user by id', async () => {
      const mockUser = { id: 'user-1', mobile: '9876543210' };
      prismaMock.user.findUnique.mockResolvedValue(mockUser);

      const result = await service.findById('user-1');
      expect(result).toEqual(mockUser);
    });
  });

  describe('createOrUpdateUser', () => {
    it('should return existing user if found', async () => {
      const mockUser = { id: 'user-1', mobile: '9876543210' };
      prismaMock.user.findFirst.mockResolvedValue(mockUser);

      const result = await service.createOrUpdateUser('9876543210');
      expect(result).toEqual(mockUser);
      expect(prismaMock.user.create).not.toHaveBeenCalled();
    });

    it('should create user if not found', async () => {
      prismaMock.user.findFirst.mockResolvedValue(null);
      const mockCreated = {
        id: 'user-2',
        mobile: '9876543210',
        mpinHash: '',
        status: UserStatus.ACTIVE,
      };
      prismaMock.user.create.mockResolvedValue(mockCreated);

      const result = await service.createOrUpdateUser('9876543210');
      expect(result).toEqual(mockCreated);
      expect(prismaMock.user.create).toHaveBeenCalled();
    });
  });

  describe('updateMpin', () => {
    it('should update user MPIN hash', async () => {
      prismaMock.user.update.mockResolvedValue({
        id: 'user-1',
        mpinHash: 'new_hash',
      });
      const result = await service.updateMpin('user-1', 'new_hash');
      expect(result.mpinHash).toBe('new_hash');
    });
  });

  describe('findDevice', () => {
    it('should find user device', async () => {
      prismaMock.userDevice.findFirst.mockResolvedValue({ id: 'device-1' });
      const result = await service.findDevice('user-1', 'device-1');
      expect(result).toEqual({ id: 'device-1' });
    });
  });

  describe('trackDevice', () => {
    it('should update existing device if found', async () => {
      prismaMock.userDevice.findFirst.mockResolvedValue({
        id: 'device-1',
        userId: 'user-1',
        deviceId: 'd-1',
      });
      prismaMock.userDevice.update.mockResolvedValue({
        id: 'device-1',
        deviceName: 'iPhone',
      });

      const result = await service.trackDevice(
        'user-1',
        'd-1',
        'iPhone',
        'iOS',
      );
      expect(result.deviceName).toBe('iPhone');
      expect(prismaMock.userDevice.update).toHaveBeenCalled();
    });

    it('should create new device if not found', async () => {
      prismaMock.userDevice.findFirst.mockResolvedValue(null);
      prismaMock.userDevice.create.mockResolvedValue({
        id: 'device-new',
        deviceName: 'Android',
      });

      const result = await service.trackDevice(
        'user-1',
        'd-1',
        'Android',
        'Android',
      );
      expect(result.deviceName).toBe('Android');
      expect(prismaMock.userDevice.create).toHaveBeenCalled();
    });
  });
});
