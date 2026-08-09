import { BrokerAdapter } from '../../src/brokers/interfaces/broker-adapter.interface';
import {
  SessionResponse,
  OrderRequest,
  OrderResponse,
} from '../../src/brokers/interfaces/broker-client.interface';

export class MockBrokerAdapter extends BrokerAdapter {
  async generateSession(credentials: {
    clientCode: string;
    password: string;
    totpKey: string;
    apiKey?: string;
    vendorCode?: string;
  }): Promise<SessionResponse> {
    return {
      accessToken:
        'mock_angel_one_access_token_' +
        credentials.clientCode +
        '_' +
        Date.now(),
      refreshToken: 'mock_refresh_' + credentials.clientCode,
      tokenExpiry: new Date(Date.now() + 12 * 60 * 60 * 1000),
    };
  }

  async validateSession(token: string): Promise<boolean> {
    if (token === 'TOKEN_EXPIRED') {
      return false;
    }
    return true;
  }

  async getMargin(token: string, clientCode: string): Promise<number> {
    if (clientCode === 'CLIENT_FAIL') {
      return 0.0;
    }
    return 100000.0;
  }

  async getAuthorizationUrl(state: string): Promise<string> {
    return `https://mock.auth.url?state=${state}`;
  }

  async completeAuthorization(callbackData: any): Promise<any> {
    return {
      accessToken: 'mock_token',
      refreshToken: 'mock_refresh',
      brokerUserId: 'MOCK123',
    };
  }

  async getProfile(token: string, clientCode?: string): Promise<any> {
    return {
      clientcode: clientCode || 'MOCK123',
      name: 'MOCK USER',
      email: 'mock@example.com',
      mobileno: '9999999999',
      exchanges: ['NSE'],
      products: ['CNC'],
      lastlogintime: new Date().toISOString(),
      brokerid: 'MOCK',
      activeStatus: 'ACTIVE',
    };
  }

  async getOrders(token: string, clientCode: string): Promise<any[]> {
    return [];
  }

  async placeOrder(
    token: string,
    clientCode: string,
    order: OrderRequest,
  ): Promise<OrderResponse> {
    if (clientCode === 'CLIENT_FAIL') {
      return {
        brokerOrderId: '',
        status: 'REJECTED',
        message: 'Insufficient Funds',
      };
    }
    return {
      brokerOrderId: 'TEST123',
      status: 'EXECUTED',
    };
  }

  async getOrderStatus(
    token: string,
    clientCode: string,
    brokerOrderId: string,
  ): Promise<OrderResponse> {
    return { brokerOrderId, status: 'EXECUTED' };
  }

  async getPositions(
    token: string,
    clientCode: string,
  ): Promise<any[]> {
    return [];
  }

  async getHoldings(
    token: string,
    clientCode: string,
  ): Promise<any[]> {
    return [];
  }

  async getFunds(
    token: string,
    clientCode: string,
  ): Promise<any> {
    return { available: 100000.0, total: 100000.0 };
  }

  async refreshSession(
    token: string,
    refreshToken: string,
  ): Promise<SessionResponse> {
    return {
      accessToken: 'refreshed_access_token_' + Date.now(),
      refreshToken: 'refreshed_refresh_token',
      tokenExpiry: new Date(Date.now() + 12 * 60 * 60 * 1000),
    };
  }

  async healthCheck(): Promise<any> {
    return { status: 'GREEN', latencyMs: 15 };
  }

  capabilities(): any {
    return { canShort: true, supportsOptions: true };
  }

  async modifyOrder(
    token: string,
    clientCode: string,
    orderId: string,
    variety: string,
    order: { quantity: number; price?: number; ordertype?: string; producttype?: string; duration?: string }
  ): Promise<OrderResponse> {
    return { brokerOrderId: orderId, status: 'PENDING' };
  }

  async cancelOrder(
    token: string,
    clientCode: string,
    orderId: string,
    variety: string
  ): Promise<OrderResponse> {
    return { brokerOrderId: orderId, status: 'CANCELLED' };
  }

  async getTradeBook(
    token: string,
    clientCode: string
  ): Promise<any[]> {
    return [];
  }

  async getLtpData(
    token: string,
    exchange: string,
    symbol: string,
    symbolToken: string
  ): Promise<any> {
    return {
      exchange,
      symbol,
      token: symbolToken,
      ltp: 100.0,
      timestamp: new Date(),
    };
  }

  async getOrderDetails(
    token: string,
    clientCode: string,
    orderId: string
  ): Promise<OrderResponse> {
    return { brokerOrderId: orderId, status: 'EXECUTED' };
  }
}

