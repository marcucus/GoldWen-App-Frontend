import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { BadRequestException, NotFoundException } from '@nestjs/common';

import { AdminService } from '../admin.service';
import { Admin } from '../../../database/entities/admin.entity';
import { User } from '../../../database/entities/user.entity';
import { Report } from '../../../database/entities/report.entity';
import { Match } from '../../../database/entities/match.entity';
import { Chat } from '../../../database/entities/chat.entity';
import { Subscription } from '../../../database/entities/subscription.entity';
import { SupportTicket } from '../../../database/entities/support-ticket.entity';
import { Prompt } from '../../../database/entities/prompt.entity';
import { CreatePromptDto, UpdatePromptDto } from '../dto/prompt.dto';
import { CustomLoggerService } from '../../../common/logger';
import { NotificationsService } from '../../notifications/notifications.service';

describe('AdminService - Prompt Management', () => {
  let service: AdminService;
  let promptRepository: Repository<Prompt>;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AdminService,
        {
          provide: getRepositoryToken(Admin),
          useClass: Repository,
        },
        {
          provide: getRepositoryToken(Prompt),
          useClass: Repository,
        },
        // Add other required repository mocks
        {
          provide: getRepositoryToken(User),
          useClass: Repository,
        },
        {
          provide: getRepositoryToken(Report),
          useClass: Repository,
        },
        {
          provide: getRepositoryToken(Match),
          useClass: Repository,
        },
        {
          provide: getRepositoryToken(Chat),
          useClass: Repository,
        },
        {
          provide: getRepositoryToken(Subscription),
          useClass: Repository,
        },
        {
          provide: getRepositoryToken(SupportTicket),
          useClass: Repository,
        },
        // Mock NotificationsService and CustomLoggerService
        {
          provide: NotificationsService,
          useValue: {
            sendNotification: jest.fn(),
          },
        },
        {
          provide: CustomLoggerService,
          useValue: {
            info: jest.fn(),
            error: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<AdminService>(AdminService);
    promptRepository = module.get<Repository<Prompt>>(
      getRepositoryToken(Prompt),
    );
  });

  describe('getPrompts', () => {
    it('should return all prompts ordered by order field', async () => {
      const mockPrompts = [
        {
          id: '1',
          text: 'First prompt',
          order: 1,
          isActive: true,
          isRequired: true,
        },
        {
          id: '2',
          text: 'Second prompt',
          order: 2,
          isActive: true,
          isRequired: false,
        },
      ];

      jest
        .spyOn(promptRepository, 'find')
        .mockResolvedValue(mockPrompts as any);

      const result = await service.getPrompts();

      expect(result).toEqual(mockPrompts);
      expect(promptRepository.find).toHaveBeenCalledWith({
        order: { order: 'ASC' },
      });
    });
  });

  describe('createPrompt', () => {
    it('should create a new prompt with default values', async () => {
      const createPromptDto: CreatePromptDto = {
        text: 'New prompt',
        order: 1,
      };

      const mockCreatedPrompt = {
        id: 'new-id',
        ...createPromptDto,
        isRequired: true,
        isActive: true,
        maxLength: 500,
      };

      jest
        .spyOn(promptRepository, 'create')
        .mockReturnValue(mockCreatedPrompt as any);
      jest
        .spyOn(promptRepository, 'save')
        .mockResolvedValue(mockCreatedPrompt as any);

      const result = await service.createPrompt(createPromptDto);

      expect(result).toEqual(mockCreatedPrompt);
      expect(promptRepository.create).toHaveBeenCalledWith({
        ...createPromptDto,
        isRequired: true,
        isActive: true,
        maxLength: 500,
      });
    });

    it('should create a prompt with custom values', async () => {
      const createPromptDto: CreatePromptDto = {
        text: 'Optional prompt',
        order: 2,
        isRequired: false,
        isActive: true,
        category: 'lifestyle',
        placeholder: 'Tell us more...',
        maxLength: 300,
      };

      const mockCreatedPrompt = {
        id: 'new-id',
        ...createPromptDto,
      };

      jest
        .spyOn(promptRepository, 'create')
        .mockReturnValue(mockCreatedPrompt as any);
      jest
        .spyOn(promptRepository, 'save')
        .mockResolvedValue(mockCreatedPrompt as any);

      const result = await service.createPrompt(createPromptDto);

      expect(result).toEqual(mockCreatedPrompt);
      expect(promptRepository.create).toHaveBeenCalledWith(createPromptDto);
    });
  });

  describe('updatePrompt', () => {
    it('should update an existing prompt', async () => {
      const promptId = 'existing-id';
      const updatePromptDto: UpdatePromptDto = {
        text: 'Updated prompt text',
        isRequired: false,
      };

      const existingPrompt = {
        id: promptId,
        text: 'Original text',
        order: 1,
        isRequired: true,
        isActive: true,
      };

      const updatedPrompt = {
        ...existingPrompt,
        ...updatePromptDto,
      };

      jest
        .spyOn(promptRepository, 'findOne')
        .mockResolvedValue(existingPrompt as any);
      jest
        .spyOn(promptRepository, 'save')
        .mockResolvedValue(updatedPrompt as any);

      const result = await service.updatePrompt(promptId, updatePromptDto);

      expect(result).toEqual(updatedPrompt);
      expect(promptRepository.findOne).toHaveBeenCalledWith({
        where: { id: promptId },
      });
    });

    it('should throw NotFoundException for non-existent prompt', async () => {
      const promptId = 'non-existent-id';
      const updatePromptDto: UpdatePromptDto = {
        text: 'Updated text',
      };

      jest.spyOn(promptRepository, 'findOne').mockResolvedValue(null);

      await expect(
        service.updatePrompt(promptId, updatePromptDto),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('deletePrompt', () => {
    it('should delete an existing prompt', async () => {
      const promptId = 'existing-id';
      const existingPrompt = {
        id: promptId,
        text: 'Prompt to delete',
      };

      jest
        .spyOn(promptRepository, 'findOne')
        .mockResolvedValue(existingPrompt as any);
      jest.spyOn(promptRepository, 'remove').mockResolvedValue(undefined);

      await service.deletePrompt(promptId);

      expect(promptRepository.findOne).toHaveBeenCalledWith({
        where: { id: promptId },
      });
      expect(promptRepository.remove).toHaveBeenCalledWith(existingPrompt);
    });

    it('should throw NotFoundException for non-existent prompt', async () => {
      const promptId = 'non-existent-id';

      jest.spyOn(promptRepository, 'findOne').mockResolvedValue(null);

      await expect(service.deletePrompt(promptId)).rejects.toThrow(
        NotFoundException,
      );
    });
  });
});
