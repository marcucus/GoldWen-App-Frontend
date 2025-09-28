import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MulterModule } from '@nestjs/platform-express';
import { ConfigService } from '@nestjs/config';
import { diskStorage } from 'multer';
import { extname } from 'path';

import { ProfilesController } from './profiles.controller';
import { PersonalityController } from './personality.controller';
import { ProfilesService } from './profiles.service';
import { DatabaseSeederService } from './database-seeder.service';
import { ProfileCompletionGuard } from '../auth/guards/profile-completion.guard';

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
          destination: (req, file, callback) => {
            const uploadPath = './uploads/photos';
            // Ensure directory exists
            if (!require('fs').existsSync(uploadPath)) {
              require('fs').mkdirSync(uploadPath, { recursive: true });
            }
            callback(null, uploadPath);
          },
          filename: (req, file, callback) => {
            const uniqueSuffix =
              Date.now() + '-' + Math.round(Math.random() * 1e9);
            const ext = extname(file.originalname);
            callback(null, `photo-${uniqueSuffix}${ext}`);
          },
        }),
        fileFilter: (req, file, callback) => {
          console.log('File upload attempt:', {
            originalname: file.originalname,
            mimetype: file.mimetype,
            size: file.size
          });
          
          // Check for valid image MIME types
          const validMimeTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
          
          // Primary check: MIME type
          if (validMimeTypes.includes(file.mimetype.toLowerCase())) {
            console.log('Accepted file type:', file.mimetype);
            callback(null, true);
            return;
          }
          
          // Fallback: Check file extension if MIME type is application/octet-stream
          if (file.mimetype === 'application/octet-stream' && file.originalname) {
            const extension = file.originalname.split('.').pop()?.toLowerCase();
            const validExtensions = ['jpg', 'jpeg', 'png', 'webp'];
            
            if (extension && validExtensions.includes(extension)) {
              console.log('Accepted file based on extension:', extension);
              callback(null, true);
              return;
            }
          }
          
          // Reject if neither MIME type nor extension is valid
          console.log('Rejected file type:', file.mimetype);
          callback(
            new Error(`Only image files (JPEG, PNG, WebP) are allowed! Received: ${file.mimetype}`),
            false,
          );
        },
        limits: {
          fileSize: 10 * 1024 * 1024, // 10MB limit
          files: 6, // Max 6 files
        },
      }),
      inject: [ConfigService],
    }),
  ],
  providers: [ProfilesService, DatabaseSeederService, ProfileCompletionGuard],
  controllers: [ProfilesController, PersonalityController],
  exports: [ProfilesService, ProfileCompletionGuard],
})
export class ProfilesModule {}
