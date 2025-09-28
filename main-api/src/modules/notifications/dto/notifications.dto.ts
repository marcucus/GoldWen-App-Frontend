import {
  IsEnum,
  IsOptional,
  IsBoolean,
  IsString,
  IsObject,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { NotificationType } from '../../../common/enums';

export class GetNotificationsDto {
  @ApiPropertyOptional({ description: 'Page number', default: 1 })
  @IsOptional()
  @Transform(({ value }) => parseInt(value))
  page?: number = 1;

  @ApiPropertyOptional({ description: 'Number of items per page', default: 20 })
  @IsOptional()
  @Transform(({ value }) => parseInt(value))
  limit?: number = 20;

  @ApiPropertyOptional({
    description: 'Filter by notification type',
    enum: NotificationType,
  })
  @IsOptional()
  @IsEnum(NotificationType)
  type?: NotificationType;

  @ApiPropertyOptional({ description: 'Filter by read status' })
  @IsOptional()
  @Transform(({ value }) => value === 'true')
  @IsBoolean()
  read?: boolean;
}

export class UpdateNotificationSettingsDto {
  @ApiPropertyOptional({ description: 'Enable daily selection notifications' })
  @IsOptional()
  @IsBoolean()
  dailySelection?: boolean;

  @ApiPropertyOptional({ description: 'Enable new match notifications' })
  @IsOptional()
  @IsBoolean()
  newMatch?: boolean;

  @ApiPropertyOptional({ description: 'Enable new message notifications' })
  @IsOptional()
  @IsBoolean()
  newMessage?: boolean;

  @ApiPropertyOptional({ description: 'Enable chat expiring notifications' })
  @IsOptional()
  @IsBoolean()
  chatExpiring?: boolean;

  @ApiPropertyOptional({ description: 'Enable subscription notifications' })
  @IsOptional()
  @IsBoolean()
  subscription?: boolean;
}

export class CreateNotificationDto {
  @ApiProperty({ description: 'User ID to send notification to' })
  @IsString()
  userId: string;

  @ApiProperty({ description: 'Notification type', enum: NotificationType })
  @IsEnum(NotificationType)
  type: NotificationType;

  @ApiProperty({ description: 'Notification title' })
  @IsString()
  title: string;

  @ApiProperty({ description: 'Notification body' })
  @IsString()
  body: string;

  @ApiPropertyOptional({ description: 'Additional notification data' })
  @IsOptional()
  @IsObject()
  data?: any;

  @ApiPropertyOptional({ description: 'Schedule notification for later' })
  @IsOptional()
  scheduledFor?: Date;
}

export class TestNotificationDto {
  @ApiPropertyOptional({
    description: 'Notification title',
    default: 'Test Notification',
  })
  @IsOptional()
  @IsString()
  title?: string = 'Test Notification';

  @ApiPropertyOptional({
    description: 'Notification body',
    default: 'This is a test notification',
  })
  @IsOptional()
  @IsString()
  body?: string = 'This is a test notification';

  @ApiPropertyOptional({
    description: 'Notification type',
    enum: NotificationType,
    default: NotificationType.DAILY_SELECTION,
  })
  @IsOptional()
  @IsEnum(NotificationType)
  type?: NotificationType = NotificationType.DAILY_SELECTION;
}

export class SendGroupNotificationDto {
  @ApiProperty({
    description: 'User IDs to send notification to',
    type: [String],
  })
  @IsString({ each: true })
  userIds: string[];

  @ApiProperty({ description: 'Notification type', enum: NotificationType })
  @IsEnum(NotificationType)
  type: NotificationType;

  @ApiProperty({ description: 'Notification title' })
  @IsString()
  title: string;

  @ApiProperty({ description: 'Notification body' })
  @IsString()
  body: string;

  @ApiPropertyOptional({ description: 'Additional notification data' })
  @IsOptional()
  @IsObject()
  data?: any;
}
