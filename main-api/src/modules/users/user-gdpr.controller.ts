import { Controller, Get, Delete, UseGuards, Req, Query } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from '@nestjs/swagger';
import type { Request } from 'express';

import { GdprService } from './gdpr.service';
import { ExportDataDto } from './dto/consent.dto';
import { SuccessResponseDto } from '../../common/dto/response.dto';
import { User } from '../../database/entities/user.entity';

@ApiTags('User GDPR')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'))
@Controller('user')
export class UserGdprController {
  constructor(private gdprService: GdprService) {}

  @ApiOperation({
    summary: 'Export user data for GDPR compliance (data portability)',
    description:
      'Download complete user data in JSON format for GDPR compliance',
  })
  @ApiResponse({
    status: 200,
    description: 'User data exported successfully',
    schema: {
      type: 'object',
      properties: {
        success: { type: 'boolean', example: true },
        message: {
          type: 'string',
          example: 'User data exported successfully in json format',
        },
        data: {
          type: 'object',
          properties: {
            exportedAt: { type: 'string', format: 'date-time' },
            userId: { type: 'string' },
            data: {
              type: 'object',
              description:
                'Complete user data including profile, messages, matches, etc.',
            },
          },
        },
      },
    },
  })
  @Get('export')
  async exportUserData(@Req() req: Request, @Query() exportDto: ExportDataDto) {
    const user = req.user as User;
    const exportData = await this.gdprService.exportUserData(
      user.id,
      exportDto.format,
    );

    return {
      success: true,
      message: `User data exported successfully in ${exportDto.format || 'json'} format`,
      data: exportData,
    };
  }

  @ApiOperation({
    summary: 'Delete user account (Right to be forgotten)',
    description:
      'Permanently delete user account and all associated data with complete anonymization for GDPR compliance',
  })
  @ApiResponse({
    status: 200,
    description: 'Account deleted successfully with complete anonymization',
    type: SuccessResponseDto,
  })
  @Delete('me')
  async deleteAccount(@Req() req: Request) {
    const user = req.user as User;

    // Use GDPR service for complete deletion with anonymization
    await this.gdprService.deleteUserCompletely(user.id);

    return new SuccessResponseDto(
      'Account deleted successfully with complete anonymization',
    );
  }
}
