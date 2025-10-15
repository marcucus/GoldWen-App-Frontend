import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { EmailService } from './email.service';
import { CustomLoggerService } from '../../common/logger';
import * as sgMail from '@sendgrid/mail';

// Mock SendGrid
jest.mock('@sendgrid/mail', () => ({
  setApiKey: jest.fn(),
  send: jest.fn(),
}));

describe('EmailService (modules/email)', () => {
  let service: EmailService;
  let loggerService: CustomLoggerService;

  const mockConfigService = {
    get: jest.fn(),
  };

  const mockLoggerService = {
    warn: jest.fn(),
    info: jest.fn(),
    error: jest.fn(),
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  const createTestModule = async (): Promise<void> => {
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
    loggerService = module.get<CustomLoggerService>(CustomLoggerService);
  };

  it('should be defined', async () => {
    await createTestModule();
    expect(service).toBeDefined();
  });

  describe('SendGrid Configuration', () => {
    it('should initialize SendGrid when provider is sendgrid', async () => {
      jest.clearAllMocks();
      mockConfigService.get.mockImplementation((key: string) => {
        if (key === 'email') {
          return {
            provider: 'sendgrid',
            sendgridApiKey: 'SG.test-api-key',
            from: 'test@goldwen.com',
          };
        }
        if (key === 'email.sendgridApiKey') return 'SG.test-api-key';
        return undefined;
      });

      await createTestModule();

      expect(sgMail.setApiKey).toHaveBeenCalledWith('SG.test-api-key');
      expect(loggerService.info).toHaveBeenCalledWith(
        'SendGrid email service initialized successfully',
        expect.objectContaining({
          provider: 'sendgrid',
        }),
      );
    });

    it('should warn when SendGrid API key is missing', async () => {
      jest.clearAllMocks();
      mockConfigService.get.mockImplementation((key: string) => {
        if (key === 'email') {
          return {
            provider: 'sendgrid',
            sendgridApiKey: '',
          };
        }
        if (key === 'email.sendgridApiKey') return '';
        return undefined;
      });

      await createTestModule();

      expect(loggerService.warn).toHaveBeenCalledWith(
        'SendGrid API key not configured, email service will be disabled',
        'EmailService',
      );
    });
  });

  describe('SMTP Configuration', () => {
    it('should initialize SMTP when provider is smtp', async () => {
      jest.clearAllMocks();
      mockConfigService.get.mockImplementation((key: string) => {
        if (key === 'email') {
          return {
            provider: 'smtp',
            smtp: {
              host: 'smtp.gmail.com',
              port: 587,
              secure: false,
              user: 'test@gmail.com',
              pass: 'app-password',
            },
          };
        }
        return undefined;
      });

      await createTestModule();

      expect(loggerService.info).toHaveBeenCalledWith(
        'SMTP email service initialized successfully',
        expect.objectContaining({
          provider: 'smtp',
          host: 'smtp.gmail.com',
        }),
      );
    });

    it('should warn when SMTP configuration is incomplete', async () => {
      jest.clearAllMocks();
      mockConfigService.get.mockImplementation((key: string) => {
        if (key === 'email') {
          return {
            provider: 'smtp',
            smtp: {
              host: '',
              user: '',
              pass: '',
            },
          };
        }
        return undefined;
      });

      await createTestModule();

      expect(loggerService.warn).toHaveBeenCalledWith(
        'SMTP configuration incomplete, email service will be disabled',
        'EmailService',
      );
    });
  });

  describe('sendWelcomeEmail', () => {
    beforeEach(async () => {
      jest.clearAllMocks();
      mockConfigService.get.mockImplementation((key: string) => {
        if (key === 'email') {
          return {
            provider: 'sendgrid',
            sendgridApiKey: 'SG.test-api-key',
            from: 'noreply@goldwen.com',
          };
        }
        if (key === 'email.sendgridApiKey') return 'SG.test-api-key';
        if (key === 'email.from') return 'noreply@goldwen.com';
        return undefined;
      });
      await createTestModule();
    });

    it('should send welcome email successfully', async () => {
      const mockSend = sgMail.send as jest.Mock;
      mockSend.mockResolvedValueOnce([{ statusCode: 202 }]);

      await service.sendWelcomeEmail('user@example.com', 'John');

      expect(mockSend).toHaveBeenCalledWith(
        expect.objectContaining({
          to: 'user@example.com',
          subject: 'Bienvenue sur GoldWen !',
          from: 'noreply@goldwen.com',
        }),
      );

      expect(loggerService.info).toHaveBeenCalledWith(
        'Welcome email sent successfully',
        expect.objectContaining({
          email: 'us***@example.com',
          provider: 'sendgrid',
        }),
      );
    });

    it('should handle SendGrid errors gracefully', async () => {
      const mockSend = sgMail.send as jest.Mock;
      mockSend.mockRejectedValueOnce(
        new Error('SendGrid API error: Invalid API key'),
      );

      await service.sendWelcomeEmail('user@example.com', 'John');

      expect(loggerService.error).toHaveBeenCalledWith(
        'Failed to send welcome email',
        expect.any(String),
        'EmailService',
      );
    });
  });

  describe('sendDataExportReadyEmail', () => {
    beforeEach(async () => {
      jest.clearAllMocks();
      mockConfigService.get.mockImplementation((key: string) => {
        if (key === 'email') {
          return {
            provider: 'sendgrid',
            sendgridApiKey: 'SG.test-api-key',
            from: 'noreply@goldwen.com',
          };
        }
        if (key === 'email.sendgridApiKey') return 'SG.test-api-key';
        if (key === 'email.from') return 'noreply@goldwen.com';
        return undefined;
      });
      await createTestModule();
    });

    it('should send data export ready email successfully', async () => {
      const mockSend = sgMail.send as jest.Mock;
      mockSend.mockResolvedValueOnce([{ statusCode: 202 }]);

      await service.sendDataExportReadyEmail(
        'user@example.com',
        'John',
        'https://example.com/download',
      );

      expect(mockSend).toHaveBeenCalledWith(
        expect.objectContaining({
          to: 'user@example.com',
          subject: 'Votre export de données est prêt',
        }),
      );

      expect(loggerService.info).toHaveBeenCalledWith(
        'Data export ready email sent successfully',
        expect.objectContaining({
          provider: 'sendgrid',
        }),
      );
    });
  });

  describe('sendAccountDeletedEmail', () => {
    beforeEach(async () => {
      jest.clearAllMocks();
      mockConfigService.get.mockImplementation((key: string) => {
        if (key === 'email') {
          return {
            provider: 'sendgrid',
            sendgridApiKey: 'SG.test-api-key',
            from: 'noreply@goldwen.com',
          };
        }
        if (key === 'email.sendgridApiKey') return 'SG.test-api-key';
        if (key === 'email.from') return 'noreply@goldwen.com';
        return undefined;
      });
      await createTestModule();
    });

    it('should send account deleted email successfully', async () => {
      const mockSend = sgMail.send as jest.Mock;
      mockSend.mockResolvedValueOnce([{ statusCode: 202 }]);

      await service.sendAccountDeletedEmail('user@example.com', 'John');

      expect(mockSend).toHaveBeenCalledWith(
        expect.objectContaining({
          to: 'user@example.com',
          subject: 'Votre compte GoldWen a été supprimé',
        }),
      );

      expect(loggerService.info).toHaveBeenCalledWith(
        'Account deleted email sent successfully',
        expect.objectContaining({
          provider: 'sendgrid',
        }),
      );
    });

    it('should not throw error on failure (non-critical email)', async () => {
      const mockSend = sgMail.send as jest.Mock;
      mockSend.mockRejectedValueOnce(new Error('SendGrid error'));

      await expect(
        service.sendAccountDeletedEmail('user@example.com', 'John'),
      ).resolves.not.toThrow();

      expect(loggerService.error).toHaveBeenCalledWith(
        'Failed to send account deleted email',
        expect.any(String),
        'EmailService',
      );
    });
  });

  describe('sendSubscriptionConfirmedEmail', () => {
    beforeEach(async () => {
      jest.clearAllMocks();
      mockConfigService.get.mockImplementation((key: string) => {
        if (key === 'email') {
          return {
            provider: 'sendgrid',
            sendgridApiKey: 'SG.test-api-key',
            from: 'noreply@goldwen.com',
          };
        }
        if (key === 'email.sendgridApiKey') return 'SG.test-api-key';
        if (key === 'email.from') return 'noreply@goldwen.com';
        return undefined;
      });
      await createTestModule();
    });

    it('should send subscription confirmed email successfully', async () => {
      const mockSend = sgMail.send as jest.Mock;
      mockSend.mockResolvedValueOnce([{ statusCode: 202 }]);

      const expiryDate = new Date('2025-12-31');
      await service.sendSubscriptionConfirmedEmail(
        'user@example.com',
        'John',
        'GoldWen Plus',
        expiryDate,
      );

      expect(mockSend).toHaveBeenCalledWith(
        expect.objectContaining({
          to: 'user@example.com',
          subject: 'Votre abonnement GoldWen est confirmé',
        }),
      );

      expect(loggerService.info).toHaveBeenCalledWith(
        'Subscription confirmed email sent successfully',
        expect.objectContaining({
          provider: 'sendgrid',
          subscriptionType: 'GoldWen Plus',
        }),
      );
    });

    it('should include subscription type in email template', async () => {
      const mockSend = sgMail.send as jest.Mock;
      mockSend.mockResolvedValueOnce([{ statusCode: 202 }]);

      const expiryDate = new Date('2025-12-31');
      await service.sendSubscriptionConfirmedEmail(
        'user@example.com',
        'John',
        'GoldWen Plus',
        expiryDate,
      );

      const callArg = mockSend.mock.calls[0][0];
      expect(callArg.html).toContain('GoldWen Plus');
      expect(callArg.html).toContain('John');
    });
  });

  describe('sendPasswordResetEmail', () => {
    beforeEach(async () => {
      jest.clearAllMocks();
      mockConfigService.get.mockImplementation((key: string) => {
        if (key === 'email') {
          return {
            provider: 'sendgrid',
            sendgridApiKey: 'SG.test-api-key',
            from: 'noreply@goldwen.com',
          };
        }
        if (key === 'email.sendgridApiKey') return 'SG.test-api-key';
        if (key === 'email.from') return 'noreply@goldwen.com';
        if (key === 'app.frontendUrl') return 'https://goldwen.com';
        return undefined;
      });
      await createTestModule();
    });

    it('should send password reset email successfully', async () => {
      const mockSend = sgMail.send as jest.Mock;
      mockSend.mockResolvedValueOnce([{ statusCode: 202 }]);

      await service.sendPasswordResetEmail('user@example.com', 'reset-token');

      expect(mockSend).toHaveBeenCalledWith(
        expect.objectContaining({
          to: 'user@example.com',
          subject: 'Réinitialisation de votre mot de passe GoldWen',
        }),
      );

      const callArg = mockSend.mock.calls[0][0];
      expect(callArg.html).toContain(
        'https://goldwen.com/reset-password?token=reset-token',
      );
    });

    it('should throw error on failure (critical email)', async () => {
      const mockSend = sgMail.send as jest.Mock;
      const sendGridError = new Error('SendGrid error');
      mockSend.mockRejectedValueOnce(sendGridError);

      await expect(
        service.sendPasswordResetEmail('user@example.com', 'reset-token'),
      ).rejects.toThrow('SendGrid error');

      expect(loggerService.error).toHaveBeenCalledWith(
        'Failed to send password reset email',
        expect.any(String),
        'EmailService',
      );
    });
  });

  describe('Error handling', () => {
    it('should handle SendGrid API errors with proper message', async () => {
      jest.clearAllMocks();
      mockConfigService.get.mockImplementation((key: string) => {
        if (key === 'email') {
          return {
            provider: 'sendgrid',
            sendgridApiKey: 'SG.test-api-key',
            from: 'noreply@goldwen.com',
          };
        }
        if (key === 'email.sendgridApiKey') return 'SG.test-api-key';
        if (key === 'email.from') return 'noreply@goldwen.com';
        return undefined;
      });
      await createTestModule();

      const mockSend = sgMail.send as jest.Mock;
      const sendGridError = new Error('Unauthorized');
      (sendGridError as any).code = 401;

      mockSend.mockRejectedValueOnce(sendGridError);

      await service.sendWelcomeEmail('user@example.com', 'John');

      expect(loggerService.info).toHaveBeenCalledWith(
        'Welcome email error details',
        expect.objectContaining({
          error: expect.stringContaining('SendGrid API error'),
        }),
      );
    });
  });

  describe('Email masking', () => {
    it('should mask email addresses in logs', async () => {
      jest.clearAllMocks();
      mockConfigService.get.mockImplementation((key: string) => {
        if (key === 'email') {
          return {
            provider: 'sendgrid',
            sendgridApiKey: 'SG.test-api-key',
            from: 'noreply@goldwen.com',
          };
        }
        if (key === 'email.sendgridApiKey') return 'SG.test-api-key';
        if (key === 'email.from') return 'noreply@goldwen.com';
        return undefined;
      });
      await createTestModule();

      const mockSend = sgMail.send as jest.Mock;
      mockSend.mockResolvedValueOnce([{ statusCode: 202 }]);

      await service.sendWelcomeEmail('johndoe@example.com', 'John');

      expect(loggerService.info).toHaveBeenCalledWith(
        'Welcome email sent successfully',
        expect.objectContaining({
          email: 'jo***@example.com',
        }),
      );
    });
  });
});
