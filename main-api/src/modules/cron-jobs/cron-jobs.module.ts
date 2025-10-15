import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { CleanupScheduler } from './schedulers/cleanup.scheduler';
import { MatchingScheduler } from '../matching/matching.scheduler';
import { ChatScheduler } from '../chat/chat.scheduler';
import { MatchingModule } from '../matching/matching.module';
import { ChatModule } from '../chat/chat.module';

import { Notification } from '../../database/entities/notification.entity';

/**
 * CronJobsModule
 *
 * This module centralizes all scheduled tasks (cron jobs) in the application.
 * It imports and re-exports schedulers from other modules for better organization
 * and provides additional cleanup schedulers.
 *
 * Scheduled Jobs:
 * - Daily Selection Generation (12:00 PM) - MatchingScheduler
 * - Chat Expiration (Every Hour) - ChatScheduler
 * - Chat Expiration Warnings (Every Hour) - ChatScheduler
 * - Daily Selections Cleanup (Midnight) - MatchingScheduler
 * - Old Chats Cleanup (Midnight) - ChatScheduler
 * - General Data Cleanup (3:00 AM) - CleanupScheduler
 */
@Module({
  imports: [
    TypeOrmModule.forFeature([Notification]),
    MatchingModule,
    ChatModule,
  ],
  providers: [CleanupScheduler],
  exports: [CleanupScheduler],
})
export class CronJobsModule {}
