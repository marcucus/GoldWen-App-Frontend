import { IsString, IsNotEmpty, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class DeleteAccountDto {
  @ApiProperty({
    description: 'User password for verification',
    example: 'MySecurePassword123',
  })
  @IsString()
  @IsNotEmpty()
  @MinLength(1)
  password: string;

  @ApiProperty({
    description: 'Confirmation text - must be exactly "DELETE"',
    example: 'DELETE',
  })
  @IsString()
  @IsNotEmpty()
  confirmationText: string;
}
