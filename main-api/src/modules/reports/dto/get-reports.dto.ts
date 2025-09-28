import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsInt, Min, Max } from 'class-validator';
import { Transform } from 'class-transformer';
import { ReportStatus, ReportType } from '../../../common/enums';

export class GetReportsDto {
  @ApiProperty({
    description: 'Page number for pagination (default: 1)',
    minimum: 1,
    default: 1,
    required: false,
  })
  @IsOptional()
  @Transform(({ value }) => parseInt(value))
  @IsInt({ message: 'Page must be an integer' })
  @Min(1, { message: 'Page must be at least 1' })
  page?: number = 1;

  @ApiProperty({
    description: 'Number of items per page (default: 10, max: 100)',
    minimum: 1,
    maximum: 100,
    default: 10,
    required: false,
  })
  @IsOptional()
  @Transform(({ value }) => parseInt(value))
  @IsInt({ message: 'Limit must be an integer' })
  @Min(1, { message: 'Limit must be at least 1' })
  @Max(100, { message: 'Limit must not exceed 100' })
  limit?: number = 10;

  @ApiProperty({
    description: 'Filter by report status',
    enum: ReportStatus,
    required: false,
  })
  @IsOptional()
  @IsEnum(ReportStatus, { message: 'Status must be a valid enum value' })
  status?: ReportStatus;

  @ApiProperty({
    description: 'Filter by report type',
    enum: ReportType,
    required: false,
  })
  @IsOptional()
  @IsEnum(ReportType, { message: 'Type must be a valid enum value' })
  type?: ReportType;
}
