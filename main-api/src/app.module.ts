import { Module, MiddlewareConsumer } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ScheduleModule } from '@nestjs/schedule';
import { BullModule } from '@nestjs/bull';
import { RedisModule } from '@nestjs-modules/ioredis';

import { AppController } from './app.controller';
import { AppService } from './app.service';

// Logger
import { LoggerModule, LoggingMiddleware } from './common/logger';

// Monitoring
import { MonitoringModule } from './common/monitoring';

// Middleware
import { SecurityLoggingMiddleware } from './common/middleware';

// Configuration
import {
  databaseConfig,
  redisConfig,
  jwtConfig,
  appConfig,
  oauthConfig,
  fileUploadConfig,
  notificationConfig,
  emailConfig,
  matchingServiceConfig,
  revenueCatConfig,
  monitoringConfig,
} from './config/configuration';

// Modules
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { ProfilesModule } from './modules/profiles/profiles.module';
import { MatchingModule } from './modules/matching/matching.module';
import { ChatModule } from './modules/chat/chat.module';
import { ConversationsModule } from './modules/conversations/conversations.module';
import { SubscriptionsModule } from './modules/subscriptions/subscriptions.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { PreferencesModule } from './modules/preferences/preferences.module';
import { AdminModule } from './modules/admin/admin.module';
import { ReportsModule } from './modules/reports/reports.module';
import { StatsModule } from './modules/stats/stats.module';

@Module({
  imports: [
    // Logger - Global module
    LoggerModule,

    // Configuration
    ConfigModule.forRoot({
      isGlobal: true,
      load: [
        databaseConfig,
        redisConfig,
        jwtConfig,
        appConfig,
        oauthConfig,
        fileUploadConfig,
        notificationConfig,
        emailConfig,
        matchingServiceConfig,
        revenueCatConfig,
        monitoringConfig,
      ],
    }),

    // Database
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => ({
        type: 'postgres',
        host: configService.get('database.host'),
        port: configService.get('database.port'),
        username: configService.get('database.username'),
        password: configService.get('database.password'),
        database: configService.get('database.database'),
        autoLoadEntities: true,
        synchronize: true,
        entities: [__dirname + '/**/*.entity{.ts,.js}'],
        logging: configService.get('app.environment') === 'development',
      }),
      inject: [ConfigService],
    }),

    // Redis for queues
    BullModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => ({
        redis: {
          host: configService.get('redis.host'),
          port: configService.get('redis.port'),
          password: configService.get('redis.password'),
        },
      }),
      inject: [ConfigService],
    }),

    // Redis for application use (separate from Bull queues)
    RedisModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => ({
        type: 'single',
        url: `redis://${configService.get('redis.host')}:${configService.get('redis.port')}`,
        options: {
          password: configService.get('redis.password') || undefined,
        },
      }),
      inject: [ConfigService],
    }),

    // Schedule for cron jobs
    ScheduleModule.forRoot(),

    // Global modules
    LoggerModule,
    MonitoringModule,

    // Feature modules
    AuthModule,
    UsersModule,
    ProfilesModule,
    MatchingModule,
    ChatModule,
    ConversationsModule,
    SubscriptionsModule,
    NotificationsModule,
    PreferencesModule,
    AdminModule,
    ReportsModule,
    StatsModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(LoggingMiddleware).forRoutes('*'); // Apply to all routes
    consumer.apply(SecurityLoggingMiddleware).forRoutes('*'); // Apply security logging
  }
}
