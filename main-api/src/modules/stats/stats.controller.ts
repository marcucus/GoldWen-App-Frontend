import {
  Controller,
  Get,
  Query,
  Param,
  UseGuards,
  Res,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiResponse,
  ApiQuery,
} from '@nestjs/swagger';
import type { Response } from 'express';

import { StatsService } from './stats.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RoleGuard } from '../auth/guards/role.guard';

import {
  GetActivityStatsDto,
  ExportStatsDto,
  GlobalStatsResponseDto,
  UserStatsResponseDto,
  ActivityStatsResponseDto,
  ExportFormat,
} from './dto';
import { UserRole } from '../../common/enums';

@ApiTags('stats')
@Controller('stats')
export class StatsController {
  constructor(private readonly statsService: StatsService) {}

  @Get('global')
  @UseGuards(JwtAuthGuard, RoleGuard)
  @ApiBearerAuth()
  @ApiOperation({ 
    summary: 'Get global platform statistics',
    description: 'Retrieve comprehensive statistics about the platform including user counts, matches, revenue, etc. Admin access required.'
  })
  @ApiResponse({ 
    status: 200, 
    description: 'Global statistics retrieved successfully',
    type: GlobalStatsResponseDto 
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - Admin access required' })
  async getGlobalStats(): Promise<{
    success: boolean;
    data: GlobalStatsResponseDto;
  }> {
    const stats = await this.statsService.getGlobalStats();
    
    return {
      success: true,
      data: stats,
    };
  }

  @Get('user/:userId')
  @UseGuards(JwtAuthGuard, RoleGuard)
  @ApiBearerAuth()
  @ApiOperation({ 
    summary: 'Get user-specific statistics',
    description: 'Retrieve detailed statistics for a specific user including matches, messages, activity metrics, etc. Admin access required.'
  })
  @ApiResponse({ 
    status: 200, 
    description: 'User statistics retrieved successfully',
    type: UserStatsResponseDto 
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - Admin access required' })
  @ApiResponse({ status: 404, description: 'User not found' })
  async getUserStats(@Param('userId') userId: string): Promise<{
    success: boolean;
    data: UserStatsResponseDto;
  }> {
    const stats = await this.statsService.getUserStats(userId);
    
    return {
      success: true,
      data: stats,
    };
  }

  @Get('activity')
  @UseGuards(JwtAuthGuard, RoleGuard)
  @ApiBearerAuth()
  @ApiOperation({ 
    summary: 'Get platform activity statistics',
    description: 'Retrieve time-based activity statistics including user registrations, matches, messages over specified time periods. Admin access required.'
  })
  @ApiQuery({
    name: 'startDate',
    required: false,
    description: 'Start date for activity statistics (YYYY-MM-DD)',
    example: '2024-01-01'
  })
  @ApiQuery({
    name: 'endDate', 
    required: false,
    description: 'End date for activity statistics (YYYY-MM-DD)',
    example: '2024-12-31'
  })
  @ApiQuery({
    name: 'period',
    required: false,
    description: 'Time period for grouping data',
    enum: ['daily', 'weekly', 'monthly', 'yearly']
  })
  @ApiResponse({ 
    status: 200, 
    description: 'Activity statistics retrieved successfully',
    type: ActivityStatsResponseDto 
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - Admin access required' })
  async getActivityStats(@Query() query: GetActivityStatsDto): Promise<{
    success: boolean;
    data: ActivityStatsResponseDto;
  }> {
    const stats = await this.statsService.getActivityStats(query);
    
    return {
      success: true,
      data: stats,
    };
  }

  @Get('global/export')
  @UseGuards(JwtAuthGuard, RoleGuard)
  @ApiBearerAuth()
  @ApiOperation({ 
    summary: 'Export global statistics',
    description: 'Export global platform statistics in various formats (JSON, CSV, PDF). Admin access required.'
  })
  @ApiQuery({
    name: 'format',
    required: false,
    description: 'Export format',
    enum: ['json', 'csv', 'pdf']
  })
  @ApiQuery({
    name: 'includeDetails',
    required: false,
    description: 'Include detailed breakdown in export',
    type: Boolean
  })
  @ApiResponse({ status: 200, description: 'Statistics exported successfully' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - Admin access required' })
  async exportGlobalStats(
    @Query() exportOptions: ExportStatsDto,
    @Res() res: Response,
  ): Promise<void> {
    const exported = await this.statsService.exportStats('global', undefined, exportOptions);
    
    // Set appropriate headers based on format
    if (exported.format === ExportFormat.JSON) {
      res.setHeader('Content-Type', 'application/json');
    } else if (exported.format === ExportFormat.CSV) {
      res.setHeader('Content-Type', 'text/csv');
    } else if (exported.format === ExportFormat.PDF) {
      res.setHeader('Content-Type', 'application/pdf');
    }
    
    res.setHeader('Content-Disposition', `attachment; filename="${exported.filename}"`);
    
    if (exported.format === ExportFormat.JSON) {
      res.json(exported.data);
    } else {
      // For now, return JSON for other formats too
      // In a real implementation, you would format the data appropriately
      res.json(exported.data);
    }
  }

  @Get('activity/export')
  @UseGuards(JwtAuthGuard, RoleGuard)
  @ApiBearerAuth()
  @ApiOperation({ 
    summary: 'Export activity statistics',
    description: 'Export platform activity statistics in various formats (JSON, CSV, PDF). Admin access required.'
  })
  @ApiQuery({
    name: 'startDate',
    required: false,
    description: 'Start date for activity statistics',
  })
  @ApiQuery({
    name: 'endDate',
    required: false, 
    description: 'End date for activity statistics',
  })
  @ApiQuery({
    name: 'period',
    required: false,
    description: 'Time period for grouping data',
    enum: ['daily', 'weekly', 'monthly', 'yearly']
  })
  @ApiQuery({
    name: 'format',
    required: false,
    description: 'Export format',
    enum: ['json', 'csv', 'pdf']
  })
  @ApiResponse({ status: 200, description: 'Activity statistics exported successfully' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - Admin access required' })
  async exportActivityStats(
    @Query() query: GetActivityStatsDto & ExportStatsDto,
    @Res() res: Response,
  ): Promise<void> {
    const { format, includeDetails, ...activityQuery } = query;
    const exportOptions = { format, includeDetails };
    
    const exported = await this.statsService.exportStats('activity', activityQuery, exportOptions);
    
    // Set appropriate headers based on format
    if (exported.format === ExportFormat.JSON) {
      res.setHeader('Content-Type', 'application/json');
    } else if (exported.format === ExportFormat.CSV) {
      res.setHeader('Content-Type', 'text/csv');
    } else if (exported.format === ExportFormat.PDF) {
      res.setHeader('Content-Type', 'application/pdf');
    }
    
    res.setHeader('Content-Disposition', `attachment; filename="${exported.filename}"`);
    
    if (exported.format === ExportFormat.JSON) {
      res.json(exported.data);
    } else {
      // For now, return JSON for other formats too
      // In a real implementation, you would format the data appropriately
      res.json(exported.data);
    }
  }
}