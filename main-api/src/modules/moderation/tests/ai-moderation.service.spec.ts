import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { AiModerationService } from '../services/ai-moderation.service';
import { CustomLoggerService } from '../../../common/logger';

describe('AiModerationService', () => {
  let service: AiModerationService;
  let configService: ConfigService;
  let logger: CustomLoggerService;

  beforeEach(async () => {
    const mockConfigService = {
      get: jest.fn((key: string, defaultValue?: any) => {
        const config = {
          'moderation.openai.apiKey': '',
          'moderation.openai.model': 'text-moderation-latest',
          'moderation.autoBlock.textThreshold': 0.7,
          'moderation.autoBlock.enabled': false,
        };
        return config[key] ?? defaultValue;
      }),
    };

    const mockLogger = {
      info: jest.fn(),
      warn: jest.fn(),
      error: jest.fn(),
      logBusinessEvent: jest.fn(),
      logSecurityEvent: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AiModerationService,
        {
          provide: ConfigService,
          useValue: mockConfigService,
        },
        {
          provide: CustomLoggerService,
          useValue: mockLogger,
        },
      ],
    }).compile();

    service = module.get<AiModerationService>(AiModerationService);
    configService = module.get<ConfigService>(ConfigService);
    logger = module.get<CustomLoggerService>(CustomLoggerService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('moderateText', () => {
    it('should return safe result when OpenAI is not configured', async () => {
      const result = await service.moderateText('Test text');

      expect(result.flagged).toBe(false);
      expect(result.shouldBlock).toBe(false);
      expect(logger.warn).toHaveBeenCalledWith(
        'OpenAI not configured, skipping text moderation',
      );
    });

    it('should return safe result for empty text', async () => {
      const result = await service.moderateText('');

      expect(result.flagged).toBe(false);
      expect(result.shouldBlock).toBe(false);
    });

    it('should return safe result for whitespace-only text', async () => {
      const result = await service.moderateText('   ');

      expect(result.flagged).toBe(false);
      expect(result.shouldBlock).toBe(false);
    });
  });

  describe('moderateTextBatch', () => {
    it('should return safe results for all texts when OpenAI is not configured', async () => {
      const texts = ['Text 1', 'Text 2', 'Text 3'];
      const results = await service.moderateTextBatch(texts);

      expect(results).toHaveLength(3);
      results.forEach((result) => {
        expect(result.flagged).toBe(false);
        expect(result.shouldBlock).toBe(false);
      });
    });
  });

  describe('createSafeResult', () => {
    it('should create a safe result with all flags set to false', async () => {
      const result = await service.moderateText('');

      expect(result.flagged).toBe(false);
      expect(result.shouldBlock).toBe(false);
      expect(result.categories.sexual).toBe(false);
      expect(result.categories.hate).toBe(false);
      expect(result.categories.harassment).toBe(false);
      expect(result.categories.selfHarm).toBe(false);
      expect(result.categories.sexualMinors).toBe(false);
      expect(result.categories.hateThreatening).toBe(false);
      expect(result.categories.violenceGraphic).toBe(false);
      expect(result.categories.violence).toBe(false);
      expect(result.categoryScores.sexual).toBe(0);
      expect(result.categoryScores.hate).toBe(0);
      expect(result.categoryScores.harassment).toBe(0);
      expect(result.categoryScores.selfHarm).toBe(0);
      expect(result.categoryScores.sexualMinors).toBe(0);
      expect(result.categoryScores.hateThreatening).toBe(0);
      expect(result.categoryScores.violenceGraphic).toBe(0);
      expect(result.categoryScores.violence).toBe(0);
    });
  });

  describe('Configuration', () => {
    it('should log warning when OpenAI API key is not configured', () => {
      expect(logger.warn).toHaveBeenCalledWith(
        'OpenAI API key not configured. Text moderation will be disabled.',
      );
    });

    it('should initialize with correct threshold from config', () => {
      expect(configService.get).toHaveBeenCalledWith(
        'moderation.autoBlock.textThreshold',
        0.7,
      );
    });

    it('should initialize with correct auto-block setting from config', () => {
      expect(configService.get).toHaveBeenCalledWith(
        'moderation.autoBlock.enabled',
        false,
      );
    });
  });
});
