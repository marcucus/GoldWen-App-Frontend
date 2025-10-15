import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { PresenceService } from '../services/presence.service';
import { User } from '../../../database/entities/user.entity';
import { CustomLoggerService } from '../../../common/logger';

describe('PresenceService', () => {
  let service: PresenceService;
  let userRepository: Repository<User>;
  let logger: CustomLoggerService;

  const mockUserRepository = {
    update: jest.fn(),
    findOne: jest.fn(),
  };

  const mockLogger = {
    info: jest.fn(),
    error: jest.fn(),
    warn: jest.fn(),
    debug: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PresenceService,
        {
          provide: getRepositoryToken(User),
          useValue: mockUserRepository,
        },
        {
          provide: CustomLoggerService,
          useValue: mockLogger,
        },
      ],
    }).compile();

    service = module.get<PresenceService>(PresenceService);
    userRepository = module.get<Repository<User>>(getRepositoryToken(User));
    logger = module.get<CustomLoggerService>(CustomLoggerService);

    jest.clearAllMocks();
  });

  describe('setUserOnline', () => {
    it('should mark user as online', async () => {
      const userId = 'user-1';

      await service.setUserOnline(userId);

      expect(service.isUserOnline(userId)).toBe(true);
      expect(mockUserRepository.update).toHaveBeenCalledWith(
        userId,
        expect.objectContaining({
          lastActiveAt: expect.any(Date),
        }),
      );
      expect(mockLogger.info).toHaveBeenCalledWith(
        'User marked as online',
        expect.objectContaining({ userId }),
      );
    });
  });

  describe('setUserOffline', () => {
    it('should mark user as offline', async () => {
      const userId = 'user-1';

      await service.setUserOnline(userId);
      expect(service.isUserOnline(userId)).toBe(true);

      await service.setUserOffline(userId);
      expect(service.isUserOnline(userId)).toBe(false);
      expect(mockLogger.info).toHaveBeenCalledWith(
        'User marked as offline',
        expect.objectContaining({ userId }),
      );
    });
  });

  describe('updateUserActivity', () => {
    it('should update user activity timestamp', async () => {
      const userId = 'user-1';

      await service.setUserOnline(userId);
      const firstCheck = service.isUserOnline(userId);

      service.updateUserActivity(userId);
      const secondCheck = service.isUserOnline(userId);

      expect(firstCheck).toBe(true);
      expect(secondCheck).toBe(true);
    });
  });

  describe('isUserOnline', () => {
    it('should return true for recently active user', async () => {
      const userId = 'user-1';

      await service.setUserOnline(userId);

      expect(service.isUserOnline(userId)).toBe(true);
    });

    it('should return false for user who has not been active', () => {
      const userId = 'user-1';

      expect(service.isUserOnline(userId)).toBe(false);
    });

    it('should return false for user whose activity is stale', async () => {
      jest.useFakeTimers();
      const userId = 'user-1';

      await service.setUserOnline(userId);
      expect(service.isUserOnline(userId)).toBe(true);

      // Advance time beyond threshold (30 seconds)
      jest.advanceTimersByTime(35000);

      expect(service.isUserOnline(userId)).toBe(false);

      jest.useRealTimers();
    });
  });

  describe('getLastSeen', () => {
    it('should get last seen from in-memory state', async () => {
      const userId = 'user-1';

      await service.setUserOnline(userId);
      const lastSeen = await service.getLastSeen(userId);

      expect(lastSeen).toBeInstanceOf(Date);
    });

    it('should get last seen from database when not in memory', async () => {
      const userId = 'user-1';
      const lastActiveAt = new Date();

      mockUserRepository.findOne.mockResolvedValue({
        id: userId,
        lastActiveAt,
      });

      const lastSeen = await service.getLastSeen(userId);

      expect(lastSeen).toEqual(lastActiveAt);
    });

    it('should return null when user not found', async () => {
      const userId = 'user-1';

      mockUserRepository.findOne.mockResolvedValue(null);

      const lastSeen = await service.getLastSeen(userId);

      expect(lastSeen).toBeNull();
    });
  });

  describe('getPresenceStatus', () => {
    it('should get presence status for online user', async () => {
      const userId = 'user-1';

      await service.setUserOnline(userId);
      const status = await service.getPresenceStatus(userId);

      expect(status.userId).toBe(userId);
      expect(status.isOnline).toBe(true);
      expect(status.lastSeen).toBeInstanceOf(Date);
    });

    it('should get presence status for offline user', async () => {
      const userId = 'user-1';
      const lastActiveAt = new Date();

      mockUserRepository.findOne.mockResolvedValue({
        id: userId,
        lastActiveAt,
      });

      const status = await service.getPresenceStatus(userId);

      expect(status.userId).toBe(userId);
      expect(status.isOnline).toBe(false);
      expect(status.lastSeen).toEqual(lastActiveAt);
    });
  });

  describe('getMultiplePresenceStatus', () => {
    it('should get presence status for multiple users', async () => {
      const userIds = ['user-1', 'user-2'];

      await service.setUserOnline('user-1');
      mockUserRepository.findOne.mockResolvedValue({
        id: 'user-2',
        lastActiveAt: new Date(),
      });

      const statuses = await service.getMultiplePresenceStatus(userIds);

      expect(statuses).toHaveLength(2);
      expect(statuses[0].userId).toBe('user-1');
      expect(statuses[0].isOnline).toBe(true);
      expect(statuses[1].userId).toBe('user-2');
    });
  });

  describe('getOnlineUsers', () => {
    it('should get all currently online users', async () => {
      await service.setUserOnline('user-1');
      await service.setUserOnline('user-2');
      await service.setUserOnline('user-3');

      const onlineUsers = service.getOnlineUsers();

      expect(onlineUsers).toHaveLength(3);
      expect(onlineUsers).toContain('user-1');
      expect(onlineUsers).toContain('user-2');
      expect(onlineUsers).toContain('user-3');
    });

    it('should exclude stale users', async () => {
      jest.useFakeTimers();

      await service.setUserOnline('user-1');
      await service.setUserOnline('user-2');

      // Advance time beyond threshold for user-1
      jest.advanceTimersByTime(35000);

      await service.setUserOnline('user-2'); // Refresh user-2

      const onlineUsers = service.getOnlineUsers();

      expect(onlineUsers).toContain('user-2');
      expect(onlineUsers).not.toContain('user-1');

      jest.useRealTimers();
    });
  });

  describe('cleanupStaleStatuses', () => {
    it('should clean up stale presence statuses', async () => {
      jest.useFakeTimers();

      await service.setUserOnline('user-1');
      await service.setUserOnline('user-2');

      // Advance time to make statuses stale (60+ seconds)
      jest.advanceTimersByTime(65000);

      const cleaned = service.cleanupStaleStatuses();

      expect(cleaned).toBe(2);
      expect(mockLogger.info).toHaveBeenCalledWith(
        'Cleaned up stale presence statuses',
        expect.objectContaining({ count: 2 }),
      );

      jest.useRealTimers();
    });

    it('should not clean up recent statuses', async () => {
      await service.setUserOnline('user-1');

      const cleaned = service.cleanupStaleStatuses();

      expect(cleaned).toBe(0);
    });
  });

  describe('formatLastSeen', () => {
    it('should format recent activity as "À l\'instant"', () => {
      const now = new Date();
      const result = service.formatLastSeen(now);

      expect(result).toBe("À l'instant");
    });

    it('should format minutes ago', () => {
      const fiveMinutesAgo = new Date(Date.now() - 5 * 60000);
      const result = service.formatLastSeen(fiveMinutesAgo);

      expect(result).toBe('Il y a 5 min');
    });

    it('should format hours ago', () => {
      const twoHoursAgo = new Date(Date.now() - 2 * 3600000);
      const result = service.formatLastSeen(twoHoursAgo);

      expect(result).toBe('Il y a 2h');
    });

    it('should format yesterday', () => {
      const yesterday = new Date(Date.now() - 24 * 3600000);
      const result = service.formatLastSeen(yesterday);

      expect(result).toBe('Hier');
    });

    it('should format days ago', () => {
      const threeDaysAgo = new Date(Date.now() - 3 * 24 * 3600000);
      const result = service.formatLastSeen(threeDaysAgo);

      expect(result).toBe('Il y a 3 jours');
    });

    it('should format date for old activity', () => {
      const tenDaysAgo = new Date(Date.now() - 10 * 24 * 3600000);
      const result = service.formatLastSeen(tenDaysAgo);

      expect(result).toMatch(/\d{2}\/\d{2}\/\d{4}/); // French date format
    });
  });
});
