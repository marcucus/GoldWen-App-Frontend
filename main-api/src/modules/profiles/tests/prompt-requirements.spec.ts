import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { BadRequestException, NotFoundException } from '@nestjs/common';

import { ProfilesService } from '../profiles.service';
import { Profile } from '../../../database/entities/profile.entity';
import { User } from '../../../database/entities/user.entity';
import { PersonalityQuestion } from '../../../database/entities/personality-question.entity';
import { PersonalityAnswer } from '../../../database/entities/personality-answer.entity';
import { Photo } from '../../../database/entities/photo.entity';
import { Prompt } from '../../../database/entities/prompt.entity';
import { PromptAnswer } from '../../../database/entities/prompt-answer.entity';
import { SubmitPromptAnswersDto } from '../dto/profiles.dto';

describe('ProfilesService - Dynamic Prompt Requirements', () => {
  let service: ProfilesService;
  let profileRepository: Repository<Profile>;
  let promptRepository: Repository<Prompt>;
  let promptAnswerRepository: Repository<PromptAnswer>;
  let userRepository: Repository<any>;

  const mockProfile = {
    id: 'profile-id',
    userId: 'user-id',
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
          provide: getRepositoryToken(Prompt),
          useClass: Repository,
        },
        {
          provide: getRepositoryToken(PromptAnswer),
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
      ],
    }).compile();

    service = module.get<ProfilesService>(ProfilesService);
    profileRepository = module.get<Repository<Profile>>(
      getRepositoryToken(Profile),
    );
    promptRepository = module.get<Repository<Prompt>>(
      getRepositoryToken(Prompt),
    );
    promptAnswerRepository = module.get<Repository<PromptAnswer>>(
      getRepositoryToken(PromptAnswer),
    );
    userRepository = module.get<Repository<any>>(getRepositoryToken(User));
  });

  describe('submitPromptAnswers with dynamic validation', () => {
    it('should accept answers for all required prompts', async () => {
      const requiredPrompts = [
        { id: 'prompt-1', isActive: true, isRequired: true, text: 'Prompt 1' },
        { id: 'prompt-2', isActive: true, isRequired: true, text: 'Prompt 2' },
      ];

      const allPrompts = [
        ...requiredPrompts,
        { id: 'prompt-3', isActive: true, isRequired: false, text: 'Prompt 3' },
      ];

      const promptAnswersDto: SubmitPromptAnswersDto = {
        answers: [
          { promptId: 'prompt-1', answer: 'Answer 1' },
          { promptId: 'prompt-2', answer: 'Answer 2' },
          { promptId: 'prompt-3', answer: 'Answer 3' }, // Optional prompt
        ],
      };

      // Mock repository calls
      jest
        .spyOn(promptRepository, 'find')
        .mockImplementation((options: any) => {
          if (options.where.isRequired) {
            return Promise.resolve(requiredPrompts as any);
          }
          return Promise.resolve(allPrompts as any);
        });

      jest
        .spyOn(profileRepository, 'findOne')
        .mockResolvedValue(mockProfile as any);
      jest.spyOn(promptAnswerRepository, 'delete').mockResolvedValue({} as any);
      jest
        .spyOn(promptAnswerRepository, 'create')
        .mockImplementation((data) => data as any);
      jest.spyOn(promptAnswerRepository, 'save').mockResolvedValue([] as any);

      // Mock updateProfileCompletionStatus method
      const updateSpy = jest
        .spyOn(service as any, 'updateProfileCompletionStatus')
        .mockResolvedValue(undefined);

      await service.submitPromptAnswers('user-id', promptAnswersDto);

      expect(promptAnswerRepository.save).toHaveBeenCalled();
      expect(updateSpy).toHaveBeenCalledWith('user-id');
    });

    it('should reject when missing required prompt answers', async () => {
      const requiredPrompts = [
        { id: 'prompt-1', isActive: true, isRequired: true, text: 'Prompt 1' },
        { id: 'prompt-2', isActive: true, isRequired: true, text: 'Prompt 2' },
      ];

      const allPrompts = [
        ...requiredPrompts,
        { id: 'prompt-3', isActive: true, isRequired: false, text: 'Prompt 3' },
      ];

      const promptAnswersDto: SubmitPromptAnswersDto = {
        answers: [
          { promptId: 'prompt-1', answer: 'Answer 1' },
          // Missing prompt-2 (required)
        ],
      };

      jest
        .spyOn(promptRepository, 'find')
        .mockImplementation((options: any) => {
          if (options.where.isRequired) {
            return Promise.resolve(requiredPrompts as any);
          }
          return Promise.resolve(allPrompts as any);
        });

      await expect(
        service.submitPromptAnswers('user-id', promptAnswersDto),
      ).rejects.toThrow(BadRequestException);
    });

    it('should reject answers to inactive prompts', async () => {
      const requiredPrompts = [
        { id: 'prompt-1', isActive: true, isRequired: true, text: 'Prompt 1' },
      ];

      const allPrompts = [
        ...requiredPrompts,
        // Note: prompt-2 is not in active prompts list
      ];

      const promptAnswersDto: SubmitPromptAnswersDto = {
        answers: [
          { promptId: 'prompt-1', answer: 'Answer 1' },
          { promptId: 'prompt-2', answer: 'Answer to inactive prompt' },
        ],
      };

      jest
        .spyOn(promptRepository, 'find')
        .mockImplementation((options: any) => {
          if (options.where.isRequired) {
            return Promise.resolve(requiredPrompts as any);
          }
          return Promise.resolve(allPrompts as any);
        });

      await expect(
        service.submitPromptAnswers('user-id', promptAnswersDto),
      ).rejects.toThrow(BadRequestException);
    });

    it('should throw NotFoundException when profile not found', async () => {
      const promptAnswersDto: SubmitPromptAnswersDto = {
        answers: [{ promptId: 'prompt-1', answer: 'Answer 1' }],
      };

      // Mock that prompts exist and are valid, but profile doesn't exist
      jest
        .spyOn(promptRepository, 'find')
        .mockImplementationOnce(() =>
          Promise.resolve([
            {
              id: 'prompt-1',
              isActive: true,
              isRequired: true,
              text: 'Prompt 1',
            },
          ] as any),
        )
        .mockImplementationOnce(() =>
          Promise.resolve([
            {
              id: 'prompt-1',
              isActive: true,
              isRequired: true,
              text: 'Prompt 1',
            },
          ] as any),
        );

      jest.spyOn(profileRepository, 'findOne').mockResolvedValue(null);

      await expect(
        service.submitPromptAnswers('user-id', promptAnswersDto),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('getUserPromptAnswers', () => {
    it('should return user prompt answers with prompt relations', async () => {
      const mockAnswers = [
        {
          id: 'answer-1',
          promptId: 'prompt-1',
          answer: 'My answer',
          prompt: { id: 'prompt-1', text: 'What makes you happy?' },
        },
      ];

      const profileWithAnswers = {
        ...mockProfile,
        promptAnswers: mockAnswers,
      };

      jest
        .spyOn(profileRepository, 'findOne')
        .mockResolvedValue(profileWithAnswers as any);

      const result = await service.getUserPromptAnswers('user-id');

      expect(result).toEqual(mockAnswers);
      expect(profileRepository.findOne).toHaveBeenCalledWith({
        where: { userId: 'user-id' },
        relations: ['promptAnswers', 'promptAnswers.prompt'],
      });
    });

    it('should throw NotFoundException when profile not found', async () => {
      jest.spyOn(profileRepository, 'findOne').mockResolvedValue(null);

      await expect(service.getUserPromptAnswers('user-id')).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should return empty array when user has no prompt answers', async () => {
      const profileWithoutAnswers = {
        ...mockProfile,
        promptAnswers: null,
      };

      jest
        .spyOn(profileRepository, 'findOne')
        .mockResolvedValue(profileWithoutAnswers as any);

      const result = await service.getUserPromptAnswers('user-id');

      expect(result).toEqual([]);
    });
  });
});
