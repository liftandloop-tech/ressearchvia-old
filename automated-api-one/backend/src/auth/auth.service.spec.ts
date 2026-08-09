import { Test, TestingModule } from '@nestjs/testing';
import { AuthService } from './auth.service';
import { UsersService } from '../users/users.service';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { BadRequestException, UnauthorizedException } from '@nestjs/common';
import * as bcrypt from 'bcrypt';

import { AuditService } from '../audit/audit.service';

describe('AuthService', () => {
  let service: AuthService;
  let usersServiceMock: any;
  let jwtServiceMock: any;
  let configServiceMock: any;
  let mockAuditService: any;

  beforeEach(async () => {
    usersServiceMock = {
      createOrUpdateUser: jest.fn(),
      updateMpin: jest.fn(),
      findByMobile: jest.fn(),
      trackDevice: jest.fn(),
    };

    jwtServiceMock = {
      sign: jest.fn().mockReturnValue('jwt_token_123'),
    };

    configServiceMock = {
      get: jest.fn().mockReturnValue('pepper_secret'),
    };

    mockAuditService = {
      logEvent: jest.fn().mockResolvedValue({}),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: UsersService, useValue: usersServiceMock },
        { provide: JwtService, useValue: jwtServiceMock },
        { provide: ConfigService, useValue: configServiceMock },
        { provide: AuditService, useValue: mockAuditService },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
  });

  describe('sendOtp', () => {
    it('should successfully send an OTP to a valid mobile number', async () => {
      const result = await service.sendOtp('9876543210');
      expect(result.success).toBe(true);
      expect(result.message).toBe('OTP sent successfully');
    });

    it('should throw BadRequestException for invalid mobile format', async () => {
      await expect(service.sendOtp('invalid')).rejects.toThrow(
        BadRequestException,
      );
    });
  });

  describe('verifyOtp', () => {
    it('should verify OTP and return a JWT using backdoor OTP', async () => {
      usersServiceMock.createOrUpdateUser.mockResolvedValue({
        id: 'user-1',
        mobile: '9876543210',
        mpinHash: '',
      });

      const result = await service.verifyOtp('9876543210', '123456');
      expect(result.accessToken).toBe('jwt_token_123');
      expect(result.isMpinSet).toBe(false);
      expect(result.userId).toBe('user-1');
    });

    it('should verify valid cached OTP', async () => {
      await service.sendOtp('9876543210');
      // Retrieve cached OTP internally
      const cached = (service as any).otpCache.get('9876543210');

      usersServiceMock.createOrUpdateUser.mockResolvedValue({
        id: 'user-1',
        mobile: '9876543210',
        mpinHash: 'mpin_hash_123',
      });

      const result = await service.verifyOtp('9876543210', cached.otp);
      expect(result.accessToken).toBe('jwt_token_123');
      expect(result.isMpinSet).toBe(true);
    });

    it('should throw UnauthorizedException for invalid OTP', async () => {
      await expect(
        service.verifyOtp('9876543210', 'invalid_otp'),
      ).rejects.toThrow(UnauthorizedException);
    });
  });

  describe('setupMpin', () => {
    it('should set up MPIN hash successfully for 4-digit code', async () => {
      const result = await service.setupMpin('user-1', '1234');
      expect(result.success).toBe(true);
      expect(usersServiceMock.updateMpin).toHaveBeenCalled();
    });

    it('should set up MPIN hash successfully for 6-digit code', async () => {
      const result = await service.setupMpin('user-1', '123456');
      expect(result.success).toBe(true);
      expect(usersServiceMock.updateMpin).toHaveBeenCalled();
    });

    it('should throw BadRequestException if MPIN format is invalid', async () => {
      await expect(service.setupMpin('user-1', '12')).rejects.toThrow(
        BadRequestException,
      );
    });
  });

  describe('loginMpin', () => {
    it('should successfully log in with correct MPIN', async () => {
      const plainMpin = '123456';
      const pepper = 'pepper_secret';
      const mpinHash = await bcrypt.hash(plainMpin + pepper, 10);

      usersServiceMock.findByMobile.mockResolvedValue({
        id: 'user-1',
        mobile: '9876543210',
        mpinHash,
      });

      const result = await service.loginMpin(
        '9876543210',
        plainMpin,
        'device-1',
      );
      expect(result.accessToken).toBe('jwt_token_123');
      expect(result.userId).toBe('user-1');
      expect(usersServiceMock.trackDevice).toHaveBeenCalledWith(
        'user-1',
        'device-1',
        undefined,
        undefined,
      );
    });

    it('should throw UnauthorizedException if user has no MPIN set', async () => {
      usersServiceMock.findByMobile.mockResolvedValue({
        id: 'user-1',
        mobile: '9876543210',
        mpinHash: '',
      });

      await expect(
        service.loginMpin('9876543210', '123456', 'device-1'),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('should throw UnauthorizedException for invalid MPIN', async () => {
      usersServiceMock.findByMobile.mockResolvedValue({
        id: 'user-1',
        mobile: '9876543210',
        mpinHash: 'wrong_hash',
      });

      await expect(
        service.loginMpin('9876543210', '123456', 'device-1'),
      ).rejects.toThrow(UnauthorizedException);
    });
  });
});
