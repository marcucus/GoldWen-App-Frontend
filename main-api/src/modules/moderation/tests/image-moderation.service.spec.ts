import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { ImageModerationService } from '../services/image-moderation.service';
import { CustomLoggerService } from '../../../common/logger';

describe('ImageModerationService', () => {
  let service: ImageModerationService;
  let configService: ConfigService;
  let logger: CustomLoggerService;

  beforeEach(async () => {
    const mockConfigService = {
      get: jest.fn((key: string, defaultValue?: any) => {
        const config = {
          'moderation.aws.region': '',
          'moderation.aws.accessKeyId': '',
          'moderation.aws.secretAccessKey': '',
          'moderation.autoBlock.imageThreshold': 80,
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
        ImageModerationService,
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

    service = module.get<ImageModerationService>(ImageModerationService);
    configService = module.get<ConfigService>(ConfigService);
    logger = module.get<CustomLoggerService>(CustomLoggerService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('moderateImage', () => {
    it('should return safe result when AWS Rekognition is not configured', async () => {
      const result = await service.moderateImage('/path/to/image.jpg');

      expect(result.flagged).toBe(false);
      expect(result.shouldBlock).toBe(false);
      expect(result.labels).toEqual([]);
      expect(logger.warn).toHaveBeenCalledWith(
        'AWS Rekognition not configured, skipping image moderation',
      );
    });
  });

  describe('moderateImageFromUrl', () => {
    it('should return safe result when AWS Rekognition is not configured', async () => {
      const result = await service.moderateImageFromUrl(
        'https://example.com/image.jpg',
      );

      expect(result.flagged).toBe(false);
      expect(result.shouldBlock).toBe(false);
      expect(result.labels).toEqual([]);
      expect(logger.warn).toHaveBeenCalledWith(
        'AWS Rekognition not configured, skipping image moderation',
      );
    });
  });

  describe('createSafeResult', () => {
    it('should create a safe result with empty labels', async () => {
      const result = await service.moderateImage('/path/to/image.jpg');

      expect(result.flagged).toBe(false);
      expect(result.shouldBlock).toBe(false);
      expect(result.labels).toEqual([]);
      expect(result.reason).toBeUndefined();
    });
  });

  describe('Configuration', () => {
    it('should log warning when AWS credentials are not configured', () => {
      expect(logger.warn).toHaveBeenCalledWith(
        'AWS credentials not configured. Image moderation will be disabled.',
      );
    });

    it('should initialize with correct threshold from config', () => {
      expect(configService.get).toHaveBeenCalledWith(
        'moderation.autoBlock.imageThreshold',
        80,
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
