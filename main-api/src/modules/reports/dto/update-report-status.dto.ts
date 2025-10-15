import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsString, MaxLength, IsOptional } from 'class-validator';
import { ReportStatus } from '../../../common/enums';

export class UpdateReportStatusDto {
  @ApiProperty({
    description: 'New status for the report',
    enum: ReportStatus,
    example: ReportStatus.RESOLVED,
  })
  @IsEnum(ReportStatus, { message: 'Status must be a valid enum value' })
  status: ReportStatus;

  @ApiProperty({
    description: 'Review notes from the moderator (optional)',
    maxLength: 1000,
    required: false,
    example: 'Report reviewed and action taken. User has been warned.',
  })
  @IsOptional()
  @IsString({ message: 'Review notes must be a string' })
  @MaxLength(1000, { message: 'Review notes must not exceed 1000 characters' })
  reviewNotes?: string;

  @ApiProperty({
    description: 'Resolution details or action taken (optional)',
    maxLength: 1000,
    required: false,
    example: 'User account temporarily suspended for 24 hours',
  })
  @IsOptional()
  @IsString({ message: 'Resolution must be a string' })
  @MaxLength(1000, { message: 'Resolution must not exceed 1000 characters' })
  resolution?: string;
}
