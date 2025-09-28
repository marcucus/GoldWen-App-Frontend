import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { ConfigService } from '@nestjs/config';
import { Reflector } from '@nestjs/core';
import { AppModule } from './app.module';
import { CustomLoggerService } from './common/logger';
import { HttpExceptionFilter } from './common/filters';
import { ResponseInterceptor, CacheInterceptor } from './common/interceptors';
import { SentryService } from './common/monitoring';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  const configService = app.get(ConfigService);
  const logger = app.get(CustomLoggerService);
  const reflector = app.get(Reflector);
  const sentry = app.get(SentryService);

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
  app.useGlobalFilters(new HttpExceptionFilter(logger, sentry));

  // Global interceptors - order matters for interceptor chain
  app.useGlobalInterceptors(new CacheInterceptor(reflector));
  app.useGlobalInterceptors(new ResponseInterceptor(logger));

  // CORS
  app.enableCors({
    origin: '*', // Accepte toutes les origines temporairement
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'Origin', 'X-Requested-With'],
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
      .addTag('Preferences', 'User preferences management')
      .addTag('Admin', 'Administrative operations')
      .build();

    const document = SwaggerModule.createDocument(app, config);
    SwaggerModule.setup(`${apiPrefix}/docs`, app, document);
  }

  await app.listen(port, '0.0.0.0');
  logger.info('🚀 GoldWen API is running successfully', {
    url: `http://192.168.1.183:${port}/${apiPrefix}`,
    networkUrl: `http://192.168.1.183:${port}/${apiPrefix}`,
    docs: `http://192.168.1.183:${port}/${apiPrefix}/docs`,
    environment: configService.get('app.environment'),
  });
}

bootstrap();
