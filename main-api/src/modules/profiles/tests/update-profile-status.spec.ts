import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException, NotFoundException } from '@nestjs/common';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { ProfilesService } from '../profiles.service';
import { Profile } from '../../../database/entities/profile.entity';
import { User } from '../../../database/entities/user.entity';
import { PersonalityQuestion } from '../../../database/entities/personality-question.entity';
import { PersonalityAnswer } from '../../../database/entities/personality-answer.entity';
import { Photo } from '../../../database/entities/photo.entity';
import { Prompt } from '../../../database/entities/prompt.entity';
import { PromptAnswer } from '../../../database/entities/prompt-answer.entity';
import { UpdateProfileStatusDto } from '../dto/profiles.dto';
import { ModerationService } from '../../moderation/services/moderation.service';

/**
 * Tests for strict profile validation when updating visibility status
 * Validates the requirements from specifications.md:
 * - 3 photos minimum
 * - All required prompts answered
 * - Personality questionnaire completed
 * - Basic info (birthDate, bio) provided
 */
describe('ProfilesService - updateProfileStatus Strict Validation', () => {
  let service: ProfilesService;
  let userRepository: Repository<User>;
  let profileRepository: Repository<Profile>;
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
          useValue: {},
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
    userRepository = module.get<Repository<User>>(getRepositoryToken(User));
    profileRepository = module.get<Repository<Profile>>(
      getRepositoryToken(Profile),
    );
    promptRepository = module.get<Repository<Prompt>>(
      getRepositoryToken(Prompt),
    );
    personalityQuestionRepository = module.get<Repository<PersonalityQuestion>>(
      getRepositoryToken(PersonalityQuestion),
    );
  });

  describe('Setting profile visibility', () => {
    it('should throw NotFoundException when user not found', async () => {
      jest.spyOn(userRepository, 'findOne').mockResolvedValue(null);

      const statusDto: UpdateProfileStatusDto = { isVisible: true };

      await expect(
        service.updateProfileStatus('non-existent-user', statusDto),
      ).rejects.toThrow(NotFoundException);
    });

    it('should throw NotFoundException when profile not found', async () => {
      const userWithoutProfile = {
        id: 'user-id',
        profile: null,
      };

      jest
        .spyOn(userRepository, 'findOne')
        .mockResolvedValue(userWithoutProfile as any);

      const statusDto: UpdateProfileStatusDto = { isVisible: true };

      await expect(
        service.updateProfileStatus('user-id', statusDto),
      ).rejects.toThrow(NotFoundException);
    });

    it('should allow setting profile to not visible without validation', async () => {
      const incompleteUser = {
        id: 'user-id',
        profile: {
          id: 'profile-id',
          userId: 'user-id',
          photos: [], // No photos
          promptAnswers: [],
          birthDate: null,
          bio: null,
          isVisible: true,
        },
        personalityAnswers: [],
      };

      jest
        .spyOn(userRepository, 'findOne')
        .mockResolvedValue(incompleteUser as any);
      jest.spyOn(profileRepository, 'save').mockResolvedValue(null);
      jest.spyOn(userRepository, 'save').mockResolvedValue(null);
      jest.spyOn(promptRepository, 'find').mockResolvedValue([]);
      jest.spyOn(personalityQuestionRepository, 'count').mockResolvedValue(0);

      const statusDto: UpdateProfileStatusDto = { isVisible: false };

      await expect(
        service.updateProfileStatus('user-id', statusDto),
      ).resolves.not.toThrow();

      expect(profileRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({ isVisible: false }),
      );
    });

    it('should reject visibility when profile has less than 3 photos', async () => {
      const userWithFewPhotos = {
        id: 'user-id',
        profile: {
          id: 'profile-id',
          userId: 'user-id',
          photos: [{ id: 'photo-1' }, { id: 'photo-2' }], // Only 2 photos
          promptAnswers: [
            { promptId: 'prompt-1', answer: 'test' },
            { promptId: 'prompt-2', answer: 'test' },
            { promptId: 'prompt-3', answer: 'test' },
          ],
          birthDate: '1990-01-01',
          bio: 'Test bio',
          isVisible: false,
        },
        personalityAnswers: Array(10).fill({ id: 'answer' }),
      };

      jest
        .spyOn(userRepository, 'findOne')
        .mockResolvedValue(userWithFewPhotos as any);
      jest.spyOn(promptRepository, 'find').mockResolvedValue([
        { id: 'prompt-1', isActive: true, isRequired: true },
        { id: 'prompt-2', isActive: true, isRequired: true },
        { id: 'prompt-3', isActive: true, isRequired: true },
      ] as any);
      jest.spyOn(personalityQuestionRepository, 'count').mockResolvedValue(10);

      const statusDto: UpdateProfileStatusDto = { isVisible: true };

      await expect(
        service.updateProfileStatus('user-id', statusDto),
      ).rejects.toThrow(BadRequestException);

      try {
        await service.updateProfileStatus('user-id', statusDto);
      } catch (error) {
        expect(error.response.code).toBe('PROFILE_INCOMPLETE');
        expect(error.response.missingRequirements).toContain(
          'Need 1 more photo(s)',
        );
      }
    });

    it('should reject visibility when required prompts not answered', async () => {
      const requiredPrompts = [
        { id: 'prompt-1', isActive: true, isRequired: true },
        { id: 'prompt-2', isActive: true, isRequired: true },
        { id: 'prompt-3', isActive: true, isRequired: true },
      ];

      const userWithMissingPrompts = {
        id: 'user-id',
        profile: {
          id: 'profile-id',
          userId: 'user-id',
          photos: [{ id: '1' }, { id: '2' }, { id: '3' }],
          promptAnswers: [
            { promptId: 'prompt-1', answer: 'test' },
            // Missing prompt-2 and prompt-3
          ],
          birthDate: '1990-01-01',
          bio: 'Test bio',
          isVisible: false,
        },
        personalityAnswers: Array(10).fill({ id: 'answer' }),
      };

      jest
        .spyOn(userRepository, 'findOne')
        .mockResolvedValue(userWithMissingPrompts as any);
      jest
        .spyOn(promptRepository, 'find')
        .mockResolvedValue(requiredPrompts as any);
      jest.spyOn(personalityQuestionRepository, 'count').mockResolvedValue(10);

      const statusDto: UpdateProfileStatusDto = { isVisible: true };

      await expect(
        service.updateProfileStatus('user-id', statusDto),
      ).rejects.toThrow(BadRequestException);

      try {
        await service.updateProfileStatus('user-id', statusDto);
      } catch (error) {
        expect(error.response.code).toBe('PROFILE_INCOMPLETE');
        expect(error.response.missingRequirements).toContain(
          'Need to answer 2 more prompts (1/3)',
        );
      }
    });

    it('should reject visibility when personality questionnaire not completed', async () => {
      const userWithoutPersonality = {
        id: 'user-id',
        profile: {
          id: 'profile-id',
          userId: 'user-id',
          photos: [{ id: '1' }, { id: '2' }, { id: '3' }],
          promptAnswers: [
            { promptId: 'prompt-1', answer: 'test' },
            { promptId: 'prompt-2', answer: 'test' },
            { promptId: 'prompt-3', answer: 'test' },
          ],
          birthDate: '1990-01-01',
          bio: 'Test bio',
          isVisible: false,
        },
        personalityAnswers: [{ id: '1' }], // Only 1 answer, need 10
      };

      jest
        .spyOn(userRepository, 'findOne')
        .mockResolvedValue(userWithoutPersonality as any);
      jest.spyOn(promptRepository, 'find').mockResolvedValue([
        { id: 'prompt-1', isActive: true, isRequired: true },
        { id: 'prompt-2', isActive: true, isRequired: true },
        { id: 'prompt-3', isActive: true, isRequired: true },
      ] as any);
      jest.spyOn(personalityQuestionRepository, 'count').mockResolvedValue(10);

      const statusDto: UpdateProfileStatusDto = { isVisible: true };

      await expect(
        service.updateProfileStatus('user-id', statusDto),
      ).rejects.toThrow(BadRequestException);

      try {
        await service.updateProfileStatus('user-id', statusDto);
      } catch (error) {
        expect(error.response.code).toBe('PROFILE_INCOMPLETE');
        expect(error.response.missingRequirements).toContain(
          'Need to complete personality questionnaire',
        );
      }
    });

    it('should reject visibility when basic info missing', async () => {
      const userWithoutBasicInfo = {
        id: 'user-id',
        profile: {
          id: 'profile-id',
          userId: 'user-id',
          photos: [{ id: '1' }, { id: '2' }, { id: '3' }],
          promptAnswers: [
            { promptId: 'prompt-1', answer: 'test' },
            { promptId: 'prompt-2', answer: 'test' },
            { promptId: 'prompt-3', answer: 'test' },
          ],
          birthDate: null, // Missing
          bio: null, // Missing
          isVisible: false,
        },
        personalityAnswers: Array(10).fill({ id: 'answer' }),
      };

      jest
        .spyOn(userRepository, 'findOne')
        .mockResolvedValue(userWithoutBasicInfo as any);
      jest.spyOn(promptRepository, 'find').mockResolvedValue([
        { id: 'prompt-1', isActive: true, isRequired: true },
        { id: 'prompt-2', isActive: true, isRequired: true },
        { id: 'prompt-3', isActive: true, isRequired: true },
      ] as any);
      jest.spyOn(personalityQuestionRepository, 'count').mockResolvedValue(10);

      const statusDto: UpdateProfileStatusDto = { isVisible: true };

      await expect(
        service.updateProfileStatus('user-id', statusDto),
      ).rejects.toThrow(BadRequestException);

      try {
        await service.updateProfileStatus('user-id', statusDto);
      } catch (error) {
        expect(error.response.code).toBe('PROFILE_INCOMPLETE');
        expect(error.response.missingRequirements).toContainEqual(
          expect.stringContaining('birth date'),
        );
        expect(error.response.missingRequirements).toContainEqual(
          expect.stringContaining('bio'),
        );
      }
    });

    it('should allow visibility when all requirements are met', async () => {
      const completeUser = {
        id: 'user-id',
        profile: {
          id: 'profile-id',
          userId: 'user-id',
          photos: [{ id: '1' }, { id: '2' }, { id: '3' }],
          promptAnswers: [
            { promptId: 'prompt-1', answer: 'test' },
            { promptId: 'prompt-2', answer: 'test' },
            { promptId: 'prompt-3', answer: 'test' },
          ],
          birthDate: '1990-01-01',
          bio: 'Complete bio',
          isVisible: false,
        },
        personalityAnswers: Array(10).fill({ id: 'answer' }),
      };

      jest
        .spyOn(userRepository, 'findOne')
        .mockResolvedValue(completeUser as any);
      jest.spyOn(profileRepository, 'save').mockResolvedValue(null);
      jest.spyOn(userRepository, 'save').mockResolvedValue(null);
      jest.spyOn(promptRepository, 'find').mockResolvedValue([
        { id: 'prompt-1', isActive: true, isRequired: true },
        { id: 'prompt-2', isActive: true, isRequired: true },
        { id: 'prompt-3', isActive: true, isRequired: true },
      ] as any);
      jest.spyOn(personalityQuestionRepository, 'count').mockResolvedValue(10);

      const statusDto: UpdateProfileStatusDto = { isVisible: true };

      await expect(
        service.updateProfileStatus('user-id', statusDto),
      ).resolves.not.toThrow();

      expect(profileRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({ isVisible: true }),
      );
    });

    it('should provide detailed missing requirements in error', async () => {
      const incompleteUser = {
        id: 'user-id',
        profile: {
          id: 'profile-id',
          userId: 'user-id',
          photos: [{ id: '1' }], // Only 1 photo
          promptAnswers: [], // No prompts
          birthDate: null,
          bio: null,
          isVisible: false,
        },
        personalityAnswers: [], // No personality answers
      };

      jest
        .spyOn(userRepository, 'findOne')
        .mockResolvedValue(incompleteUser as any);
      jest.spyOn(promptRepository, 'find').mockResolvedValue([
        { id: 'prompt-1', isActive: true, isRequired: true },
        { id: 'prompt-2', isActive: true, isRequired: true },
        { id: 'prompt-3', isActive: true, isRequired: true },
      ] as any);
      jest.spyOn(personalityQuestionRepository, 'count').mockResolvedValue(10);

      const statusDto: UpdateProfileStatusDto = { isVisible: true };

      try {
        await service.updateProfileStatus('user-id', statusDto);
        fail('Should have thrown BadRequestException');
      } catch (error) {
        expect(error).toBeInstanceOf(BadRequestException);
        expect(error.response.code).toBe('PROFILE_INCOMPLETE');
        expect(error.response.missingRequirements).toHaveLength(4);
        expect(error.response.missingRequirements).toContain(
          'Need 2 more photo(s)',
        );
        expect(error.response.missingRequirements).toContain(
          'Need to answer 3 more prompts (0/3)',
        );
        expect(error.response.missingRequirements).toContain(
          'Need to complete personality questionnaire',
        );
        expect(error.response.missingRequirements).toContainEqual(
          expect.stringContaining('birth date'),
        );
      }
    });

    it('should reject visibility when user has more than 3 prompts', async () => {
      const userWithTooManyPrompts = {
        id: 'user-id',
        profile: {
          id: 'profile-id',
          userId: 'user-id',
          photos: [{ id: '1' }, { id: '2' }, { id: '3' }],
          promptAnswers: [
            { promptId: 'prompt-1' },
            { promptId: 'prompt-2' },
            { promptId: 'prompt-3' },
            { promptId: 'prompt-4' }, // Too many!
          ],
          birthDate: '1990-01-01',
          bio: 'Test bio',
        },
        personalityAnswers: Array(10).fill({ id: 'answer' }),
      };

      jest
        .spyOn(userRepository, 'findOne')
        .mockResolvedValue(userWithTooManyPrompts as any);
      jest.spyOn(personalityQuestionRepository, 'count').mockResolvedValue(10);

      await expect(
        service.updateProfileStatus('user-id', { isVisible: true }),
      ).rejects.toThrow(BadRequestException);

      try {
        await service.updateProfileStatus('user-id', { isVisible: true });
      } catch (error) {
        expect(error).toBeInstanceOf(BadRequestException);
        expect(error.response.code).toBe('PROFILE_INCOMPLETE');
        expect(error.response.missingRequirements).toContain(
          'Need to remove 1 prompt to have exactly 3 (4/3)',
        );
      }
    });
  });
});
