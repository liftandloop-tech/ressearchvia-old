"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AngelOneEndpoints = void 0;
exports.AngelOneEndpoints = {
    LOGIN: '/rest/auth/angelbroking/user/v1/loginByPassword',
    PROFILE: '/rest/secure/angelbroking/user/v1/getProfile',
    ORDER_BOOK: '/rest/secure/angelbroking/order/v1/getOrderBook',
    POSITION: '/rest/secure/angelbroking/order/v1/getPosition',
    HOLDINGS: '/rest/secure/angelbroking/portfolio/v1/getHolding',
    FUNDS: '/rest/secure/angelbroking/user/v1/getRMS',
    PLACE_ORDER: '/rest/secure/angelbroking/order/v1/placeOrder',
    MODIFY_ORDER: '/rest/secure/angelbroking/order/v1/modifyOrder',
    CANCEL_ORDER: '/rest/secure/angelbroking/order/v1/cancelOrder',
    TRADE_BOOK: '/rest/secure/angelbroking/order/v1/getTradeBook',
    LTP_DATA: '/rest/secure/angelbroking/order/v1/getLtpData',
    ORDER_DETAILS: '/rest/secure/angelbroking/order/v1/details/',
    REFRESH_TOKEN: '/rest/auth/angelbroking/jwt/v1/generateTokens',
};
//# sourceMappingURL=angel-one-endpoints.js.map