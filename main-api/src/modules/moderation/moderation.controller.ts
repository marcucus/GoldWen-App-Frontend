import {
  Controller,
  Post,
  Get,
  Body,
  Param,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ModerationService } from './services/moderation.service';
import {
  ModerateTextDto,
  ModerateTextBatchDto,
  PhotoModerationStatusDto,
  PhotoModerationWebhookDto,
} from './dto/moderation.dto';

@Controller('moderation')
export class ModerationController {
  constructor(private readonly moderationService: ModerationService) {}

  /**
   * Webhook endpoint for photo moderation
   * Called automatically after photo upload
   */
  @Post('webhook/photo')
  @HttpCode(HttpStatus.OK)
  async photoModerationWebhook(@Body() dto: PhotoModerationWebhookDto) {
    const result = await this.moderationService.moderatePhoto(dto.photoId);
    return {
      success: true,
      data: result,
    };
  }

  /**
   * Get photo moderation status
   */
  @Get('photo/:photoId/status')
  @UseGuards(JwtAuthGuard)
  async getPhotoStatus(@Param('photoId') photoId: string) {
    const status =
      await this.moderationService.getPhotoModerationStatus(photoId);
    return {
      success: true,
      data: status,
    };
  }

  /**
   * Admin endpoint to manually moderate a photo
   */
  @Post('admin/photo/:photoId')
  @UseGuards(JwtAuthGuard)
  async adminModeratePhoto(@Param('photoId') photoId: string) {
    const result = await this.moderationService.moderatePhoto(photoId);
    return {
      success: true,
      data: result,
    };
  }

  /**
   * Admin endpoint to moderate text content
   */
  @Post('admin/text')
  @UseGuards(JwtAuthGuard)
  async adminModerateText(@Body() dto: ModerateTextDto) {
    const result = await this.moderationService.moderateTextContent(dto.text);
    return {
      success: true,
      data: result,
    };
  }

  /**
   * Admin endpoint to moderate multiple text contents
   */
  @Post('admin/text/batch')
  @UseGuards(JwtAuthGuard)
  async adminModerateTextBatch(@Body() dto: ModerateTextBatchDto) {
    const results = await this.moderationService.moderateTextContentBatch(
      dto.texts,
    );
    return {
      success: true,
      data: results,
    };
  }
}
