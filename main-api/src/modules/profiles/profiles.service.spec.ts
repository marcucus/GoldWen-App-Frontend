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

describe('ProfilesService', () => {
  let service: ProfilesService;
  let userRepository: Repository<User>;
  let profileRepository: Repository<Profile>;

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
          },
        },
      ],
    }).compile();

    service = module.get<ProfilesService>(ProfilesService);
    userRepository = module.get<Repository<User>>(getRepositoryToken(User));
    profileRepository = module.get<Repository<Profile>>(getRepositoryToken(Profile));
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
});