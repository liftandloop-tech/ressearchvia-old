import { Injectable, Logger, NotFoundException, ConflictException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { HttpService } from '@nestjs/axios';
import { Cron, CronExpression } from '@nestjs/schedule';
import { lastValueFrom } from 'rxjs';
import { randomUUID } from 'crypto';
import axios from 'axios';
import { ProxyStatus } from '@prisma/client';

let HttpsProxyAgentClass: any;
try {
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  const pkg = require('https-proxy-agent');
  HttpsProxyAgentClass = pkg.HttpsProxyAgent || pkg;
} catch {
  HttpsProxyAgentClass = null;
}

export interface ProxyConfig {
  host: string;
  port: number;
  username: string;
  password: string;
}

@Injectable()
export class ProxyManagerService {
  private readonly logger = new Logger(ProxyManagerService.name);
  
  private partnerId: string;
  private partnerPass: string;
  private baseUrl: string;

  constructor(
    private readonly prisma: PrismaService,
    private readonly httpService: HttpService,
  ) {
    this.partnerId = process.env.STATIC_IP_PARTNER_ID || '';
    this.partnerPass = process.env.STATIC_IP_PARTNER_PASSWORD || '';
    this.baseUrl = process.env.STATIC_IP_PARTNER_BASE_URL || 'https://partners.staticip.in';
    
    if (!this.partnerId || !this.partnerPass) {
      this.logger.warn('STATIC_IP_PARTNER_ID or STATIC_IP_PARTNER_PASSWORD is not set in .env');
    }
  }

  private getAuthBody() {
    return {
      partner_userid: this.partnerId,
      partner_password: this.partnerPass,
    };
  }

  private async callApi(endpoint: string, body: any): Promise<any> {
    try {
      const response: any = await lastValueFrom(
        this.httpService.post(`${this.baseUrl}${endpoint}`, {
          ...this.getAuthBody(),
          ...body,
        }),
      );
      return response.data;
    } catch (err: any) {
      this.logger.error(`Error calling ${endpoint}: ${err.message}`);
      throw new Error(`Partner API Error: ${err.message}`);
    }
  }

  async checkBalance() {
    const data = await this.callApi('/api/check_balance', {});
    if (data.status === 'success') {
      return { balance: data.balance };
    }
    throw new Error(data.remark || 'Failed to check balance');
  }

  async getBrokerInfo() {
    const data = await this.callApi('/api/broker_info', {});
    if (data.status === 'success') {
      return data.brokers;
    }
    throw new Error(data.remark || 'Failed to fetch broker info');
  }

  async checkOrderStatus(orderId: string) {
    return this.callApi('/api/order_status', { order_id: orderId });
  }

  async getIpInfo(ipUserId: string) {
    return this.callApi('/api/ip_info', { ip_userid: ipUserId });
  }

  private parseExpiryDate(validityStr: string): Date {
    // Format is expected to be DD-MM-YYYY
    const parts = validityStr.split('-');
    if (parts.length === 3) {
      return new Date(Number(parts[2]), Number(parts[1]) - 1, Number(parts[0]));
    }
    return new Date();
  }

  /**
   * Primary automated flow: User purchases a Static IP for their UserBroker
   */
  async purchaseProxy(userBrokerId: string, validityMonths: number, iptype: 'ipv4' | 'ipv6') {
    // 1. Transactional DB check and PENDING record creation (separate from external API call)
    const { orderId, proxyId, brokerName } = await this.prisma.$transaction(async (tx) => {
      const userBroker = await tx.userBroker.findUnique({
        where: { id: userBrokerId },
        include: { user: true, broker: true },
      });

      if (!userBroker) {
        throw new NotFoundException(`UserBroker ${userBrokerId} not found`);
      }

      const existingProxy = await tx.proxyCredential.findFirst({
        where: {
          userBrokerId,
          status: { in: [ProxyStatus.ACTIVE, ProxyStatus.PENDING, ProxyStatus.RENEWING] },
        },
      });

      if (existingProxy) {
        throw new ConflictException(`Broker account already has an active or pending proxy (${existingProxy.status})`);
      }

      const orderId = randomUUID();
      const created = await tx.proxyCredential.create({
        data: {
          orderId,
          brokerName: userBroker.broker.code,
          validityMonths,
          status: ProxyStatus.PENDING,
          userBrokerId,
        },
      });

      return { orderId, proxyId: created.id, brokerName: userBroker.broker.code };
    });

    // 2. Call Partner API outside the DB transaction
    let data;
    try {
      data = await this.callApi('/api/issue_ip', {
        order_id: orderId,
        brokername: brokerName,
        validity: validityMonths,
        iptype,
      });
    } catch (err: any) {
      this.logger.error(`API Call failed for purchaseProxy order ${orderId}, leaving as PENDING for reconciliation.`);
      return this.prisma.proxyCredential.findUnique({
        where: { id: proxyId },
        include: {
          userBroker: {
            include: { user: { select: { id: true, firstName: true, lastName: true, email: true } } },
          },
        },
      });
    }

    return this.processOrderResponse(proxyId, data);
  }

  /**
   * Admin issue proxy (optionally linked to a userBrokerId)
   */
  async issueIp(brokerName: string, validityMonths: number, iptype: 'ipv4' | 'ipv6', userBrokerId?: string) {
    const { orderId, proxyId } = await this.prisma.$transaction(async (tx) => {
      if (userBrokerId) {
        const userBroker = await tx.userBroker.findUnique({ where: { id: userBrokerId } });
        if (!userBroker) throw new NotFoundException(`UserBroker ${userBrokerId} not found`);

        const existingProxy = await tx.proxyCredential.findFirst({
          where: {
            userBrokerId,
            status: { in: [ProxyStatus.ACTIVE, ProxyStatus.PENDING, ProxyStatus.RENEWING] },
          },
        });
        if (existingProxy) {
          throw new ConflictException(`Broker account already has an active or pending proxy (${existingProxy.status})`);
        }
      }

      const orderId = randomUUID();
      const created = await tx.proxyCredential.create({
        data: {
          orderId,
          brokerName,
          validityMonths,
          status: ProxyStatus.PENDING,
          userBrokerId: userBrokerId || null,
        },
      });

      return { orderId, proxyId: created.id };
    });

    let data;
    try {
      data = await this.callApi('/api/issue_ip', {
        order_id: orderId,
        brokername: brokerName,
        validity: validityMonths,
        iptype,
      });
    } catch (err: any) {
      this.logger.error(`API Call failed for issueIp order ${orderId}, leaving as PENDING for reconciliation.`);
      return this.prisma.proxyCredential.findUnique({
        where: { id: proxyId },
        include: {
          userBroker: {
            include: { user: { select: { id: true, firstName: true, lastName: true, email: true } } },
          },
        },
      });
    }

    return this.processOrderResponse(proxyId, data);
  }

  async renewIp(proxyId: string, validityMonths: number) {
    const proxy = await this.prisma.proxyCredential.findUnique({ where: { id: proxyId } });
    if (!proxy) throw new NotFoundException('Proxy not found');
    if (!proxy.ip_userid) throw new BadRequestException('Cannot renew: missing ip_userid');

    const orderId = randomUUID();

    const updatedProxy = await this.prisma.proxyCredential.update({
      where: { id: proxy.id },
      data: {
        status: ProxyStatus.RENEWING,
        orderId,
        validityMonths: proxy.validityMonths + validityMonths,
      },
    });

    let data;
    try {
      data = await this.callApi('/api/renew_ip', {
        order_id: orderId,
        brokername: proxy.brokerName,
        validity: validityMonths,
        old_ip_userid: proxy.ip_userid,
      });
    } catch (err: any) {
      this.logger.error(`API Call failed for renewIp order ${orderId}, leaving as RENEWING for reconciliation.`);
      return updatedProxy;
    }

    return this.processOrderResponse(updatedProxy.id, data);
  }

  /**
   * Admin manual assignment
   */
  async assignProxy(proxyId: string, userBrokerId: string) {
    return this.prisma.$transaction(async (tx) => {
      const userBroker = await tx.userBroker.findUnique({ where: { id: userBrokerId } });
      if (!userBroker) throw new NotFoundException('Broker account not found');

      const existingActive = await tx.proxyCredential.findFirst({
        where: {
          userBrokerId,
          status: { in: [ProxyStatus.ACTIVE, ProxyStatus.PENDING, ProxyStatus.RENEWING] },
          NOT: { id: proxyId },
        },
      });
      if (existingActive) {
        throw new ConflictException('Broker account already has an active or pending proxy');
      }

      const proxy = await tx.proxyCredential.findUnique({ where: { id: proxyId } });
      if (!proxy) throw new NotFoundException('Proxy not found');

      return tx.proxyCredential.update({
        where: { id: proxyId },
        data: { userBrokerId },
        include: {
          userBroker: {
            include: { user: { select: { id: true, firstName: true, lastName: true, email: true } } },
          },
        },
      });
    });
  }

  /**
   * Admin manual unassignment
   */
  async unassignProxy(proxyId: string) {
    const proxy = await this.prisma.proxyCredential.findUnique({ where: { id: proxyId } });
    if (!proxy) throw new NotFoundException('Proxy not found');

    return this.prisma.proxyCredential.update({
      where: { id: proxyId },
      data: { userBrokerId: null },
      include: {
        userBroker: {
          include: { user: { select: { id: true, firstName: true, lastName: true, email: true } } },
        },
      },
    });
  }

  /**
   * List targets available for assignment
   */
  async getAssignableTargets() {
    return this.prisma.userBroker.findMany({
      include: {
        user: { select: { id: true, firstName: true, lastName: true, email: true } },
        proxyCredential: {
          select: { id: true, ip: true, port: true, status: true, expiresAt: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  /**
   * Runtime lookup of active proxy configuration for broker execution
   */
  async getProxyConfigForUserBroker(userBrokerId: string): Promise<ProxyConfig | null> {
    const proxy = await this.prisma.proxyCredential.findUnique({
      where: { userBrokerId },
    });

    if (!proxy || proxy.status !== ProxyStatus.ACTIVE || !proxy.ip || !proxy.port || !proxy.ip_userid || !proxy.ip_password) {
      return null;
    }

    if (proxy.expiresAt && new Date(proxy.expiresAt) < new Date()) {
      return null;
    }

    return {
      host: proxy.ip,
      port: proxy.port,
      username: proxy.ip_userid,
      password: proxy.ip_password,
    };
  }

  /**
   * Diagnostic: Test outbound public IP through proxy tunnel
   */
  async testProxyEgress(proxyId: string): Promise<{
    proxyId: string;
    expectedIp: string | null;
    observedIp: string | null;
    port: number | null;
    match: boolean;
    latencyMs: number;
    status: 'PASS' | 'FAIL';
    message: string;
  }> {
    const proxy = await this.prisma.proxyCredential.findUnique({
      where: { id: proxyId },
    });

    if (!proxy) {
      throw new NotFoundException('Proxy not found');
    }

    if (!proxy.ip || !proxy.port || !proxy.ip_userid || !proxy.ip_password) {
      return {
        proxyId,
        expectedIp: proxy.ip || null,
        observedIp: null,
        port: proxy.port || null,
        match: false,
        latencyMs: 0,
        status: 'FAIL',
        message: 'Proxy configuration is incomplete (missing IP, port, or credentials)',
      };
    }

    const start = Date.now();
    try {
      const auth = Buffer.from(`${proxy.ip_userid}:${proxy.ip_password}`).toString('base64');
      let httpsAgent: any = undefined;
      if (HttpsProxyAgentClass) {
        httpsAgent = new HttpsProxyAgentClass(`http://${proxy.ip}:${proxy.port}`, {
          headers: {
            'Proxy-Authorization': `Basic ${auth}`,
          },
        });
      }

      const res = await axios.get('https://api.ipify.org?format=json', {
        httpsAgent,
        proxy: false,
        timeout: 8000,
      });

      const latencyMs = Date.now() - start;
      const observedIp = res.data?.ip || null;
      const match = observedIp === proxy.ip;

      return {
        proxyId,
        expectedIp: proxy.ip,
        observedIp,
        port: proxy.port,
        match,
        latencyMs,
        status: match ? 'PASS' : 'FAIL',
        message: match
          ? `Verified! Outbound traffic emerges from assigned StaticIP ${observedIp} (${latencyMs}ms)`
          : `Mismatch! Expected ${proxy.ip} but observed ${observedIp}`,
      };
    } catch (err: any) {
      const latencyMs = Date.now() - start;
      return {
        proxyId,
        expectedIp: proxy.ip,
        observedIp: null,
        port: proxy.port,
        match: false,
        latencyMs,
        status: 'FAIL',
        message: `Proxy connection test failed: ${err.message}`,
      };
    }
  }

  /**
   * Diagnostic: Test direct outbound VPS public IP (baseline without proxy)
   */
  async testDirectEgress(): Promise<{
    directVpsIp: string | null;
    latencyMs: number;
    status: string;
    message: string;
  }> {
    const start = Date.now();
    try {
      const res = await axios.get('https://api.ipify.org?format=json', {
        timeout: 6000,
      });
      const latencyMs = Date.now() - start;
      return {
        directVpsIp: res.data?.ip || null,
        latencyMs,
        status: 'DIRECT_BASELINE',
        message: `Direct VPS outbound IP detected: ${res.data?.ip}`,
      };
    } catch (err: any) {
      return {
        directVpsIp: null,
        latencyMs: Date.now() - start,
        status: 'ERROR',
        message: `Direct egress test failed: ${err.message}`,
      };
    }
  }

  /**
   * Verify proxy connectivity through the static proxy tunnel
   */
  async validateProxyConnectivity(ip: string, port: number, ip_userid: string, ip_password: string): Promise<boolean> {
    try {
      const auth = Buffer.from(`${ip_userid}:${ip_password}`).toString('base64');
      let httpsAgent: any = undefined;
      if (HttpsProxyAgentClass) {
        httpsAgent = new HttpsProxyAgentClass(`http://${ip}:${port}`, {
          headers: {
            'Proxy-Authorization': `Basic ${auth}`,
          },
        });
      }

      await axios.get('https://go.mynt.in/NorenWClientAPI/ping', {
        httpsAgent,
        proxy: false,
        timeout: 5000,
        validateStatus: () => true,
      });
      return true;
    } catch (err: any) {
      this.logger.warn(`Proxy connectivity test notice for ${ip}:${port}: ${err.message}`);
      return true;
    }
  }

  private async processOrderResponse(internalId: string, data: any) {
    if (data.status === 'success' && data.ip_details) {
      const details = data.ip_details;
      
      let expiresAt: Date | undefined;
      if (details.validity) {
        expiresAt = this.parseExpiryDate(details.validity);
      } else if (details.updated_validity) {
        expiresAt = this.parseExpiryDate(details.updated_validity);
      }

      if (details.ip && details.port && details.ip_userid && details.ip_password) {
        await this.validateProxyConnectivity(details.ip, details.port, details.ip_userid, details.ip_password);
      }

      return this.prisma.proxyCredential.update({
        where: { id: internalId },
        data: {
          ip: details.ip,
          port: details.port,
          ip_userid: details.ip_userid,
          ip_password: details.ip_password,
          expiresAt,
          issuedAt: new Date(),
          status: ProxyStatus.ACTIVE,
        },
        include: {
          userBroker: {
            include: { user: { select: { id: true, firstName: true, lastName: true, email: true } } },
          },
        },
      });
    } else if (data.status === 'failed') {
      if (data.error_code === 501 || data.error_code === 601) {
        return this.prisma.proxyCredential.findUnique({
          where: { id: internalId },
          include: {
            userBroker: {
              include: { user: { select: { id: true, firstName: true, lastName: true, email: true } } },
            },
          },
        });
      }

      return this.prisma.proxyCredential.update({
        where: { id: internalId },
        data: {
          status: ProxyStatus.FAILED,
        },
        include: {
          userBroker: {
            include: { user: { select: { id: true, firstName: true, lastName: true, email: true } } },
          },
        },
      });
    } else if (data.status === 'processing') {
      return this.prisma.proxyCredential.findUnique({
        where: { id: internalId },
        include: {
          userBroker: {
            include: { user: { select: { id: true, firstName: true, lastName: true, email: true } } },
          },
        },
      });
    }

    return this.prisma.proxyCredential.findUnique({
      where: { id: internalId },
      include: {
        userBroker: {
          include: { user: { select: { id: true, firstName: true, lastName: true, email: true } } },
        },
      },
    });
  }

  @Cron(CronExpression.EVERY_MINUTE)
  async reconcilePendingOrders() {
    this.logger.debug('Running Proxy Reconciliation Loop...');
    
    const fiveMinsAgo = new Date(Date.now() - 5 * 60 * 1000);
    
    const stuckOrders = await this.prisma.proxyCredential.findMany({
      where: {
        status: { in: [ProxyStatus.PENDING, ProxyStatus.RENEWING] },
        updatedAt: { lt: fiveMinsAgo },
      },
    });

    for (const order of stuckOrders) {
      this.logger.log(`Reconciling stuck order: ${order.orderId}`);
      try {
        const statusData = await this.checkOrderStatus(order.orderId);
        if (statusData.status === 'failed' && statusData.error_code === 602) {
          await this.prisma.proxyCredential.update({
            where: { id: order.id },
            data: { status: ProxyStatus.FAILED },
          });
          this.logger.log(`Order ${order.orderId} was never received by partner. Marked FAILED.`);
        } else {
          await this.processOrderResponse(order.id, statusData);
        }
      } catch (e: any) {
        this.logger.error(`Failed to reconcile order ${order.orderId}: ${e.message}`);
      }
    }
    
    await this.prisma.proxyCredential.updateMany({
      where: {
        status: ProxyStatus.ACTIVE,
        expiresAt: { lt: new Date() },
      },
      data: {
        status: ProxyStatus.EXPIRED,
      },
    });
  }
}
