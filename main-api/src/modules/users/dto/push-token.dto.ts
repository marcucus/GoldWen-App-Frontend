import { IsString, IsEnum, IsOptional, IsNotEmpty } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Platform } from '../../../database/entities/push-token.entity';

export class RegisterPushTokenDto {
  @ApiProperty({ description: 'FCM/APNs device token' })
  @IsString()
  @IsNotEmpty()
  token: string;

  @ApiProperty({ description: 'Platform type', enum: Platform })
  @IsEnum(Platform)
  platform: Platform;

  @ApiPropertyOptional({ description: 'App version' })
  @IsOptional()
  @IsString()
  appVersion?: string;

  @ApiPropertyOptional({ description: 'Device identifier' })
  @IsOptional()
  @IsString()
  deviceId?: string;
}

export class DeletePushTokenDto {
  @ApiProperty({ description: 'FCM/APNs device token to remove' })
  @IsString()
  @IsNotEmpty()
  token: string;
}
