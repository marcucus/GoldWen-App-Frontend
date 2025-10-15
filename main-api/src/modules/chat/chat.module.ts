import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { JwtModule } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';

import { ChatController } from './chat.controller';
import { ChatService } from './chat.service';
import { ChatGateway } from './chat.gateway';
import { ChatScheduler } from './chat.scheduler';
import { TypingIndicatorService } from './services/typing-indicator.service';
import { ReadReceiptsService } from './services/read-receipts.service';
import { PresenceService } from './services/presence.service';
import { NotificationsModule } from '../notifications/notifications.module';
import { ProfilesModule } from '../profiles/profiles.module';

import { Chat } from '../../database/entities/chat.entity';
import { Message } from '../../database/entities/message.entity';
import { Match } from '../../database/entities/match.entity';
import { User } from '../../database/entities/user.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([Chat, Message, Match, User]),
    JwtModule.registerAsync({
      useFactory: (configService: ConfigService) => ({
        secret: configService.get('jwt.secret'),
        signOptions: {
          expiresIn: configService.get('jwt.expiresIn'),
        },
      }),
      inject: [ConfigService],
    }),
    forwardRef(() => NotificationsModule),
    ProfilesModule,
  ],
  providers: [
    ChatService,
    ChatGateway,
    ChatScheduler,
    TypingIndicatorService,
    ReadReceiptsService,
    PresenceService,
  ],
  controllers: [ChatController],
  exports: [
    ChatService,
    ChatGateway,
    ChatScheduler,
    TypingIndicatorService,
    ReadReceiptsService,
    PresenceService,
  ],
})
export class ChatModule {}
