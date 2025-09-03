import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { EmailService } from './email.service';
import { CustomLoggerService } from './logger';

describe('EmailService', () => {
  let service: EmailService;
  let configService: ConfigService;
  let loggerService: CustomLoggerService;

  const mockConfigService = {
    get: jest.fn(),
  };

  const mockLoggerService = {
    warn: jest.fn(),
    info: jest.fn(),
    error: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        EmailService,
        {
          provide: ConfigService,
          useValue: mockConfigService,
        },
        {
          provide: CustomLoggerService,
          useValue: mockLoggerService,
        },
      ],
    }).compile();

    service = module.get<EmailService>(EmailService);
    configService = module.get<ConfigService>(ConfigService);
    loggerService = module.get<CustomLoggerService>(CustomLoggerService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('configuration handling', () => {
    it('should handle missing email configuration gracefully', () => {
      // Mock incomplete email config
      mockConfigService.get.mockImplementation((key: string) => {
        if (key === 'email') {
          return {
            smtp: {
              host: '',
              user: '',
              pass: '',
            },
          };
        }
        return undefined;
      });

      // Create a new service instance to trigger initialization
      const newService = new EmailService(configService, loggerService);

      expect(loggerService.warn).toHaveBeenCalledWith(
        'Email configuration incomplete, email service will be disabled',
        'EmailService',
      );
    });

    it('should use correct configuration keys', () => {
      const mockEmailConfig = {
        from: 'test@goldwen.com',
        smtp: {
          host: 'smtp.gmail.com',
          port: 587,
          secure: false,
          user: 'test@gmail.com',
          pass: 'app-password',
        },
      };

      mockConfigService.get.mockImplementation((key: string) => {
        if (key === 'email') return mockEmailConfig;
        if (key === 'email.from') return mockEmailConfig.from;
        if (key === 'app.frontendUrl') return 'http://localhost:3001';
        return undefined;
      });

      // Create a new service instance to trigger initialization
      const newService = new EmailService(configService, loggerService);

      // Verify configuration was accessed
      expect(configService.get).toHaveBeenCalledWith('email');
    });
  });

  describe('error message handling', () => {
    it('should provide helpful Gmail authentication error messages', () => {
      const testCases = [
        {
          input: new Error('Username and Password not accepted'),
          expectedContains: 'App Password',
        },
        {
          input: new Error('BadCredentials'),
          expectedContains: 'App Password',
        },
        {
          input: new Error('Invalid login'),
          expectedContains: 'email credentials',
        },
        {
          input: new Error('Some other error'),
          expectedContains: 'Some other error',
        },
      ];

      testCases.forEach(({ input, expectedContains }) => {
        const result = (service as any).getEmailErrorMessage(input);
        expect(result).toContain(expectedContains);
      });
    });
  });
});
