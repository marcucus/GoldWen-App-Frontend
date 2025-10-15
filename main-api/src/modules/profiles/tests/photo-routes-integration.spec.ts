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

/**
 * Integration tests for the three photo management routes requested in the issue:
 * 1. PUT /profiles/me/photos/:photoId/order
 * 2. PUT /profiles/me/photos/:photoId/primary
 * 3. GET /profiles/completion
 *
 * These tests verify the implementation matches specifications.md and TACHES_FRONTEND.md
 */
describe('ProfilesService - Photo Management Routes Integration', () => {
  let service: ProfilesService;
  let profileRepository: Repository<Profile>;
  let photoRepository: Repository<Photo>;
  let userRepository: Repository<User>;
  let promptRepository: Repository<Prompt>;
  let personalityQuestionRepository: Repository<PersonalityQuestion>;

  const mockModerationService = {
    moderateTextContent: jest.fn().mockResolvedValue({ approved: true }),
    moderatePhoto: jest.fn().mockResolvedValue({ approved: true }),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ProfilesService,
        {
          provide: getRepositoryToken(Profile),
          useValue: {
            findOne: jest.fn(),
            save: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(User),
          useValue: {
            findOne: jest.fn(),
            save: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(PersonalityQuestion),
          useValue: {
            count: jest.fn(),
            find: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(PersonalityAnswer),
          useValue: {},
        },
        {
          provide: getRepositoryToken(Photo),
          useValue: {
            findOne: jest.fn(),
            save: jest.fn(),
            update: jest.fn(),
            createQueryBuilder: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(Prompt),
          useValue: {
            find: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(PromptAnswer),
          useValue: {},
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
    promptRepository = module.get<Repository<Prompt>>(
      getRepositoryToken(Prompt),
    );
    personalityQuestionRepository = module.get<Repository<PersonalityQuestion>>(
      getRepositoryToken(PersonalityQuestion),
    );
  });

  describe('PUT /profiles/me/photos/:photoId/order - Update Photo Order', () => {
    it('should successfully reorder photos with drag & drop', async () => {
      const mockPhotos = [
        { id: 'photo-1', order: 1, profileId: 'profile-1' },
        { id: 'photo-2', order: 2, profileId: 'profile-1' },
        { id: 'photo-3', order: 3, profileId: 'profile-1' },
      ];

      const mockProfile = {
        id: 'profile-1',
        userId: 'user-1',
        photos: mockPhotos,
      };

      jest
        .spyOn(profileRepository, 'findOne')
        .mockResolvedValue(mockProfile as any);

      const queryBuilder = {
        update: jest.fn().mockReturnThis(),
        set: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        execute: jest.fn().mockResolvedValue({}),
      };

      jest
        .spyOn(photoRepository, 'createQueryBuilder')
        .mockReturnValue(queryBuilder as any);

      const updatedPhoto = { ...mockPhotos[2], order: 1 };
      jest
        .spyOn(photoRepository, 'save')
        .mockResolvedValue(updatedPhoto as any);

      const result = await service.updatePhotoOrder('user-1', 'photo-3', 1);

      expect(result).toBeDefined();
      expect(result.id).toBe('photo-3');
      expect(result.order).toBe(1);
      expect(photoRepository.save).toHaveBeenCalled();
    });

    it('should validate newOrder is within valid range', async () => {
      const mockPhotos = [
        { id: 'photo-1', order: 1 },
        { id: 'photo-2', order: 2 },
      ];

      const mockProfile = {
        id: 'profile-1',
        userId: 'user-1',
        photos: mockPhotos,
      };

      jest
        .spyOn(profileRepository, 'findOne')
        .mockResolvedValue(mockProfile as any);

      // Try to set order to 5 when only 2 photos exist
      await expect(
        service.updatePhotoOrder('user-1', 'photo-1', 5),
      ).rejects.toThrow(BadRequestException);
    });

    it('should handle photo not found error', async () => {
      const mockProfile = {
        id: 'profile-1',
        userId: 'user-1',
        photos: [{ id: 'photo-1', order: 1 }],
      };

      jest
        .spyOn(profileRepository, 'findOne')
        .mockResolvedValue(mockProfile as any);

      await expect(
        service.updatePhotoOrder('user-1', 'nonexistent-photo', 1),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('PUT /profiles/me/photos/:photoId/primary - Set Primary Photo', () => {
    it('should set a photo as primary and unset others', async () => {
      const mockPhotos = [
        { id: 'photo-1', isPrimary: true, profileId: 'profile-1' },
        { id: 'photo-2', isPrimary: false, profileId: 'profile-1' },
        { id: 'photo-3', isPrimary: false, profileId: 'profile-1' },
      ];

      const mockProfile = {
        id: 'profile-1',
        userId: 'user-1',
        photos: mockPhotos,
      };

      jest
        .spyOn(profileRepository, 'findOne')
        .mockResolvedValue(mockProfile as any);

      jest.spyOn(photoRepository, 'update').mockResolvedValue({} as any);

      const updatedPhoto = { ...mockPhotos[1], isPrimary: true };
      jest
        .spyOn(photoRepository, 'save')
        .mockResolvedValue(updatedPhoto as any);

      const result = await service.setPrimaryPhoto('user-1', 'photo-2');

      expect(result).toBeDefined();
      expect(result.id).toBe('photo-2');
      expect(result.isPrimary).toBe(true);
      expect(photoRepository.update).toHaveBeenCalledWith(
        { profileId: 'profile-1' },
        { isPrimary: false },
      );
    });

    it('should handle photo not found error', async () => {
      const mockProfile = {
        id: 'profile-1',
        userId: 'user-1',
        photos: [{ id: 'photo-1', isPrimary: true }],
      };

      jest
        .spyOn(profileRepository, 'findOne')
        .mockResolvedValue(mockProfile as any);

      await expect(
        service.setPrimaryPhoto('user-1', 'nonexistent-photo'),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('GET /profiles/completion - Profile Completion Status', () => {
    it('should return correct completion status with minimum 3 photos requirement', async () => {
      const requiredPrompts = [
        { id: 'prompt-1', text: 'About you', isActive: true, isRequired: true },
        { id: 'prompt-2', text: 'Hobbies', isActive: true, isRequired: true },
        { id: 'prompt-3', text: 'Goals', isActive: true, isRequired: true },
      ];

      const mockUser = {
        id: 'user-1',
        profile: {
          id: 'profile-1',
          userId: 'user-1',
          photos: [{ id: '1' }, { id: '2' }, { id: '3' }], // Exactly 3 photos
          promptAnswers: [
            { promptId: 'prompt-1' },
            { promptId: 'prompt-2' },
            { promptId: 'prompt-3' },
          ],
          birthDate: '1990-01-01',
          bio: 'Test bio',
        },
        personalityAnswers: [
          { id: 'answer-1' },
          { id: 'answer-2' },
          { id: 'answer-3' },
          { id: 'answer-4' },
          { id: 'answer-5' },
        ],
      };

      jest.spyOn(userRepository, 'findOne').mockResolvedValue(mockUser as any);
      jest
        .spyOn(promptRepository, 'find')
        .mockResolvedValue(requiredPrompts as any);
      jest.spyOn(personalityQuestionRepository, 'count').mockResolvedValue(5);

      const result = await service.getProfileCompletion('user-1');

      // Verify response structure matches frontend expectations from TACHES_FRONTEND.md
      expect(result).toHaveProperty('isComplete');
      expect(result).toHaveProperty('completionPercentage');
      expect(result).toHaveProperty('requirements');
      expect(result).toHaveProperty('missingSteps');
      expect(result).toHaveProperty('nextStep');

      // Verify minimumPhotos structure
      expect(result.requirements.minimumPhotos).toEqual({
        required: 3,
        current: 3,
        satisfied: true,
      });

      // Verify minimumPrompts structure (not "promptAnswers")
      expect(result.requirements).toHaveProperty('minimumPrompts');
      expect(result.requirements.minimumPrompts).toEqual({
        required: 3,
        current: 3,
        satisfied: true,
        missing: [],
      });

      // Verify personalityQuestionnaire is an object (not boolean)
      expect(result.requirements.personalityQuestionnaire).toEqual({
        required: true,
        completed: true,
        satisfied: true,
      });

      expect(result.isComplete).toBe(true);
      expect(result.completionPercentage).toBe(100);
    });

    it('should enforce minimum 3 photos requirement', async () => {
      const mockUser = {
        id: 'user-1',
        profile: {
          id: 'profile-1',
          userId: 'user-1',
          photos: [{ id: '1' }, { id: '2' }], // Only 2 photos
          promptAnswers: [
            { promptId: 'prompt-1' },
            { promptId: 'prompt-2' },
            { promptId: 'prompt-3' },
          ],
          birthDate: '1990-01-01',
          bio: 'Test bio',
        },
        personalityAnswers: Array(5).fill({ id: 'answer' }),
      };

      jest.spyOn(userRepository, 'findOne').mockResolvedValue(mockUser as any);
      jest.spyOn(promptRepository, 'find').mockResolvedValue([
        { id: 'prompt-1', isActive: true, isRequired: true },
        { id: 'prompt-2', isActive: true, isRequired: true },
        { id: 'prompt-3', isActive: true, isRequired: true },
      ] as any);
      jest.spyOn(personalityQuestionRepository, 'count').mockResolvedValue(5);

      const result = await service.getProfileCompletion('user-1');

      expect(result.requirements.minimumPhotos).toEqual({
        required: 3,
        current: 2,
        satisfied: false,
      });
      expect(result.isComplete).toBe(false);
      expect(result.missingSteps).toContain('Upload at least 3 photos');
    });

    it('should provide correct nextStep guidance', async () => {
      const mockUser = {
        id: 'user-1',
        profile: {
          id: 'profile-1',
          userId: 'user-1',
          photos: [], // No photos
          promptAnswers: [],
          birthDate: null,
          bio: null,
        },
        personalityAnswers: [],
      };

      jest.spyOn(userRepository, 'findOne').mockResolvedValue(mockUser as any);
      jest.spyOn(promptRepository, 'find').mockResolvedValue([]);
      jest.spyOn(personalityQuestionRepository, 'count').mockResolvedValue(5);

      const result = await service.getProfileCompletion('user-1');

      expect(result.nextStep).toBeTruthy();
      expect(typeof result.nextStep).toBe('string');
      // Priority order: basicInfo > personality > photos > prompts
      expect(result.nextStep).toContain('birth date');
    });

    it('should include missing prompts details', async () => {
      const requiredPrompts = [
        { id: 'prompt-1', text: 'About you', isActive: true, isRequired: true },
        {
          id: 'prompt-2',
          text: 'Your hobbies',
          isActive: true,
          isRequired: true,
        },
      ];

      const mockUser = {
        id: 'user-1',
        profile: {
          id: 'profile-1',
          userId: 'user-1',
          photos: [{ id: '1' }, { id: '2' }, { id: '3' }],
          promptAnswers: [], // No prompt answers
          birthDate: '1990-01-01',
          bio: 'Test bio',
        },
        personalityAnswers: Array(5).fill({ id: 'answer' }),
      };

      jest.spyOn(userRepository, 'findOne').mockResolvedValue(mockUser as any);
      jest
        .spyOn(promptRepository, 'find')
        .mockResolvedValue(requiredPrompts as any);
      jest.spyOn(personalityQuestionRepository, 'count').mockResolvedValue(5);

      const result = await service.getProfileCompletion('user-1');

      expect(result.requirements.minimumPrompts.satisfied).toBe(false);
      expect(result.requirements.minimumPrompts.missing).toHaveLength(2);
      expect(result.requirements.minimumPrompts.missing).toEqual([
        { id: 'prompt-1', text: 'About you' },
        { id: 'prompt-2', text: 'Your hobbies' },
      ]);
    });
  });
});
