import {
  Controller,
  Get,
  Post,
  UseGuards,
  Request,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { EgressService } from './egress.service';

@Controller('egress')
export class EgressController {
  constructor(private readonly egressService: EgressService) {}

  @UseGuards(JwtAuthGuard)
  @Get('status')
  async getUserEgressStatus(@Request() req) {
    const userId = req.user.userId;
    try {
      const resolved = await this.egressService.resolveEgress(userId);
      return { success: true, assignment: resolved };
    } catch (err: any) {
      return { success: false, message: err.message };
    }
  }

  @UseGuards(JwtAuthGuard)
  @Post('allocate')
  @HttpCode(HttpStatus.OK)
  async allocateUserEgress(@Request() req) {
    const userId = req.user.userId;
    const creds = await this.egressService.allocateEgress(userId);
    return {
      success: true,
      publicIp: creds.publicIp,
      proxyUsername: creds.proxyUsername,
      proxyEndpoint: `http://${creds.proxyHost}:${creds.proxyPort}`,
    };
  }

  @UseGuards(JwtAuthGuard)
  @Post('rotate')
  @HttpCode(HttpStatus.OK)
  async rotateUserCredentials(@Request() req) {
    const userId = req.user.userId;
    const creds = await this.egressService.rotateToken(userId);
    return {
      success: true,
      publicIp: creds.publicIp,
      proxyUsername: creds.proxyUsername,
    };
  }

  @UseGuards(JwtAuthGuard)
  @Post('release')
  @HttpCode(HttpStatus.OK)
  async releaseUserEgress(@Request() req) {
    const userId = req.user.userId;
    const success = await this.egressService.releaseEgress(userId);
    return { success, message: success ? 'Egress IP released back to pool' : 'Release failed' };
  }

  @UseGuards(JwtAuthGuard)
  @Get('test')
  async testEgressConnectivity(@Request() req) {
    const userId = req.user.userId;
    return this.egressService.testEgressConnectivity(userId);
  }

  @UseGuards(JwtAuthGuard)
  @Get('pool-status')
  async getPoolStatus() {
    return this.egressService.getPoolStatus();
  }

  @UseGuards(JwtAuthGuard)
  @Post('reconcile')
  @HttpCode(HttpStatus.OK)
  async reconcileProxy() {
    const success = await this.egressService.reconcileProxy();
    return { success, message: success ? 'Proxy mappings reconciled' : 'Reconciliation failed' };
  }
}
