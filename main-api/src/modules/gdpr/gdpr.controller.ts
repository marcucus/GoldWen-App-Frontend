import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Param,
  UseGuards,
  Req,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiParam,
} from '@nestjs/swagger';
import type { Request } from 'express';

import { GdprService } from './gdpr.service';
import { ConsentDto, ExportDataDto } from './dto/gdpr.dto';
import { User } from '../../database/entities/user.entity';

@ApiTags('GDPR')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'))
@Controller('gdpr')
export class GdprController {
  constructor(private gdprService: GdprService) {}

  // ========== Art. 20 RGPD - Right to Data Portability ==========

  @ApiOperation({
    summary: 'Request data export (Art. 20 RGPD - Data Portability)',
    description:
      'Request a complete export of all user data in JSON or PDF format. The request is processed asynchronously and can be retrieved using the request ID.',
  })
  @ApiResponse({
    status: 201,
    description: 'Export request created successfully',
    schema: {
      type: 'object',
      properties: {
        success: { type: 'boolean', example: true },
        message: { type: 'string', example: 'Data export request created' },
        data: {
          type: 'object',
          properties: {
            requestId: { type: 'string', format: 'uuid' },
            status: { type: 'string', example: 'pending' },
            format: { type: 'string', example: 'json' },
            createdAt: { type: 'string', format: 'date-time' },
          },
        },
      },
    },
  })
  @Post('export-data')
  async requestDataExport(
    @Req() req: Request,
    @Body() exportDto: ExportDataDto,
  ) {
    const user = req.user as User;
    const exportRequest = await this.gdprService.requestDataExport(
      user.id,
      exportDto.format,
    );

    return {
      success: true,
      message: 'Data export request created successfully',
      data: {
        requestId: exportRequest.id,
        status: exportRequest.status,
        format: exportRequest.format,
        createdAt: exportRequest.createdAt,
        expiresAt: exportRequest.expiresAt,
      },
    };
  }

  @ApiOperation({
    summary: 'Get data export request status',
    description: 'Check the status of a data export request',
  })
  @ApiParam({
    name: 'requestId',
    description: 'Export request ID',
    type: 'string',
  })
  @ApiResponse({
    status: 200,
    description: 'Export request status retrieved',
  })
  @Get('export-data/:requestId')
  async getExportRequestStatus(
    @Req() req: Request,
    @Param('requestId') requestId: string,
  ) {
    const user = req.user as User;
    const request = await this.gdprService.getExportRequestStatus(
      user.id,
      requestId,
    );

    return {
      success: true,
      data: {
        requestId: request.id,
        status: request.status,
        format: request.format,
        fileUrl: request.fileUrl,
        completedAt: request.completedAt,
        expiresAt: request.expiresAt,
        createdAt: request.createdAt,
      },
    };
  }

  @ApiOperation({
    summary: 'Get all export requests',
    description: 'Get all data export requests for the current user',
  })
  @ApiResponse({
    status: 200,
    description: 'Export requests retrieved',
  })
  @Get('export-data')
  async getUserExportRequests(@Req() req: Request) {
    const user = req.user as User;
    const requests = await this.gdprService.getUserExportRequests(user.id);

    return {
      success: true,
      data: requests.map((request) => ({
        requestId: request.id,
        status: request.status,
        format: request.format,
        fileUrl: request.fileUrl,
        completedAt: request.completedAt,
        expiresAt: request.expiresAt,
        createdAt: request.createdAt,
      })),
    };
  }

  // ========== Art. 17 RGPD - Right to be Forgotten ==========

  @ApiOperation({
    summary: 'Request account deletion (Art. 17 RGPD - Right to be Forgotten)',
    description:
      'Request permanent deletion of user account and all associated data with complete anonymization. This process is irreversible.',
  })
  @ApiResponse({
    status: 201,
    description: 'Account deletion request created',
    schema: {
      type: 'object',
      properties: {
        success: { type: 'boolean', example: true },
        message: {
          type: 'string',
          example: 'Account deletion request created',
        },
        data: {
          type: 'object',
          properties: {
            requestId: { type: 'string', format: 'uuid' },
            status: { type: 'string', example: 'pending' },
            requestedAt: { type: 'string', format: 'date-time' },
          },
        },
      },
    },
  })
  @Delete('delete-account')
  async requestAccountDeletion(
    @Req() req: Request,
    @Body() body: { reason?: string },
  ) {
    const user = req.user as User;
    const deletionRequest = await this.gdprService.requestAccountDeletion(
      user.id,
      body.reason,
    );

    return {
      success: true,
      message:
        'Account deletion request created. Your account will be permanently deleted.',
      data: {
        requestId: deletionRequest.id,
        status: deletionRequest.status,
        requestedAt: deletionRequest.requestedAt,
      },
    };
  }

  @ApiOperation({
    summary: 'Get account deletion request status',
    description: 'Check the status of an account deletion request',
  })
  @ApiParam({
    name: 'requestId',
    description: 'Deletion request ID',
    type: 'string',
  })
  @ApiResponse({
    status: 200,
    description: 'Deletion request status retrieved',
  })
  @Get('delete-account/:requestId')
  async getDeletionRequestStatus(
    @Req() req: Request,
    @Param('requestId') requestId: string,
  ) {
    const user = req.user as User;
    const request = await this.gdprService.getDeletionRequestStatus(
      user.id,
      requestId,
    );

    return {
      success: true,
      data: {
        requestId: request.id,
        status: request.status,
        requestedAt: request.requestedAt,
        completedAt: request.completedAt,
        metadata: request.metadata,
      },
    };
  }

  // ========== Art. 7 RGPD - Consent Management ==========

  @ApiOperation({
    summary: 'Record user consent (Art. 7 RGPD - Consent)',
    description: 'Record or update user consent for data processing',
  })
  @ApiResponse({
    status: 201,
    description: 'Consent recorded successfully',
  })
  @Post('consent')
  async recordConsent(@Req() req: Request, @Body() consentDto: ConsentDto) {
    const user = req.user as User;
    const consent = await this.gdprService.recordConsent(user.id, {
      dataProcessing: consentDto.dataProcessing,
      marketing: consentDto.marketing,
      analytics: consentDto.analytics,
      consentedAt: consentDto.consentedAt,
    });

    return {
      success: true,
      message: 'Consent recorded successfully',
      data: {
        id: consent.id,
        dataProcessing: consent.dataProcessing,
        marketing: consent.marketing,
        analytics: consent.analytics,
        consentedAt: consent.consentedAt,
        isActive: consent.isActive,
        createdAt: consent.createdAt,
      },
    };
  }

  @ApiOperation({
    summary: 'Get current consent status',
    description: 'Retrieve the current active consent for the user',
  })
  @ApiResponse({
    status: 200,
    description: 'Current consent status retrieved',
  })
  @Get('consent')
  async getCurrentConsent(@Req() req: Request) {
    const user = req.user as User;
    const consent = await this.gdprService.getCurrentConsent(user.id);

    return {
      success: true,
      data: consent
        ? {
            id: consent.id,
            dataProcessing: consent.dataProcessing,
            marketing: consent.marketing,
            analytics: consent.analytics,
            consentedAt: consent.consentedAt,
            isActive: consent.isActive,
            createdAt: consent.createdAt,
          }
        : null,
    };
  }

  @ApiOperation({
    summary: 'Get consent history',
    description:
      'Retrieve the complete consent history for the user (Art. 7 RGPD)',
  })
  @ApiResponse({
    status: 200,
    description: 'Consent history retrieved',
  })
  @Get('consent/history')
  async getConsentHistory(@Req() req: Request) {
    const user = req.user as User;
    const history = await this.gdprService.getConsentHistory(user.id);

    return {
      success: true,
      data: history.map((consent) => ({
        id: consent.id,
        dataProcessing: consent.dataProcessing,
        marketing: consent.marketing,
        analytics: consent.analytics,
        consentedAt: consent.consentedAt,
        revokedAt: consent.revokedAt,
        isActive: consent.isActive,
        createdAt: consent.createdAt,
      })),
    };
  }

  @ApiOperation({
    summary: 'Revoke consent',
    description: 'Revoke the current active consent',
  })
  @ApiResponse({
    status: 200,
    description: 'Consent revoked successfully',
  })
  @Delete('consent')
  async revokeConsent(@Req() req: Request) {
    const user = req.user as User;
    await this.gdprService.revokeConsent(user.id);

    return {
      success: true,
      message: 'Consent revoked successfully',
    };
  }
}
