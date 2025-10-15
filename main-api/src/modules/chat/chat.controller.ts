import {
  Controller,
  Get,
  Post,
  Delete,
  Put,
  Param,
  Body,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiResponse,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ProfileCompletionGuard } from '../auth/guards/profile-completion.guard';
import { ChatService } from './chat.service';
import {
  SendMessageDto,
  GetMessagesDto,
  ExtendChatDto,
  AcceptChatDto,
} from './dto/chat.dto';

@ApiTags('chat')
@Controller('chat')
@UseGuards(JwtAuthGuard, ProfileCompletionGuard)
@ApiBearerAuth()
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Get()
  @ApiOperation({ summary: 'Get all user chats' })
  @ApiResponse({ status: 200, description: 'Chats retrieved successfully' })
  async getUserChats(@Request() req: any) {
    return this.chatService.getUserChats(req.user.id);
  }

  @Get('stats')
  @ApiOperation({ summary: 'Get chat statistics' })
  @ApiResponse({
    status: 200,
    description: 'Chat statistics retrieved successfully',
  })
  async getChatStats(@Request() req: any) {
    return this.chatService.getChatStats(req.user.id);
  }

  @Get('match/:matchId')
  @ApiOperation({ summary: 'Get chat by match ID' })
  @ApiResponse({ status: 200, description: 'Chat retrieved successfully' })
  async getChatByMatchId(
    @Request() req: any,
    @Param('matchId') matchId: string,
  ) {
    return this.chatService.getChatByMatchId(matchId, req.user.id);
  }

  @Get(':chatId/messages')
  @ApiOperation({ summary: 'Get chat messages' })
  @ApiResponse({ status: 200, description: 'Messages retrieved successfully' })
  async getChatMessages(
    @Request() req: any,
    @Param('chatId') chatId: string,
    @Query() query: GetMessagesDto,
  ) {
    return this.chatService.getChatMessages(
      chatId,
      req.user.id,
      query.page,
      query.limit,
    );
  }

  @Post(':chatId/messages')
  @ApiOperation({ summary: 'Send a message' })
  @ApiResponse({ status: 201, description: 'Message sent successfully' })
  async sendMessage(
    @Request() req: any,
    @Param('chatId') chatId: string,
    @Body() sendMessageDto: SendMessageDto,
  ) {
    return this.chatService.sendMessage(chatId, req.user.id, sendMessageDto);
  }

  @Put(':chatId/messages/read')
  @ApiOperation({ summary: 'Mark messages as read' })
  @ApiResponse({ status: 200, description: 'Messages marked as read' })
  async markMessagesAsRead(
    @Request() req: any,
    @Param('chatId') chatId: string,
  ) {
    await this.chatService.markMessagesAsRead(chatId, req.user.id);
    return { message: 'Messages marked as read' };
  }

  @Delete('messages/:messageId')
  @ApiOperation({ summary: 'Delete a message' })
  @ApiResponse({ status: 200, description: 'Message deleted successfully' })
  async deleteMessage(
    @Request() req: any,
    @Param('messageId') messageId: string,
  ) {
    await this.chatService.deleteMessage(messageId, req.user.id);
    return { message: 'Message deleted successfully' };
  }

  @Put(':chatId/extend')
  @ApiOperation({ summary: 'Extend chat expiry time (premium feature)' })
  @ApiResponse({ status: 200, description: 'Chat time extended successfully' })
  async extendChatTime(
    @Request() req: any,
    @Param('chatId') chatId: string,
    @Body() extendChatDto: ExtendChatDto,
  ) {
    return this.chatService.extendChatTime(
      chatId,
      req.user.id,
      extendChatDto.hours,
    );
  }

  @Post('accept/:matchId')
  @ApiOperation({ summary: 'Accept or decline a chat request from a match' })
  @ApiResponse({
    status: 200,
    description: 'Chat request processed successfully',
  })
  async acceptChatRequest(
    @Request() req: any,
    @Param('matchId') matchId: string,
    @Body() acceptChatDto: AcceptChatDto,
  ) {
    return this.chatService.acceptChatRequest(
      matchId,
      req.user.id,
      acceptChatDto.accept,
    );
  }
}
