import { Module } from '@nestjs/common';
import { AnalyticsService } from './analytics.service';
import { AnalyticsMiddleware } from './analytics.middleware';
import { GdprModule } from '../gdpr/gdpr.module';

@Module({
  imports: [GdprModule],
  providers: [AnalyticsService, AnalyticsMiddleware],
  exports: [AnalyticsService, AnalyticsMiddleware],
})
export class AnalyticsModule {}
