import { Module } from '@nestjs/common';
import { ConversationsController } from './conversations.controller';
import { ChatModule } from '../chat/chat.module';
import { MatchingModule } from '../matching/matching.module';

@Module({
  imports: [ChatModule, MatchingModule],
  controllers: [ConversationsController],
})
export class ConversationsModule {}
