"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var TwilioProvider_1, Msg91Provider_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.Msg91Provider = exports.TwilioProvider = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
let TwilioProvider = TwilioProvider_1 = class TwilioProvider {
    config;
    logger = new common_1.Logger(TwilioProvider_1.name);
    constructor(config) {
        this.config = config;
    }
    async sendSms(to, message) {
        if (to.includes('twilio-fail')) {
            throw new Error('Twilio failed to send SMS');
        }
        this.logger.log(`[Twilio Mock] Sending SMS to ${to}: ${message}`);
        return `twilio-${Date.now()}`;
    }
};
exports.TwilioProvider = TwilioProvider;
exports.TwilioProvider = TwilioProvider = TwilioProvider_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [config_1.ConfigService])
], TwilioProvider);
let Msg91Provider = Msg91Provider_1 = class Msg91Provider {
    config;
    logger = new common_1.Logger(Msg91Provider_1.name);
    constructor(config) {
        this.config = config;
    }
    async sendSms(to, message) {
        if (to.includes('msg91-fail')) {
            throw new Error('Msg91 failed to send SMS');
        }
        this.logger.log(`[Msg91 Mock] Sending SMS to ${to}: ${message}`);
        return `msg91-${Date.now()}`;
    }
};
exports.Msg91Provider = Msg91Provider;
exports.Msg91Provider = Msg91Provider = Msg91Provider_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [config_1.ConfigService])
], Msg91Provider);
//# sourceMappingURL=sms.providers.js.map