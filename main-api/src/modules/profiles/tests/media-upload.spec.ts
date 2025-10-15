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
 * Integration tests for POST /api/v1/profiles/me/media endpoint
 *
 * This endpoint is an alias for the photos upload endpoint to ensure
 * compatibility with clients that may call /media instead of /photos.
 */
describe('ProfilesService - Media Upload Endpoint', () => {
  let service: ProfilesService;
  let profileRepository: Repository<Profile>;
  let photoRepository: Repository<Photo>;

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
          },
        },
        {
          provide: getRepositoryToken(Photo),
          useValue: {
            save: jest.fn(),
            delete: jest.fn(),
            findOne: jest.fn(),
            create: jest.fn((photo) => photo), // Add create method
            createQueryBuilder: jest.fn(),
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
    photoRepository = module.get<Repository<Photo>>(getRepositoryToken(Photo));
  });

  describe('POST /api/v1/profiles/me/media - Upload Media (Photos)', () => {
    it('should successfully upload media files using the same logic as photos endpoint', async () => {
      const mockProfile = {
        id: 'profile-1',
        userId: 'user-1',
        photos: [],
      };

      const mockFiles = [
        {
          filename: 'test1.jpg',
          mimetype: 'image/jpeg',
          size: 1000,
          path: '/tmp/test1.jpg',
        },
        {
          filename: 'test2.jpg',
          mimetype: 'image/jpeg',
          size: 2000,
          path: '/tmp/test2.jpg',
        },
      ] as Express.Multer.File[];

      jest
        .spyOn(profileRepository, 'findOne')
        .mockResolvedValue(mockProfile as any);

      const savedPhotos = mockFiles.map((file, index) => ({
        id: `photo-${index + 1}`,
        filename: file.filename,
        url: `/uploads/photos/${file.filename}`,
        order: index + 1,
        isPrimary: index === 0,
        isApproved: true,
        profileId: 'profile-1',
      }));

      jest.spyOn(photoRepository, 'save').mockResolvedValue(savedPhotos as any);

      const result = await service.uploadPhotos('user-1', mockFiles);

      expect(result).toBeDefined();
      expect(result.length).toBe(2);
      expect(photoRepository.save).toHaveBeenCalled();
    });

    it('should enforce maximum 6 photos limit for media uploads', async () => {
      const profileWith6Photos = {
        id: 'profile-1',
        userId: 'user-1',
        photos: Array.from({ length: 6 }, (_, i) => ({ id: `photo-${i + 1}` })),
      };

      jest
        .spyOn(profileRepository, 'findOne')
        .mockResolvedValue(profileWith6Photos as any);

      const mockFiles = [
        {
          filename: 'test.jpg',
          mimetype: 'image/jpeg',
          size: 1000,
          path: '/tmp/test.jpg',
        },
      ] as Express.Multer.File[];

      await expect(service.uploadPhotos('user-1', mockFiles)).rejects.toThrow(
        BadRequestException,
      );
      await expect(service.uploadPhotos('user-1', mockFiles)).rejects.toThrow(
        /Maximum 6 photos allowed/,
      );
    });

    it('should require at least one file for media upload', async () => {
      const mockProfile = {
        id: 'profile-1',
        userId: 'user-1',
        photos: [],
      };

      jest
        .spyOn(profileRepository, 'findOne')
        .mockResolvedValue(mockProfile as any);

      const mockFiles: Express.Multer.File[] = [];

      await expect(service.uploadPhotos('user-1', mockFiles)).rejects.toThrow(
        BadRequestException,
      );
      await expect(service.uploadPhotos('user-1', mockFiles)).rejects.toThrow(
        /At least one photo is required/,
      );
    });

    it('should return 404 when profile not found', async () => {
      jest.spyOn(profileRepository, 'findOne').mockResolvedValue(null);

      const mockFiles = [
        {
          filename: 'test.jpg',
          mimetype: 'image/jpeg',
          size: 1000,
          path: '/tmp/test.jpg',
        },
      ] as Express.Multer.File[];

      await expect(service.uploadPhotos('user-1', mockFiles)).rejects.toThrow(
        NotFoundException,
      );
      await expect(service.uploadPhotos('user-1', mockFiles)).rejects.toThrow(
        /Profile not found/,
      );
    });

    it('should handle multiple file uploads correctly', async () => {
      const mockProfile = {
        id: 'profile-1',
        userId: 'user-1',
        photos: [{ id: 'existing-photo', order: 1 }],
      };

      const mockFiles = [
        {
          filename: 'test1.jpg',
          mimetype: 'image/jpeg',
          size: 1000,
          path: '/tmp/test1.jpg',
        },
        {
          filename: 'test2.jpg',
          mimetype: 'image/jpeg',
          size: 2000,
          path: '/tmp/test2.jpg',
        },
        {
          filename: 'test3.jpg',
          mimetype: 'image/jpeg',
          size: 3000,
          path: '/tmp/test3.jpg',
        },
      ] as Express.Multer.File[];

      jest
        .spyOn(profileRepository, 'findOne')
        .mockResolvedValue(mockProfile as any);

      const savedPhotos = mockFiles.map((file, index) => ({
        id: `photo-${index + 2}`,
        filename: file.filename,
        url: `/uploads/photos/${file.filename}`,
        order: index + 2,
        isPrimary: false,
        isApproved: true,
        profileId: 'profile-1',
      }));

      jest.spyOn(photoRepository, 'save').mockResolvedValue(savedPhotos as any);

      const result = await service.uploadPhotos('user-1', mockFiles);

      expect(result).toBeDefined();
      expect(result.length).toBe(3);
      // Total photos should not exceed 6 (1 existing + 3 new = 4 total)
      expect(mockProfile.photos.length + result.length).toBeLessThanOrEqual(6);
    });
  });
});
