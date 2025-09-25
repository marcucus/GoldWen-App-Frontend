import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ProfilesService } from './profiles.service';
import { Profile } from '../../database/entities/profile.entity';
import { User } from '../../database/entities/user.entity';
import { PersonalityQuestion } from '../../database/entities/personality-question.entity';
import { PersonalityAnswer } from '../../database/entities/personality-answer.entity';
import { Photo } from '../../database/entities/photo.entity';
import { Prompt } from '../../database/entities/prompt.entity';
import { PromptAnswer } from '../../database/entities/prompt-answer.entity';
import { UserStatus } from '../../common/enums';
import { BadRequestException, NotFoundException } from '@nestjs/common';

describe('ProfilesService', () => {
  let service: ProfilesService;
  let userRepository: Repository<User>;
  let profileRepository: Repository<Profile>;
  let promptAnswerRepository: Repository<PromptAnswer>;

  const mockUser = {
    id: 'user-id',
    email: 'test@example.com',
    isProfileCompleted: false,
    isOnboardingCompleted: false,
    status: UserStatus.ACTIVE,
    profile: {
      id: 'profile-id',
      userId: 'user-id',
      birthDate: new Date('1990-01-01'),
      bio: 'Test bio',
      photos: [
        { id: 'photo1' },
        { id: 'photo2' },
        { id: 'photo3' },
      ],
      promptAnswers: [
        { id: 'answer1', promptId: 'prompt1' },
        { id: 'answer2', promptId: 'prompt2' },
        { id: 'answer3', promptId: 'prompt3' },
      ],
    },
    personalityAnswers: [
      { id: 'panswer1', questionId: 'q1' },
      { id: 'panswer2', questionId: 'q2' },
    ],
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
            find: jest.fn(),
            count: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(PersonalityAnswer),
          useValue: {
            save: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(Photo),
          useValue: {
            save: jest.fn(),
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
          useValue: {
            save: jest.fn(),
            delete: jest.fn(),
            create: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<ProfilesService>(ProfilesService);
    userRepository = module.get<Repository<User>>(getRepositoryToken(User));
    profileRepository = module.get<Repository<Profile>>(getRepositoryToken(Profile));
    promptAnswerRepository = module.get<Repository<PromptAnswer>>(getRepositoryToken(PromptAnswer));
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('updateProfileStatus', () => {
    it('should update user status and completion flags', async () => {
      const userRepositorySaveSpy = jest.spyOn(userRepository, 'save');
      jest.spyOn(userRepository, 'findOne').mockResolvedValue(mockUser as any);

      await service.updateProfileStatus('user-id', {
        status: 'active',
        completed: true,
      });

      expect(userRepositorySaveSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          status: 'active',
          isProfileCompleted: true,
          isOnboardingCompleted: true,
        })
      );
    });

    it('should recalculate completion status when completed is false', async () => {
      jest.spyOn(userRepository, 'findOne').mockResolvedValue(mockUser as any);
      
      // Spy on the private method
      const updateCompletionSpy = jest.spyOn(service as any, 'updateProfileCompletionStatus').mockResolvedValue(undefined);

      await service.updateProfileStatus('user-id', {
        status: 'active',
        completed: false,
      });

      // Should call the completion status calculation method
      expect(updateCompletionSpy).toHaveBeenCalledWith('user-id');
    });
  });

  describe('submitPromptAnswers', () => {
    const mockProfile = {
      id: 'profile-id',
      userId: 'user-id',
    };

    beforeEach(() => {
      jest.spyOn(profileRepository, 'findOne').mockResolvedValue(mockProfile as any);
      jest.spyOn(promptAnswerRepository, 'delete').mockResolvedValue({} as any);
      jest.spyOn(promptAnswerRepository, 'create').mockImplementation((data) => data as any);
      jest.spyOn(promptAnswerRepository, 'save').mockResolvedValue([] as any);
    });

    it('should throw BadRequestException if not exactly 3 answers provided', async () => {
      const answersDto = {
        answers: [
          { promptId: 'prompt1', answer: 'Answer 1' },
          { promptId: 'prompt2', answer: 'Answer 2' }
        ]
      };

      await expect(service.submitPromptAnswers('user-id', answersDto))
        .rejects.toThrow(new BadRequestException('Exactly 3 prompt answers are required'));
    });

    it('should throw NotFoundException if profile not found', async () => {
      jest.spyOn(profileRepository, 'findOne').mockResolvedValue(null);
      
      const answersDto = {
        answers: [
          { promptId: 'prompt1', answer: 'Answer 1' },
          { promptId: 'prompt2', answer: 'Answer 2' },
          { promptId: 'prompt3', answer: 'Answer 3' }
        ]
      };

      await expect(service.submitPromptAnswers('user-id', answersDto))
        .rejects.toThrow(new NotFoundException('Profile not found'));
    });

    it('should successfully save exactly 3 prompt answers', async () => {
      const answersDto = {
        answers: [
          { promptId: 'prompt1', answer: 'Answer 1' },
          { promptId: 'prompt2', answer: 'Answer 2' },
          { promptId: 'prompt3', answer: 'Answer 3' }
        ]
      };

      const createSpy = jest.spyOn(promptAnswerRepository, 'create');
      const saveSpy = jest.spyOn(promptAnswerRepository, 'save');
      const deleteSpy = jest.spyOn(promptAnswerRepository, 'delete');

      await service.submitPromptAnswers('user-id', answersDto);

      expect(deleteSpy).toHaveBeenCalledWith({ profileId: mockProfile.id });
      expect(createSpy).toHaveBeenCalledTimes(3);
      expect(saveSpy).toHaveBeenCalled();

      // Verify the created entities have the correct structure
      const createCalls = createSpy.mock.calls;
      expect(createCalls[0][0]).toEqual(expect.objectContaining({
        profileId: mockProfile.id,
        promptId: 'prompt1',
        answer: 'Answer 1',
        order: 1
      }));
      expect(createCalls[1][0]).toEqual(expect.objectContaining({
        profileId: mockProfile.id,
        promptId: 'prompt2',
        answer: 'Answer 2',
        order: 2
      }));
      expect(createCalls[2][0]).toEqual(expect.objectContaining({
        profileId: mockProfile.id,
        promptId: 'prompt3',
        answer: 'Answer 3',
        order: 3
      }));
    });
  });
});