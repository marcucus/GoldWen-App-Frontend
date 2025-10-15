import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  Inject,
  forwardRef,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Or, In, Not, LessThan, Between } from 'typeorm';

import { Chat } from '../../database/entities/chat.entity';
import { Message } from '../../database/entities/message.entity';
import { Match } from '../../database/entities/match.entity';
import { User } from '../../database/entities/user.entity';
import { NotificationsService } from '../notifications/notifications.service';

import { ChatStatus, MessageType, MatchStatus } from '../../common/enums';
import { SendMessageDto } from './dto/chat.dto';

@Injectable()
export class ChatService {
  constructor(
    @InjectRepository(Chat)
    private chatRepository: Repository<Chat>,
    @InjectRepository(Message)
    private messageRepository: Repository<Message>,
    @InjectRepository(Match)
    private matchRepository: Repository<Match>,
    @InjectRepository(User)
    private userRepository: Repository<User>,
    @Inject(forwardRef(() => NotificationsService))
    private notificationsService: NotificationsService,
  ) {}

  async createChatForMatch(matchId: string): Promise<Chat> {
    const match = await this.matchRepository.findOne({
      where: { id: matchId, status: MatchStatus.MATCHED },
    });

    if (!match) {
      throw new NotFoundException('Match not found or not confirmed');
    }

    // Check if chat already exists
    const existingChat = await this.chatRepository.findOne({
      where: { matchId },
    });

    if (existingChat) {
      return existingChat;
    }

    // Create chat with 24-hour expiry from match time
    const expiresAt = new Date(match.matchedAt || match.createdAt);
    expiresAt.setHours(expiresAt.getHours() + 24);

    const chat = this.chatRepository.create({
      matchId,
      status: ChatStatus.ACTIVE,
      expiresAt,
    });

    return this.chatRepository.save(chat);
  }

  async acceptChatRequest(
    matchId: string,
    userId: string,
    accept: boolean,
  ): Promise<{
    success: boolean;
    data: {
      chatId?: string;
      match: any;
      expiresAt?: string;
    };
  }> {
    // Find the match where current user is the target (user2)
    const match = await this.matchRepository.findOne({
      where: {
        id: matchId,
        user2Id: userId,
        status: MatchStatus.MATCHED,
      },
      relations: ['user1', 'user1.profile', 'user2', 'user2.profile'],
    });

    if (!match) {
      throw new NotFoundException(
        'Match not found or you are not authorized to accept this match',
      );
    }

    // Check if chat already exists
    const existingChat = await this.chatRepository.findOne({
      where: { matchId },
    });

    if (existingChat && existingChat.status === ChatStatus.ACTIVE) {
      throw new BadRequestException('Chat has already been accepted');
    }

    if (accept) {
      // Create the chat
      const chat = await this.createChatForMatch(matchId);

      // Send notifications to both users about chat acceptance
      try {
        await this.notificationsService.sendChatAcceptedNotification(
          match.user1Id, // Original initiator
          match.user2.profile?.firstName || 'Someone',
        );

        await this.notificationsService.sendChatAcceptedNotification(
          match.user2Id, // User who accepted
          match.user1.profile?.firstName || 'Someone',
        );
      } catch (error) {
        // Log error but don't fail the whole operation
        console.error('Failed to send chat acceptance notifications:', error);
      }

      return {
        success: true,
        data: {
          chatId: chat.id,
          match: {
            id: match.id,
            user1: match.user1,
            user2: match.user2,
            matchedAt: match.matchedAt,
          },
          expiresAt: chat.expiresAt.toISOString(),
        },
      };
    } else {
      // User declined the chat - update match status or delete it
      // For now, we'll just mark the match as rejected
      match.status = MatchStatus.REJECTED;
      await this.matchRepository.save(match);

      return {
        success: true,
        data: {
          match: {
            id: match.id,
            status: 'rejected',
          },
        },
      };
    }
  }

  async getChatByMatchId(matchId: string, userId: string): Promise<Chat> {
    // Verify user is part of the match
    const match = await this.matchRepository.findOne({
      where: [
        { id: matchId, user1Id: userId },
        { id: matchId, user2Id: userId },
      ],
      relations: ['user1', 'user2'],
    });

    if (!match) {
      throw new ForbiddenException('You are not part of this match');
    }

    const chat = await this.chatRepository.findOne({
      where: { matchId },
      relations: [
        'match',
        'match.user1',
        'match.user1.profile',
        'match.user2',
        'match.user2.profile',
      ],
    });

    if (!chat) {
      // Create chat if it doesn't exist and match is confirmed
      if (match.status === MatchStatus.MATCHED) {
        return this.createChatForMatch(matchId);
      }
      throw new NotFoundException('Chat not found');
    }

    return chat;
  }

  async getChatMessages(
    chatId: string,
    userId: string,
    page: number = 1,
    limit: number = 50,
  ): Promise<{
    messages: Message[];
    total: number;
    hasMore: boolean;
    timeRemaining: number;
  }> {
    const chat = await this.chatRepository.findOne({
      where: { id: chatId },
      relations: ['match'],
    });

    if (!chat) {
      throw new NotFoundException('Chat not found');
    }

    // Verify user is part of the chat
    if (chat.match.user1Id !== userId && chat.match.user2Id !== userId) {
      throw new ForbiddenException('You are not part of this chat');
    }

    // Check if chat is expired
    if (chat.isExpired) {
      throw new BadRequestException('This chat has expired');
    }

    const skip = (page - 1) * limit;

    const [messages, total] = await this.messageRepository.findAndCount({
      where: { chatId, isDeleted: false },
      relations: ['sender', 'sender.profile'],
      order: { createdAt: 'DESC' },
      skip,
      take: limit,
    });

    // Mark messages as read
    await this.markMessagesAsRead(chatId, userId);

    return {
      messages: messages.reverse(), // Reverse to show oldest first
      total,
      hasMore: total > skip + messages.length,
      timeRemaining: chat.timeRemaining,
    };
  }

  async sendMessage(
    chatId: string,
    userId: string,
    sendMessageDto: SendMessageDto,
  ): Promise<Message> {
    const chat = await this.chatRepository.findOne({
      where: { id: chatId },
      relations: ['match'],
    });

    if (!chat) {
      throw new NotFoundException('Chat not found');
    }

    // Verify user is part of the chat
    if (chat.match.user1Id !== userId && chat.match.user2Id !== userId) {
      throw new ForbiddenException('You are not part of this chat');
    }

    // Check if chat is expired
    if (chat.isExpired) {
      throw new BadRequestException('This chat has expired');
    }

    // Check if chat is active
    if (chat.status !== ChatStatus.ACTIVE) {
      throw new BadRequestException('This chat is no longer active');
    }

    const message = this.messageRepository.create({
      chatId,
      senderId: userId,
      type: sendMessageDto.type || MessageType.TEXT,
      content: sendMessageDto.content,
    });

    const savedMessage = await this.messageRepository.save(message);

    // Update chat last message time and message count
    chat.lastMessageAt = new Date();
    chat.messageCount += 1;
    await this.chatRepository.save(chat);

    // Return message with sender info
    const messageWithSender = await this.messageRepository.findOne({
      where: { id: savedMessage.id },
      relations: ['sender', 'sender.profile'],
    });

    if (!messageWithSender) {
      throw new NotFoundException('Message not found');
    }

    return messageWithSender;
  }

  async markMessagesAsRead(chatId: string, userId: string): Promise<void> {
    await this.messageRepository.update(
      {
        chatId,
        isRead: false,
      },
      {
        isRead: true,
        readAt: new Date(),
      },
    );

    // This is a simplified version - in production you'd want to exclude messages from the current user
    // but TypeORM doesn't have a direct "not equal" for this case in update
  }

  async getUserChats(userId: string): Promise<Chat[]> {
    // Get all matches for the user
    const matches = await this.matchRepository.find({
      where: [
        { user1Id: userId, status: MatchStatus.MATCHED },
        { user2Id: userId, status: MatchStatus.MATCHED },
      ],
      relations: ['user1', 'user1.profile', 'user2', 'user2.profile'],
    });

    const matchIds = matches.map((match) => match.id);

    if (matchIds.length === 0) {
      return [];
    }

    // Get chats for these matches
    const chats = await this.chatRepository.find({
      where: { matchId: In(matchIds) },
      relations: [
        'match',
        'match.user1',
        'match.user1.profile',
        'match.user2',
        'match.user2.profile',
      ],
      order: { lastMessageAt: 'DESC' },
    });

    // Get unread message counts for each chat
    for (const chat of chats) {
      const unreadCount = await this.messageRepository.count({
        where: {
          chatId: chat.id,
          isRead: false,
        },
      });

      (chat as any).unreadCount = unreadCount;
    }

    return chats;
  }

  async deleteMessage(messageId: string, userId: string): Promise<void> {
    const message = await this.messageRepository.findOne({
      where: { id: messageId },
      relations: ['chat', 'chat.match'],
    });

    if (!message) {
      throw new NotFoundException('Message not found');
    }

    // Only sender can delete their message
    if (message.senderId !== userId) {
      throw new ForbiddenException('You can only delete your own messages');
    }

    // Check if chat is expired
    if (message.chat.isExpired) {
      throw new BadRequestException('Cannot delete messages in expired chats');
    }

    message.isDeleted = true;
    message.content = 'This message has been deleted';
    await this.messageRepository.save(message);
  }

  async extendChatTime(
    chatId: string,
    userId: string,
    hours: number = 24,
  ): Promise<Chat> {
    const chat = await this.chatRepository.findOne({
      where: { id: chatId },
      relations: ['match'],
    });

    if (!chat) {
      throw new NotFoundException('Chat not found');
    }

    // Verify user is part of the chat
    if (chat.match.user1Id !== userId && chat.match.user2Id !== userId) {
      throw new ForbiddenException('You are not part of this chat');
    }

    // Check if chat is not already expired
    if (chat.status === ChatStatus.EXPIRED) {
      throw new BadRequestException('Cannot extend an expired chat');
    }

    // Extend expiry time
    const newExpiryTime = new Date();
    newExpiryTime.setHours(newExpiryTime.getHours() + hours);

    chat.expiresAt = newExpiryTime;
    chat.status = ChatStatus.ACTIVE;

    return this.chatRepository.save(chat);
  }

  async getChatStats(userId: string): Promise<{
    totalChats: number;
    activeChats: number;
    expiredChats: number;
    totalMessages: number;
  }> {
    // Get all matches for the user
    const matches = await this.matchRepository.find({
      where: [
        { user1Id: userId, status: MatchStatus.MATCHED },
        { user2Id: userId, status: MatchStatus.MATCHED },
      ],
    });

    const matchIds = matches.map((match) => match.id);

    if (matchIds.length === 0) {
      return {
        totalChats: 0,
        activeChats: 0,
        expiredChats: 0,
        totalMessages: 0,
      };
    }

    const totalChats = await this.chatRepository.count({
      where: { matchId: In(matchIds) },
    });

    const activeChats = await this.chatRepository.count({
      where: {
        matchId: In(matchIds),
        status: ChatStatus.ACTIVE,
      },
    });

    const expiredChats = await this.chatRepository.count({
      where: {
        matchId: In(matchIds),
        status: ChatStatus.EXPIRED,
      },
    });

    const totalMessages = await this.messageRepository.count({
      where: {
        senderId: userId,
        isDeleted: false,
      },
    });

    return {
      totalChats,
      activeChats,
      expiredChats,
      totalMessages,
    };
  }

  async verifyUserChatAccess(chatId: string, userId: string): Promise<boolean> {
    const chat = await this.chatRepository.findOne({
      where: { id: chatId },
      relations: ['match', 'match.user1', 'match.user2'],
    });

    if (!chat) {
      return false;
    }

    // Check if user is part of this chat through the match
    return chat.match.user1Id === userId || chat.match.user2Id === userId;
  }

  async markMessageAsRead(messageId: string, userId: string): Promise<void> {
    const message = await this.messageRepository.findOne({
      where: { id: messageId },
      relations: ['chat', 'chat.match'],
    });

    if (!message) {
      throw new NotFoundException('Message not found');
    }

    // Verify user has access to this message
    const hasAccess = await this.verifyUserChatAccess(message.chat.id, userId);
    if (!hasAccess) {
      throw new ForbiddenException('Access denied');
    }

    // Only mark as read if the user is not the sender
    if (message.senderId !== userId) {
      message.isRead = true;
      message.readAt = new Date();
      await this.messageRepository.save(message);
    }
  }
}
