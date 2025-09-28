import { Injectable } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { InjectRedis } from '@nestjs-modules/ioredis';
import Redis from 'ioredis';

@Injectable()
export class AppService {
  constructor(
    @InjectDataSource() private dataSource: DataSource,
    @InjectRedis() private redis: Redis,
  ) {}

  getHello(): string {
    return 'GoldWen API - Designed to be deleted ❤️';
  }

  async getHealth() {
    const startTime = Date.now();

    // Check Database
    let dbStatus = 'healthy';
    let dbResponseTime = 0;
    try {
      const dbStart = Date.now();
      await this.dataSource.query('SELECT 1');
      dbResponseTime = Date.now() - dbStart;
    } catch (error) {
      dbStatus = 'unhealthy';
    }

    // Check Redis
    let redisStatus = 'healthy';
    let redisResponseTime = 0;
    try {
      const redisStart = Date.now();
      await this.redis.ping();
      redisResponseTime = Date.now() - redisStart;
    } catch (error) {
      redisStatus = 'unhealthy';
    }

    const totalResponseTime = Date.now() - startTime;
    const overallStatus =
      dbStatus === 'healthy' && redisStatus === 'healthy'
        ? 'healthy'
        : 'degraded';

    return {
      status: overallStatus,
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      environment: process.env.NODE_ENV || 'development',
      version: '1.0.0',
      responseTime: totalResponseTime,
      services: {
        api: 'healthy',
        database: {
          status: dbStatus,
          responseTime: dbResponseTime,
        },
        cache: {
          status: redisStatus,
          responseTime: redisResponseTime,
        },
      },
      memory: {
        used: Math.round(process.memoryUsage().heapUsed / 1024 / 1024),
        total: Math.round(process.memoryUsage().heapTotal / 1024 / 1024),
        external: Math.round(process.memoryUsage().external / 1024 / 1024),
      },
      system: {
        nodeVersion: process.version,
        platform: process.platform,
        arch: process.arch,
      },
    };
  }
}
