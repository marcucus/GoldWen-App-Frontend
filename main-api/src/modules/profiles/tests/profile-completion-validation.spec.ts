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
      const requiredPrompts = [
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
        .mockResolvedValue(requiredPrompts as any);
      jest.spyOn(personalityQuestionRepository, 'count').mockResolvedValue(10);

      const result = await service.getProfileCompletion('user-id');

      expect(result.nextStep).toBe('Answer 2 required prompts');
    });

    it('should return completion message when profile is complete', async () => {
      const requiredPrompts = [
        {
          id: 'prompt-1',
          text: 'What makes you happy?',
          isActive: true,
          isRequired: true,
        },
      ];

      const completeUser = {
        ...mockUser,
        profile: {
          ...mockProfile,
          photos: [{ id: '1' }, { id: '2' }, { id: '3' }], // Has photos
          promptAnswers: [{ promptId: 'prompt-1' }], // Has prompt answers
        },
        personalityAnswers: Array(10).fill({ id: 'answer' }), // Complete personality
      };

      jest
        .spyOn(userRepository, 'findOne')
        .mockResolvedValue(completeUser as any);
      jest
        .spyOn(promptRepository, 'find')
        .mockResolvedValue(requiredPrompts as any);
      jest.spyOn(personalityQuestionRepository, 'count').mockResolvedValue(10);

      const result = await service.getProfileCompletion('user-id');

      expect(result.nextStep).toBe('Profile is complete!');
      expect(result.isComplete).toBe(true);
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
});
