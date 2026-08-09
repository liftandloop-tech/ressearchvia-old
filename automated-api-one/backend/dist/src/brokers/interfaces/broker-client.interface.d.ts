export interface OrderRequest {
    symbol: string;
    exchange: string;
    quantity: number;
    price?: number;
    orderType: 'MARKET' | 'LIMIT' | 'SL' | 'STOPLOSS_LIMIT' | 'STOPLOSS_MARKET';
    side: 'BUY' | 'SELL';
    triggerPrice?: number;
    squareoff?: number;
    stoploss?: number;
    trailingStopLoss?: number;
    metadata?: {
        segmentId?: string;
        clientId?: string;
        tradeId?: string;
    };
}
export interface OrderResponse {
    brokerOrderId: string;
    status: 'PENDING' | 'EXECUTED' | 'REJECTED' | 'CANCELLED';
    message?: string;
}
export interface SessionResponse {
    accessToken: string;
    refreshToken?: string;
    tokenExpiry: Date;
}
export interface BrokerCallbackData {
    params: Record<string, string | undefined>;
}
export interface BrokerSession {
    accessToken: string;
    refreshToken?: string;
    feedToken?: string;
    expiresAt?: Date;
    brokerUserId?: string;
}
export interface PositionResponse {
    symbol: string;
    quantity: number;
    avgPrice: number;
    currentPrice: number;
    unrealizedPnl: number;
    realizedPnl: number;
}
export interface HoldingResponse {
    symbol: string;
    quantity: number;
    avgPrice: number;
    currentPrice: number;
    unrealizedPnl?: number;
    collateralQuantity?: number;
}
export interface FundsResponse {
    availableMargin: number;
    usedMargin: number;
    totalMargin: number;
}
export interface BrokerHealthResponse {
    reachable: boolean;
    responseTimeMs: number;
}
export interface BrokerCapabilities {
    positions: boolean;
    holdings: boolean;
    funds: boolean;
    gtt: boolean;
    margin: boolean;
}
export interface ProfileResponse {
    clientcode: string;
    name: string;
    email: string;
    mobileno: string;
    exchanges: string[];
    products: string[];
    lastlogintime: string;
    brokerid: string;
    activeStatus: string;
}
export interface BrokerClient {
    generateSession(credentials: {
        clientCode: string;
        password: string;
        totpKey: string;
        apiKey?: string;
        vendorCode?: string;
    }): Promise<SessionResponse>;
    getAuthorizationUrl(state: string): Promise<string>;
    completeAuthorization(callbackData: BrokerCallbackData): Promise<BrokerSession>;
    validateSession(token: string): Promise<boolean>;
    getMargin(token: string, clientCode: string): Promise<number>;
    getProfile(token: string, clientCode?: string): Promise<ProfileResponse>;
    getOrders(token: string, clientCode: string): Promise<any[]>;
    placeOrder(token: string, clientCode: string, order: OrderRequest): Promise<OrderResponse>;
    getOrderStatus(token: string, clientCode: string, brokerOrderId: string): Promise<OrderResponse>;
    getPositions(token: string, clientCode: string): Promise<PositionResponse[]>;
    getHoldings(token: string, clientCode: string): Promise<HoldingResponse[]>;
    getFunds(token: string, clientCode: string): Promise<FundsResponse>;
    refreshSession(token: string, refreshToken: string): Promise<SessionResponse>;
    healthCheck(): Promise<BrokerHealthResponse>;
    capabilities(): BrokerCapabilities;
    modifyOrder(token: string, clientCode: string, orderId: string, variety: string, order: {
        quantity: number;
        price?: number;
        ordertype?: string;
        producttype?: string;
        duration?: string;
    }): Promise<OrderResponse>;
    cancelOrder(token: string, clientCode: string, orderId: string, variety: string): Promise<OrderResponse>;
    getTradeBook(token: string, clientCode: string): Promise<BrokerTrade[]>;
    getLtpData(token: string, exchange: string, symbol: string, symbolToken: string): Promise<BrokerLtp>;
    getOrderDetails(token: string, clientCode: string, orderId: string): Promise<OrderResponse>;
}
export interface BrokerTrade {
    tradeId: string;
    orderId: string;
    symbol: string;
    quantity: number;
    price: number;
    side: 'BUY' | 'SELL';
    executedAt: Date;
}
export interface BrokerLtp {
    exchange: string;
    symbol: string;
    token: string;
    ltp: number;
    timestamp: Date;
}
