import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Param,
  Body,
  Query,
  UseGuards,
  Request,
  BadRequestException,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiResponse,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ChatService } from '../chat/chat.service';
import { MatchingService } from '../matching/matching.service';
import { SendMessageDto, GetMessagesDto } from '../chat/dto/chat.dto';
import { CreateConversationDto } from './dto/conversations.dto';

@ApiTags('conversations')
@Controller('conversations')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class ConversationsController {
  constructor(
    private readonly chatService: ChatService,
    private readonly matchingService: MatchingService,
  ) {}

  @Post()
  @ApiOperation({ summary: 'Create conversation for mutual match' })
  @ApiResponse({
    status: 201,
    description: 'Conversation created successfully',
  })
  async createConversation(
    @Request() req: any,
    @Body() createConversationDto: CreateConversationDto,
  ) {
    // Verify mutual match exists
    const match = await this.matchingService.getMutualMatch(
      req.user.id,
      createConversationDto.matchId,
    );

    if (!match) {
      throw new BadRequestException('No mutual match found');
    }

    // Create or get existing chat for this match
    const chat = await this.chatService.createChatForMatch(match.id);

    return {
      conversationId: chat.id,
      matchId: match.id,
      expiresAt: chat.expiresAt,
      timeRemaining: chat.timeRemaining,
      status: chat.status,
    };
  }

  @Get()
  @ApiOperation({ summary: 'Get all user conversations' })
  @ApiResponse({
    status: 200,
    description: 'Conversations retrieved successfully',
  })
  async getConversations(@Request() req: any) {
    return this.chatService.getUserChats(req.user.id);
  }

  @Get(':id/messages')
  @ApiOperation({ summary: 'Get conversation messages' })
  @ApiResponse({ status: 200, description: 'Messages retrieved successfully' })
  async getConversationMessages(
    @Request() req: any,
    @Param('id') conversationId: string,
    @Query() query: GetMessagesDto,
  ) {
    return this.chatService.getChatMessages(
      conversationId,
      req.user.id,
      query.page,
      query.limit,
    );
  }

  @Post(':id/messages')
  @ApiOperation({ summary: 'Send a message in conversation' })
  @ApiResponse({ status: 201, description: 'Message sent successfully' })
  async sendMessage(
    @Request() req: any,
    @Param('id') conversationId: string,
    @Body() sendMessageDto: SendMessageDto,
  ) {
    return this.chatService.sendMessage(
      conversationId,
      req.user.id,
      sendMessageDto,
    );
  }

  @Put(':id/messages/read')
  @ApiOperation({ summary: 'Mark messages as read' })
  @ApiResponse({ status: 200, description: 'Messages marked as read' })
  async markMessagesAsRead(
    @Request() req: any,
    @Param('id') conversationId: string,
  ) {
    await this.chatService.markMessagesAsRead(conversationId, req.user.id);
    return { message: 'Messages marked as read' };
  }

  @Delete(':id/messages/:messageId')
  @ApiOperation({ summary: 'Delete a message' })
  @ApiResponse({ status: 200, description: 'Message deleted successfully' })
  async deleteMessage(
    @Request() req: any,
    @Param('messageId') messageId: string,
  ) {
    await this.chatService.deleteMessage(messageId, req.user.id);
    return { message: 'Message deleted successfully' };
  }
}
