import { Test, TestingModule } from '@nestjs/testing';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { CustomLoggerService } from './common/logger';

describe('AppController', () => {
  let appController: AppController;
  let appService: AppService;

  beforeEach(async () => {
    const mockLogger = {
      info: jest.fn(),
      error: jest.fn(),
      warn: jest.fn(),
      debug: jest.fn(),
    };

    const mockAppService = {
      getHello: jest
        .fn()
        .mockReturnValue('GoldWen API - Designed to be deleted ❤️'),
      getHealth: jest.fn().mockResolvedValue({
        status: 'healthy',
        timestamp: '2025-01-01T00:00:00.000Z',
        uptime: 3600,
        environment: 'test',
        version: '1.0.0',
        responseTime: 50,
        services: {
          api: 'healthy',
          database: { status: 'healthy', responseTime: 25 },
          cache: { status: 'healthy', responseTime: 5 },
        },
      }),
    };

    const app: TestingModule = await Test.createTestingModule({
      controllers: [AppController],
      providers: [
        {
          provide: AppService,
          useValue: mockAppService,
        },
        {
          provide: CustomLoggerService,
          useValue: mockLogger,
        },
      ],
    }).compile();

    appController = app.get<AppController>(AppController);
    appService = app.get<AppService>(AppService);
  });

  describe('root', () => {
    it('should return the GoldWen welcome message', () => {
      expect(appController.getHello()).toBe(
        'GoldWen API - Designed to be deleted ❤️',
      );
    });
  });

  describe('health', () => {
    it('should return health status', async () => {
      const result = await appController.getHealth();

      expect(result).toEqual({
        status: 'healthy',
        timestamp: '2025-01-01T00:00:00.000Z',
        uptime: 3600,
        environment: 'test',
        version: '1.0.0',
        responseTime: 50,
        services: {
          api: 'healthy',
          database: { status: 'healthy', responseTime: 25 },
          cache: { status: 'healthy', responseTime: 5 },
        },
      });

      expect(appService.getHealth).toHaveBeenCalled();
    });
  });
});
