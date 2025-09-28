import { Controller, Get, UseGuards, Query } from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';
import { MonitoringService } from './monitoring.service';
import { CustomLoggerService } from '../../common/logger';

@ApiTags('Admin - Monitoring')
@Controller('admin/monitoring')
@UseGuards(JwtAuthGuard, AdminGuard)
@ApiBearerAuth()
export class MonitoringController {
  constructor(
    private readonly monitoringService: MonitoringService,
    private readonly logger: CustomLoggerService,
  ) {}

  @Get('dashboard')
  @ApiOperation({ summary: 'Get monitoring dashboard data' })
  @ApiResponse({ status: 200, description: 'Dashboard data' })
  async getDashboard() {
    this.logger.logSecurityEvent(
      'admin_monitoring_dashboard_accessed',
      {},
      'info',
    );
    return this.monitoringService.getDashboardData();
  }

  @Get('metrics')
  @ApiOperation({ summary: 'Get system metrics' })
  @ApiResponse({ status: 200, description: 'System metrics' })
  async getMetrics() {
    this.logger.logSecurityEvent(
      'admin_monitoring_metrics_accessed',
      {},
      'info',
    );
    return this.monitoringService.getSystemMetrics();
  }

  @Get('logs')
  @ApiOperation({ summary: 'Get recent logs' })
  @ApiResponse({ status: 200, description: 'Recent logs' })
  async getLogs(
    @Query('level') level?: string,
    @Query('limit') limit?: number,
    @Query('offset') offset?: number,
  ) {
    this.logger.logSecurityEvent(
      'admin_monitoring_logs_accessed',
      { level, limit, offset },
      'info',
    );
    return this.monitoringService.getRecentLogs({
      level,
      limit: limit || 100,
      offset: offset || 0,
    });
  }

  @Get('alerts')
  @ApiOperation({ summary: 'Get recent alerts' })
  @ApiResponse({ status: 200, description: 'Recent alerts' })
  async getAlerts() {
    this.logger.logSecurityEvent(
      'admin_monitoring_alerts_accessed',
      {},
      'info',
    );
    return this.monitoringService.getRecentAlerts();
  }

  @Get('performance')
  @ApiOperation({ summary: 'Get performance metrics' })
  @ApiResponse({ status: 200, description: 'Performance metrics' })
  async getPerformanceMetrics() {
    this.logger.logSecurityEvent(
      'admin_monitoring_performance_accessed',
      {},
      'info',
    );
    return this.monitoringService.getPerformanceMetrics();
  }
}
