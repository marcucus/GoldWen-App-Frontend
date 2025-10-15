import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { LegalService } from './legal.service';
import { PrivacyPolicy } from '../../database/entities/privacy-policy.entity';

describe('LegalService', () => {
  let service: LegalService;
  let repository: Repository<PrivacyPolicy>;

  const mockPrivacyPolicy: PrivacyPolicy = {
    id: '123e4567-e89b-12d3-a456-426614174000',
    version: '1.0.0',
    content: JSON.stringify({ sections: [] }),
    htmlContent: '<html>Privacy Policy</html>',
    isActive: true,
    effectiveDate: new Date('2024-01-01'),
    createdAt: new Date('2024-01-01'),
    updatedAt: new Date('2024-01-01'),
  };

  const mockRepository = {
    findOne: jest.fn(),
    create: jest.fn(),
    save: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        LegalService,
        {
          provide: getRepositoryToken(PrivacyPolicy),
          useValue: mockRepository,
        },
      ],
    }).compile();

    service = module.get<LegalService>(LegalService);
    repository = module.get<Repository<PrivacyPolicy>>(
      getRepositoryToken(PrivacyPolicy),
    );

    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('getPrivacyPolicy', () => {
    it('should return the latest active privacy policy', async () => {
      mockRepository.findOne.mockResolvedValue(mockPrivacyPolicy);

      const result = await service.getPrivacyPolicy('latest');

      expect(result).toEqual(mockPrivacyPolicy);
      expect(mockRepository.findOne).toHaveBeenCalledWith({
        where: { isActive: true },
        order: { effectiveDate: 'DESC' },
      });
    });

    it('should return a specific version when requested', async () => {
      mockRepository.findOne.mockResolvedValue(mockPrivacyPolicy);

      const result = await service.getPrivacyPolicy('1.0.0');

      expect(result).toEqual(mockPrivacyPolicy);
      expect(mockRepository.findOne).toHaveBeenCalledWith({
        where: { version: '1.0.0' },
      });
    });

    it('should create a default policy if none exists', async () => {
      mockRepository.findOne.mockResolvedValue(null);
      mockRepository.create.mockReturnValue(mockPrivacyPolicy);
      mockRepository.save.mockResolvedValue(mockPrivacyPolicy);

      const result = await service.getPrivacyPolicy('latest');

      expect(result).toEqual(mockPrivacyPolicy);
      expect(mockRepository.create).toHaveBeenCalled();
      expect(mockRepository.save).toHaveBeenCalled();
    });
  });
});
