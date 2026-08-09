"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.WebsocketEvent = void 0;
var WebsocketEvent;
(function (WebsocketEvent) {
    WebsocketEvent["ORDER_EXECUTED"] = "order.executed";
    WebsocketEvent["ORDER_REJECTED"] = "order.rejected";
    WebsocketEvent["POSITION_UPDATED"] = "position.updated";
    WebsocketEvent["TARGET_HIT"] = "target.hit";
    WebsocketEvent["STOPLOSS_HIT"] = "stoploss.hit";
    WebsocketEvent["SIGNAL_RECEIVED"] = "signal.received";
    WebsocketEvent["SIGNAL_COMPLETED"] = "signal.completed";
    WebsocketEvent["RISK_LOCKED"] = "risk.locked";
    WebsocketEvent["RISK_UNLOCKED"] = "risk.unlocked";
    WebsocketEvent["BROKER_DISCONNECTED"] = "broker.disconnected";
    WebsocketEvent["CONSENT_REQUIRED"] = "consent.required";
    WebsocketEvent["SUBSCRIPTION_EXPIRED"] = "subscription.expired";
})(WebsocketEvent || (exports.WebsocketEvent = WebsocketEvent = {}));
//# sourceMappingURL=websocket-event.enum.js.map