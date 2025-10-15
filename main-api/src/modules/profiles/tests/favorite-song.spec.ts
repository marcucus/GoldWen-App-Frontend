import { Test, TestingModule } from '@nestjs/testing';
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
import { ModerationService } from '../../moderation/services/moderation.service';

describe('ProfilesService - Favorite Song Field', () => {
  let service: ProfilesService;
  let profileRepository: Repository<Profile>;
  let userRepository: Repository<User>;

  const mockProfile = {
    id: 'profile-id',
    userId: 'user-id',
    firstName: 'John',
    lastName: 'Doe',
    favoriteSong: null,
  };

  const mockUser = {
    id: 'user-id',
    email: 'test@example.com',
    isProfileCompleted: false,
    isOnboardingCompleted: false,
    profile: mockProfile,
    personalityAnswers: [],
  };

  const mockModerationService = {
    moderateTextContent: jest.fn().mockResolvedValue({ approved: true }),
    moderateTextContentBatch: jest.fn().mockResolvedValue([{ approved: true }]),
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
    profileRepository = module.get<Repository<Profile>>(
      getRepositoryToken(Profile),
    );
    userRepository = module.get<Repository<User>>(getRepositoryToken(User));
  });

  describe('updateProfile - favoriteSong field', () => {
    it('should update profile with favoriteSong', async () => {
      const profileToUpdate = { ...mockProfile };
      const updatedProfile = {
        ...mockProfile,
        favoriteSong: 'Bohemian Rhapsody by Queen',
      };

      jest
        .spyOn(profileRepository, 'findOne')
        .mockResolvedValueOnce(profileToUpdate as any)
        .mockResolvedValueOnce({
          ...updatedProfile,
          photos: [],
          promptAnswers: [],
          user: mockUser,
        } as any);
      jest
        .spyOn(profileRepository, 'save')
        .mockResolvedValue(updatedProfile as any);
      jest.spyOn(userRepository, 'findOne').mockResolvedValue(mockUser as any);
      jest.spyOn(userRepository, 'save').mockResolvedValue(mockUser as any);

      const result = await service.updateProfile('user-id', {
        favoriteSong: 'Bohemian Rhapsody by Queen',
      });

      expect(result.favoriteSong).toBe('Bohemian Rhapsody by Queen');
      // eslint-disable-next-line @typescript-eslint/unbound-method
      expect(profileRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({
          favoriteSong: 'Bohemian Rhapsody by Queen',
        }),
      );
    });

    it('should allow updating favoriteSong to null/empty', async () => {
      const profileToUpdate = {
        ...mockProfile,
        favoriteSong: 'Old Song',
      };
      const updatedProfile = {
        ...mockProfile,
        favoriteSong: null,
      };

      jest
        .spyOn(profileRepository, 'findOne')
        .mockResolvedValueOnce(profileToUpdate as any)
        .mockResolvedValueOnce({
          ...updatedProfile,
          photos: [],
          promptAnswers: [],
          user: mockUser,
        } as any);
      jest
        .spyOn(profileRepository, 'save')
        .mockResolvedValue(updatedProfile as any);
      jest.spyOn(userRepository, 'findOne').mockResolvedValue(mockUser as any);
      jest.spyOn(userRepository, 'save').mockResolvedValue(mockUser as any);

      await service.updateProfile('user-id', {
        favoriteSong: undefined,
      });

      // eslint-disable-next-line @typescript-eslint/unbound-method
      expect(profileRepository.save).toHaveBeenCalled();
    });

    it('should accept favoriteSong with maximum length', async () => {
      const longSong = 'A'.repeat(200); // Max length is 200
      const profileToUpdate = { ...mockProfile };
      const updatedProfile = {
        ...mockProfile,
        favoriteSong: longSong,
      };

      jest
        .spyOn(profileRepository, 'findOne')
        .mockResolvedValueOnce(profileToUpdate as any)
        .mockResolvedValueOnce({
          ...updatedProfile,
          photos: [],
          promptAnswers: [],
          user: mockUser,
        } as any);
      jest
        .spyOn(profileRepository, 'save')
        .mockResolvedValue(updatedProfile as any);
      jest.spyOn(userRepository, 'findOne').mockResolvedValue(mockUser as any);
      jest.spyOn(userRepository, 'save').mockResolvedValue(mockUser as any);

      const result = await service.updateProfile('user-id', {
        favoriteSong: longSong,
      });

      expect(result.favoriteSong).toBe(longSong);
    });
  });

  describe('getProfile - favoriteSong field', () => {
    it('should return profile with favoriteSong field', async () => {
      const mockProfileWithSong = {
        ...mockProfile,
        favoriteSong: 'Imagine by John Lennon',
        photos: [],
        promptAnswers: [],
        user: mockUser,
      };

      jest
        .spyOn(profileRepository, 'findOne')
        .mockResolvedValue(mockProfileWithSong as any);

      const result = await service.getProfile('user-id');

      expect(result).toBeDefined();
      expect(result.favoriteSong).toBe('Imagine by John Lennon');
    });

    it('should return profile with null favoriteSong when not set', async () => {
      const mockProfileWithoutSong = {
        ...mockProfile,
        favoriteSong: null,
        photos: [],
        promptAnswers: [],
        user: mockUser,
      };

      jest
        .spyOn(profileRepository, 'findOne')
        .mockResolvedValue(mockProfileWithoutSong as any);

      const result = await service.getProfile('user-id');

      expect(result).toBeDefined();
      expect(result.favoriteSong).toBeNull();
    });
  });
});
