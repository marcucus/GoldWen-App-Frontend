import {
  Controller,
  Get,
  Post,
  Put,
  Body,
  Param,
  Query,
  UseGuards,
  Req,
  HttpStatus,
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

import { ReportsService } from './reports.service';
import { CreateReportDto } from './dto/create-report.dto';
import { UpdateReportStatusDto } from './dto/update-report-status.dto';
import { GetReportsDto } from './dto/get-reports.dto';
import { User } from '../../database/entities/user.entity';
import { AdminGuard } from '../auth/guards/admin.guard';

@ApiTags('Reports')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'))
@Controller('reports')
export class ReportsController {
  constructor(private readonly reportsService: ReportsService) {}

  @ApiOperation({
    summary: 'Create a new report',
    description:
      'Submit a report for inappropriate content, harassment, or other violations',
  })
  @ApiResponse({
    status: HttpStatus.CREATED,
    description: 'Report created successfully',
    schema: {
      example: {
        success: true,
        reportId: '123e4567-e89b-12d3-a456-426614174000',
      },
    },
  })
  @ApiResponse({
    status: HttpStatus.BAD_REQUEST,
    description: 'Invalid input, duplicate report, or daily limit reached',
    schema: {
      example: {
        success: false,
        message: 'You have already submitted a similar report for this target',
        error: 'BadRequestException',
      },
    },
  })
  @Post()
  async createReport(
    @Req() req: Request,
    @Body() createReportDto: CreateReportDto,
  ) {
    const user = req.user as User;
    const report = await this.reportsService.createReport(
      user.id,
      createReportDto,
    );

    return {
      success: true,
      reportId: report.id,
    };
  }

  @ApiOperation({
    summary: "Get user's submitted reports",
    description: 'Retrieve all reports submitted by the current user',
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: 'Reports retrieved successfully',
    schema: {
      example: {
        success: true,
        data: [
          {
            id: '123e4567-e89b-12d3-a456-426614174000',
            type: 'harassment',
            status: 'resolved',
            reason: 'User was sending inappropriate messages',
            createdAt: '2023-01-01T12:00:00Z',
            reviewedAt: '2023-01-02T10:00:00Z',
          },
        ],
        pagination: {
          page: 1,
          limit: 10,
          total: 1,
          pages: 1,
          hasNext: false,
          hasPrev: false,
        },
      },
    },
  })
  @Get('me')
  async getUserReports(
    @Req() req: Request,
    @Query() getReportsDto: GetReportsDto,
  ) {
    const user = req.user as User;
    const result = await this.reportsService.getUserReports(
      user.id,
      getReportsDto,
    );

    return {
      success: true,
      data: result.data,
      pagination: result.pagination,
    };
  }

  @ApiOperation({
    summary: 'Get all reports (Admin only)',
    description:
      'Retrieve all reports for moderation (requires admin privileges)',
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: 'Reports retrieved successfully',
    schema: {
      example: {
        success: true,
        data: [
          {
            id: '123e4567-e89b-12d3-a456-426614174000',
            type: 'spam',
            status: 'pending',
            reason: 'User is sending spam messages',
            reporter: {
              id: 'reporter-id',
              email: 'reporter@example.com',
            },
            reportedUser: {
              id: 'reported-id',
              email: 'reported@example.com',
            },
            createdAt: '2023-01-01T12:00:00Z',
          },
        ],
        pagination: {
          page: 1,
          limit: 10,
          total: 1,
          pages: 1,
          hasNext: false,
          hasPrev: false,
        },
      },
    },
  })
  @ApiResponse({
    status: HttpStatus.FORBIDDEN,
    description: 'Access denied - Admin privileges required',
  })
  @UseGuards(AdminGuard)
  @Get()
  async getReports(@Query() getReportsDto: GetReportsDto) {
    const result = await this.reportsService.getReports(getReportsDto);

    return {
      success: true,
      data: result.data,
      pagination: result.pagination,
    };
  }

  @ApiOperation({
    summary: 'Update report status (Admin only)',
    description: 'Update the status of a report and add review notes',
  })
  @ApiParam({
    name: 'reportId',
    description: 'UUID of the report to update',
    type: 'string',
    format: 'uuid',
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: 'Report status updated successfully',
    schema: {
      example: {
        success: true,
        message: 'Report status updated successfully',
        data: {
          id: '123e4567-e89b-12d3-a456-426614174000',
          status: 'resolved',
          reviewNotes: 'User has been warned and content removed',
          reviewedAt: '2023-01-02T10:00:00Z',
        },
      },
    },
  })
  @ApiResponse({
    status: HttpStatus.NOT_FOUND,
    description: 'Report not found',
  })
  @ApiResponse({
    status: HttpStatus.FORBIDDEN,
    description: 'Access denied - Admin privileges required',
  })
  @UseGuards(AdminGuard)
  @Put(':reportId/status')
  async updateReportStatus(
    @Param('reportId') reportId: string,
    @Req() req: Request,
    @Body() updateStatusDto: UpdateReportStatusDto,
  ) {
    const reviewer = req.user as User;
    const updatedReport = await this.reportsService.updateReportStatus(
      reportId,
      reviewer.id,
      updateStatusDto,
    );

    return {
      success: true,
      message: 'Report status updated successfully',
      data: {
        id: updatedReport.id,
        status: updatedReport.status,
        reviewNotes: updatedReport.reviewNotes,
        resolution: updatedReport.resolution,
        reviewedAt: updatedReport.reviewedAt,
        reviewedBy: updatedReport.reviewedBy?.id,
      },
    };
  }

  @ApiOperation({
    summary: 'Get report by ID (Admin only)',
    description: 'Retrieve detailed information about a specific report',
  })
  @ApiParam({
    name: 'reportId',
    description: 'UUID of the report to retrieve',
    type: 'string',
    format: 'uuid',
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: 'Report retrieved successfully',
  })
  @ApiResponse({
    status: HttpStatus.NOT_FOUND,
    description: 'Report not found',
  })
  @ApiResponse({
    status: HttpStatus.FORBIDDEN,
    description: 'Access denied - Admin privileges required',
  })
  @UseGuards(AdminGuard)
  @Get(':reportId')
  async getReportById(@Param('reportId') reportId: string) {
    const report = await this.reportsService.getReportById(reportId);

    return {
      success: true,
      data: report,
    };
  }

  @ApiOperation({
    summary: 'Get report statistics (Admin only)',
    description: 'Get aggregated statistics about reports for admin dashboard',
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: 'Statistics retrieved successfully',
    schema: {
      example: {
        success: true,
        data: {
          total: 150,
          byStatus: {
            pending: 25,
            reviewed: 50,
            resolved: 60,
            dismissed: 15,
          },
          byType: {
            inappropriate_content: 45,
            harassment: 30,
            fake_profile: 25,
            spam: 35,
            other: 15,
          },
        },
      },
    },
  })
  @ApiResponse({
    status: HttpStatus.FORBIDDEN,
    description: 'Access denied - Admin privileges required',
  })
  @UseGuards(AdminGuard)
  @Get('admin/statistics')
  async getReportStatistics() {
    const statistics = await this.reportsService.getReportStatistics();

    return {
      success: true,
      data: statistics,
    };
  }
}
