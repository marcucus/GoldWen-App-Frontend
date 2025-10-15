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
import { ModerationService } from '../moderation/services/moderation.service';

describe('ProfilesService', () => {
  let service: ProfilesService;
  let userRepository: Repository<User>;
  let profileRepository: Repository<Profile>;
  let promptRepository: Repository<Prompt>;
  let personalityQuestionRepository: Repository<PersonalityQuestion>;

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
      photos: [{ id: 'photo1' }, { id: 'photo2' }, { id: 'photo3' }],
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

  const mockModerationService = {
    moderateTextContent: jest.fn().mockResolvedValue({ approved: true }),
    moderateTextContentBatch: jest
      .fn()
      .mockImplementation((texts: string[]) =>
        Promise.resolve(texts.map(() => ({ approved: true }))),
      ),
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

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('getProfile', () => {
    it('should return profile with pseudo field', async () => {
      const mockProfile = {
        id: 'profile-id',
        userId: 'user-id',
        firstName: 'John',
        lastName: 'Doe',
        pseudo: 'johndoe123',
        birthDate: new Date('1990-01-01'),
        bio: 'Test bio',
        photos: [],
        promptAnswers: [],
        user: mockUser,
      };

      jest
        .spyOn(profileRepository, 'findOne')
        .mockResolvedValue(mockProfile as any);

      const result = await service.getProfile('user-id');

      expect(result).toBeDefined();
      expect(result.pseudo).toBe('johndoe123');
      expect(result.firstName).toBe('John');
      expect(result.lastName).toBe('Doe');
    });

    it('should throw NotFoundException when profile does not exist', async () => {
      jest.spyOn(profileRepository, 'findOne').mockResolvedValue(null);

      await expect(service.getProfile('non-existent-user')).rejects.toThrow(
        'Profile not found',
      );
    });
  });

  describe('updateProfile', () => {
    it('should update profile with pseudo field', async () => {
      const mockProfile = {
        id: 'profile-id',
        userId: 'user-id',
        firstName: 'John',
        lastName: 'Doe',
        pseudo: 'oldpseudo',
      };

      const updatedProfile = {
        ...mockProfile,
        pseudo: 'newpseudo',
      };

      jest
        .spyOn(profileRepository, 'findOne')
        .mockResolvedValue(mockProfile as any);
      jest
        .spyOn(profileRepository, 'save')
        .mockResolvedValue(updatedProfile as any);

      const result = await service.updateProfile('user-id', {
        pseudo: 'newpseudo',
      });

      expect(result.pseudo).toBe('newpseudo');
      expect(profileRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({
          pseudo: 'newpseudo',
        }),
      );
    });
  });

  describe('updateProfileStatus', () => {
    it('should allow setting profile visibility to false without validation', async () => {
      const profileRepositorySaveSpy = jest.spyOn(profileRepository, 'save');
      jest.spyOn(userRepository, 'findOne').mockResolvedValue(mockUser as any);
      jest.spyOn(userRepository, 'save').mockResolvedValue(mockUser as any);
      jest.spyOn(promptRepository, 'find').mockResolvedValue([]);
      jest.spyOn(personalityQuestionRepository, 'count').mockResolvedValue(0);

      await service.updateProfileStatus('user-id', {
        isVisible: false,
      });

      expect(profileRepositorySaveSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          isVisible: false,
        }),
      );
    });

    it('should validate profile completion when setting visibility to true', async () => {
      const incompleteUser = {
        ...mockUser,
        profile: {
          ...mockUser.profile,
          photos: [], // Incomplete profile
        },
      };

      jest
        .spyOn(userRepository, 'findOne')
        .mockResolvedValue(incompleteUser as any);
      jest.spyOn(promptRepository, 'find').mockResolvedValue([]);
      jest.spyOn(personalityQuestionRepository, 'count').mockResolvedValue(0);

      await expect(
        service.updateProfileStatus('user-id', {
          isVisible: true,
        }),
      ).rejects.toThrow();
    });
  });
});
