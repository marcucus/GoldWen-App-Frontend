import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { SentryService } from './sentry.service';
import { AlertingService } from './alerting.service';
import { DatadogService } from './datadog.service';
import { CustomLoggerService } from '../logger';

describe('Monitoring Services', () => {
  let sentryService: SentryService;
  let alertingService: AlertingService;
  let datadogService: DatadogService;
  let configService: ConfigService;
  let loggerService: CustomLoggerService;

  const mockConfigService = {
    get: jest.fn((key: string) => {
      const config = {
        'monitoring.sentry.dsn': '',
        'monitoring.sentry.environment': 'test',
        'monitoring.sentry.tracesSampleRate': 0.1,
        'monitoring.sentry.profilesSampleRate': 0.01,
        'monitoring.datadog.apiKey': '',
        'monitoring.datadog.appKey': '',
        'monitoring.alerts.webhookUrl': 'http://test.webhook.com',
        'monitoring.alerts.slackWebhookUrl': '',
        'monitoring.alerts.emailRecipients': ['test@example.com'],
        'app.environment': 'test',
      };
      return config[key];
    }),
  };

  const mockLoggerService = {
    error: jest.fn(),
    warn: jest.fn(),
    info: jest.fn(),
    debug: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SentryService,
        AlertingService,
        DatadogService,
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

    sentryService = module.get<SentryService>(SentryService);
    alertingService = module.get<AlertingService>(AlertingService);
    datadogService = module.get<DatadogService>(DatadogService);
    configService = module.get<ConfigService>(ConfigService);
    loggerService = module.get<CustomLoggerService>(CustomLoggerService);
  });

  describe('SentryService', () => {
    it('should be defined', () => {
      expect(sentryService).toBeDefined();
    });

    it('should filter sensitive data', () => {
      const testData = {
        password: 'secret123',
        token: 'abc123',
        user: {
          email: 'test@example.com',
          credit_card: '1234-5678-9012-3456',
        },
        safe_data: 'this is safe',
      };

      const filtered = (sentryService as any).constructor.filterSensitiveData(
        testData,
      );

      expect(filtered.password).toBe('[FILTERED]');
      expect(filtered.token).toBe('[FILTERED]');
      expect(filtered.user.credit_card).toBe('[FILTERED]');
      expect(filtered.safe_data).toBe('this is safe');
    });

    it('should capture exceptions without sensitive data', () => {
      const error = new Error('Test error');
      const context = {
        user: { id: '123', password: 'secret' },
        metadata: { token: 'abc123', info: 'safe' },
      };

      // Should not throw even with sensitive data
      expect(() => {
        sentryService.captureException(error, context);
      }).not.toThrow();
    });
  });

  describe('AlertingService', () => {
    it('should be defined', () => {
      expect(alertingService).toBeDefined();
    });

    it('should log alerts properly', async () => {
      const alert = {
        level: 'critical' as const,
        title: 'Test Alert',
        message: 'This is a test alert',
        metadata: { test: true },
      };

      await alertingService.sendAlert(alert);

      expect(mockLoggerService.error).toHaveBeenCalledWith(
        'ALERT [CRITICAL]: Test Alert',
        undefined,
        'AlertingService',
      );
    });

    it('should handle missing configuration gracefully', async () => {
      // Mock empty config
      mockConfigService.get.mockReturnValue(undefined);

      const alert = {
        level: 'warning' as const,
        title: 'Test Warning',
        message: 'This is a test warning',
      };

      await expect(alertingService.sendAlert(alert)).resolves.not.toThrow();
      expect(mockLoggerService.warn).toHaveBeenCalledWith(
        'No alerting channels configured',
        'AlertingService',
      );
    });

    it('should send critical alerts with proper level', async () => {
      await alertingService.sendCriticalAlert(
        'Critical Test',
        'Critical message',
      );

      expect(mockLoggerService.error).toHaveBeenCalledWith(
        'ALERT [CRITICAL]: Critical Test',
        undefined,
        'AlertingService',
      );
    });
  });
});

  describe('DatadogService', () => {
    it('should be defined', () => {
      expect(datadogService).toBeDefined();
    });

    it('should handle missing configuration gracefully', async () => {
      // DatadogService should be initialized without keys
      const result = await datadogService.sendGaugeMetric('test.metric', 1.0);
      
      expect(result).toBe(false);
      expect(mockLoggerService.debug).toHaveBeenCalledWith(
        'DataDog not enabled, skipping metric: test.metric',
        'DatadogService'
      );
    });

    it('should track system metrics without errors', async () => {
      await expect(datadogService.trackSystemMetrics()).resolves.not.toThrow();
    });

    it('should track API metrics without errors', async () => {
      await expect(
        datadogService.trackApiMetrics('/test', 'GET', 150, 200)
      ).resolves.not.toThrow();
    });

    it('should track business metrics without errors', async () => {
      await expect(
        datadogService.trackBusinessMetrics('user_login', 1, ['source:mobile'])
      ).resolves.not.toThrow();
    });
  });
});
