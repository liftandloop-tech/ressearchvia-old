/**
 * Zebu API endpoint paths.
 * Base URL: https://go.mynt.in/NorenWClientAPI
 *
 * All requests are POST with form-encoded body:
 *   jData=<JSON-string>&jKey=<susertoken>
 *
 * Authentication: Uses OAuth 2.0 flow via /OAuthlogin/authorize/oauth,
 * GenAcsTok (/GenAcsTok), and RefreshToken (/RefreshToken).
 * susertoken is returned from GenAcsTok and
 * must be included as `jKey` in every subsequent request body.
 */
export const ZebuEndpoints = {

  /** Fetch client profile details */
  CLIENT_DETAILS: '/ClientDetails',

  /** Fetch account limits / margin / funds */
  LIMITS: '/Limits',

  /** Day-wise position book */
  POSITION_BOOK: '/PositionBook',

  /** Equity holdings */
  HOLDINGS: '/Holdings',

  /** Place a new order */
  PLACE_ORDER: '/PlaceOrder',

  /** Modify an existing order */
  MODIFY_ORDER: '/ModifyOrder',

  /** Cancel an existing order */
  CANCEL_ORDER: '/CancelOrder',

  /** Fetch the order book (all orders for the day) */
  ORDER_BOOK: '/OrderBook',

  /** Fetch executed trades for the day */
  TRADE_BOOK: '/TradeBook',

  /** Fetch Last Traded Price / market quotes for a scrip */
  GET_QUOTES: '/GetQuotes',

  /** Logout and invalidate the session token */
  LOGOUT: '/Logout',

  /** Zebu OAuth access token generation */
  GEN_ACCESS_TOKEN: '/GenAcsTok',

  /** Zebu OAuth token refresh */
  REFRESH_TOKEN: '/RefreshToken',
} as const;
