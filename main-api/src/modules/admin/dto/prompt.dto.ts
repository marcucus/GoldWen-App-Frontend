import {
  IsString,
  IsOptional,
  IsBoolean,
  IsNumber,
  MaxLength,
  Min,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreatePromptDto {
  @ApiProperty({
    description: 'The prompt text/question',
    example: 'What makes you laugh the most?',
  })
  @IsString()
  @MaxLength(200)
  text: string;

  @ApiProperty({
    description: 'Display order of the prompt',
    example: 1,
  })
  @IsNumber()
  @Min(1)
  order: number;

  @ApiPropertyOptional({
    description: 'Whether this prompt is required for profile completion',
    default: true,
  })
  @IsOptional()
  @IsBoolean()
  isRequired?: boolean;

  @ApiPropertyOptional({
    description: 'Whether this prompt is active/visible to users',
    default: true,
  })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @ApiPropertyOptional({
    description: 'Category/group for the prompt',
    example: 'personality',
  })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  category?: string;

  @ApiPropertyOptional({
    description: 'Placeholder text for the input field',
    example: 'Share what brings joy to your life...',
  })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  placeholder?: string;

  @ApiPropertyOptional({
    description: 'Maximum length for user answers',
    default: 500,
  })
  @IsOptional()
  @IsNumber()
  @Min(10)
  maxLength?: number;
}

export class UpdatePromptDto {
  @ApiPropertyOptional({
    description: 'The prompt text/question',
    example: 'What makes you laugh the most?',
  })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  text?: string;

  @ApiPropertyOptional({
    description: 'Display order of the prompt',
    example: 1,
  })
  @IsOptional()
  @IsNumber()
  @Min(1)
  order?: number;

  @ApiPropertyOptional({
    description: 'Whether this prompt is required for profile completion',
  })
  @IsOptional()
  @IsBoolean()
  isRequired?: boolean;

  @ApiPropertyOptional({
    description: 'Whether this prompt is active/visible to users',
  })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @ApiPropertyOptional({
    description: 'Category/group for the prompt',
    example: 'personality',
  })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  category?: string;

  @ApiPropertyOptional({
    description: 'Placeholder text for the input field',
    example: 'Share what brings joy to your life...',
  })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  placeholder?: string;

  @ApiPropertyOptional({
    description: 'Maximum length for user answers',
  })
  @IsOptional()
  @IsNumber()
  @Min(10)
  maxLength?: number;
}
