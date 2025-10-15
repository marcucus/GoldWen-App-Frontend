import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { FirebaseService } from './firebase.service';
import { CustomLoggerService } from '../../common/logger';
import * as admin from 'firebase-admin';

// Mock firebase-admin
jest.mock('firebase-admin', () => ({
  initializeApp: jest.fn(),
  credential: {
    cert: jest.fn(),
  },
  messaging: jest.fn(() => ({
    send: jest.fn(),
  })),
}));

describe('FirebaseService', () => {
  let service: FirebaseService;
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
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        FirebaseService,
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

    service = module.get<FirebaseService>(FirebaseService);
    configService = module.get<ConfigService>(ConfigService);
    loggerService = module.get<CustomLoggerService>(CustomLoggerService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('initialization', () => {
    it('should warn if Firebase configuration is missing', async () => {
      mockConfigService.get.mockReturnValue(undefined);

      await service.onModuleInit();

      expect(loggerService.warn).toHaveBeenCalledWith(
        'Firebase configuration not found, Firebase notifications will be disabled',
        'FirebaseService',
      );
      expect(service.isInitialized()).toBe(false);
    });

    it('should initialize with environment credentials', async () => {
      const mockFirebaseConfig = {
        projectId: 'test-project',
        clientEmail: 'test@test.com',
        privateKey: 'test-key',
      };

      mockConfigService.get.mockReturnValue(mockFirebaseConfig);

      await service.onModuleInit();

      expect(admin.credential.cert).toHaveBeenCalledWith({
        projectId: mockFirebaseConfig.projectId,
        clientEmail: mockFirebaseConfig.clientEmail,
        privateKey: mockFirebaseConfig.privateKey,
      });
    });

    it('should warn if credentials are incomplete', async () => {
      mockConfigService.get.mockReturnValue({
        projectId: 'test-project',
        // Missing clientEmail and privateKey
      });

      await service.onModuleInit();

      expect(loggerService.warn).toHaveBeenCalledWith(
        'Firebase credentials not configured, Firebase notifications will be disabled',
        'FirebaseService',
      );
    });
  });

  describe('sendToDevice', () => {
    it('should return error if Firebase is not initialized', async () => {
      mockConfigService.get.mockReturnValue(undefined);
      await service.onModuleInit();

      const result = await service.sendToDevice('test-token', {
        title: 'Test',
        body: 'Test body',
      });

      expect(result.success).toBe(false);
      expect(result.error).toBe('Firebase not initialized');
      expect(result.errorCode).toBe('NOT_INITIALIZED');
    });

    it('should return error if device token is missing when Firebase is not initialized', async () => {
      mockConfigService.get.mockReturnValue(undefined);
      await service.onModuleInit();

      const result = await service.sendToDevice('', {
        title: 'Test',
        body: 'Test body',
      });

      expect(result.success).toBe(false);
      // When not initialized, we check for no token second
      expect(result.errorCode).toMatch(/NOT_INITIALIZED|MISSING_TOKEN/);
    });
  });

  describe('sendToMultipleDevices', () => {
    it('should return errors for all tokens if Firebase is not initialized', async () => {
      mockConfigService.get.mockReturnValue(undefined);
      await service.onModuleInit();

      const tokens = ['token1', 'token2', 'token3'];
      const results = await service.sendToMultipleDevices(tokens, {
        title: 'Test',
        body: 'Test body',
      });

      expect(results).toHaveLength(3);
      results.forEach((result) => {
        expect(result.success).toBe(false);
        expect(result.errorCode).toBe('NOT_INITIALIZED');
      });
    });
  });

  describe('isInvalidTokenError', () => {
    it('should identify invalid registration token errors', () => {
      expect(
        service.isInvalidTokenError('messaging/invalid-registration-token'),
      ).toBe(true);
      expect(
        service.isInvalidTokenError(
          'messaging/registration-token-not-registered',
        ),
      ).toBe(true);
      expect(service.isInvalidTokenError('messaging/invalid-argument')).toBe(
        true,
      );
    });

    it('should not identify other errors as invalid token errors', () => {
      expect(service.isInvalidTokenError('messaging/server-error')).toBe(false);
      expect(service.isInvalidTokenError('unknown-error')).toBe(false);
      expect(service.isInvalidTokenError(undefined)).toBe(false);
    });
  });

  describe('sendToTopic', () => {
    it('should return error if Firebase is not initialized', async () => {
      mockConfigService.get.mockReturnValue(undefined);
      await service.onModuleInit();

      const result = await service.sendToTopic('test-topic', {
        title: 'Test',
        body: 'Test body',
      });

      expect(result.success).toBe(false);
      expect(result.error).toBe('Firebase not initialized');
      expect(result.errorCode).toBe('NOT_INITIALIZED');
    });
  });
});
