import { IsString, IsEnum, IsOptional, IsNotEmpty } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Platform } from '../../../database/entities/push-token.entity';

export class RegisterPushTokenDto {
  @ApiProperty({
    description: 'FCM device token',
    example: 'fGxY7Z...',
  })
  @IsString()
  @IsNotEmpty()
  token: string;

  @ApiProperty({
    description: 'Device platform',
    enum: Platform,
    example: Platform.IOS,
  })
  @IsEnum(Platform)
  platform: Platform;

  @ApiPropertyOptional({
    description: 'App version',
    example: '1.0.0',
  })
  @IsOptional()
  @IsString()
  appVersion?: string;

  @ApiPropertyOptional({
    description: 'Device identifier',
    example: 'iPhone13,2',
  })
  @IsOptional()
  @IsString()
  deviceId?: string;
}

export class DeletePushTokenDto {
  @ApiProperty({
    description: 'FCM device token to delete',
    example: 'fGxY7Z...',
  })
  @IsString()
  @IsNotEmpty()
  token: string;
}
