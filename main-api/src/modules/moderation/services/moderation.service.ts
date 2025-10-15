import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Photo } from '../../../database/entities/photo.entity';
import { User } from '../../../database/entities/user.entity';
import { AiModerationService } from './ai-moderation.service';
import { ImageModerationService } from './image-moderation.service';
import { ForbiddenWordsService } from './forbidden-words.service';
import { NotificationsService } from '../../notifications/notifications.service';
import { CustomLoggerService } from '../../../common/logger';
import { NotificationType } from '../../../common/enums';

@Injectable()
export class ModerationService {
  constructor(
    @InjectRepository(Photo)
    private photoRepository: Repository<Photo>,
    @InjectRepository(User)
    private userRepository: Repository<User>,
    private aiModerationService: AiModerationService,
    private imageModerationService: ImageModerationService,
    private forbiddenWordsService: ForbiddenWordsService,
    private notificationsService: NotificationsService,
    private logger: CustomLoggerService,
  ) {}

  /**
   * Moderate a photo by ID
   */
  async moderatePhoto(photoId: string): Promise<{
    photoId: string;
    approved: boolean;
    reason?: string;
  }> {
    const photo = await this.photoRepository.findOne({
      where: { id: photoId },
      relations: ['profile'],
    });

    if (!photo) {
      throw new NotFoundException('Photo not found');
    }

    // Get the full path to the photo
    const photoPath = photo.url.startsWith('/')
      ? photo.url
      : `./uploads/${photo.filename}`;

    const moderationResult =
      await this.imageModerationService.moderateImage(photoPath);

    // Update photo approval status
    photo.isApproved = !moderationResult.shouldBlock;
    if (moderationResult.shouldBlock) {
      photo.rejectionReason = moderationResult.reason || null;
    } else {
      photo.rejectionReason = null;
    }

    await this.photoRepository.save(photo);

    // If photo is blocked, notify the user
    if (moderationResult.shouldBlock) {
      await this.handlePhotoBlocked(
        photo,
        moderationResult.reason || 'Inappropriate content detected',
      );
    }

    this.logger.logBusinessEvent('photo_moderation_completed', {
      photoId,
      approved: photo.isApproved,
      flagged: moderationResult.flagged,
      shouldBlock: moderationResult.shouldBlock,
    });

    return {
      photoId,
      approved: photo.isApproved,
      reason: photo.rejectionReason || undefined,
    };
  }

  /**
   * Get photo moderation status
   */
  async getPhotoModerationStatus(photoId: string): Promise<{
    photoId: string;
    isApproved: boolean;
    rejectionReason?: string;
  }> {
    const photo = await this.photoRepository.findOne({
      where: { id: photoId },
    });

    if (!photo) {
      throw new NotFoundException('Photo not found');
    }

    return {
      photoId,
      isApproved: photo.isApproved,
      rejectionReason: photo.rejectionReason || undefined,
    };
  }

  /**
   * Moderate text content (for messages, profile descriptions, etc.)
   */
  async moderateTextContent(
    text: string,
    userId?: string,
  ): Promise<{
    approved: boolean;
    reason?: string;
  }> {
    // First check for forbidden words
    const forbiddenWordsResult = this.forbiddenWordsService.checkText(text);
    if (forbiddenWordsResult.containsForbiddenWords) {
      this.logger.logSecurityEvent('text_content_blocked', {
        userId,
        reason: 'forbidden_words',
        foundWords: forbiddenWordsResult.foundWords,
      });

      if (userId) {
        await this.handleTextContentBlocked(
          userId,
          forbiddenWordsResult.reason || 'Content contains forbidden words',
        );
      }

      return {
        approved: false,
        reason: forbiddenWordsResult.reason,
      };
    }

    // Then check with AI moderation
    const moderationResult = await this.aiModerationService.moderateText(text);

    if (moderationResult.shouldBlock) {
      this.logger.logSecurityEvent('text_content_blocked', {
        userId,
        flagged: moderationResult.flagged,
        categories: moderationResult.categories,
      });

      if (userId) {
        await this.handleTextContentBlocked(
          userId,
          moderationResult.reason || 'Inappropriate content detected',
        );
      }
    }

    return {
      approved: !moderationResult.shouldBlock,
      reason: moderationResult.shouldBlock
        ? moderationResult.reason
        : undefined,
    };
  }

  /**
   * Moderate text content in batch
   */
  async moderateTextContentBatch(
    texts: string[],
  ): Promise<Array<{ approved: boolean; reason?: string }>> {
    // First check all texts for forbidden words
    const forbiddenWordsResults =
      this.forbiddenWordsService.checkTextBatch(texts);

    // Check if any contain forbidden words
    const forbiddenIndices = forbiddenWordsResults
      .map((result, index) => ({ result, index }))
      .filter(({ result }) => result.containsForbiddenWords);

    // If any texts contain forbidden words, return early with rejections
    if (forbiddenIndices.length > 0) {
      return texts.map((text, index) => {
        const forbiddenResult = forbiddenWordsResults[index];
        if (forbiddenResult.containsForbiddenWords) {
          return {
            approved: false,
            reason: forbiddenResult.reason,
          };
        }
        // For texts without forbidden words, still need to check AI moderation
        // We'll process these below
        return { approved: true };
      });
    }

    // Then check with AI moderation for texts that passed forbidden words check
    const results = await this.aiModerationService.moderateTextBatch(texts);

    return results.map((result) => ({
      approved: !result.shouldBlock,
      reason: result.shouldBlock ? result.reason : undefined,
    }));
  }

  /**
   * Handle when a photo is blocked
   */
  private async handlePhotoBlocked(
    photo: Photo,
    reason: string,
  ): Promise<void> {
    try {
      // Find the user associated with this photo's profile
      const profile = photo.profile;
      if (profile && profile.userId) {
        // Send notification to user
        await this.notificationsService.createNotification({
          userId: profile.userId,
          type: NotificationType.SYSTEM,
          title: 'Photo Rejected',
          body: `One of your photos was rejected: ${reason}`,
          data: {
            photoId: photo.id,
            reason,
          },
        });

        this.logger.logBusinessEvent('photo_blocked_notification_sent', {
          userId: profile.userId,
          photoId: photo.id,
          reason,
        });
      }
    } catch (error) {
      this.logger.error(
        `Error handling blocked photo notification: ${photo.id}`,
        error.stack,
        'ModerationService',
      );
    }
  }

  /**
   * Handle when text content is blocked
   */
  private async handleTextContentBlocked(
    userId: string,
    reason: string,
  ): Promise<void> {
    try {
      // Send notification to user
      await this.notificationsService.createNotification({
        userId,
        type: NotificationType.SYSTEM,
        title: 'Content Moderation',
        body: `Your content was flagged: ${reason}`,
        data: {
          reason,
        },
      });

      // Check if user should be warned or suspended
      // This is a simple implementation - could be enhanced with a strike system
      const user = await this.userRepository.findOne({
        where: { id: userId },
      });

      if (user) {
        this.logger.logSecurityEvent('user_content_blocked', {
          userId,
          email: user.email,
          reason,
        });
      }
    } catch (error) {
      this.logger.error(
        `Error handling blocked text content notification: ${userId}`,
        error.stack,
        'ModerationService',
      );
    }
  }
}
