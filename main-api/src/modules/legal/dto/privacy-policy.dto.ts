import { IsOptional, IsEnum, IsString } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class GetPrivacyPolicyDto {
  @ApiPropertyOptional({
    description: 'Version of the privacy policy to retrieve',
    example: 'latest',
  })
  @IsOptional()
  @IsString()
  version?: string = 'latest';

  @ApiPropertyOptional({
    description: 'Format of the privacy policy response',
    example: 'json',
    enum: ['json', 'html'],
  })
  @IsOptional()
  @IsEnum(['json', 'html'])
  format?: 'json' | 'html' = 'json';
}
