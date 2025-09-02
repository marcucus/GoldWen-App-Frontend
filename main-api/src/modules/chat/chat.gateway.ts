import {
  WebSocketGateway,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  OnGatewayConnection,
  OnGatewayDisconnect,
  OnGatewayInit,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { UseGuards, Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ChatService } from './chat.service';
import { CustomLoggerService } from '../../common/logger';
import { MessageType } from '../../common/enums';

interface AuthenticatedSocket extends Socket {
  userId?: string;
  user?: any;
}

@WebSocketGateway({
  cors: {
    origin: process.env.FRONTEND_URL || true,
    credentials: true,
  },
  namespace: '/chat',
})
export class ChatGateway
  implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer()
  server: Server;

  constructor(
    private readonly chatService: ChatService,
    private readonly jwtService: JwtService,
    private readonly logger: CustomLoggerService,
  ) {}

  afterInit(server: Server) {
    this.logger.info('WebSocket Gateway initialized for chat');
  }

  async handleConnection(client: AuthenticatedSocket, ...args: any[]) {
    try {
      // Extract token from auth object or query
      const token =
        client.handshake.auth?.token || client.handshake.query?.token;

      if (!token) {
      this.logger.warn('WebSocket connection rejected: No token provided');
        client.disconnect();
        return;
      }

      // Verify JWT token
      const payload = this.jwtService.verify(token);
      client.userId = payload.sub;
      client.user = payload;

      this.logger.info('WebSocket client connected', {
        clientId: client.id,
        userId: client.userId,
      });

      // Join user to their personal room for notifications
      await client.join(`user:${client.userId}`);
    } catch (error) {
      this.logger.error('WebSocket authentication failed', error.message, 'ChatGateway');
      client.disconnect();
    }
  }

  handleDisconnect(client: AuthenticatedSocket) {
    this.logger.info('WebSocket client disconnected', {
      clientId: client.id,
      userId: client.userId,
    });
  }

  @SubscribeMessage('join_chat')
  async handleJoinChat(
    @MessageBody() data: { conversationId: string },
    @ConnectedSocket() client: AuthenticatedSocket,
  ) {
    try {
      // Verify user has access to this conversation
      const hasAccess = await this.chatService.verifyUserChatAccess(
        data.conversationId,
        client.userId!,
      );

      if (!hasAccess) {
        client.emit('error', {
          message: 'Access denied to this conversation',
        });
        return;
      }

      // Join the conversation room
      await client.join(`chat:${data.conversationId}`);

      this.logger.info('User joined chat room', {
        userId: client.userId,
        conversationId: data.conversationId,
      });

      client.emit('joined_chat', {
        conversationId: data.conversationId,
      });
    } catch (error) {
      this.logger.error('Error joining chat', error.message, 'ChatGateway');
      client.emit('error', { message: 'Failed to join chat' });
    }
  }

  @SubscribeMessage('leave_chat')
  async handleLeaveChat(
    @MessageBody() data: { conversationId: string },
    @ConnectedSocket() client: AuthenticatedSocket,
  ) {
    await client.leave(`chat:${data.conversationId}`);

    this.logger.info('User left chat room', {
      userId: client.userId,
      conversationId: data.conversationId,
    });

    client.emit('left_chat', {
      conversationId: data.conversationId,
    });
  }

  @SubscribeMessage('send_message')
  async handleSendMessage(
    @MessageBody()
    data: {
      conversationId: string;
      content: string;
      type?: string;
    },
    @ConnectedSocket() client: AuthenticatedSocket,
  ) {
    try {
      // Send message through chat service
      const message = await this.chatService.sendMessage(
        data.conversationId,
        client.userId!,
        {
          content: data.content,
          type: (data.type as MessageType) || MessageType.TEXT,
        },
      );

      // Emit to all users in the conversation
      this.server.to(`chat:${data.conversationId}`).emit('new_message', {
        messageId: message.id,
        conversationId: data.conversationId,
        senderId: client.userId,
        content: data.content,
        type: data.type || 'text',
        timestamp: message.createdAt,
      });

      this.logger.info('Message sent via WebSocket', {
        messageId: message.id,
        senderId: client.userId,
        conversationId: data.conversationId,
      });
    } catch (error) {
      this.logger.error('Error sending message via WebSocket', error.message, 'ChatGateway');
      client.emit('error', { message: 'Failed to send message' });
    }
  }

  @SubscribeMessage('start_typing')
  async handleStartTyping(
    @MessageBody() data: { conversationId: string },
    @ConnectedSocket() client: AuthenticatedSocket,
  ) {
    // Broadcast to other users in the conversation
    client.to(`chat:${data.conversationId}`).emit('user_typing', {
      conversationId: data.conversationId,
      userId: client.userId,
    });
  }

  @SubscribeMessage('stop_typing')
  async handleStopTyping(
    @MessageBody() data: { conversationId: string },
    @ConnectedSocket() client: AuthenticatedSocket,
  ) {
    // Broadcast to other users in the conversation
    client.to(`chat:${data.conversationId}`).emit('user_stopped_typing', {
      conversationId: data.conversationId,
      userId: client.userId,
    });
  }

  @SubscribeMessage('read_message')
  async handleReadMessage(
    @MessageBody()
    data: {
      conversationId: string;
      messageId: string;
    },
    @ConnectedSocket() client: AuthenticatedSocket,
  ) {
    try {
      await this.chatService.markMessageAsRead(
        data.messageId,
        client.userId!,
      );

      // Notify other users in the conversation
      client.to(`chat:${data.conversationId}`).emit('message_read', {
        conversationId: data.conversationId,
        messageId: data.messageId,
        readBy: client.userId,
      });

      this.logger.info('Message marked as read', {
        messageId: data.messageId,
        userId: client.userId,
        conversationId: data.conversationId,
      });
    } catch (error) {
      this.logger.error('Error marking message as read', error.message, 'ChatGateway');
      client.emit('error', { message: 'Failed to mark message as read' });
    }
  }

  // Method to send notifications from other services
  async sendNotificationToUser(
    userId: string,
    notification: {
      type: string;
      title: string;
      body: string;
      data?: any;
    },
  ) {
    this.server.to(`user:${userId}`).emit('notification', notification);

    this.logger.info('Notification sent via WebSocket', {
      userId,
      type: notification.type,
    });
  }

  // Method to notify about new matches
  async notifyNewMatch(
    userId: string,
    matchData: {
      conversationId: string;
      matchedUserId: string;
      matchId: string;
    },
  ) {
    this.server.to(`user:${userId}`).emit('new_match', matchData);

    this.logger.info('New match notification sent', {
      userId,
      matchId: matchData.matchId,
    });
  }

  // Method to notify about chat expiration
  async notifyChatExpiring(
    conversationId: string,
    expiresAt: Date,
  ) {
    this.server.to(`chat:${conversationId}`).emit('chat_expiring', {
      conversationId,
      expiresAt,
    });

    this.logger.info('Chat expiring notification sent', {
      conversationId,
      expiresAt,
    });
  }

  // Method to notify about expired chats
  async notifyChatExpired(conversationId: string) {
    this.server.to(`chat:${conversationId}`).emit('chat_expired', {
      conversationId,
    });

    this.logger.info('Chat expired notification sent', {
      conversationId,
    });
  }
}