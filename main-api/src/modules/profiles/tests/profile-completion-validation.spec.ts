import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { NotFoundException } from '@nestjs/common';

import { ProfilesService } from '../profiles.service';
import { Profile } from '../../../database/entities/profile.entity';
import { User } from '../../../database/entities/user.entity';
import { PersonalityQuestion } from '../../../database/entities/personality-question.entity';
import { PersonalityAnswer } from '../../../database/entities/personality-answer.entity';
import { Photo } from '../../../database/entities/photo.entity';
import { Prompt } from '../../../database/entities/prompt.entity';
import { PromptAnswer } from '../../../database/entities/prompt-answer.entity';
import { ModerationService } from '../../moderation/services/moderation.service';

describe('ProfilesService - Profile Completion Validation', () => {
  let service: ProfilesService;
  let userRepository: Repository<User>;
  let promptRepository: Repository<Prompt>;
  let personalityQuestionRepository: Repository<PersonalityQuestion>;

  const mockProfile = {
    id: 'profile-id',
    userId: 'user-id',
    bio: 'Test bio',
    birthDate: '1990-01-01',
  };

  const mockUser = {
    id: 'user-id',
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
          useValue: { findOne: jest.fn() },
        },
        {
          provide: getRepositoryToken(User),
          useValue: { findOne: jest.fn() },
        },
        {
          provide: getRepositoryToken(PersonalityQuestion),
          useValue: { count: jest.fn() },
        },
        {
          provide: getRepositoryToken(PersonalityAnswer),
          useValue: {},
        },
        {
          provide: getRepositoryToken(Photo),
          useValue: {},
        },
        {
          provide: getRepositoryToken(Prompt),
          useValue: { find: jest.fn() },
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
    userRepository = module.get<Repository<User>>(getRepositoryToken(User));
    promptRepository = module.get<Repository<Prompt>>(
      getRepositoryToken(Prompt),
    );
    personalityQuestionRepository = module.get<Repository<PersonalityQuestion>>(
      getRepositoryToken(PersonalityQuestion),
    );
  });

  describe('getProfileCompletion', () => {
    it('should include nextStep field in response', async () => {
      const userWithIncompleteProfile = {
        ...mockUser,
        profile: {
          ...mockProfile,
          photos: [], // No photos
          promptAnswers: [], // No prompt answers
        },
        personalityAnswers: [], // No personality answers
      };

      jest
        .spyOn(userRepository, 'findOne')
        .mockResolvedValue(userWithIncompleteProfile as any);
      jest.spyOn(promptRepository, 'find').mockResolvedValue([]);
      jest.spyOn(personalityQuestionRepository, 'count').mockResolvedValue(10);

      const result = await service.getProfileCompletion('user-id');

      expect(result).toHaveProperty('nextStep');
      expect(typeof result.nextStep).toBe('string');
      expect(result.nextStep).toBeTruthy();
    });

    it('should return correct nextStep for missing basic info', async () => {
      const userWithoutBasicInfo = {
        ...mockUser,
        profile: {
          ...mockProfile,
          bio: null, // Missing bio
          birthDate: null, // Missing birthDate
          photos: [{ id: '1' }, { id: '2' }, { id: '3' }], // Has photos
          promptAnswers: [], // No prompt answers
        },
        personalityAnswers: [{ id: '1' }, { id: '2' }], // Has some answers
      };

      jest
        .spyOn(userRepository, 'findOne')
        .mockResolvedValue(userWithoutBasicInfo as any);
      jest.spyOn(promptRepository, 'find').mockResolvedValue([]);
      jest.spyOn(personalityQuestionRepository, 'count').mockResolvedValue(2);

      const result = await service.getProfileCompletion('user-id');

      expect(result.nextStep).toContain('birth date');
      expect(result.nextStep).toContain('bio');
    });

    it('should return correct nextStep for missing personality questionnaire', async () => {
      const userWithoutPersonality = {
        ...mockUser,
        profile: {
          ...mockProfile,
          photos: [{ id: '1' }, { id: '2' }, { id: '3' }], // Has photos
          promptAnswers: [], // No prompt answers
        },
        personalityAnswers: [], // No personality answers
      };

      jest
        .spyOn(userRepository, 'findOne')
        .mockResolvedValue(userWithoutPersonality as any);
      jest.spyOn(promptRepository, 'find').mockResolvedValue([]);
      jest.spyOn(personalityQuestionRepository, 'count').mockResolvedValue(10);

      const result = await service.getProfileCompletion('user-id');

      expect(result.nextStep).toBe('Complete personality questionnaire');
    });

    it('should return correct nextStep for missing photos', async () => {
      const userWithoutPhotos = {
        ...mockUser,
        profile: {
          ...mockProfile,
          photos: [{ id: '1' }], // Only 1 photo (need 3)
          promptAnswers: [],
        },
        personalityAnswers: Array(10).fill({ id: 'answer' }), // Complete personality
      };

      jest
        .spyOn(userRepository, 'findOne')
        .mockResolvedValue(userWithoutPhotos as any);
      jest.spyOn(promptRepository, 'find').mockResolvedValue([]);
      jest.spyOn(personalityQuestionRepository, 'count').mockResolvedValue(10);

      const result = await service.getProfileCompletion('user-id');

      expect(result.nextStep).toBe('Upload at least 3 photos');
    });

    it('should return correct nextStep for missing prompts', async () => {
      const availablePrompts = [
        {
          id: 'prompt-1',
          text: 'What makes you happy?',
          isActive: true,
          isRequired: true,
        },
        {
          id: 'prompt-2',
          text: 'Describe yourself',
          isActive: true,
          isRequired: true,
        },
        {
          id: 'prompt-3',
          text: 'Your passion',
          isActive: true,
          isRequired: true,
        },
      ];

      const userWithoutPrompts = {
        ...mockUser,
        profile: {
          ...mockProfile,
          photos: [{ id: '1' }, { id: '2' }, { id: '3' }], // Has photos
          promptAnswers: [], // No prompt answers
        },
        personalityAnswers: Array(10).fill({ id: 'answer' }), // Complete personality
      };

      jest
        .spyOn(userRepository, 'findOne')
        .mockResolvedValue(userWithoutPrompts as any);
      jest
        .spyOn(promptRepository, 'find')
        .mockResolvedValue(availablePrompts as any);
      jest.spyOn(personalityQuestionRepository, 'count').mockResolvedValue(10);

      const result = await service.getProfileCompletion('user-id');

      expect(result.nextStep).toBe('Answer 3 more prompts');
    });

    it('should return completion message when profile is complete', async () => {
      const availablePrompts = [
        {
          id: 'prompt-1',
          text: 'What makes you happy?',
          isActive: true,
          isRequired: true,
        },
        {
          id: 'prompt-2',
          text: 'Describe yourself',
          isActive: true,
          isRequired: true,
        },
        {
          id: 'prompt-3',
          text: 'Your passion',
          isActive: true,
          isRequired: true,
        },
      ];

      const completeUser = {
        ...mockUser,
        profile: {
          ...mockProfile,
          photos: [{ id: '1' }, { id: '2' }, { id: '3' }], // Has photos
          promptAnswers: [
            { promptId: 'prompt-1' },
            { promptId: 'prompt-2' },
            { promptId: 'prompt-3' },
          ], // Has 3 prompt answers
        },
        personalityAnswers: Array(10).fill({ id: 'answer' }), // Complete personality
      };

      jest
        .spyOn(userRepository, 'findOne')
        .mockResolvedValue(completeUser as any);
      jest
        .spyOn(promptRepository, 'find')
        .mockResolvedValue(availablePrompts as any);
      jest.spyOn(personalityQuestionRepository, 'count').mockResolvedValue(10);

      const result = await service.getProfileCompletion('user-id');

      expect(result.nextStep).toBe('Profile is complete!');
      expect(result.isComplete).toBe(true);
    });

    it('should return requirements with correct structure for frontend', async () => {
      const availablePrompts = [
        {
          id: 'prompt-1',
          text: 'What makes you happy?',
          isActive: true,
          isRequired: true,
        },
        {
          id: 'prompt-2',
          text: 'Describe yourself',
          isActive: true,
          isRequired: true,
        },
        {
          id: 'prompt-3',
          text: 'Your passion',
          isActive: true,
          isRequired: true,
        },
      ];

      const userWithPartialCompletion = {
        ...mockUser,
        profile: {
          ...mockProfile,
          photos: [{ id: '1' }, { id: '2' }], // Only 2 photos (need 3)
          promptAnswers: [], // No prompt answers
        },
        personalityAnswers: Array(10).fill({ id: 'answer' }), // Complete personality
      };

      jest
        .spyOn(userRepository, 'findOne')
        .mockResolvedValue(userWithPartialCompletion as any);
      jest
        .spyOn(promptRepository, 'find')
        .mockResolvedValue(availablePrompts as any);
      jest.spyOn(personalityQuestionRepository, 'count').mockResolvedValue(10);

      const result = await service.getProfileCompletion('user-id');

      // Check minimumPhotos structure
      expect(result.requirements.minimumPhotos).toEqual({
        required: 3,
        current: 2,
        satisfied: false,
      });

      // Check minimumPrompts structure (should use this name, not promptAnswers)
      expect(result.requirements.minimumPrompts).toBeDefined();
      expect(result.requirements.minimumPrompts).toEqual({
        required: 3,
        current: 0,
        satisfied: false,
        missing: [
          { id: 'prompt-1', text: 'What makes you happy?' },
          { id: 'prompt-2', text: 'Describe yourself' },
          { id: 'prompt-3', text: 'Your passion' },
        ],
      });

      // Check personalityQuestionnaire structure (should be an object, not boolean)
      expect(result.requirements.personalityQuestionnaire).toEqual({
        required: true,
        completed: true,
        satisfied: true,
      });

      // Check basicInfo is present
      expect(result.requirements.basicInfo).toBe(true);
    });

    it('should throw NotFoundException when profile not found', async () => {
      jest.spyOn(userRepository, 'findOne').mockResolvedValue(null);

      await expect(
        service.getProfileCompletion('nonexistent-user'),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('isProfileVisible', () => {
    it('should return true for completed profile', async () => {
      jest.spyOn(userRepository, 'findOne').mockResolvedValue({
        isProfileCompleted: true,
      } as any);

      const result = await service.isProfileVisible('user-id');
      expect(result).toBe(true);
    });

    it('should return false for incomplete profile', async () => {
      jest.spyOn(userRepository, 'findOne').mockResolvedValue({
        isProfileCompleted: false,
      } as any);

      const result = await service.isProfileVisible('user-id');
      expect(result).toBe(false);
    });

    it('should return false when user not found', async () => {
      jest.spyOn(userRepository, 'findOne').mockResolvedValue(null);

      const result = await service.isProfileVisible('nonexistent-user');
      expect(result).toBe(false);
    });
  });

  describe('getProfileCompletion with more than 3 prompts', () => {
    it('should mark profile as incomplete when user has more than 3 prompt answers', async () => {
      const availablePrompts = [
        {
          id: 'prompt-1',
          text: 'What makes you happy?',
          isActive: true,
          isRequired: true,
        },
        {
          id: 'prompt-2',
          text: 'Describe yourself',
          isActive: true,
          isRequired: true,
        },
        {
          id: 'prompt-3',
          text: 'Your passion',
          isActive: true,
          isRequired: true,
        },
      ];

      const userWithTooManyPrompts = {
        ...mockUser,
        profile: {
          ...mockProfile,
          photos: [{ id: '1' }, { id: '2' }, { id: '3' }], // Has photos
          promptAnswers: [
            { promptId: 'prompt-1' },
            { promptId: 'prompt-2' },
            { promptId: 'prompt-3' },
            { promptId: 'prompt-4' }, // Too many prompts (4 instead of 3)
          ],
        },
        personalityAnswers: Array(10).fill({ id: 'answer' }), // Complete personality
      };

      jest
        .spyOn(userRepository, 'findOne')
        .mockResolvedValue(userWithTooManyPrompts as any);
      jest
        .spyOn(promptRepository, 'find')
        .mockResolvedValue(availablePrompts as any);
      jest.spyOn(personalityQuestionRepository, 'count').mockResolvedValue(10);

      const result = await service.getProfileCompletion('user-id');

      expect(result.isComplete).toBe(false);
      expect(result.requirements.minimumPrompts.satisfied).toBe(false);
      expect(result.requirements.minimumPrompts.current).toBe(4);
      expect(result.missingSteps).toContain(
        'You have too many prompts (4/3). Please remove 1 prompt',
      );
    });
  });
});
