import { Test, TestingModule } from '@nestjs/testing';
import { TypingIndicatorService } from '../services/typing-indicator.service';
import { CustomLoggerService } from '../../../common/logger';

describe('TypingIndicatorService', () => {
  let service: TypingIndicatorService;
  let logger: CustomLoggerService;

  const mockLogger = {
    info: jest.fn(),
    error: jest.fn(),
    warn: jest.fn(),
    debug: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        TypingIndicatorService,
        {
          provide: CustomLoggerService,
          useValue: mockLogger,
        },
      ],
    }).compile();

    service = module.get<TypingIndicatorService>(TypingIndicatorService);
    logger = module.get<CustomLoggerService>(CustomLoggerService);

    jest.clearAllMocks();
  });

  afterEach(() => {
    // Clear all timeouts
    jest.clearAllTimers();
  });

  describe('startTyping', () => {
    it('should start typing indicator for a user', () => {
      const userId = 'user-1';
      const conversationId = 'conv-1';

      service.startTyping(userId, conversationId);

      expect(service.isTyping(userId, conversationId)).toBe(true);
      expect(mockLogger.info).toHaveBeenCalledWith(
        'Typing indicator started',
        expect.objectContaining({
          userId,
          conversationId,
        }),
      );
    });

    it('should clear existing timeout when starting typing again', () => {
      const userId = 'user-1';
      const conversationId = 'conv-1';

      service.startTyping(userId, conversationId);
      const firstTyping = service.isTyping(userId, conversationId);

      service.startTyping(userId, conversationId);
      const secondTyping = service.isTyping(userId, conversationId);

      expect(firstTyping).toBe(true);
      expect(secondTyping).toBe(true);
      expect(mockLogger.info).toHaveBeenCalledTimes(3); // start, stop, start
    });

    it('should call onTimeout callback after timeout', (done) => {
      jest.useFakeTimers();
      const userId = 'user-1';
      const conversationId = 'conv-1';
      const onTimeout = jest.fn();

      service.startTyping(userId, conversationId, onTimeout);

      expect(service.isTyping(userId, conversationId)).toBe(true);

      jest.advanceTimersByTime(5000);

      expect(service.isTyping(userId, conversationId)).toBe(false);
      expect(onTimeout).toHaveBeenCalledWith(userId, conversationId);

      jest.useRealTimers();
      done();
    });
  });

  describe('stopTyping', () => {
    it('should stop typing indicator for a user', () => {
      const userId = 'user-1';
      const conversationId = 'conv-1';

      service.startTyping(userId, conversationId);
      expect(service.isTyping(userId, conversationId)).toBe(true);

      service.stopTyping(userId, conversationId);
      expect(service.isTyping(userId, conversationId)).toBe(false);
    });

    it('should not error when stopping non-existent typing', () => {
      const userId = 'user-1';
      const conversationId = 'conv-1';

      expect(() => {
        service.stopTyping(userId, conversationId);
      }).not.toThrow();
    });
  });

  describe('isTyping', () => {
    it('should return true when user is typing', () => {
      const userId = 'user-1';
      const conversationId = 'conv-1';

      service.startTyping(userId, conversationId);
      expect(service.isTyping(userId, conversationId)).toBe(true);
    });

    it('should return false when user is not typing', () => {
      const userId = 'user-1';
      const conversationId = 'conv-1';

      expect(service.isTyping(userId, conversationId)).toBe(false);
    });
  });

  describe('getTypingUsers', () => {
    it('should return all users typing in a conversation', () => {
      const conversationId = 'conv-1';
      const user1 = 'user-1';
      const user2 = 'user-2';

      service.startTyping(user1, conversationId);
      service.startTyping(user2, conversationId);

      const typingUsers = service.getTypingUsers(conversationId);

      expect(typingUsers).toHaveLength(2);
      expect(typingUsers).toContain(user1);
      expect(typingUsers).toContain(user2);
    });

    it('should return empty array when no users are typing', () => {
      const conversationId = 'conv-1';
      const typingUsers = service.getTypingUsers(conversationId);

      expect(typingUsers).toEqual([]);
    });
  });

  describe('clearUserTyping', () => {
    it('should clear all typing indicators for a user', () => {
      const userId = 'user-1';
      const conv1 = 'conv-1';
      const conv2 = 'conv-2';

      service.startTyping(userId, conv1);
      service.startTyping(userId, conv2);

      const clearedConversations = service.clearUserTyping(userId);

      expect(clearedConversations).toHaveLength(2);
      expect(clearedConversations).toContain(conv1);
      expect(clearedConversations).toContain(conv2);
      expect(service.isTyping(userId, conv1)).toBe(false);
      expect(service.isTyping(userId, conv2)).toBe(false);
    });

    it('should return empty array when user has no active typing', () => {
      const userId = 'user-1';
      const clearedConversations = service.clearUserTyping(userId);

      expect(clearedConversations).toEqual([]);
    });
  });

  describe('clearConversationTyping', () => {
    it('should clear all typing indicators for a conversation', () => {
      const conversationId = 'conv-1';
      const user1 = 'user-1';
      const user2 = 'user-2';

      service.startTyping(user1, conversationId);
      service.startTyping(user2, conversationId);

      service.clearConversationTyping(conversationId);

      expect(service.isTyping(user1, conversationId)).toBe(false);
      expect(service.isTyping(user2, conversationId)).toBe(false);
    });
  });
});
