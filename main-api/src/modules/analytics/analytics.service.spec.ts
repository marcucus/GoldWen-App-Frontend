import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { AnalyticsService } from './analytics.service';
import { GdprService } from '../gdpr/gdpr.service';

describe('AnalyticsService', () => {
  let service: AnalyticsService;
  let gdprService: GdprService;
  let configService: ConfigService;

  const mockConfigService = {
    get: jest.fn((key: string) => {
      const config: Record<string, unknown> = {
        'analytics.mixpanel.token': 'test-token',
        'analytics.mixpanel.enabled': true,
        'app.environment': 'test',
      };
      return config[key];
    }),
  };

  const mockGdprService = {
    getCurrentConsent: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AnalyticsService,
        {
          provide: ConfigService,
          useValue: mockConfigService,
        },
        {
          provide: GdprService,
          useValue: mockGdprService,
        },
      ],
    }).compile();

    service = module.get<AnalyticsService>(AnalyticsService);
    gdprService = module.get<GdprService>(GdprService);
    configService = module.get<ConfigService>(ConfigService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('trackEvent', () => {
    it('should skip tracking if analytics is disabled', async () => {
      mockConfigService.get.mockReturnValueOnce('');
      mockConfigService.get.mockReturnValueOnce(false);

      const newService = new AnalyticsService(configService, gdprService);
      await newService.trackEvent({
        name: 'test_event',
        userId: 'user-123',
      });

      expect(mockGdprService.getCurrentConsent).not.toHaveBeenCalled();
    });

    it('should skip tracking if user has not consented to analytics', async () => {
      mockGdprService.getCurrentConsent.mockResolvedValueOnce({
        analytics: false,
        dataProcessing: true,
        marketing: false,
      });

      await service.trackEvent({
        name: 'test_event',
        userId: 'user-123',
      });

      expect(mockGdprService.getCurrentConsent).toHaveBeenCalledWith(
        'user-123',
      );
    });

    it('should track event if user has consented to analytics', async () => {
      mockGdprService.getCurrentConsent.mockResolvedValueOnce({
        analytics: true,
        dataProcessing: true,
        marketing: false,
      });

      await service.trackEvent({
        name: 'test_event',
        userId: 'user-123',
        properties: { key: 'value' },
      });

      expect(mockGdprService.getCurrentConsent).toHaveBeenCalledWith(
        'user-123',
      );
    });

    it('should default to opt-out if no consent record exists', async () => {
      mockGdprService.getCurrentConsent.mockResolvedValueOnce(null);

      await service.trackEvent({
        name: 'test_event',
        userId: 'user-123',
      });

      expect(mockGdprService.getCurrentConsent).toHaveBeenCalledWith(
        'user-123',
      );
    });

    it('should handle errors gracefully when checking consent', async () => {
      mockGdprService.getCurrentConsent.mockRejectedValueOnce(
        new Error('Database error'),
      );

      await expect(
        service.trackEvent({
          name: 'test_event',
          userId: 'user-123',
        }),
      ).resolves.not.toThrow();
    });
  });

  describe('trackOnboarding', () => {
    it('should track onboarding events with correct properties', async () => {
      mockGdprService.getCurrentConsent.mockResolvedValueOnce({
        analytics: true,
        dataProcessing: true,
        marketing: false,
      });

      const trackEventSpy = jest.spyOn(service, 'trackEvent');

      await service.trackOnboarding('user-123', {
        step: 'registration',
        method: 'google',
      });

      expect(trackEventSpy).toHaveBeenCalledWith({
        name: 'onboarding_registration',
        userId: 'user-123',
        properties: {
          step: 'registration',
          method: 'google',
        },
      });
    });
  });

  describe('trackMatching', () => {
    it('should track matching events with compatibility score', async () => {
      mockGdprService.getCurrentConsent.mockResolvedValueOnce({
        analytics: true,
        dataProcessing: true,
        marketing: false,
      });

      const trackEventSpy = jest.spyOn(service, 'trackEvent');

      await service.trackMatching('user-123', {
        action: 'match_created',
        matchId: 'match-456',
        compatibilityScore: 85,
      });

      expect(trackEventSpy).toHaveBeenCalledWith({
        name: 'matching_match_created',
        userId: 'user-123',
        properties: {
          action: 'match_created',
          matchId: 'match-456',
          compatibilityScore: 85,
        },
      });
    });
  });

  describe('trackChat', () => {
    it('should track chat events', async () => {
      mockGdprService.getCurrentConsent.mockResolvedValueOnce({
        analytics: true,
        dataProcessing: true,
        marketing: false,
      });

      const trackEventSpy = jest.spyOn(service, 'trackEvent');

      await service.trackChat('user-123', {
        action: 'message_sent',
        conversationId: 'conv-789',
      });

      expect(trackEventSpy).toHaveBeenCalledWith({
        name: 'chat_message_sent',
        userId: 'user-123',
        properties: {
          action: 'message_sent',
          conversationId: 'conv-789',
        },
      });
    });
  });

  describe('trackSubscription', () => {
    it('should track subscription events and update user profile', async () => {
      mockGdprService.getCurrentConsent.mockResolvedValue({
        analytics: true,
        dataProcessing: true,
        marketing: false,
      });

      const trackEventSpy = jest.spyOn(service, 'trackEvent');
      const identifyUserSpy = jest.spyOn(service, 'identifyUser');

      await service.trackSubscription('user-123', {
        action: 'subscription_started',
        plan: 'GoldWen Plus',
        price: 9.99,
        currency: 'USD',
      });

      expect(trackEventSpy).toHaveBeenCalledWith({
        name: 'subscription_subscription_started',
        userId: 'user-123',
        properties: {
          action: 'subscription_started',
          plan: 'GoldWen Plus',
          price: 9.99,
          currency: 'USD',
        },
      });

      expect(identifyUserSpy).toHaveBeenCalledWith('user-123', {
        subscription_plan: 'GoldWen Plus',
        is_subscriber: true,
      });
    });

    it('should update user profile when subscription is cancelled', async () => {
      mockGdprService.getCurrentConsent.mockResolvedValue({
        analytics: true,
        dataProcessing: true,
        marketing: false,
      });

      const identifyUserSpy = jest.spyOn(service, 'identifyUser');

      await service.trackSubscription('user-123', {
        action: 'subscription_cancelled',
        plan: 'GoldWen Plus',
      });

      expect(identifyUserSpy).toHaveBeenCalledWith('user-123', {
        is_subscriber: false,
      });
    });
  });

  describe('identifyUser', () => {
    it('should skip identification if user has not consented', async () => {
      mockGdprService.getCurrentConsent.mockResolvedValueOnce({
        analytics: false,
        dataProcessing: true,
        marketing: false,
      });

      await service.identifyUser('user-123', {
        name: 'John Doe',
        email: 'john@example.com',
      });

      expect(mockGdprService.getCurrentConsent).toHaveBeenCalledWith(
        'user-123',
      );
    });

    it('should identify user if consent is given', async () => {
      mockGdprService.getCurrentConsent.mockResolvedValueOnce({
        analytics: true,
        dataProcessing: true,
        marketing: false,
      });

      await service.identifyUser('user-123', {
        name: 'John Doe',
        email: 'john@example.com',
      });

      expect(mockGdprService.getCurrentConsent).toHaveBeenCalledWith(
        'user-123',
      );
    });
  });

  describe('GDPR compliance', () => {
    it('should opt out user from analytics', async () => {
      await expect(service.optOut('user-123')).resolves.not.toThrow();
    });

    it('should delete all user analytics data', async () => {
      await expect(service.deleteUserData('user-123')).resolves.not.toThrow();
    });
  });
});
