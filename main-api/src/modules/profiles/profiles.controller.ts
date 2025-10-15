import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  UseGuards,
  Request,
  UseInterceptors,
  UploadedFiles,
} from '@nestjs/common';
import { FilesInterceptor } from '@nestjs/platform-express';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiResponse,
  ApiConsumes,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { SkipProfileCompletion } from '../auth/decorators/skip-profile-completion.decorator';
import { ProfilesService } from './profiles.service';
import { CacheControl } from '../../common/interceptors/cache.interceptor';
import { CacheStrategy } from '../../common/enums/cache-strategy.enum';
import {
  ProfileResponseDto,
  UpdateProfileDto,
  SubmitPersonalityAnswersDto,
  UploadPhotosDto,
  SubmitPromptAnswersDto,
  UpdatePromptAnswersDto,
  UpdateProfileStatusDto,
  UpdatePhotoOrderDto,
} from './dto/profiles.dto';

@ApiTags('profiles')
@Controller('profiles')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class ProfilesController {
  constructor(private readonly profilesService: ProfilesService) {}

  @Get('me')
  @CacheControl(CacheStrategy.SHORT_CACHE)
  @SkipProfileCompletion()
  @ApiOperation({ summary: 'Get current user profile' })
  @ApiResponse({
    status: 200,
    description:
      'Profile retrieved successfully. The response includes the pseudo field (username).',
    type: ProfileResponseDto,
  })
  async getProfile(@Request() req: any) {
    return this.profilesService.getProfile(req.user.id);
  }

  @Put('me')
  @SkipProfileCompletion()
  @ApiOperation({
    summary: 'Update current user profile',
    description:
      'Update profile fields. All text fields (bio, pseudo, jobTitle, company, education, favoriteSong) are moderated for inappropriate content and forbidden words.',
  })
  @ApiResponse({
    status: 200,
    description:
      'Profile updated successfully. You can update the pseudo field (username) using this endpoint.',
    type: ProfileResponseDto,
  })
  @ApiResponse({
    status: 400,
    description:
      'Invalid request or content moderation failed. Text fields contain forbidden words or inappropriate content.',
  })
  async updateProfile(
    @Request() req: any,
    @Body() updateProfileDto: UpdateProfileDto,
  ) {
    return this.profilesService.updateProfile(req.user.id, updateProfileDto);
  }

  @Get('completion')
  @SkipProfileCompletion()
  @ApiOperation({
    summary: 'Get profile completion status',
    description:
      'Returns detailed profile completion status including requirements: 3 photos, exactly 3 prompts, personality questionnaire, and basic info (birthDate, bio).',
  })
  @ApiResponse({ status: 200, description: 'Profile completion status' })
  async getProfileCompletion(@Request() req: any) {
    return this.profilesService.getProfileCompletion(req.user.id);
  }

  @Get('personality-questions')
  @CacheControl(CacheStrategy.LONG_CACHE)
  @SkipProfileCompletion()
  @ApiOperation({ summary: 'Get personality questionnaire questions' })
  @ApiResponse({ status: 200, description: 'Personality questions retrieved' })
  async getPersonalityQuestions() {
    return this.profilesService.getPersonalityQuestions();
  }

  @Post('me/personality-answers')
  @SkipProfileCompletion()
  @ApiOperation({ summary: 'Submit personality questionnaire answers' })
  @ApiResponse({
    status: 201,
    description: 'Personality answers submitted successfully',
  })
  async submitPersonalityAnswers(
    @Request() req: any,
    @Body() answersDto: SubmitPersonalityAnswersDto,
  ) {
    console.log('Received personality answers:', answersDto);
    await this.profilesService.submitPersonalityAnswers(
      req.user.id,
      answersDto,
    );
    return { message: 'Personality answers submitted successfully' };
  }

  @Post('me/photos')
  @SkipProfileCompletion()
  @ApiOperation({ summary: 'Upload profile photos' })
  @ApiResponse({ status: 201, description: 'Photos uploaded successfully' })
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FilesInterceptor('photos', 6)) // Max 6 photos as per requirements
  async uploadPhotos(
    @Request() req: any,
    @UploadedFiles() files: Express.Multer.File[],
  ) {
    return this.profilesService.uploadPhotos(req.user.id, files);
  }

  @Post('me/media')
  @SkipProfileCompletion()
  @ApiOperation({ summary: 'Upload profile media (alias for photos endpoint)' })
  @ApiResponse({ status: 201, description: 'Media uploaded successfully' })
  @ApiResponse({
    status: 400,
    description: 'Invalid file type, size, or count',
  })
  @ApiResponse({ status: 404, description: 'Profile not found' })
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FilesInterceptor('photos', 6)) // Max 6 photos as per requirements
  async uploadMedia(
    @Request() req: any,
    @UploadedFiles() files: Express.Multer.File[],
  ) {
    return this.profilesService.uploadPhotos(req.user.id, files);
  }

  @Delete('me/photos/:photoId')
  @SkipProfileCompletion()
  @ApiOperation({ summary: 'Delete a profile photo' })
  @ApiResponse({ status: 200, description: 'Photo deleted successfully' })
  async deletePhoto(@Request() req: any, @Param('photoId') photoId: string) {
    await this.profilesService.deletePhoto(req.user.id, photoId);
    return { message: 'Photo deleted successfully' };
  }

  @Put('me/photos/:photoId/primary')
  @SkipProfileCompletion()
  @ApiOperation({ summary: 'Set photo as primary' })
  @ApiResponse({
    status: 200,
    description: 'Primary photo updated successfully',
  })
  async setPrimaryPhoto(
    @Request() req: any,
    @Param('photoId') photoId: string,
  ) {
    return this.profilesService.setPrimaryPhoto(req.user.id, photoId);
  }

  @Put('me/photos/:photoId/order')
  @SkipProfileCompletion()
  @ApiOperation({ summary: 'Update photo order for drag & drop' })
  @ApiResponse({
    status: 200,
    description: 'Photo order updated successfully',
  })
  async updatePhotoOrder(
    @Request() req: any,
    @Param('photoId') photoId: string,
    @Body() orderDto: UpdatePhotoOrderDto,
  ) {
    return this.profilesService.updatePhotoOrder(
      req.user.id,
      photoId,
      orderDto.newOrder,
    );
  }

  @Get('prompts')
  @CacheControl(CacheStrategy.LONG_CACHE)
  @SkipProfileCompletion()
  @ApiOperation({
    summary: 'Get available prompts',
    description:
      'Returns all active prompts. Users can select and answer any 3 of them. Required prompts are prioritized first, then ordered by their order field.',
  })
  @ApiResponse({ status: 200, description: 'Prompts retrieved successfully' })
  async getPrompts() {
    return this.profilesService.getPrompts();
  }

  @Post('me/prompt-answers')
  @SkipProfileCompletion()
  @ApiOperation({
    summary: 'Submit prompt answers',
    description:
      'Submit exactly 3 prompt answers. This is required for profile completion. Each answer must be max 150 characters and will be moderated for inappropriate content.',
  })
  @ApiResponse({
    status: 201,
    description: 'Prompt answers submitted successfully',
  })
  @ApiResponse({
    status: 400,
    description:
      'Invalid request - must provide exactly 3 answers, or content moderation failed',
  })
  async submitPromptAnswers(
    @Request() req: any,
    @Body() promptAnswersDto: SubmitPromptAnswersDto,
  ) {
    await this.profilesService.submitPromptAnswers(
      req.user.id,
      promptAnswersDto,
    );
    return { message: 'Prompt answers submitted successfully' };
  }

  @Get('me/prompt-answers')
  @SkipProfileCompletion()
  @ApiOperation({ summary: 'Get user prompt answers' })
  @ApiResponse({
    status: 200,
    description: 'User prompt answers retrieved successfully',
  })
  async getUserPromptAnswers(@Request() req: any) {
    return this.profilesService.getUserPromptAnswers(req.user.id);
  }

  @Put('me/prompt-answers')
  @SkipProfileCompletion()
  @ApiOperation({
    summary: 'Update prompt answers',
    description:
      'Update all prompt answers at once. Must provide exactly 3 answers. Each answer must be max 150 characters and will be moderated for inappropriate content.',
  })
  @ApiResponse({
    status: 200,
    description: 'Prompt answers updated successfully',
  })
  @ApiResponse({
    status: 400,
    description:
      'Invalid request - must provide exactly 3 answers, or content moderation failed',
  })
  async updatePromptAnswers(
    @Request() req: any,
    @Body() updateDto: UpdatePromptAnswersDto,
  ) {
    const updated = await this.profilesService.updatePromptAnswers(
      req.user.id,
      updateDto,
    );
    return { success: true, promptAnswers: updated };
  }

  @Put('me/status')
  @SkipProfileCompletion()
  @ApiOperation({ summary: 'Update profile status' })
  @ApiResponse({
    status: 200,
    description: 'Profile status updated successfully',
  })
  async updateProfileStatus(
    @Request() req: any,
    @Body() statusDto: UpdateProfileStatusDto,
  ) {
    await this.profilesService.updateProfileStatus(req.user.id, statusDto);
    return { message: 'Profile status updated successfully' };
  }
}
