import { Module } from '@nestjs/common';
import { NotificationsController } from './notifications.controller';
import { NotificationsService } from './notifications.service';
import { PrismaService } from '../prisma.service';
import { NotificationRateLimiterService } from './notification-rate-limiter.service';
import { NotificationDeduplicationService } from './notification-deduplication.service';
import { NotificationTemplateService } from './notification-template.service';

import { ResendProvider, SmtpProvider } from './providers/email.providers';
import { TwilioProvider, Msg91Provider } from './providers/sms.providers';
import { WhatsAppCloudProvider } from './providers/whatsapp.provider';
import { FcmProvider } from './providers/push.provider';

import { EmailProcessor } from './processors/email.processor';
import { SmsProcessor } from './processors/sms.processor';
import { WhatsAppProcessor } from './processors/whatsapp.processor';
import { PushProcessor } from './processors/push.processor';

import { AlertingService } from './alerting.service';

@Module({
  controllers: [NotificationsController],
  providers: [
    NotificationsService,
    PrismaService,
    NotificationRateLimiterService,
    NotificationDeduplicationService,
    NotificationTemplateService,
    AlertingService,
    ResendProvider,
    SmtpProvider,
    TwilioProvider,
    Msg91Provider,
    WhatsAppCloudProvider,
    FcmProvider,
    EmailProcessor,
    SmsProcessor,
    WhatsAppProcessor,
    PushProcessor,
  ],
  exports: [NotificationsService, AlertingService],
})
export class NotificationsModule {}
