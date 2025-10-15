import { Test, TestingModule } from '@nestjs/testing';
import { NotFoundException } from '@nestjs/common';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ModerationService } from '../services/moderation.service';
import { AiModerationService } from '../services/ai-moderation.service';
import { ImageModerationService } from '../services/image-moderation.service';
import { ForbiddenWordsService } from '../services/forbidden-words.service';
import { NotificationsService } from '../../notifications/notifications.service';
import { CustomLoggerService } from '../../../common/logger';
import { Photo } from '../../../database/entities/photo.entity';
import { User } from '../../../database/entities/user.entity';
import { NotificationType } from '../../../common/enums';

describe('ModerationService', () => {
  let service: ModerationService;
  let photoRepository: Repository<Photo>;
  let userRepository: Repository<User>;
  let aiModerationService: AiModerationService;
  let imageModerationService: ImageModerationService;
  let forbiddenWordsService: ForbiddenWordsService;
  let notificationsService: NotificationsService;
  let logger: CustomLoggerService;

  beforeEach(async () => {
    const mockPhotoRepository = {
      findOne: jest.fn(),
      save: jest.fn(),
    };

    const mockUserRepository = {
      findOne: jest.fn(),
    };

    const mockAiModerationService = {
      moderateText: jest.fn(),
      moderateTextBatch: jest.fn(),
    };

    const mockImageModerationService = {
      moderateImage: jest.fn(),
    };

    const mockForbiddenWordsService = {
      checkText: jest.fn().mockReturnValue({ containsForbiddenWords: false }),
      checkTextBatch: jest
        .fn()
        .mockImplementation((texts: string[]) =>
          texts.map(() => ({ containsForbiddenWords: false })),
        ),
    };

    const mockNotificationsService = {
      createNotification: jest.fn(),
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
        ModerationService,
        {
          provide: getRepositoryToken(Photo),
          useValue: mockPhotoRepository,
        },
        {
          provide: getRepositoryToken(User),
          useValue: mockUserRepository,
        },
        {
          provide: AiModerationService,
          useValue: mockAiModerationService,
        },
        {
          provide: ImageModerationService,
          useValue: mockImageModerationService,
        },
        {
          provide: ForbiddenWordsService,
          useValue: mockForbiddenWordsService,
        },
        {
          provide: NotificationsService,
          useValue: mockNotificationsService,
        },
        {
          provide: CustomLoggerService,
          useValue: mockLogger,
        },
      ],
    }).compile();

    service = module.get<ModerationService>(ModerationService);
    photoRepository = module.get<Repository<Photo>>(getRepositoryToken(Photo));
    userRepository = module.get<Repository<User>>(getRepositoryToken(User));
    aiModerationService = module.get<AiModerationService>(AiModerationService);
    imageModerationService = module.get<ImageModerationService>(
      ImageModerationService,
    );
    forbiddenWordsService = module.get<ForbiddenWordsService>(
      ForbiddenWordsService,
    );
    notificationsService =
      module.get<NotificationsService>(NotificationsService);
    logger = module.get<CustomLoggerService>(CustomLoggerService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('moderatePhoto', () => {
    it('should throw NotFoundException if photo does not exist', async () => {
      jest.spyOn(photoRepository, 'findOne').mockResolvedValue(null);

      await expect(service.moderatePhoto('non-existent-id')).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should moderate photo and approve it if not flagged', async () => {
      const mockPhoto = {
        id: 'photo-1',
        url: '/uploads/photo.jpg',
        filename: 'photo.jpg',
        isApproved: false,
        rejectionReason: null,
        profile: { userId: 'user-1' },
      } as Photo;

      const mockModerationResult = {
        flagged: false,
        labels: [],
        shouldBlock: false,
      };

      jest.spyOn(photoRepository, 'findOne').mockResolvedValue(mockPhoto);
      jest
        .spyOn(imageModerationService, 'moderateImage')
        .mockResolvedValue(mockModerationResult);
      jest.spyOn(photoRepository, 'save').mockResolvedValue(mockPhoto);

      const result = await service.moderatePhoto('photo-1');

      expect(result.photoId).toBe('photo-1');
      expect(result.approved).toBe(true);
      expect(result.reason).toBeUndefined();
      expect(photoRepository.save).toHaveBeenCalled();
      expect(notificationsService.createNotification).not.toHaveBeenCalled();
    });

    it('should moderate photo and reject it if flagged', async () => {
      const mockPhoto = {
        id: 'photo-1',
        url: '/uploads/photo.jpg',
        filename: 'photo.jpg',
        isApproved: true,
        rejectionReason: null,
        profile: { userId: 'user-1' },
      } as Photo;

      const mockModerationResult = {
        flagged: true,
        labels: [{ name: 'Explicit Nudity', confidence: 95 }],
        shouldBlock: true,
        reason: 'Image contains inappropriate content: Explicit Nudity',
      };

      jest.spyOn(photoRepository, 'findOne').mockResolvedValue(mockPhoto);
      jest
        .spyOn(imageModerationService, 'moderateImage')
        .mockResolvedValue(mockModerationResult);
      jest.spyOn(photoRepository, 'save').mockResolvedValue(mockPhoto);
      jest
        .spyOn(notificationsService, 'createNotification')
        .mockResolvedValue({} as any);

      const result = await service.moderatePhoto('photo-1');

      expect(result.photoId).toBe('photo-1');
      expect(result.approved).toBe(false);
      expect(result.reason).toBe(
        'Image contains inappropriate content: Explicit Nudity',
      );
      expect(photoRepository.save).toHaveBeenCalled();
      expect(notificationsService.createNotification).toHaveBeenCalledWith({
        userId: 'user-1',
        type: NotificationType.SYSTEM,
        title: 'Photo Rejected',
        body: 'One of your photos was rejected: Image contains inappropriate content: Explicit Nudity',
        data: {
          photoId: 'photo-1',
          reason: 'Image contains inappropriate content: Explicit Nudity',
        },
      });
    });
  });

  describe('getPhotoModerationStatus', () => {
    it('should throw NotFoundException if photo does not exist', async () => {
      jest.spyOn(photoRepository, 'findOne').mockResolvedValue(null);

      await expect(
        service.getPhotoModerationStatus('non-existent-id'),
      ).rejects.toThrow(NotFoundException);
    });

    it('should return photo moderation status', async () => {
      const mockPhoto = {
        id: 'photo-1',
        isApproved: true,
        rejectionReason: null,
      } as Photo;

      jest.spyOn(photoRepository, 'findOne').mockResolvedValue(mockPhoto);

      const result = await service.getPhotoModerationStatus('photo-1');

      expect(result.photoId).toBe('photo-1');
      expect(result.isApproved).toBe(true);
      expect(result.rejectionReason).toBeUndefined();
    });

    it('should return rejection reason if photo was rejected', async () => {
      const mockPhoto = {
        id: 'photo-1',
        isApproved: false,
        rejectionReason: 'Inappropriate content',
      } as Photo;

      jest.spyOn(photoRepository, 'findOne').mockResolvedValue(mockPhoto);

      const result = await service.getPhotoModerationStatus('photo-1');

      expect(result.photoId).toBe('photo-1');
      expect(result.isApproved).toBe(false);
      expect(result.rejectionReason).toBe('Inappropriate content');
    });
  });

  describe('moderateTextContent', () => {
    it('should approve text if not flagged', async () => {
      const mockModerationResult = {
        flagged: false,
        shouldBlock: false,
        categories: {},
        categoryScores: {},
      };

      jest
        .spyOn(aiModerationService, 'moderateText')
        .mockResolvedValue(mockModerationResult as any);

      const result = await service.moderateTextContent(
        'This is safe text',
        'user-1',
      );

      expect(result.approved).toBe(true);
      expect(result.reason).toBeUndefined();
      expect(logger.logSecurityEvent).not.toHaveBeenCalled();
    });

    it('should block text if flagged and send notification', async () => {
      const mockModerationResult = {
        flagged: true,
        shouldBlock: true,
        categories: { hate: true },
        categoryScores: { hate: 0.9 },
        reason: 'Content contains inappropriate hate speech',
      };

      const mockUser = {
        id: 'user-1',
        email: 'user@example.com',
      } as User;

      jest
        .spyOn(aiModerationService, 'moderateText')
        .mockResolvedValue(mockModerationResult as any);
      jest.spyOn(userRepository, 'findOne').mockResolvedValue(mockUser);
      jest
        .spyOn(notificationsService, 'createNotification')
        .mockResolvedValue({} as any);

      const result = await service.moderateTextContent(
        'Inappropriate text',
        'user-1',
      );

      expect(result.approved).toBe(false);
      expect(result.reason).toBe('Content contains inappropriate hate speech');
      expect(logger.logSecurityEvent).toHaveBeenCalledWith(
        'text_content_blocked',
        {
          userId: 'user-1',
          flagged: true,
          categories: { hate: true },
        },
      );
      expect(notificationsService.createNotification).toHaveBeenCalled();
    });
  });

  describe('moderateTextContentBatch', () => {
    it('should moderate multiple texts', async () => {
      const mockResults = [
        {
          flagged: false,
          shouldBlock: false,
          categories: {},
          categoryScores: {},
        },
        {
          flagged: true,
          shouldBlock: true,
          categories: {},
          categoryScores: {},
          reason: 'Inappropriate content',
        },
      ];

      jest
        .spyOn(aiModerationService, 'moderateTextBatch')
        .mockResolvedValue(mockResults as any);

      const result = await service.moderateTextContentBatch([
        'Safe text',
        'Unsafe text',
      ]);

      expect(result).toHaveLength(2);
      expect(result[0].approved).toBe(true);
      expect(result[1].approved).toBe(false);
      expect(result[1].reason).toBe('Inappropriate content');
    });
  });
});
