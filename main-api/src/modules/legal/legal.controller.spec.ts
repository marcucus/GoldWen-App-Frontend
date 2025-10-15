import { Test, TestingModule } from '@nestjs/testing';
import { LegalController } from './legal.controller';
import { LegalService } from './legal.service';
import { PrivacyPolicy } from '../../database/entities/privacy-policy.entity';

describe('LegalController', () => {
  let controller: LegalController;
  let service: LegalService;

  const mockPrivacyPolicy: PrivacyPolicy = {
    id: '123e4567-e89b-12d3-a456-426614174000',
    version: '1.0.0',
    content: JSON.stringify({
      sections: [
        {
          title: 'Test Section',
          content: 'Test content',
        },
      ],
    }),
    htmlContent: '<html><body>Privacy Policy</body></html>',
    isActive: true,
    effectiveDate: new Date('2024-01-01'),
    createdAt: new Date('2024-01-01'),
    updatedAt: new Date('2024-01-01'),
  };

  const mockLegalService = {
    getPrivacyPolicy: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [LegalController],
      providers: [
        {
          provide: LegalService,
          useValue: mockLegalService,
        },
      ],
    }).compile();

    controller = module.get<LegalController>(LegalController);
    service = module.get<LegalService>(LegalService);

    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  describe('getPrivacyPolicy', () => {
    it('should return privacy policy in JSON format by default', async () => {
      mockLegalService.getPrivacyPolicy.mockResolvedValue(mockPrivacyPolicy);

      const result = await controller.getPrivacyPolicy({
        version: 'latest',
        format: 'json',
      });

      expect(result).toEqual({
        version: '1.0.0',
        content: JSON.parse(mockPrivacyPolicy.content),
        lastUpdated: mockPrivacyPolicy.effectiveDate,
        effectiveDate: mockPrivacyPolicy.effectiveDate,
      });
      expect(mockLegalService.getPrivacyPolicy).toHaveBeenCalledWith('latest');
    });

    it('should return privacy policy in HTML format when requested', async () => {
      mockLegalService.getPrivacyPolicy.mockResolvedValue(mockPrivacyPolicy);

      const result = await controller.getPrivacyPolicy({
        version: 'latest',
        format: 'html',
      });

      expect(result).toEqual(mockPrivacyPolicy.htmlContent);
      expect(mockLegalService.getPrivacyPolicy).toHaveBeenCalledWith('latest');
    });

    it('should request specific version when provided', async () => {
      mockLegalService.getPrivacyPolicy.mockResolvedValue(mockPrivacyPolicy);

      await controller.getPrivacyPolicy({
        version: '1.0.0',
        format: 'json',
      });

      expect(mockLegalService.getPrivacyPolicy).toHaveBeenCalledWith('1.0.0');
    });
  });
});
