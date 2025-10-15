import {
  IsBoolean,
  IsOptional,
  IsString,
  IsDateString,
  IsEnum,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class ConsentDto {
  @ApiProperty({
    description: 'Consent for data processing (required by RGPD Art. 7)',
    example: true,
  })
  @IsBoolean()
  dataProcessing: boolean;

  @ApiPropertyOptional({
    description: 'Consent for marketing communications',
    example: false,
  })
  @IsOptional()
  @IsBoolean()
  marketing?: boolean;

  @ApiPropertyOptional({
    description: 'Consent for analytics tracking',
    example: false,
  })
  @IsOptional()
  @IsBoolean()
  analytics?: boolean;

  @ApiProperty({
    description: 'ISO date string when consent was given',
    example: '2024-01-15T10:30:00.000Z',
  })
  @IsDateString()
  consentedAt: string;
}

export class ExportDataDto {
  @ApiPropertyOptional({
    description: 'Export format (JSON or PDF)',
    example: 'json',
    enum: ['json', 'pdf'],
    default: 'json',
  })
  @IsOptional()
  @IsEnum(['json', 'pdf'])
  format?: 'json' | 'pdf' = 'json';
}

export class AccountDeletionDto {
  @ApiPropertyOptional({
    description: 'Optional reason for account deletion',
    example: 'No longer using the service',
  })
  @IsOptional()
  @IsString()
  reason?: string;
}
