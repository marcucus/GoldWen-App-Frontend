import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { CustomLoggerService } from '../logger';

export interface DatadogMetric {
  metric: string;
  points: Array<[number, number]>;
  tags?: string[];
  type?: 'gauge' | 'count' | 'rate';
}

export interface DatadogEvent {
  title: string;
  text: string;
  alert_type?: 'error' | 'warning' | 'info' | 'success';
  tags?: string[];
  source_type_name?: string;
}

@Injectable()
export class DatadogService {
  private apiKey: string;
  private appKey: string;
  private baseUrl = 'https://api.datadoghq.com';
  private enabled: boolean;

  constructor(
    private configService: ConfigService,
    private logger: CustomLoggerService,
  ) {
    this.apiKey = this.configService.get('monitoring.datadog.apiKey') || '';
    this.appKey = this.configService.get('monitoring.datadog.appKey') || '';
    this.enabled = !!(this.apiKey && this.appKey);
    
    if (!this.enabled) {
      this.logger.info('DataDog not configured, skipping initialization');
    } else {
      this.logger.info('DataDog monitoring service initialized');
    }
  }

  async sendMetric(metric: DatadogMetric): Promise<boolean> {
    if (!this.enabled) {
      this.logger.debug(`DataDog not enabled, skipping metric: ${metric.metric}`, 'DatadogService');
      return false;
    }

    try {
      const response = await fetch(`${this.baseUrl}/api/v1/series`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'DD-API-KEY': this.apiKey,
          'DD-APPLICATION-KEY': this.appKey,
        },
        body: JSON.stringify({
          series: [metric],
        }),
      });

      if (!response.ok) {
        throw new Error(`DataDog API error: ${response.status} ${response.statusText}`);
      }

      this.logger.debug(`Metric sent to DataDog: ${metric.metric}`, 'DatadogService');
      return true;
    } catch (error) {
      this.logger.error('Failed to send metric to DataDog', error.stack, 'DatadogService');
      return false;
    }
  }

  async sendEvent(event: DatadogEvent): Promise<boolean> {
    if (!this.enabled) {
      this.logger.debug(`DataDog not enabled, skipping event: ${event.title}`, 'DatadogService');
      return false;
    }

    try {
      const response = await fetch(`${this.baseUrl}/api/v1/events`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'DD-API-KEY': this.apiKey,
          'DD-APPLICATION-KEY': this.appKey,
        },
        body: JSON.stringify(event),
      });

      if (!response.ok) {
        throw new Error(`DataDog API error: ${response.status} ${response.statusText}`);
      }

      this.logger.debug(`Event sent to DataDog: ${event.title}`, 'DatadogService');
      return true;
    } catch (error) {
      this.logger.error('Failed to send event to DataDog', error.stack, 'DatadogService');
      return false;
    }
  }

  // Helper methods for common use cases
  async sendGaugeMetric(metric: string, value: number, tags?: string[]): Promise<boolean> {
    return this.sendMetric({
      metric,
      points: [[Date.now() / 1000, value]],
      type: 'gauge',
      tags,
    });
  }

  async sendCountMetric(metric: string, value: number, tags?: string[]): Promise<boolean> {
    return this.sendMetric({
      metric,
      points: [[Date.now() / 1000, value]],
      type: 'count',
      tags,
    });
  }

  async sendAlert(title: string, message: string, level: 'error' | 'warning' | 'info' = 'info', tags?: string[]): Promise<boolean> {
    return this.sendEvent({
      title,
      text: message,
      alert_type: level,
      tags: [...(tags || []), 'source:goldwen-api'],
      source_type_name: 'goldwen',
    });
  }

  // System monitoring helpers
  async trackSystemMetrics(): Promise<void> {
    if (!this.enabled) return;

    const memoryUsage = process.memoryUsage();
    const uptime = process.uptime();
    
    // Send memory metrics
    await Promise.allSettled([
      this.sendGaugeMetric('goldwen.system.memory.heap_used', Math.round(memoryUsage.heapUsed / 1024 / 1024), ['unit:mb']),
      this.sendGaugeMetric('goldwen.system.memory.heap_total', Math.round(memoryUsage.heapTotal / 1024 / 1024), ['unit:mb']),
      this.sendGaugeMetric('goldwen.system.memory.external', Math.round(memoryUsage.external / 1024 / 1024), ['unit:mb']),
      this.sendGaugeMetric('goldwen.system.uptime', uptime, ['unit:seconds']),
    ]);
  }

  async trackApiMetrics(endpoint: string, method: string, responseTime: number, statusCode: number): Promise<void> {
    if (!this.enabled) return;

    const tags = [
      `endpoint:${endpoint}`,
      `method:${method}`,
      `status:${statusCode}`,
      `status_class:${Math.floor(statusCode / 100)}xx`,
    ];

    await Promise.allSettled([
      this.sendGaugeMetric('goldwen.api.response_time', responseTime, tags),
      this.sendCountMetric('goldwen.api.requests', 1, tags),
    ]);
  }

  async trackBusinessMetrics(event: string, value: number = 1, tags?: string[]): Promise<void> {
    if (!this.enabled) return;

    await this.sendCountMetric(`goldwen.business.${event}`, value, tags);
  }
}