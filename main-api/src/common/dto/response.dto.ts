import { ApiProperty } from '@nestjs/swagger';

export interface ResponseMetadata {
  requestId?: string;
  processingTime?: number;
  cacheExpiry?: string;
  loadingState?: 'initial' | 'loading' | 'success' | 'error';
}

export class SuccessResponseDto<T = any> {
  @ApiProperty({ example: true })
  success: boolean;

  @ApiProperty({ example: 'Operation completed successfully' })
  message: string;

  @ApiProperty({ required: false })
  data?: T;

  @ApiProperty({ required: false })
  metadata?: ResponseMetadata;

  constructor(
    message: string = 'Operation completed successfully',
    data?: T,
    metadata?: ResponseMetadata,
  ) {
    this.success = true;
    this.message = message;
    this.data = data;
    this.metadata = metadata;
  }
}

export class ErrorResponseDto {
  @ApiProperty({ example: false })
  success: boolean;

  @ApiProperty({ example: 'An error occurred' })
  message: string;

  @ApiProperty({ example: 'VALIDATION_ERROR', required: false })
  code?: string;

  @ApiProperty({ example: [], required: false })
  errors?: any[];

  @ApiProperty({ required: false })
  metadata?: ResponseMetadata;

  @ApiProperty({
    example: 'Please check your input and try again',
    description: 'Suggested action for error recovery',
    required: false,
  })
  recoveryAction?: string;

  @ApiProperty({ example: '2024-01-01T00:00:00.000Z' })
  timestamp: string;

  @ApiProperty({ example: '/api/v1/endpoint' })
  path: string;

  constructor(
    message: string,
    path: string,
    code?: string,
    errors?: any[],
    recoveryAction?: string,
    metadata?: ResponseMetadata,
  ) {
    this.success = false;
    this.message = message;
    this.code = code;
    this.errors = errors;
    this.recoveryAction = recoveryAction;
    this.timestamp = new Date().toISOString();
    this.path = path;
    this.metadata = metadata;
  }
}
