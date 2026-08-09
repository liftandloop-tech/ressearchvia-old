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
var ResendProvider_1, SmtpProvider_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.SmtpProvider = exports.ResendProvider = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
let ResendProvider = ResendProvider_1 = class ResendProvider {
    config;
    logger = new common_1.Logger(ResendProvider_1.name);
    constructor(config) {
        this.config = config;
    }
    async sendEmail(to, subject, body) {
        const apiKey = this.config.get('RESEND_API_KEY');
        if (to.includes('resend-fail')) {
            throw new Error('Resend failed to send email');
        }
        this.logger.log(`[Resend Mock] Sending email to ${to}: ${subject}`);
        return `resend-${Date.now()}`;
    }
};
exports.ResendProvider = ResendProvider;
exports.ResendProvider = ResendProvider = ResendProvider_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [config_1.ConfigService])
], ResendProvider);
let SmtpProvider = SmtpProvider_1 = class SmtpProvider {
    config;
    logger = new common_1.Logger(SmtpProvider_1.name);
    constructor(config) {
        this.config = config;
    }
    async sendEmail(to, subject, body) {
        if (to.includes('smtp-fail')) {
            throw new Error('SMTP failed to send email');
        }
        const host = this.config.get('SMTP_HOST') || 'localhost';
        this.logger.log(`[SMTP Mock] Sending email via ${host} to ${to}: ${subject}`);
        return `smtp-${Date.now()}`;
    }
};
exports.SmtpProvider = SmtpProvider;
exports.SmtpProvider = SmtpProvider = SmtpProvider_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [config_1.ConfigService])
], SmtpProvider);
//# sourceMappingURL=email.providers.js.map