import { Test, TestingModule } from '@nestjs/testing';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { CustomLoggerService } from './common/logger';

describe('AppController', () => {
  let appController: AppController;

  beforeEach(async () => {
    const mockLogger = {
      info: jest.fn(),
      error: jest.fn(),
      warn: jest.fn(),
      debug: jest.fn(),
    };

    const app: TestingModule = await Test.createTestingModule({
      controllers: [AppController],
      providers: [
        AppService,
        {
          provide: CustomLoggerService,
          useValue: mockLogger,
        },
      ],
    }).compile();

    appController = app.get<AppController>(AppController);
  });

  describe('root', () => {
    it('should return the GoldWen welcome message', () => {
      expect(appController.getHello()).toBe(
        'GoldWen API - Designed to be deleted ❤️',
      );
    });
  });
});
