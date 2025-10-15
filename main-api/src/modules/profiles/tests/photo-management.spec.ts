import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException, NotFoundException } from '@nestjs/common';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { ProfilesService } from '../profiles.service';
import { Profile } from '../../../database/entities/profile.entity';
import { User } from '../../../database/entities/user.entity';
import { Photo } from '../../../database/entities/photo.entity';
import { PersonalityQuestion } from '../../../database/entities/personality-question.entity';
import { PersonalityAnswer } from '../../../database/entities/personality-answer.entity';
import { Prompt } from '../../../database/entities/prompt.entity';
import { PromptAnswer } from '../../../database/entities/prompt-answer.entity';
import { ModerationService } from '../../moderation/services/moderation.service';

describe('ProfilesService - Photo Management', () => {
  let service: ProfilesService;
  let profileRepository: Repository<Profile>;
  let photoRepository: Repository<Photo>;
  let userRepository: Repository<User>;
  let personalityQuestionRepository: Repository<PersonalityQuestion>;
  let promptRepository: Repository<Prompt>;

  const mockProfile = {
    id: 'profile-1',
    userId: 'user-1',
    photos: [],
  };

  const mockUser = {
    id: 'user-1',
    profile: mockProfile,
    personalityAnswers: [],
  };

  const mockModerationService = {
    moderateTextContent: jest.fn(),
    moderatePhoto: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ProfilesService,
        {
          provide: getRepositoryToken(Profile),
          useClass: Repository,
        },
        {
          provide: getRepositoryToken(User),
          useClass: Repository,
        },
        {
          provide: getRepositoryToken(PersonalityQuestion),
          useClass: Repository,
        },
        {
          provide: getRepositoryToken(PersonalityAnswer),
          useClass: Repository,
        },
        {
          provide: getRepositoryToken(Photo),
          useClass: Repository,
        },
        {
          provide: getRepositoryToken(Prompt),
          useClass: Repository,
        },
        {
          provide: getRepositoryToken(PromptAnswer),
          useClass: Repository,
        },
        {
          provide: ModerationService,
          useValue: mockModerationService,
        },
      ],
    }).compile();

    service = module.get<ProfilesService>(ProfilesService);
    profileRepository = module.get<Repository<Profile>>(
      getRepositoryToken(Profile),
    );
    photoRepository = module.get<Repository<Photo>>(getRepositoryToken(Photo));
    userRepository = module.get<Repository<User>>(getRepositoryToken(User));
    personalityQuestionRepository = module.get<Repository<PersonalityQuestion>>(
      getRepositoryToken(PersonalityQuestion),
    );
    promptRepository = module.get<Repository<Prompt>>(
      getRepositoryToken(Prompt),
    );
  });

  describe('updatePhotoOrder', () => {
    it('should update photo order successfully', async () => {
      const mockPhoto = {
        id: 'photo-1',
        order: 2,
        profileId: 'profile-1',
      };

      const mockPhotos = [
        { id: 'photo-1', order: 1 },
        { id: 'photo-2', order: 2 },
        { id: 'photo-3', order: 3 },
      ];

      const profileWithPhotos = {
        ...mockProfile,
        photos: mockPhotos,
      };

      jest
        .spyOn(profileRepository, 'findOne')
        .mockResolvedValue(profileWithPhotos as any);
      jest.spyOn(photoRepository, 'createQueryBuilder').mockReturnValue({
        update: jest.fn().mockReturnThis(),
        set: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        execute: jest.fn().mockResolvedValue({}),
      } as any);
      jest.spyOn(photoRepository, 'save').mockResolvedValue(mockPhoto as any);

      const result = await service.updatePhotoOrder('user-1', 'photo-2', 1);

      expect(result).toBeDefined();
      expect(photoRepository.save).toHaveBeenCalled();
    });

    it('should throw NotFoundException when profile not found', async () => {
      jest.spyOn(profileRepository, 'findOne').mockResolvedValue(null);

      await expect(
        service.updatePhotoOrder('user-1', 'photo-1', 1),
      ).rejects.toThrow(NotFoundException);
    });

    it('should throw NotFoundException when photo not found', async () => {
      jest.spyOn(profileRepository, 'findOne').mockResolvedValue({
        ...mockProfile,
        photos: [],
      } as any);

      await expect(
        service.updatePhotoOrder('user-1', 'photo-1', 1),
      ).rejects.toThrow(NotFoundException);
    });

    it('should throw BadRequestException when new order is invalid', async () => {
      const profileWithPhotos = {
        ...mockProfile,
        photos: [{ id: 'photo-1', order: 1 }],
      };

      jest
        .spyOn(profileRepository, 'findOne')
        .mockResolvedValue(profileWithPhotos as any);

      await expect(
        service.updatePhotoOrder('user-1', 'photo-1', 5),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe('getProfileCompletion', () => {
    it('should return correct completion status', async () => {
      const userWithData = {
        ...mockUser,
        profile: {
          ...mockProfile,
          photos: [{ id: 'photo-1' }, { id: 'photo-2' }, { id: 'photo-3' }],
          promptAnswers: [
            { id: 'prompt-answer-1', promptId: 'prompt-1' },
            { id: 'prompt-answer-2', promptId: 'prompt-2' },
            { id: 'prompt-answer-3', promptId: 'prompt-3' },
          ],
          birthDate: new Date(),
          bio: 'Test bio',
        },
        personalityAnswers: [{ id: 'answer-1' }, { id: 'answer-2' }],
      };

      jest
        .spyOn(userRepository, 'findOne')
        .mockResolvedValue(userWithData as any);
      jest.spyOn(personalityQuestionRepository, 'count').mockResolvedValue(2);
      jest.spyOn(promptRepository, 'find').mockResolvedValue([
        { id: 'prompt-1', isActive: true, isRequired: true },
        { id: 'prompt-2', isActive: true, isRequired: true },
        { id: 'prompt-3', isActive: true, isRequired: true },
      ] as any);

      const result = await service.getProfileCompletion('user-1');

      expect(result.isComplete).toBe(true);
      expect(result.completionPercentage).toBe(100);
      expect(result.requirements.minimumPhotos.satisfied).toBe(true);
      expect(result.requirements.minimumPrompts.satisfied).toBe(true);
      expect(result.requirements.personalityQuestionnaire).toEqual({
        required: true,
        completed: true,
        satisfied: true,
      });
      expect(result.requirements.basicInfo).toBe(true);
    });

    it('should return incomplete status when missing photos', async () => {
      const userWithIncompleteData = {
        ...mockUser,
        profile: {
          ...mockProfile,
          photos: [{ id: 'photo-1' }], // Only 1 photo, need 3
          promptAnswers: [
            { id: 'prompt-answer-1', promptId: 'prompt-1' },
            { id: 'prompt-answer-2', promptId: 'prompt-2' },
            { id: 'prompt-answer-3', promptId: 'prompt-3' },
          ],
          birthDate: new Date(),
          bio: 'Test bio',
        },
        personalityAnswers: [{ id: 'answer-1' }, { id: 'answer-2' }],
      };

      jest
        .spyOn(userRepository, 'findOne')
        .mockResolvedValue(userWithIncompleteData as any);
      jest.spyOn(personalityQuestionRepository, 'count').mockResolvedValue(2);
      jest.spyOn(promptRepository, 'find').mockResolvedValue([
        { id: 'prompt-1', isActive: true, isRequired: true },
        { id: 'prompt-2', isActive: true, isRequired: true },
        { id: 'prompt-3', isActive: true, isRequired: true },
      ] as any);

      const result = await service.getProfileCompletion('user-1');

      expect(result.isComplete).toBe(false);
      expect(result.completionPercentage).toBe(75); // 3 out of 4 requirements met
      expect(result.requirements.minimumPhotos.satisfied).toBe(false);
      expect(result.requirements.minimumPhotos.current).toBe(1);
      expect(result.requirements.minimumPhotos.required).toBe(3);
      expect(result.missingSteps).toContain('Upload at least 3 photos');
    });
  });

  describe('uploadPhotos', () => {
    it('should validate maximum photo limit', async () => {
      const profileWith6Photos = {
        ...mockProfile,
        photos: Array.from({ length: 6 }, (_, i) => ({ id: `photo-${i + 1}` })),
      };

      jest
        .spyOn(profileRepository, 'findOne')
        .mockResolvedValue(profileWith6Photos as any);

      const mockFiles = [
        {
          filename: 'test.jpg',
          mimetype: 'image/jpeg',
          size: 1000,
          path: '/tmp/test.jpg',
        },
      ] as Express.Multer.File[];

      await expect(service.uploadPhotos('user-1', mockFiles)).rejects.toThrow(
        BadRequestException,
      );
    });

    it('should validate minimum file requirement', async () => {
      jest
        .spyOn(profileRepository, 'findOne')
        .mockResolvedValue(mockProfile as any);

      const mockFiles: Express.Multer.File[] = [];

      await expect(service.uploadPhotos('user-1', mockFiles)).rejects.toThrow(
        BadRequestException,
      );
    });
  });
});
