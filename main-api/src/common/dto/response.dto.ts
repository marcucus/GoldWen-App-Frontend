import { ApiProperty } from '@nestjs/swagger';

export class SuccessResponseDto {
  @ApiProperty({ example: true })
  success: boolean;

  @ApiProperty({ example: 'Operation completed successfully' })
  message: string;

  constructor(message: string = 'Operation completed successfully') {
    this.success = true;
    this.message = message;
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

  constructor(message: string, code?: string, errors?: any[]) {
    this.success = false;
    this.message = message;
    this.code = code;
    this.errors = errors;
  }
}
