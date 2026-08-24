import { Controller, Get, Post, Body, Param, HttpException, HttpStatus } from '@nestjs/common';
import { ProxyManagerService } from './proxy-manager.service';
import { PrismaService } from '../prisma.service';

@Controller('api')
export class ProxyManagerController {
  constructor(
    private readonly proxyService: ProxyManagerService,
    private readonly prisma: PrismaService,
  ) {}

  /**
   * Primary automated user purchase endpoint
   */
  @Post('proxies/purchase')
  async purchaseProxy(@Body() body: { userBrokerId: string; validityMonths: number; iptype: 'ipv4' | 'ipv6' }) {
    if (!body.userBrokerId || !body.validityMonths || !body.iptype) {
      throw new HttpException('Missing required fields (userBrokerId, validityMonths, iptype)', HttpStatus.BAD_REQUEST);
    }
    return this.proxyService.purchaseProxy(body.userBrokerId, body.validityMonths, body.iptype);
  }

  @Get('admin/proxies')
  async getProxies() {
    const proxies = await this.prisma.proxyCredential.findMany({
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        ip: true,
        port: true,
        brokerName: true,
        validityMonths: true,
        issuedAt: true,
        expiresAt: true,
        status: true,
        orderId: true,
        userBrokerId: true,
        createdAt: true,
        userBroker: {
          select: {
            id: true,
            brokerClientId: true,
            user: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                email: true,
              },
            },
          },
        },
      },
    });
    return proxies;
  }

  @Get('admin/proxies/assignable-targets')
  async getAssignableTargets() {
    return this.proxyService.getAssignableTargets();
  }

  @Get('admin/proxies/balance')
  async getBalance() {
    return this.proxyService.checkBalance();
  }

  @Get('admin/proxies/broker-info')
  async getBrokerInfo() {
    return this.proxyService.getBrokerInfo();
  }

  @Post('admin/proxies/issue')
  async issueProxy(@Body() body: { brokerName: string; validityMonths: number; iptype: 'ipv4' | 'ipv6'; userBrokerId?: string }) {
    if (!body.brokerName || !body.validityMonths || !body.iptype) {
      throw new HttpException('Missing required fields', HttpStatus.BAD_REQUEST);
    }
    return this.proxyService.issueIp(body.brokerName, body.validityMonths, body.iptype, body.userBrokerId);
  }

  @Post('admin/proxies/:id/assign')
  async assignProxy(@Param('id') id: string, @Body() body: { userBrokerId: string }) {
    if (!body.userBrokerId) {
      throw new HttpException('Missing userBrokerId', HttpStatus.BAD_REQUEST);
    }
    return this.proxyService.assignProxy(id, body.userBrokerId);
  }

  @Post('admin/proxies/:id/unassign')
  async unassignProxy(@Param('id') id: string) {
    return this.proxyService.unassignProxy(id);
  }

  @Post('admin/proxies/:id/renew')
  async renewProxy(@Param('id') id: string, @Body() body: { validityMonths: number }) {
    if (!body.validityMonths) {
      throw new HttpException('Missing validityMonths', HttpStatus.BAD_REQUEST);
    }
    return this.proxyService.renewIp(id, body.validityMonths);
  }

  @Get('admin/proxies/test-direct')
  async testDirectEgress() {
    return this.proxyService.testDirectEgress();
  }

  @Get('admin/proxies/:id/test')
  async testProxyEgress(@Param('id') id: string) {
    return this.proxyService.testProxyEgress(id);
  }

  @Get('admin/proxies/:id')
  async getProxy(@Param('id') id: string) {
    const proxy = await this.prisma.proxyCredential.findUnique({
      where: { id },
      select: {
        id: true,
        ip: true,
        port: true,
        brokerName: true,
        validityMonths: true,
        issuedAt: true,
        expiresAt: true,
        status: true,
        orderId: true,
        userBrokerId: true,
        createdAt: true,
        userBroker: {
          select: {
            id: true,
            brokerClientId: true,
            user: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                email: true,
              },
            },
          },
        },
      },
    });
    if (!proxy) throw new HttpException('Proxy not found', HttpStatus.NOT_FOUND);
    return proxy;
  }

  /**
   * Privileged endpoint: view raw proxy credentials
   */
  @Get('admin/proxies/:id/credentials')
  async getProxyCredentials(@Param('id') id: string) {
    const proxy = await this.prisma.proxyCredential.findUnique({
      where: { id },
    });
    if (!proxy) throw new HttpException('Proxy not found', HttpStatus.NOT_FOUND);
    
    return {
      ip_userid: proxy.ip_userid,
      ip_password: proxy.ip_password,
    };
  }

  @Get('admin/proxies/order/:orderId')
  async checkOrderStatus(@Param('orderId') orderId: string) {
    return this.proxyService.checkOrderStatus(orderId);
  }
}
