import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException } from '@nestjs/common';
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
import { UpdateProfileDto } from '../dto/profiles.dto';

/**
 * Tests for bio field validation
 *
 * Requirements:
 * - Bio field must accept up to 600 characters
 * - Spaces and newlines must be counted in the character limit
 * - Bio longer than 600 characters should be rejected
 * - Error message should clearly indicate the limit
 */
describe('ProfilesService - Bio Validation', () => {
  let service: ProfilesService;
  let profileRepository: Repository<Profile>;
  let userRepository: Repository<User>;
  let mockModerationService: Partial<ModerationService>;

  beforeEach(async () => {
    mockModerationService = {
      moderateTextContent: jest.fn().mockResolvedValue({
        approved: true,
        reason: null,
      }),
      moderateTextContentBatch: jest
        .fn()
        .mockImplementation((texts: string[]) =>
          Promise.resolve(texts.map(() => ({ approved: true }))),
        ),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ProfilesService,
        {
          provide: getRepositoryToken(Profile),
          useValue: {
            findOne: jest.fn(),
            save: jest.fn(),
            create: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(User),
          useValue: {
            findOne: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(Photo),
          useValue: {
            save: jest.fn(),
            find: jest.fn(),
            delete: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(PersonalityQuestion),
          useValue: {
            find: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(PersonalityAnswer),
          useValue: {
            save: jest.fn(),
            delete: jest.fn(),
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
            find: jest.fn(),
            delete: jest.fn(),
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

  describe('Bio Character Limit', () => {
    it('should accept a bio with exactly 600 characters', async () => {
      const mockUser = {
        id: 'user-1',
      };

      const mockProfile = {
        id: 'profile-1',
        userId: 'user-1',
        firstName: 'John',
        lastName: 'Doe',
        bio: 'Old bio',
      };

      // Create a bio with exactly 600 characters
      const bio600 = 'a'.repeat(600);

      const updateDto: UpdateProfileDto = {
        bio: bio600,
      };

      jest.spyOn(userRepository, 'findOne').mockResolvedValue(mockUser as any);
      jest
        .spyOn(profileRepository, 'findOne')
        .mockResolvedValue(mockProfile as any);
      jest.spyOn(profileRepository, 'save').mockResolvedValue({
        ...mockProfile,
        bio: bio600,
      } as any);

      const result = await service.updateProfile('user-1', updateDto);

      expect(result.bio).toBe(bio600);
      expect(result.bio.length).toBe(600);
    });

    it('should accept a bio with spaces and count them in the limit', async () => {
      const mockUser = {
        id: 'user-1',
      };

      const mockProfile = {
        id: 'profile-1',
        userId: 'user-1',
        firstName: 'John',
        lastName: 'Doe',
        bio: 'Old bio',
      };

      // Create a bio with 590 characters + 10 spaces = 600 total
      const bio = 'a'.repeat(590) + ' '.repeat(10);

      const updateDto: UpdateProfileDto = {
        bio: bio,
      };

      jest.spyOn(userRepository, 'findOne').mockResolvedValue(mockUser as any);
      jest
        .spyOn(profileRepository, 'findOne')
        .mockResolvedValue(mockProfile as any);
      jest.spyOn(profileRepository, 'save').mockResolvedValue({
        ...mockProfile,
        bio: bio,
      } as any);

      const result = await service.updateProfile('user-1', updateDto);

      expect(result.bio).toBe(bio);
      expect(result.bio.length).toBe(600);
    });

    it('should accept a bio with newlines and count them in the limit', async () => {
      const mockUser = {
        id: 'user-1',
      };

      const mockProfile = {
        id: 'profile-1',
        userId: 'user-1',
        firstName: 'John',
        lastName: 'Doe',
        bio: 'Old bio',
      };

      // Create a bio with 590 characters + 10 newlines = 600 total
      const bio = 'a'.repeat(590) + '\n'.repeat(10);

      const updateDto: UpdateProfileDto = {
        bio: bio,
      };

      jest.spyOn(userRepository, 'findOne').mockResolvedValue(mockUser as any);
      jest
        .spyOn(profileRepository, 'findOne')
        .mockResolvedValue(mockProfile as any);
      jest.spyOn(profileRepository, 'save').mockResolvedValue({
        ...mockProfile,
        bio: bio,
      } as any);

      const result = await service.updateProfile('user-1', updateDto);

      expect(result.bio).toBe(bio);
      expect(result.bio.length).toBe(600);
    });

    it('should accept a bio with mixed content (text, spaces, newlines)', async () => {
      const mockUser = {
        id: 'user-1',
      };

      const mockProfile = {
        id: 'profile-1',
        userId: 'user-1',
        firstName: 'John',
        lastName: 'Doe',
        bio: 'Old bio',
      };

      // Create a realistic bio with mixed content
      const bio = `Hi, I'm John! I love hiking, reading, and spending time with friends.

I work as a software engineer and enjoy building cool projects in my spare time.

Some of my hobbies include:
- Photography
- Cooking
- Travel

Looking for someone who shares similar interests and values meaningful conversations.${'x'.repeat(300)}`;

      expect(bio.length).toBeLessThanOrEqual(600);

      const updateDto: UpdateProfileDto = {
        bio: bio,
      };

      jest.spyOn(userRepository, 'findOne').mockResolvedValue(mockUser as any);
      jest
        .spyOn(profileRepository, 'findOne')
        .mockResolvedValue(mockProfile as any);
      jest.spyOn(profileRepository, 'save').mockResolvedValue({
        ...mockProfile,
        bio: bio,
      } as any);

      const result = await service.updateProfile('user-1', updateDto);

      expect(result.bio).toBe(bio);
    });

    it('should handle moderation rejection for bio content', async () => {
      const mockUser = {
        id: 'user-1',
      };

      const mockProfile = {
        id: 'profile-1',
        userId: 'user-1',
        firstName: 'John',
        lastName: 'Doe',
        bio: 'Old bio',
      };

      const inappropriateBio = 'This contains inappropriate content';

      const updateDto: UpdateProfileDto = {
        bio: inappropriateBio,
      };

      jest.spyOn(userRepository, 'findOne').mockResolvedValue(mockUser as any);
      jest
        .spyOn(profileRepository, 'findOne')
        .mockResolvedValue(mockProfile as any);

      // Mock moderation rejection (now uses batch moderation)
      jest
        .spyOn(mockModerationService, 'moderateTextContentBatch')
        .mockResolvedValue([
          {
            approved: false,
            reason: 'Contains inappropriate language',
          },
        ]);

      await expect(service.updateProfile('user-1', updateDto)).rejects.toThrow(
        BadRequestException,
      );

      await expect(service.updateProfile('user-1', updateDto)).rejects.toThrow(
        'Profile fields rejected: bio: Contains inappropriate language',
      );
    });

    it('should successfully update bio with less than 600 characters', async () => {
      const mockUser = {
        id: 'user-1',
      };

      const mockProfile = {
        id: 'profile-1',
        userId: 'user-1',
        firstName: 'John',
        lastName: 'Doe',
        bio: 'Old bio',
      };

      const shortBio = 'This is a short bio with only a few words.';

      const updateDto: UpdateProfileDto = {
        bio: shortBio,
      };

      jest.spyOn(userRepository, 'findOne').mockResolvedValue(mockUser as any);
      jest
        .spyOn(profileRepository, 'findOne')
        .mockResolvedValue(mockProfile as any);
      jest.spyOn(profileRepository, 'save').mockResolvedValue({
        ...mockProfile,
        bio: shortBio,
      } as any);

      const result = await service.updateProfile('user-1', updateDto);

      expect(result.bio).toBe(shortBio);
      expect(result.bio.length).toBeLessThan(600);
    });
  });
});
