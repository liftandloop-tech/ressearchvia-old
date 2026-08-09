import {
  SessionResponse,
  OrderRequest,
  OrderResponse,
  PositionResponse,
  HoldingResponse,
  FundsResponse,
  BrokerHealthResponse,
  BrokerCapabilities,
  BrokerTrade,
  BrokerLtp,
  BrokerCallbackData,
  BrokerSession,
} from './broker-client.interface';

export abstract class BrokerAdapter {
  abstract generateSession(credentials: {
    clientCode: string;
    password: string;
    totpKey: string;
    apiKey?: string;     // Per-user API key (e.g. Zebu appkey); ignored by OAuth-based brokers
    vendorCode?: string; // Per-user vendor code (e.g. Zebu vc); ignored by OAuth-based brokers
  }): Promise<SessionResponse>;
  abstract getAuthorizationUrl(state: string): Promise<string>;
  abstract completeAuthorization(callbackData: BrokerCallbackData): Promise<BrokerSession>;
  abstract validateSession(token: string): Promise<boolean>;
  abstract getMargin(token: string, clientCode: string): Promise<number>;
  abstract getProfile(token: string, clientCode?: string): Promise<any>;
  abstract getOrders(token: string, clientCode: string): Promise<any[]>;
  abstract placeOrder(
    token: string,
    clientCode: string,
    order: OrderRequest,
  ): Promise<OrderResponse>;
  abstract getOrderStatus(
    token: string,
    clientCode: string,
    brokerOrderId: string,
  ): Promise<OrderResponse>;
  abstract getPositions(
    token: string,
    clientCode: string,
  ): Promise<PositionResponse[]>;
  abstract getHoldings(
    token: string,
    clientCode: string,
  ): Promise<HoldingResponse[]>;
  abstract getFunds(token: string, clientCode: string): Promise<FundsResponse>;
  abstract refreshSession(
    token: string,
    refreshToken: string,
  ): Promise<SessionResponse>;
  abstract healthCheck(): Promise<BrokerHealthResponse>;
  abstract capabilities(): BrokerCapabilities;

  abstract modifyOrder(
    token: string,
    clientCode: string,
    orderId: string,
    variety: string,
    order: { quantity: number; price?: number; ordertype?: string; producttype?: string; duration?: string }
  ): Promise<OrderResponse>;

  abstract cancelOrder(
    token: string,
    clientCode: string,
    orderId: string,
    variety: string
  ): Promise<OrderResponse>;

  abstract getTradeBook(
    token: string,
    clientCode: string
  ): Promise<BrokerTrade[]>;

  abstract getLtpData(
    token: string,
    exchange: string,
    symbol: string,
    symbolToken: string
  ): Promise<BrokerLtp>;

  abstract getOrderDetails(
    token: string,
    clientCode: string,
    orderId: string
  ): Promise<OrderResponse>;
}

