import { ApiProperty } from '@nestjs/swagger';
import {
  IsUUID,
  IsEnum,
  IsString,
  MaxLength,
  IsOptional,
  IsArray,
  IsIn,
} from 'class-validator';
import { ReportType } from '../../../common/enums';

export class CreateReportDto {
  @ApiProperty({
    description: 'Type of target being reported (user or message)',
    enum: ['user', 'message'],
    example: 'user',
  })
  @IsIn(['user', 'message'], {
    message: 'Target type must be either "user" or "message"',
  })
  targetType: 'user' | 'message';

  @ApiProperty({
    description: 'UUID of the user or message being reported',
    example: '123e4567-e89b-12d3-a456-426614174000',
  })
  @IsUUID(4, { message: 'Target ID must be a valid UUID' })
  targetId: string;

  @ApiProperty({
    description: 'Reason/category for the report',
    enum: ReportType,
    example: ReportType.INAPPROPRIATE_CONTENT,
  })
  @IsEnum(ReportType, { message: 'Reason must be a valid enum value' })
  reason: ReportType;

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
}
