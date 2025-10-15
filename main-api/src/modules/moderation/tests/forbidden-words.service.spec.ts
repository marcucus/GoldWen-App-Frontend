import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { ForbiddenWordsService } from '../services/forbidden-words.service';
import { CustomLoggerService } from '../../../common/logger';

describe('ForbiddenWordsService', () => {
  let service: ForbiddenWordsService;
  let logger: CustomLoggerService;

  beforeEach(async () => {
    const mockConfigService = {
      get: jest.fn((key: string, defaultValue?: unknown) => {
        if (key === 'moderation.forbiddenWords.enabled') {
          return true;
        }
        if (key === 'moderation.forbiddenWords.words') {
          return ['badword', 'offensive', 'inappropriate phrase'];
        }
        return defaultValue;
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
        ForbiddenWordsService,
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

    service = module.get<ForbiddenWordsService>(ForbiddenWordsService);
    logger = module.get<CustomLoggerService>(CustomLoggerService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('checkText', () => {
    it('should detect a forbidden word in text', () => {
      const result = service.checkText('This contains a badword in it');

      expect(result.containsForbiddenWords).toBe(true);
      expect(result.foundWords).toContain('badword');
      expect(result.reason).toContain('badword');
    });

    it('should detect multiple forbidden words', () => {
      const result = service.checkText(
        'This has badword and offensive content',
      );

      expect(result.containsForbiddenWords).toBe(true);
      expect(result.foundWords).toHaveLength(2);
      expect(result.foundWords).toContain('badword');
      expect(result.foundWords).toContain('offensive');
    });

    it('should be case-insensitive', () => {
      const result = service.checkText('This has BADWORD in caps');

      expect(result.containsForbiddenWords).toBe(true);
      expect(result.foundWords).toContain('badword');
    });

    it('should detect forbidden phrases', () => {
      const result = service.checkText('This has an inappropriate phrase here');

      expect(result.containsForbiddenWords).toBe(true);
      expect(result.foundWords).toContain('inappropriate phrase');
    });

    it('should use word boundaries (not match partial words)', () => {
      const result = service.checkText('This is badwordish but not exact');

      expect(result.containsForbiddenWords).toBe(false);
    });

    it('should match whole words with word boundaries', () => {
      const result = service.checkText('The badword is here');

      expect(result.containsForbiddenWords).toBe(true);
      expect(result.foundWords).toContain('badword');
    });

    it('should return false for clean text', () => {
      const result = service.checkText('This is perfectly acceptable content');

      expect(result.containsForbiddenWords).toBe(false);
      expect(result.foundWords).toBeUndefined();
      expect(result.reason).toBeUndefined();
    });

    it('should return false for empty text', () => {
      const result = service.checkText('');

      expect(result.containsForbiddenWords).toBe(false);
    });

    it('should return false for whitespace-only text', () => {
      const result = service.checkText('   ');

      expect(result.containsForbiddenWords).toBe(false);
    });

    it('should log security event when forbidden words detected', () => {
      service.checkText('This has badword in it');

      // eslint-disable-next-line @typescript-eslint/unbound-method
      expect(logger.logSecurityEvent).toHaveBeenCalledWith(
        'forbidden_words_detected',
        expect.objectContaining({
          // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
          foundWords: expect.arrayContaining(['badword']),
        }),
      );
    });
  });

  describe('checkTextBatch', () => {
    it('should check multiple texts and return results', () => {
      const texts = [
        'Clean text',
        'Has badword here',
        'Another clean one',
        'This is offensive',
      ];

      const results = service.checkTextBatch(texts);

      expect(results).toHaveLength(4);
      expect(results[0].containsForbiddenWords).toBe(false);
      expect(results[1].containsForbiddenWords).toBe(true);
      expect(results[1].foundWords).toContain('badword');
      expect(results[2].containsForbiddenWords).toBe(false);
      expect(results[3].containsForbiddenWords).toBe(true);
      expect(results[3].foundWords).toContain('offensive');
    });

    it('should handle empty array', () => {
      const results = service.checkTextBatch([]);

      expect(results).toHaveLength(0);
    });
  });

  describe('isEnabled', () => {
    it('should return enabled status', () => {
      expect(service.isEnabled()).toBe(true);
    });
  });

  describe('getForbiddenWords', () => {
    it('should return list of forbidden words', () => {
      const words = service.getForbiddenWords();

      expect(words).toContain('badword');
      expect(words).toContain('offensive');
      expect(words).toContain('inappropriate phrase');
    });
  });

  describe('when disabled', () => {
    beforeEach(async () => {
      const mockConfigService = {
        get: jest.fn((key: string, defaultValue?: unknown) => {
          if (key === 'moderation.forbiddenWords.enabled') {
            return false;
          }
          if (key === 'moderation.forbiddenWords.words') {
            return ['badword'];
          }
          return defaultValue;
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
          ForbiddenWordsService,
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

      service = module.get<ForbiddenWordsService>(ForbiddenWordsService);
    });

    it('should not check text when disabled', () => {
      const result = service.checkText('This has badword in it');

      expect(result.containsForbiddenWords).toBe(false);
    });

    it('should return isEnabled as false', () => {
      expect(service.isEnabled()).toBe(false);
    });
  });
});
