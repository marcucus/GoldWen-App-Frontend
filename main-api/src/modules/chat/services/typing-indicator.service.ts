import { Injectable } from '@nestjs/common';
import { CustomLoggerService } from '../../../common/logger';

interface TypingState {
  userId: string;
  conversationId: string;
  timeout: NodeJS.Timeout;
}

@Injectable()
export class TypingIndicatorService {
  private typingStates: Map<string, TypingState> = new Map();
  private readonly TYPING_TIMEOUT_MS = 5000; // 5 seconds

  constructor(private readonly logger: CustomLoggerService) {}

  /**
   * Start typing indicator for a user in a conversation
   * Automatically stops after timeout
   */
  startTyping(
    userId: string,
    conversationId: string,
    onTimeout?: (userId: string, conversationId: string) => void,
  ): void {
    const key = `${conversationId}:${userId}`;

    // Clear existing timeout if any
    this.stopTyping(userId, conversationId);

    // Create new timeout
    const timeout = setTimeout(() => {
      this.stopTyping(userId, conversationId);
      if (onTimeout) {
        onTimeout(userId, conversationId);
      }
    }, this.TYPING_TIMEOUT_MS);

    this.typingStates.set(key, {
      userId,
      conversationId,
      timeout,
    });

    this.logger.info('Typing indicator started', {
      userId,
      conversationId,
      timeoutMs: this.TYPING_TIMEOUT_MS,
    });
  }

  /**
   * Stop typing indicator for a user in a conversation
   */
  stopTyping(userId: string, conversationId: string): void {
    const key = `${conversationId}:${userId}`;
    const state = this.typingStates.get(key);

    if (state) {
      clearTimeout(state.timeout);
      this.typingStates.delete(key);

      this.logger.info('Typing indicator stopped', {
        userId,
        conversationId,
      });
    }
  }

  /**
   * Check if a user is currently typing in a conversation
   */
  isTyping(userId: string, conversationId: string): boolean {
    const key = `${conversationId}:${userId}`;
    return this.typingStates.has(key);
  }

  /**
   * Get all users currently typing in a conversation
   */
  getTypingUsers(conversationId: string): string[] {
    const typingUsers: string[] = [];

    for (const [, state] of this.typingStates.entries()) {
      if (state.conversationId === conversationId) {
        typingUsers.push(state.userId);
      }
    }

    return typingUsers;
  }

  /**
   * Clear all typing indicators for a user (e.g., on disconnect)
   */
  clearUserTyping(userId: string): string[] {
    const conversationIds: string[] = [];

    for (const [key, state] of this.typingStates.entries()) {
      if (state.userId === userId) {
        clearTimeout(state.timeout);
        this.typingStates.delete(key);
        conversationIds.push(state.conversationId);
      }
    }

    if (conversationIds.length > 0) {
      this.logger.info('Cleared all typing indicators for user', {
        userId,
        conversationIds,
      });
    }

    return conversationIds;
  }

  /**
   * Clear all typing indicators for a conversation
   */
  clearConversationTyping(conversationId: string): void {
    for (const [key, state] of this.typingStates.entries()) {
      if (state.conversationId === conversationId) {
        clearTimeout(state.timeout);
        this.typingStates.delete(key);
      }
    }

    this.logger.info('Cleared all typing indicators for conversation', {
      conversationId,
    });
  }
}
