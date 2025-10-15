import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsDateString, IsEnum } from 'class-validator';

export enum ExportFormat {
  JSON = 'json',
  CSV = 'csv',
  PDF = 'pdf',
}

export enum ActivityPeriod {
  DAILY = 'daily',
  WEEKLY = 'weekly',
  MONTHLY = 'monthly',
  YEARLY = 'yearly',
}

export class GetActivityStatsDto {
  @ApiPropertyOptional({
    description: 'Start date for activity statistics',
    example: '2024-01-01',
  })
  @IsOptional()
  @IsDateString()
  startDate?: string;

  @ApiPropertyOptional({
    description: 'End date for activity statistics',
    example: '2024-12-31',
  })
  @IsOptional()
  @IsDateString()
  endDate?: string;

  @ApiPropertyOptional({
    description: 'Period for grouping activity data',
    enum: ActivityPeriod,
    example: 'monthly',
  })
  @IsOptional()
  @IsEnum(ActivityPeriod)
  period?: ActivityPeriod;
}

export class ExportStatsDto {
  @ApiPropertyOptional({
    description: 'Export format',
    enum: ExportFormat,
    default: ExportFormat.JSON,
  })
  @IsOptional()
  @IsEnum(ExportFormat)
  format?: ExportFormat;

  @ApiPropertyOptional({
    description: 'Include detailed breakdown',
    default: false,
  })
  @IsOptional()
  includeDetails?: boolean;
}

export class GlobalStatsResponseDto {
  @ApiProperty({ description: 'Total number of users' })
  totalUsers: number;

  @ApiProperty({ description: 'Number of active users' })
  activeUsers: number;

  @ApiProperty({ description: 'Number of suspended users' })
  suspendedUsers: number;

  @ApiProperty({ description: 'Total number of matches' })
  totalMatches: number;

  @ApiProperty({ description: 'Number of active chats' })
  activeChats: number;

  @ApiProperty({ description: 'Number of pending reports' })
  pendingReports: number;

  @ApiProperty({ description: 'Total revenue from subscriptions' })
  totalRevenue: number;

  @ApiProperty({ description: 'Number of active subscriptions' })
  activeSubscriptions: number;

  @ApiProperty({ description: 'Number of new registrations today' })
  newRegistrationsToday: number;

  @ApiProperty({ description: 'Number of new matches today' })
  newMatchesToday: number;

  @ApiProperty({ description: 'Number of messages sent today' })
  messagesSentToday: number;

  @ApiProperty({ description: 'Average matches per user' })
  avgMatchesPerUser: number;

  @ApiProperty({ description: 'Daily active users (last 7 days)' })
  dailyActiveUsers: number;

  @ApiProperty({ description: 'Monthly active users (last 30 days)' })
  monthlyActiveUsers: number;
}

export class UserStatsResponseDto {
  @ApiProperty({ description: 'User ID' })
  userId: string;

  @ApiProperty({ description: 'Total matches for this user' })
  totalMatches: number;

  @ApiProperty({ description: 'Active chats for this user' })
  activeChats: number;

  @ApiProperty({ description: 'Profile views received' })
  profileViews: number;

  @ApiProperty({ description: 'Current login streak' })
  loginStreak: number;

  @ApiProperty({ description: 'Messages sent by this user' })
  messagesSent: number;

  @ApiProperty({ description: 'Messages received by this user' })
  messagesReceived: number;

  @ApiProperty({ description: 'Daily selections used' })
  dailySelectionsUsed: number;

  @ApiProperty({ description: 'Total choices made' })
  totalChoicesUsed: number;

  @ApiProperty({ description: 'Average choices per selection' })
  averageChoicesPerSelection: number;

  @ApiProperty({ description: 'Match rate percentage' })
  matchRate: number;

  @ApiProperty({ description: 'Account creation date' })
  createdAt: Date;

  @ApiProperty({ description: 'Last activity date' })
  lastActiveAt: Date;

  @ApiProperty({ description: 'Has active subscription' })
  hasActiveSubscription: boolean;

  @ApiProperty({ description: 'Current subscription plan' })
  subscriptionPlan: string | null;

  @ApiProperty({ description: 'Profile completion percentage' })
  profileCompletionPercent: number;
}

export class ActivityStatsResponseDto {
  @ApiProperty({ description: 'Date range for statistics' })
  dateRange: {
    startDate: string;
    endDate: string;
  };

  @ApiProperty({ description: 'User registrations over time' })
  userRegistrations: Array<{
    date: string;
    count: number;
  }>;

  @ApiProperty({ description: 'Matches created over time' })
  matchesCreated: Array<{
    date: string;
    count: number;
  }>;

  @ApiProperty({ description: 'Messages sent over time' })
  messagesSent: Array<{
    date: string;
    count: number;
  }>;

  @ApiProperty({ description: 'Daily active users over time' })
  dailyActiveUsers: Array<{
    date: string;
    count: number;
  }>;

  @ApiProperty({ description: 'Subscription conversions over time' })
  subscriptionConversions: Array<{
    date: string;
    count: number;
  }>;

  @ApiProperty({ description: 'Top user activities summary' })
  summary: {
    totalActivity: number;
    averageDailyActivity: number;
    peakActivityDate: string;
    peakActivityCount: number;
  };
}
