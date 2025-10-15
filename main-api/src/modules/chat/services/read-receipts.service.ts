import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In, Not } from 'typeorm';
import { Message } from '../../../database/entities/message.entity';
import { CustomLoggerService } from '../../../common/logger';

interface ReadReceipt {
  messageId: string;
  userId: string;
  readAt: Date;
}

@Injectable()
export class ReadReceiptsService {
  constructor(
    @InjectRepository(Message)
    private messageRepository: Repository<Message>,
    private readonly logger: CustomLoggerService,
  ) {}

  /**
   * Mark multiple messages as read by a user
   * Returns the list of message IDs that were newly marked as read
   */
  async markMessagesAsRead(
    messageIds: string[],
    userId: string,
  ): Promise<string[]> {
    if (messageIds.length === 0) {
      return [];
    }

    const messages = await this.messageRepository.find({
      where: {
        id: In(messageIds),
        isRead: false,
      },
    });

    // Filter out messages sent by the user (can't mark own messages as read)
    const messagesToUpdate = messages.filter((msg) => msg.senderId !== userId);

    if (messagesToUpdate.length === 0) {
      return [];
    }

    const now = new Date();
    const updatedIds: string[] = [];

    for (const message of messagesToUpdate) {
      message.isRead = true;
      message.readAt = now;
      updatedIds.push(message.id);
    }

    await this.messageRepository.save(messagesToUpdate);

    this.logger.info('Messages marked as read', {
      userId,
      messageCount: updatedIds.length,
    });

    return updatedIds;
  }

  /**
   * Get read receipts for messages in a conversation
   */
  async getReadReceipts(messageIds: string[]): Promise<ReadReceipt[]> {
    if (messageIds.length === 0) {
      return [];
    }

    const messages = await this.messageRepository.find({
      where: {
        id: In(messageIds),
        isRead: true,
      },
      select: ['id', 'senderId', 'readAt'],
    });

    return messages.map((msg) => ({
      messageId: msg.id,
      userId: msg.senderId,
      readAt: msg.readAt,
    }));
  }

  /**
   * Get unread message count for a user in a conversation
   */
  async getUnreadCount(chatId: string, userId: string): Promise<number> {
    return this.messageRepository.count({
      where: {
        chatId,
        senderId: Not(userId),
        isRead: false,
      },
    });
  }

  /**
   * Mark all messages in a conversation as read for a user
   */
  async markConversationAsRead(
    chatId: string,
    userId: string,
  ): Promise<number> {
    const result = await this.messageRepository
      .createQueryBuilder()
      .update(Message)
      .set({
        isRead: true,
        readAt: new Date(),
      })
      .where('chatId = :chatId', { chatId })
      .andWhere('senderId != :userId', { userId })
      .andWhere('isRead = :isRead', { isRead: false })
      .execute();

    const affectedCount = result.affected || 0;

    this.logger.info('Conversation marked as read', {
      chatId,
      userId,
      messagesMarked: affectedCount,
    });

    return affectedCount;
  }

  /**
   * Get message read status with details
   */
  async getMessageReadStatus(messageId: string): Promise<{
    isRead: boolean;
    readAt: Date | null;
  } | null> {
    const message = await this.messageRepository.findOne({
      where: { id: messageId },
      select: ['id', 'isRead', 'readAt'],
    });

    if (!message) {
      return null;
    }

    return {
      isRead: message.isRead,
      readAt: message.readAt || null,
    };
  }
}
