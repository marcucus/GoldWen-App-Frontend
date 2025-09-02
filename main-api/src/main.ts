import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { ConfigService } from '@nestjs/config';
import { AppModule } from './app.module';
import { CustomLoggerService } from './common/logger';
import { HttpExceptionFilter } from './common/filters';
import { ResponseInterceptor } from './common/interceptors';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  const configService = app.get(ConfigService);
  const logger = app.get(CustomLoggerService);

  // Use custom logger
  app.useLogger(logger);

  const port = configService.get('app.port') || 3000;
  const apiPrefix = configService.get('app.apiPrefix') || 'api/v1';

  logger.info('🚀 Starting GoldWen API...', {
    port,
    apiPrefix,
    environment: configService.get('app.environment'),
    logLevel: configService.get('app.logLevel'),
  });

  // Global prefix
  app.setGlobalPrefix(apiPrefix);

  // Global validation pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      disableErrorMessages:
        configService.get('app.environment') === 'production',
    }),
  );

  // Global exception filter
  app.useGlobalFilters(new HttpExceptionFilter(logger));

  // Global response interceptor
  app.useGlobalInterceptors(new ResponseInterceptor(logger));

  // CORS
  app.enableCors({
    origin: process.env.FRONTEND_URL || true,
    credentials: true,
  });

  // Swagger documentation
  if (configService.get('app.environment') !== 'production') {
    const config = new DocumentBuilder()
      .setTitle('GoldWen API')
      .setDescription('GoldWen Dating App Backend API')
      .setVersion('1.0')
      .addBearerAuth()
      .addTag('Authentication', 'User authentication and authorization')
      .addTag('Users', 'User management and profile operations')
      .addTag('Profiles', 'User profile and photo management')
      .addTag('Matching', 'Daily selection and matching algorithm')
      .addTag('Chat', 'Real-time messaging and chat management')
      .addTag('Subscriptions', 'Premium subscriptions and payments')
      .addTag('Notifications', 'Push notifications and alerts')
      .addTag('Admin', 'Administrative operations')
      .build();

    const document = SwaggerModule.createDocument(app, config);
    SwaggerModule.setup(`${apiPrefix}/docs`, app, document);
  }

  await app.listen(port);
  logger.info('🚀 GoldWen API is running successfully', {
    url: `http://localhost:${port}/${apiPrefix}`,
    docs: `http://localhost:${port}/${apiPrefix}/docs`,
    environment: configService.get('app.environment'),
  });
}

bootstrap();
