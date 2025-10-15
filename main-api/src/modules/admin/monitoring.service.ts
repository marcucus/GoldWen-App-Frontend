import { Injectable } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { InjectRedis } from '@nestjs-modules/ioredis';
import Redis from 'ioredis';
import { CustomLoggerService } from '../../common/logger';
import { ConfigService } from '@nestjs/config';

export interface LogEntry {
  timestamp: string;
  level: string;
  message: string;
  context?: string;
  metadata?: any;
}

export interface SystemMetrics {
  uptime: number;
  memory: {
    used: number;
    total: number;
    percentage: number;
  };
  cpu: {
    usage: number;
  };
  database: {
    connections: number;
    queries: number;
    responseTime: number;
  };
  redis: {
    connections: number;
    memory: number;
    responseTime: number;
  };
}

@Injectable()
export class MonitoringService {
  private logs: LogEntry[] = [];
  private alerts: any[] = [];
  private maxLogsToKeep = 10000;
  private maxAlertsToKeep = 1000;

  constructor(
    @InjectDataSource() private dataSource: DataSource,
    @InjectRedis() private redis: Redis,
    private logger: CustomLoggerService,
    private configService: ConfigService,
  ) {
    // Initialize log capture
    this.setupLogCapture();
  }

  private setupLogCapture() {
    // This would integrate with Winston to capture logs
    // For now, we'll simulate with a basic implementation
  }

  async getDashboardData() {
    const [systemMetrics, dbStats, redisStats, monitoringStatus] =
      await Promise.all([
        this.getSystemMetrics(),
        this.getDatabaseStats(),
        this.getRedisStats(),
        this.getMonitoringStatus(),
      ]);

    return {
      overview: {
        status: 'healthy',
        uptime: process.uptime(),
        timestamp: new Date().toISOString(),
      },
      system: systemMetrics,
      database: dbStats,
      redis: redisStats,
      monitoring: monitoringStatus,
      recentAlerts: this.alerts.slice(-10),
      recentErrors: this.logs.filter((log) => log.level === 'error').slice(-10),
    };
  }

  async getSystemMetrics(): Promise<SystemMetrics> {
    const memoryUsage = process.memoryUsage();

    return {
      uptime: process.uptime(),
      memory: {
        used: Math.round(memoryUsage.heapUsed / 1024 / 1024),
        total: Math.round(memoryUsage.heapTotal / 1024 / 1024),
        percentage: Math.round(
          (memoryUsage.heapUsed / memoryUsage.heapTotal) * 100,
        ),
      },
      cpu: {
        usage: await this.getCpuUsage(),
      },
      database: await this.getDatabaseMetrics(),
      redis: await this.getRedisMetrics(),
    };
  }

  async getRecentLogs(options: {
    level?: string;
    limit: number;
    offset: number;
  }) {
    let filteredLogs = this.logs;

    if (options.level) {
      filteredLogs = this.logs.filter((log) => log.level === options.level);
    }

    return {
      logs: filteredLogs.slice(options.offset, options.offset + options.limit),
      total: filteredLogs.length,
      offset: options.offset,
      limit: options.limit,
    };
  }

  async getRecentAlerts() {
    return {
      alerts: this.alerts.slice(-50),
      total: this.alerts.length,
    };
  }

  async getPerformanceMetrics() {
    const [dbPerf, redisPerf] = await Promise.all([
      this.measureDatabasePerformance(),
      this.measureRedisPerformance(),
    ]);

    return {
      database: dbPerf,
      redis: redisPerf,
      api: await this.getApiPerformanceMetrics(),
    };
  }

  private async getCpuUsage(): Promise<number> {
    // Simple CPU usage calculation
    const start = process.cpuUsage();
    await new Promise((resolve) => setTimeout(resolve, 100));
    const end = process.cpuUsage(start);

    const userCpuTime = end.user / 1000; // Convert to milliseconds
    const systemCpuTime = end.system / 1000;
    const totalCpuTime = userCpuTime + systemCpuTime;

    return Math.round((totalCpuTime / 100) * 100) / 100; // As percentage of 100ms
  }

  private async getDatabaseStats() {
    try {
      const result = await this.dataSource.query(`
        SELECT 
          count(*) as total_connections,
          sum(case when state = 'active' then 1 else 0 end) as active_connections
        FROM pg_stat_activity 
        WHERE datname = current_database()
      `);

      return {
        status: 'healthy',
        totalConnections: parseInt(result[0]?.total_connections || '0'),
        activeConnections: parseInt(result[0]?.active_connections || '0'),
      };
    } catch (error) {
      this.logger.error(
        'Failed to get database stats',
        error.stack,
        'MonitoringService',
      );
      return {
        status: 'error',
        error: error.message,
      };
    }
  }

  private async getRedisStats() {
    try {
      const info = await this.redis.info('memory');
      const memoryInfo = this.parseRedisInfo(info);

      return {
        status: 'healthy',
        memoryUsed: memoryInfo.used_memory_human || 'N/A',
        memoryPeak: memoryInfo.used_memory_peak_human || 'N/A',
        connectedClients: 1, // Simplified for now - would need different Redis command
      };
    } catch (error) {
      this.logger.error(
        'Failed to get Redis stats',
        error.stack,
        'MonitoringService',
      );
      return {
        status: 'error',
        error: error.message,
      };
    }
  }

  private async getDatabaseMetrics() {
    try {
      const start = Date.now();
      await this.dataSource.query('SELECT 1');
      const responseTime = Date.now() - start;

      return {
        connections: 1, // Simplified
        queries: 0, // Would track in real implementation
        responseTime,
      };
    } catch (error) {
      return {
        connections: 0,
        queries: 0,
        responseTime: -1,
      };
    }
  }

  private async getRedisMetrics() {
    try {
      const start = Date.now();
      await this.redis.ping();
      const responseTime = Date.now() - start;

      return {
        connections: 1, // Simplified
        memory: 0, // Would get from Redis info
        responseTime,
      };
    } catch (error) {
      return {
        connections: 0,
        memory: 0,
        responseTime: -1,
      };
    }
  }

  private async measureDatabasePerformance() {
    const queries = [
      { name: 'Simple SELECT', query: 'SELECT 1' },
      { name: 'Current Time', query: 'SELECT NOW()' },
    ];

    const results = [];
    for (const { name, query } of queries) {
      const start = Date.now();
      try {
        await this.dataSource.query(query);
        results.push({
          name,
          responseTime: Date.now() - start,
          status: 'success',
        });
      } catch (error) {
        results.push({
          name,
          responseTime: -1,
          status: 'error',
          error: error.message,
        });
      }
    }

    return results;
  }

  private async measureRedisPerformance() {
    const operations = [
      { name: 'PING', operation: () => this.redis.ping() },
      {
        name: 'SET/GET',
        operation: async () => {
          await this.redis.set('test_key', 'test_value');
          return this.redis.get('test_key');
        },
      },
    ];

    const results = [];
    for (const { name, operation } of operations) {
      const start = Date.now();
      try {
        await operation();
        results.push({
          name,
          responseTime: Date.now() - start,
          status: 'success',
        });
      } catch (error) {
        results.push({
          name,
          responseTime: -1,
          status: 'error',
          error: error.message,
        });
      }
    }

    return results;
  }

  private async getApiPerformanceMetrics() {
    // This would track API response times, throughput, etc.
    // For now, return placeholder data
    return {
      averageResponseTime: 150,
      requestsPerMinute: 45,
      errorRate: 0.5,
    };
  }

  private parseRedisInfo(info: string): Record<string, string> {
    const lines = info.split('\r\n');
    const result: Record<string, string> = {};

    for (const line of lines) {
      if (line.includes(':')) {
        const [key, value] = line.split(':');
        result[key] = value;
      }
    }

    return result;
  }

  // Methods to add logs and alerts (would be called by other services)
  addLog(log: LogEntry) {
    this.logs.push(log);
    if (this.logs.length > this.maxLogsToKeep) {
      this.logs = this.logs.slice(-this.maxLogsToKeep);
    }
  }

  addAlert(alert: any) {
    this.alerts.push({
      ...alert,
      timestamp: new Date().toISOString(),
    });
    if (this.alerts.length > this.maxAlertsToKeep) {
      this.alerts = this.alerts.slice(-this.maxAlertsToKeep);
    }
  }

  private async getMonitoringStatus() {
    const monitoringConfig = this.configService.get('monitoring');

    return {
      sentry: {
        enabled: !!monitoringConfig?.sentry?.dsn,
        environment: monitoringConfig?.sentry?.environment || 'development',
        tracesSampleRate: monitoringConfig?.sentry?.tracesSampleRate || 0.1,
      },
      datadog: {
        enabled: !!(
          monitoringConfig?.datadog?.apiKey && monitoringConfig?.datadog?.appKey
        ),
        configured: !!monitoringConfig?.datadog,
      },
      alerts: {
        webhookConfigured: !!monitoringConfig?.alerts?.webhookUrl,
        slackConfigured: !!monitoringConfig?.alerts?.slackWebhookUrl,
        emailConfigured: !!(
          monitoringConfig?.alerts?.emailRecipients?.length > 0
        ),
        totalChannels: [
          monitoringConfig?.alerts?.webhookUrl,
          monitoringConfig?.alerts?.slackWebhookUrl,
          monitoringConfig?.alerts?.emailRecipients?.length > 0 && 'email',
        ].filter(Boolean).length,
      },
      logging: {
        level: this.configService.get('app.logLevel') || 'info',
        environment: this.configService.get('app.environment') || 'development',
      },
    };
  }
}
