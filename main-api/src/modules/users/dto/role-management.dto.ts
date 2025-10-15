import { IsEnum, IsNotEmpty } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { UserRole } from '../../../common/enums';

export class UpdateUserRoleDto {
  @ApiProperty({
    enum: UserRole,
    description: 'The new role to assign to the user',
    example: UserRole.MODERATOR,
  })
  @IsEnum(UserRole)
  @IsNotEmpty()
  role: UserRole;
}

export class UserRoleResponseDto {
  @ApiProperty({ description: 'User ID' })
  id: string;

  @ApiProperty({ description: 'User email' })
  email: string;

  @ApiProperty({
    enum: UserRole,
    description: 'Current user role',
  })
  role: UserRole;

  @ApiProperty({ description: 'When the role was last updated' })
  updatedAt: Date;
}

export class UserRolesListResponseDto {
  @ApiProperty({
    type: [UserRoleResponseDto],
    description: 'List of users with their roles',
  })
  users: UserRoleResponseDto[];

  @ApiProperty({ description: 'Total number of users' })
  total: number;

  @ApiProperty({ description: 'Current page number' })
  page: number;

  @ApiProperty({ description: 'Number of users per page' })
  limit: number;
}
