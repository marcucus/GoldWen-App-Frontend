import { IsBoolean, IsOptional, IsString, IsDateString } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class ConsentDto {
  @ApiProperty({ description: 'Consent for data processing', example: true })
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
    description: 'Export format',
    example: 'json',
    enum: ['json', 'pdf'],
  })
  @IsOptional()
  @IsString()
  format?: 'json' | 'pdf' = 'json';
}
