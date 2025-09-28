import { IsEnum, IsOptional, IsBoolean } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { FontSize } from '../../../common/enums';

export class AccessibilitySettingsDto {
  @ApiProperty({
    enum: FontSize,
    description: 'Font size preference',
    example: FontSize.MEDIUM,
  })
  fontSize: FontSize;

  @ApiProperty({
    description: 'High contrast mode enabled',
    example: false,
  })
  highContrast: boolean;

  @ApiProperty({
    description: 'Reduced motion enabled',
    example: false,
  })
  reducedMotion: boolean;

  @ApiProperty({
    description: 'Screen reader support enabled',
    example: false,
  })
  screenReader: boolean;
}

export class UpdateAccessibilitySettingsDto {
  @ApiPropertyOptional({
    enum: FontSize,
    description: 'Font size preference',
  })
  @IsOptional()
  @IsEnum(FontSize)
  fontSize?: FontSize;

  @ApiPropertyOptional({
    description: 'High contrast mode enabled',
  })
  @IsOptional()
  @IsBoolean()
  highContrast?: boolean;

  @ApiPropertyOptional({
    description: 'Reduced motion enabled',
  })
  @IsOptional()
  @IsBoolean()
  reducedMotion?: boolean;

  @ApiPropertyOptional({
    description: 'Screen reader support enabled',
  })
  @IsOptional()
  @IsBoolean()
  screenReader?: boolean;
}
