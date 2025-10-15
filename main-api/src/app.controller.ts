import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { AppService } from './app.service';
import { CustomLoggerService } from './common/logger';
import { CacheControl } from './common/interceptors/cache.interceptor';
import { CacheStrategy } from './common/enums/cache-strategy.enum';

@ApiTags('app')
@Controller()
export class AppController {
  constructor(
    private readonly appService: AppService,
    private readonly logger: CustomLoggerService,
  ) {}

  @Get()
  @ApiOperation({ summary: 'API Welcome message' })
  @ApiResponse({ status: 200, description: 'Welcome message' })
  getHello(): string {
    this.logger.info('Welcome endpoint accessed');
    return this.appService.getHello();
  }

  @Get('health')
  @CacheControl(CacheStrategy.SHORT_CACHE)
  @ApiOperation({ summary: 'Health check endpoint' })
  @ApiResponse({ status: 200, description: 'Service health status' })
  async getHealth() {
    const healthData = await this.appService.getHealth();

    this.logger.info('Health check requested', {
      status: healthData.status,
      uptime: healthData.uptime,
    });

    return healthData;
  }
}
