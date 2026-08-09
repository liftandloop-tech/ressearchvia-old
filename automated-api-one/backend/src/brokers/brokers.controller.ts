import {
  Controller,
  Post,
  Get,
  Delete,
  Body,
  UseGuards,
  Request,
  HttpCode,
  HttpStatus,
  BadRequestException,
  Param,
  Query,
  Res,
} from '@nestjs/common';
import { Response } from 'express';
import * as crypto from 'crypto';
import { getTodayISTString } from '../consents/consents.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { BrokerFactory } from './factory/broker.factory';
import { BrokerSessionService } from './services/broker-session.service';
import { BrokerType } from './interfaces/broker-type.enum';
import { PrismaService } from '../prisma.service';
import { RedisService } from '../infrastructure/redis/redis.service';
import {
  IsNotEmpty,
  IsString,
  IsEnum,
  IsOptional,
} from 'class-validator';
import { BrokerCode, BrokerStatus } from '@prisma/client';

export class LinkBrokerDto {
  @IsEnum(BrokerCode)
  @IsNotEmpty()
  brokerCode: BrokerCode;

  @IsString()
  @IsNotEmpty()
  brokerClientId: string;

  @IsString()
  @IsOptional()
  apiKey?: string; // Per-user API key (required for brokers like Zebu)

  @IsString()
  @IsOptional()
  vendorCode?: string; // Per-user vendor code (required for brokers like Zebu)
}

export class AuthorizeBrokerDto {
  @IsEnum(BrokerCode)
  @IsNotEmpty()
  brokerCode: BrokerCode;

  @IsString()
  @IsNotEmpty()
  mpin: string; // Password or MPIN for the broker portal

  @IsString()
  @IsNotEmpty()
  totpKey: string; // TOTP secret key or current TOTP value
}

@Controller('brokers')
export class BrokersController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly brokerFactory: BrokerFactory,
    private readonly brokerSessionService: BrokerSessionService,
    private readonly redisService: RedisService,
  ) {}



  @UseGuards(JwtAuthGuard)
  @Post('link')
  @HttpCode(HttpStatus.OK)
  async linkBroker(@Request() req, @Body() dto: LinkBrokerDto) {
    const userId = req.user.userId;

    // Check if the master broker record exists in database; if not, create it
    let broker = await this.prisma.broker.findFirst({
      where: { code: dto.brokerCode },
    });

    if (!broker) {
      broker = await this.prisma.broker.create({
        data: {
          code: dto.brokerCode,
          name: dto.brokerCode.replace('_', ' '),
          status: BrokerStatus.ACTIVE,
        },
      });
    }

    // Check if client is already linked — query via userBroker (includes soft-deleted) by
    // explicitly not filtering deletedAt, so we can restore a previously unlinked account.
    const existing = await this.prisma.userBroker.findFirst({
      where: {
        userId,
        brokerId: broker.id,
        deletedAt: { not: undefined as any },
      },
    });

    if (existing) {
      const updated = await this.prisma.userBroker.update({
        where: { id: existing.id },
        data: {
          brokerClientId: dto.brokerClientId,
          apiKey: dto.apiKey ?? existing.apiKey,
          vendorCode: dto.vendorCode ?? existing.vendorCode,
          status: BrokerStatus.ACTIVE,
          deletedAt: null, // Undelete/Restore the record
        },
      });
      return updated;
    }

    const created = await this.prisma.userBroker.create({
      data: {
        userId,
        brokerId: broker.id,
        brokerClientId: dto.brokerClientId,
        apiKey: dto.apiKey ?? null,
        vendorCode: dto.vendorCode ?? null,
        status: BrokerStatus.ACTIVE,
      },
    });
    return created;

  }

  @UseGuards(JwtAuthGuard)
  @Post('authorize')
  @HttpCode(HttpStatus.OK)
  async authorizeBroker(@Request() req, @Body() dto: AuthorizeBrokerDto) {
    const userId = req.user.userId;

    // Get linked user broker config
    const broker = await this.prisma.broker.findFirst({
      where: { code: dto.brokerCode },
    });

    if (!broker) {
      throw new BadRequestException('Broker type not registered on platform');
    }

    const userBroker = await this.prisma.userBroker.findFirst({
      where: {
        userId,
        brokerId: broker.id,
      },
    });

    if (!userBroker) {
      throw new BadRequestException(
        'Please link your broker account details first',
      );
    }

    // Resolve adapter dynamically
    const brokerType = dto.brokerCode as unknown as BrokerType;
    const adapter = this.brokerFactory.getAdapter(brokerType);

    const session = await adapter.generateSession({
      clientCode: userBroker.brokerClientId,
      password: dto.mpin, // Zebu requires password; passed in mpin field from client API DTO
      totpKey: dto.totpKey,
      apiKey: userBroker.apiKey ?? undefined,
      vendorCode: userBroker.vendorCode ?? undefined,
    });

    // Delegate to session service (stores tokens and logs BROKER_CONNECTED event)
    await this.brokerSessionService.storeSession(
      userId,
      dto.brokerCode,
      session,
      userBroker.id,
    );

    return {
      success: true,
      message: 'Broker daily session authorization completed',
      expiry: session.tokenExpiry,
    };
  }

  @UseGuards(JwtAuthGuard)
  @Get('status')
  async getBrokerStatus(@Request() req) {
    const userId = req.user.userId;

    const linkedBrokers = await this.prisma.userBroker.findMany({
      where: { userId },
      include: { broker: true },
    });

    const statusList = await Promise.all(
      linkedBrokers.map(async (ub) => {
        let isSessionActive = false;
        let availableMargin = 0;
        let profile: any = null;

        // Use brokerSessionService to validate the session
        isSessionActive = await this.brokerSessionService.validateSession(
          userId,
          ub.broker.code,
        );

        if (isSessionActive && ub.accessToken) {
          const brokerType = ub.broker.code as unknown as BrokerType;
          try {
            const adapter = this.brokerFactory.getAdapter(brokerType);
            availableMargin = await adapter.getMargin(
              ub.accessToken,
              ub.brokerClientId,
            );
            profile = await adapter.getProfile(ub.accessToken, ub.brokerClientId);
          } catch (err) {
            // Ignore error or log it
          }
        }

        return {
          brokerCode: ub.broker.code,
          brokerClientId: ub.brokerClientId,
          isSessionActive,
          availableMargin,
          profile,
          linkedAt: ub.createdAt,
        };
      }),
    );

    return statusList;
  }

  @UseGuards(JwtAuthGuard)
  @Get('/')
  async listBrokers(@Request() req) {
    const userId = req.user.userId;

    // Get linked user brokers
    const linkedUserBrokers = await this.prisma.userBroker.findMany({
      where: { userId },
      include: { broker: true },
    });

    const results: any[] = [];
    const allBrokerCodes = Object.values(BrokerCode);

    for (const code of allBrokerCodes) {
      const matched = linkedUserBrokers.find((ub) => ub.broker.code === code);
      let isSessionActive = false;
      if (matched) {
        isSessionActive = await this.brokerSessionService.validateSession(userId, code);
      }

      results.push({
        broker: code,
        status: matched 
          ? (isSessionActive ? 'CONNECTED' : 'EXPIRED') 
          : 'NOT_CONNECTED',
      });
    }

    return results;
  }

  @UseGuards(JwtAuthGuard)
  @Get(':brokerCode/auth-url')
  async getAuthUrl(
    @Request() req,
    @Param('brokerCode') brokerCodeStr: string,
  ) {
    const userId = req.user.userId;
    const brokerCode = brokerCodeStr.toUpperCase() as BrokerCode;
    if (!Object.values(BrokerCode).includes(brokerCode)) {
      throw new BadRequestException('Invalid broker code');
    }

    const state = crypto.randomUUID();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    await this.prisma.brokerAuthState.create({
      data: {
        userId,
        broker: brokerCode,
        state,
        expiresAt,
      },
    });

    try {
      const brokerType = brokerCode as unknown as BrokerType;
      const adapter = this.brokerFactory.getAdapter(brokerType);
      const authUrl = await adapter.getAuthorizationUrl(state);
      return { authUrl };
    } catch (error) {
      // Cleanup on failure
      await this.prisma.brokerAuthState.deleteMany({
        where: { broker: brokerCode, state },
      });
      throw new BadRequestException(`Failed to generate authorization URL: ${error.message}`);
    }
  }

  @Get(':brokerCode/callback')
  async handleCallback(
    @Param('brokerCode') brokerCodeStr: string,
    @Query() queryParams: Record<string, string | undefined>,
    @Res() res: any,
  ) {
    const brokerCode = brokerCodeStr.toUpperCase() as BrokerCode;
    if (!Object.values(BrokerCode).includes(brokerCode)) {
      return res.redirect(`/brokers/${brokerCodeStr}/callback/failure?error=Invalid+broker+code`);
    }

    const state = queryParams.state;
    if (!state) {
      return res.redirect(`/brokers/${brokerCodeStr}/callback/failure?error=Missing+state+parameter`);
    }

    // Verify and consume the state
    const dbState = await this.prisma.brokerAuthState.findFirst({
      where: { broker: brokerCode, state },
    });

    if (!dbState) {
      return res.redirect(`/brokers/${brokerCodeStr}/callback/failure?error=Invalid+or+expired+session`);
    }

    // Consume the token immediately
    await this.prisma.brokerAuthState.delete({
      where: { id: dbState.id },
    });

    // Check expiration
    if (new Date() > dbState.expiresAt) {
      return res.redirect(`/brokers/${brokerCodeStr}/callback/failure?error=Session+expired`);
    }

    try {
      const brokerType = brokerCode as unknown as BrokerType;
      const adapter = this.brokerFactory.getAdapter(brokerType);
      
      const session = await adapter.completeAuthorization({ params: queryParams });

      let broker = await this.prisma.broker.findFirst({
        where: { code: brokerCode },
      });

      if (!broker) {
        broker = await this.prisma.broker.create({
          data: {
            code: brokerCode,
            name: brokerCode.replace('_', ' '),
            status: BrokerStatus.ACTIVE,
          },
        });
      }

      // Use baseClient to bypass soft-delete filter — handles reconnect after disconnect
      let userBroker = await this.prisma.baseClient.userBroker.findFirst({
        where: {
          userId: dbState.userId,
          brokerId: broker.id,
        },
      });

      const brokerClientId = session.brokerUserId || 'UNKNOWN';

      if (userBroker) {
        // Restore / update the existing record (may have been soft-deleted or hard-disconnected)
        userBroker = await this.prisma.baseClient.userBroker.update({
          where: { id: userBroker.id },
          data: {
            brokerClientId: brokerClientId !== 'UNKNOWN' ? brokerClientId : userBroker.brokerClientId,
            status: BrokerStatus.ACTIVE,
            deletedAt: null,
          },
        });
      } else {
        userBroker = await this.prisma.baseClient.userBroker.create({
          data: {
            userId: dbState.userId,
            brokerId: broker.id,
            brokerClientId,
            status: BrokerStatus.ACTIVE,
          },
        });
      }

      await this.brokerSessionService.storeSession(
        dbState.userId,
        brokerCode,
        {
          accessToken: session.accessToken,
          refreshToken: session.refreshToken,
          tokenExpiry: session.expiresAt || new Date(Date.now() + 18 * 60 * 60 * 1000),
        },
        userBroker.id,
      );

      return res.redirect(`/brokers/${brokerCodeStr}/callback/success`);
    } catch (error: any) {
      return res.redirect(`/brokers/${brokerCodeStr}/callback/failure?error=${encodeURIComponent(error.message)}`);
    }
  }

  @Get(':brokerCode/callback/success')
  async showSuccessPage(@Param('brokerCode') brokerCode: string, @Res() res: any) {
    res.setHeader('Content-Type', 'text/html');
    return res.status(200).send(`
      <!DOCTYPE html>
      <html>
        <head>
          <title>Authorization Successful</title>
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600;700&display=swap" rel="stylesheet">
          <style>
            body {
              font-family: 'Poppins', sans-serif;
              background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
              color: #f8fafc;
              display: flex;
              justify-content: center;
              align-items: center;
              height: 100vh;
              margin: 0;
            }
            .card {
              background: rgba(30, 41, 59, 0.7);
              backdrop-filter: blur(16px);
              border: 1px solid rgba(255, 255, 255, 0.08);
              padding: 40px 30px;
              border-radius: 24px;
              text-align: center;
              box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.3), 0 10px 10px -5px rgba(0, 0, 0, 0.2);
              max-width: 400px;
              width: 90%;
            }
            .icon {
              font-size: 64px;
              margin-bottom: 20px;
              color: #10b981;
            }
            h1 {
              font-size: 24px;
              font-weight: 700;
              margin: 0 0 10px 0;
            }
            p {
              color: #94a3b8;
              font-size: 15px;
              line-height: 1.5;
              margin: 0;
            }
          </style>
        </head>
        <body>
          <div class="card">
            <div class="icon">✓</div>
            <h1>Connected!</h1>
            <p>${brokerCode.replace('_', ' ')} has been connected successfully. You can close this window now.</p>
          </div>
        </body>
      </html>
    `);
  }

  @Get(':brokerCode/callback/failure')
  async showFailurePage(
    @Param('brokerCode') brokerCode: string,
    @Query('error') errorMsg: string,
    @Res() res: any,
  ) {
    res.setHeader('Content-Type', 'text/html');
    return res.status(200).send(`
      <!DOCTYPE html>
      <html>
        <head>
          <title>Authorization Failed</title>
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600;700&display=swap" rel="stylesheet">
          <style>
            body {
              font-family: 'Poppins', sans-serif;
              background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
              color: #f8fafc;
              display: flex;
              justify-content: center;
              align-items: center;
              height: 100vh;
              margin: 0;
            }
            .card {
              background: rgba(30, 41, 59, 0.7);
              backdrop-filter: blur(16px);
              border: 1px solid rgba(255, 255, 255, 0.08);
              padding: 40px 30px;
              border-radius: 24px;
              text-align: center;
              box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.3), 0 10px 10px -5px rgba(0, 0, 0, 0.2);
              max-width: 400px;
              width: 90%;
            }
            .icon {
              font-size: 64px;
              margin-bottom: 20px;
              color: #ef4444;
            }
            h1 {
              font-size: 24px;
              font-weight: 700;
              margin: 0 0 10px 0;
            }
            p {
              color: #94a3b8;
              font-size: 15px;
              line-height: 1.5;
              margin: 0;
            }
          </style>
        </head>
        <body>
          <div class="card">
            <div class="icon">✗</div>
            <h1>Connection Failed</h1>
            <p>${errorMsg || 'An unknown error occurred during authorization.'}</p>
          </div>
        </body>
      </html>
    `);
  }

  @UseGuards(JwtAuthGuard)
  @Delete(':brokerCode/unlink')
  async unlinkBroker(@Request() req, @Param('brokerCode') brokerCodeStr: string) {
    const userId = req.user.userId;
    const brokerCode = brokerCodeStr.toUpperCase() as BrokerCode;

    const broker = await this.prisma.broker.findFirst({
      where: { code: brokerCode },
    });

    if (!broker) {
      throw new BadRequestException('Broker type not registered on platform');
    }

    const existing = await this.prisma.userBroker.findFirst({
      where: {
        userId,
        brokerId: broker.id,
      },
    });

    if (!existing) {
      throw new BadRequestException('No broker connection found to unlink');
    }

    // Delete UserBroker (will cascade-delete active sessions)
    await this.prisma.userBroker.delete({
      where: { id: existing.id },
    });

    // Also delete/revoke consents for today for this broker to be safe
    const todayStr = getTodayISTString();
    const todayDate = new Date(`${todayStr}T00:00:00.000Z`);
    await this.prisma.consent.deleteMany({
      where: {
        userId,
        brokerId: broker.id,
        consentDate: todayDate,
      },
    });

    return {
      success: true,
      message: 'Broker details and session disconnected successfully',
    };
  }

  private async getActiveBroker(userId: string) {
    const linkedBrokers = await this.prisma.userBroker.findMany({
      where: { userId },
      include: { broker: true },
    });

    for (const ub of linkedBrokers) {
      const isSessionActive = await this.brokerSessionService.validateSession(
        userId,
        ub.broker.code,
      );
      if (isSessionActive && ub.accessToken) {
        return { ub, code: ub.broker.code };
      }
    }
    throw new BadRequestException('No active broker session found');
  }

  @UseGuards(JwtAuthGuard)
  @Get('live/positions')
  async getLivePositions(@Request() req) {
    const userId = req.user.userId;
    const cacheKey = `live:positions:${userId}`;
    try {
      const cached = await this.redisService.getClient().get(cacheKey);
      if (cached) return JSON.parse(cached);
    } catch (_) {}

    const { ub, code } = await this.getActiveBroker(userId);
    const adapter = this.brokerFactory.getAdapter(code as unknown as BrokerType);
    const result = await adapter.getPositions(ub.accessToken!, ub.brokerClientId);

    try {
      await this.redisService.getClient().set(cacheKey, JSON.stringify(result), 'EX', 3);
    } catch (_) {}

    return result;
  }

  @UseGuards(JwtAuthGuard)
  @Get('live/holdings')
  async getLiveHoldings(@Request() req) {
    const userId = req.user.userId;
    const cacheKey = `live:holdings:${userId}`;
    try {
      const cached = await this.redisService.getClient().get(cacheKey);
      if (cached) return JSON.parse(cached);
    } catch (_) {}

    const { ub, code } = await this.getActiveBroker(userId);
    const adapter = this.brokerFactory.getAdapter(code as unknown as BrokerType);
    const result = await adapter.getHoldings(ub.accessToken!, ub.brokerClientId);

    try {
      await this.redisService.getClient().set(cacheKey, JSON.stringify(result), 'EX', 5);
    } catch (_) {}

    return result;
  }

  @UseGuards(JwtAuthGuard)
  @Get('live/orders')
  async getLiveOrders(@Request() req) {
    const userId = req.user.userId;
    const cacheKey = `live:orders:${userId}`;
    try {
      const cached = await this.redisService.getClient().get(cacheKey);
      if (cached) return JSON.parse(cached);
    } catch (_) {}

    const { ub, code } = await this.getActiveBroker(userId);
    const adapter = this.brokerFactory.getAdapter(code as unknown as BrokerType);
    const result = await adapter.getOrders(ub.accessToken!, ub.brokerClientId);

    try {
      await this.redisService.getClient().set(cacheKey, JSON.stringify(result), 'EX', 3);
    } catch (_) {}

    return result;
  }

  @UseGuards(JwtAuthGuard)
  @Get('live/trades')
  async getLiveTrades(@Request() req) {
    const userId = req.user.userId;
    const cacheKey = `live:trades:${userId}`;
    try {
      const cached = await this.redisService.getClient().get(cacheKey);
      if (cached) return JSON.parse(cached);
    } catch (_) {}

    const { ub, code } = await this.getActiveBroker(userId);
    const adapter = this.brokerFactory.getAdapter(code as unknown as BrokerType);
    const result = await adapter.getTradeBook(ub.accessToken!, ub.brokerClientId);

    try {
      await this.redisService.getClient().set(cacheKey, JSON.stringify(result), 'EX', 3);
    } catch (_) {}

    return result;
  }
}
