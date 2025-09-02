import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MulterModule } from '@nestjs/platform-express';
import { ConfigService } from '@nestjs/config';
import { diskStorage } from 'multer';
import { extname } from 'path';

import { ProfilesController } from './profiles.controller';
import { ProfilesService } from './profiles.service';
import { DatabaseSeederService } from './database-seeder.service';

import { Profile } from '../../database/entities/profile.entity';
import { User } from '../../database/entities/user.entity';
import { PersonalityQuestion } from '../../database/entities/personality-question.entity';
import { PersonalityAnswer } from '../../database/entities/personality-answer.entity';
import { Photo } from '../../database/entities/photo.entity';
import { Prompt } from '../../database/entities/prompt.entity';
import { PromptAnswer } from '../../database/entities/prompt-answer.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Profile,
      User,
      PersonalityQuestion,
      PersonalityAnswer,
      Photo,
      Prompt,
      PromptAnswer,
    ]),
    MulterModule.registerAsync({
      useFactory: (configService: ConfigService) => ({
        storage: diskStorage({
          destination: './uploads/photos',
          filename: (req, file, callback) => {
            const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
            const ext = extname(file.originalname);
            callback(null, `${file.fieldname}-${uniqueSuffix}${ext}`);
          },
        }),
        fileFilter: (req, file, callback) => {
          if (!file.mimetype.match(/\/(jpg|jpeg|png)$/)) {
            callback(new Error('Only image files are allowed!'), false);
          } else {
            callback(null, true);
          }
        },
        limits: {
          fileSize: 10 * 1024 * 1024, // 10MB limit
          files: 6, // Max 6 files
        },
      }),
      inject: [ConfigService],
    }),
  ],
  providers: [ProfilesService, DatabaseSeederService],
  controllers: [ProfilesController],
  exports: [ProfilesService],
})
export class ProfilesModule {}
