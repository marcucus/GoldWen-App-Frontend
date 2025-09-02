import { IsEmail, IsString, IsOptional, MinLength } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class LoginDto {
  @ApiProperty({ example: 'user@example.com' })
  @IsEmail()
  email: string;

  @ApiProperty({ example: 'password123', minLength: 6 })
  @IsString()
  @MinLength(6)
  password: string;
}

export class RegisterDto {
  @ApiProperty({ example: 'user@example.com' })
  @IsEmail()
  email: string;

  @ApiProperty({ example: 'password123', minLength: 6 })
  @IsString()
  @MinLength(6)
  password: string;

  @ApiProperty({ example: 'John' })
  @IsString()
  firstName: string;

  @ApiPropertyOptional({ example: 'Doe' })
  @IsOptional()
  @IsString()
  lastName?: string;
}

export class SocialLoginDto {
  @ApiProperty({ example: 'google_user_id_123' })
  @IsString()
  socialId: string;

  @ApiProperty({ example: 'google' })
  @IsString()
  provider: string;

  @ApiProperty({ example: 'user@example.com' })
  @IsEmail()
  email: string;

  @ApiProperty({ example: 'John' })
  @IsString()
  firstName: string;

  @ApiPropertyOptional({ example: 'Doe' })
  @IsOptional()
  @IsString()
  lastName?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  profilePicture?: string;
}

export class ForgotPasswordDto {
  @ApiProperty({ example: 'user@example.com' })
  @IsEmail()
  email: string;
}

export class ResetPasswordDto {
  @ApiProperty()
  @IsString()
  token: string;

  @ApiProperty({ example: 'newpassword123', minLength: 6 })
  @IsString()
  @MinLength(6)
  newPassword: string;
}

export class ChangePasswordDto {
  @ApiProperty({ example: 'currentpassword123' })
  @IsString()
  currentPassword: string;

  @ApiProperty({ example: 'newpassword123', minLength: 6 })
  @IsString()
  @MinLength(6)
  newPassword: string;
}

export class VerifyEmailDto {
  @ApiProperty()
  @IsString()
  token: string;
}
