import { Global, Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { SentryService } from './sentry.service';
import { AlertingService } from './alerting.service';
import { DatadogService } from './datadog.service';

@Global()
@Module({
  imports: [ConfigModule],
  providers: [SentryService, AlertingService, DatadogService],
  exports: [SentryService, AlertingService, DatadogService],
})
export class MonitoringModule {}
