"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.NotificationsModule = void 0;
const common_1 = require("@nestjs/common");
const notifications_controller_1 = require("./notifications.controller");
const notifications_service_1 = require("./notifications.service");
const prisma_service_1 = require("../prisma.service");
const notification_rate_limiter_service_1 = require("./notification-rate-limiter.service");
const notification_deduplication_service_1 = require("./notification-deduplication.service");
const notification_template_service_1 = require("./notification-template.service");
const email_providers_1 = require("./providers/email.providers");
const sms_providers_1 = require("./providers/sms.providers");
const whatsapp_provider_1 = require("./providers/whatsapp.provider");
const push_provider_1 = require("./providers/push.provider");
const email_processor_1 = require("./processors/email.processor");
const sms_processor_1 = require("./processors/sms.processor");
const whatsapp_processor_1 = require("./processors/whatsapp.processor");
const push_processor_1 = require("./processors/push.processor");
const alerting_service_1 = require("./alerting.service");
let NotificationsModule = class NotificationsModule {
};
exports.NotificationsModule = NotificationsModule;
exports.NotificationsModule = NotificationsModule = __decorate([
    (0, common_1.Module)({
        controllers: [notifications_controller_1.NotificationsController],
        providers: [
            notifications_service_1.NotificationsService,
            prisma_service_1.PrismaService,
            notification_rate_limiter_service_1.NotificationRateLimiterService,
            notification_deduplication_service_1.NotificationDeduplicationService,
            notification_template_service_1.NotificationTemplateService,
            alerting_service_1.AlertingService,
            email_providers_1.ResendProvider,
            email_providers_1.SmtpProvider,
            sms_providers_1.TwilioProvider,
            sms_providers_1.Msg91Provider,
            whatsapp_provider_1.WhatsAppCloudProvider,
            push_provider_1.FcmProvider,
            email_processor_1.EmailProcessor,
            sms_processor_1.SmsProcessor,
            whatsapp_processor_1.WhatsAppProcessor,
            push_processor_1.PushProcessor,
        ],
        exports: [notifications_service_1.NotificationsService, alerting_service_1.AlertingService],
    })
], NotificationsModule);
//# sourceMappingURL=notifications.module.js.map