import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  getHello(): string {
    return 'GoldWen API - Designed to be deleted ❤️';
  }

  getHealth() {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      environment: process.env.NODE_ENV || 'development',
      version: '1.0.0',
      services: {
        api: 'healthy',
        database: 'healthy', // In real app, would check actual DB connection
        cache: 'healthy', // In real app, would check Redis connection
      },
    };
  }
}
