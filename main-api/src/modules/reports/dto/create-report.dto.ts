import { ApiProperty } from '@nestjs/swagger';
import {
  IsUUID,
  IsEnum,
  IsString,
  MaxLength,
  IsOptional,
  IsArray,
} from 'class-validator';
import { ReportType } from '../../../common/enums';

export class CreateReportDto {
  @ApiProperty({
    description: 'UUID of the user being reported',
    example: '123e4567-e89b-12d3-a456-426614174000',
  })
  @IsUUID(4, { message: 'Target user ID must be a valid UUID' })
  targetUserId: string;

  @ApiProperty({
    description: 'Type of report',
    enum: ReportType,
    example: ReportType.INAPPROPRIATE_CONTENT,
  })
  @IsEnum(ReportType, { message: 'Report type must be a valid enum value' })
  type: ReportType;

  @ApiProperty({
    description: 'Reason for the report',
    maxLength: 500,
    example: 'This user posted inappropriate content in their profile photos',
  })
  @IsString({ message: 'Reason must be a string' })
  @MaxLength(500, { message: 'Reason must not exceed 500 characters' })
  reason: string;

  @ApiProperty({
    description: 'Additional description or context for the report',
    maxLength: 1000,
    required: false,
    example: 'Additional details about the inappropriate behavior...',
  })
  @IsOptional()
  @IsString({ message: 'Description must be a string' })
  @MaxLength(1000, { message: 'Description must not exceed 1000 characters' })
  description?: string;

  @ApiProperty({
    description: 'UUID of the message being reported (optional)',
    required: false,
    example: '456e7890-e12b-34c5-d678-901234567890',
  })
  @IsOptional()
  @IsUUID(4, { message: 'Message ID must be a valid UUID' })
  messageId?: string;

  @ApiProperty({
    description: 'UUID of the chat where the incident occurred (optional)',
    required: false,
    example: '789e0123-e45f-67g8-h901-234567890123',
  })
  @IsOptional()
  @IsUUID(4, { message: 'Chat ID must be a valid UUID' })
  chatId?: string;

  @ApiProperty({
    description: 'Array of evidence URLs or file paths (optional)',
    required: false,
    type: [String],
    example: ['https://example.com/evidence1.jpg', '/uploads/evidence2.png'],
  })
  @IsOptional()
  @IsArray({ message: 'Evidence must be an array' })
  @IsString({ each: true, message: 'Each evidence item must be a string' })
  evidence?: string[];
}
