import { DataSource } from 'typeorm';
import { ConfigService } from '@nestjs/config';
import { User } from '../database/entities/user.entity';
import { Profile } from '../database/entities/profile.entity';
import { PersonalityQuestion } from '../database/entities/personality-question.entity';
import { PersonalityAnswer } from '../database/entities/personality-answer.entity';
import { Photo } from '../database/entities/photo.entity';
import { Prompt } from '../database/entities/prompt.entity';
import { PromptAnswer } from '../database/entities/prompt-answer.entity';
import { DailySelection } from '../database/entities/daily-selection.entity';
import { Match } from '../database/entities/match.entity';
import { Chat } from '../database/entities/chat.entity';
import { Message } from '../database/entities/message.entity';
import { Subscription } from '../database/entities/subscription.entity';
import { Notification } from '../database/entities/notification.entity';
import { Admin } from '../database/entities/admin.entity';
import { Report } from '../database/entities/report.entity';

export const createDataSource = (configService: ConfigService) => {
  const dbType = process.env.DATABASE_TYPE || 'postgres';
  
  if (dbType === 'sqlite') {
    return new DataSource({
      type: 'sqlite',
      database: process.env.DATABASE_DATABASE || ':memory:',
      entities: [
        User,
        Profile,
        PersonalityQuestion,
        PersonalityAnswer,
        Photo,
        Prompt,
        PromptAnswer,
        DailySelection,
        Match,
        Chat,
        Message,
        Subscription,
        Notification,
        Admin,
        Report,
      ],
      migrations: ['src/database/migrations/*.ts'],
      synchronize: configService.get('app.environment') === 'development',
      logging: configService.get('app.environment') === 'development',
    });
  }
  
  return new DataSource({
    type: 'postgres',
    host: configService.get('database.host'),
    port: configService.get('database.port'),
    username: configService.get('database.username'),
    password: configService.get('database.password'),
    database: configService.get('database.database'),
    entities: [
      User,
      Profile,
      PersonalityQuestion,
      PersonalityAnswer,
      Photo,
      Prompt,
      PromptAnswer,
      DailySelection,
      Match,
      Chat,
      Message,
      Subscription,
      Notification,
      Admin,
      Report,
    ],
    migrations: ['src/database/migrations/*.ts'],
    synchronize: configService.get('app.environment') === 'development',
    logging: configService.get('app.environment') === 'development',
  });
};
