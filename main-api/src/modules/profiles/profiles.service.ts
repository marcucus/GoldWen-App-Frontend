import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as path from 'path';
import * as fs from 'fs';

import { Profile } from '../../database/entities/profile.entity';
import { User } from '../../database/entities/user.entity';
import { PersonalityQuestion } from '../../database/entities/personality-question.entity';
import { PersonalityAnswer } from '../../database/entities/personality-answer.entity';
import { Photo } from '../../database/entities/photo.entity';
import { Prompt } from '../../database/entities/prompt.entity';
import { PromptAnswer } from '../../database/entities/prompt-answer.entity';
import { ModerationService } from '../moderation/services/moderation.service';

import {
  UpdateProfileDto,
  SubmitPersonalityAnswersDto,
  SubmitPromptAnswersDto,
  UpdatePromptAnswersDto,
  UpdateProfileStatusDto,
} from './dto/profiles.dto';

@Injectable()
export class ProfilesService {
  constructor(
    @InjectRepository(Profile)
    private profileRepository: Repository<Profile>,
    @InjectRepository(User)
    private userRepository: Repository<User>,
    @InjectRepository(PersonalityQuestion)
    private personalityQuestionRepository: Repository<PersonalityQuestion>,
    @InjectRepository(PersonalityAnswer)
    private personalityAnswerRepository: Repository<PersonalityAnswer>,
    @InjectRepository(Photo)
    private photoRepository: Repository<Photo>,
    @InjectRepository(Prompt)
    private promptRepository: Repository<Prompt>,
    @InjectRepository(PromptAnswer)
    private promptAnswerRepository: Repository<PromptAnswer>,
    private moderationService: ModerationService,
  ) {}

  async getProfile(userId: string): Promise<Profile> {
    const profile = await this.profileRepository.findOne({
      where: { userId },
      relations: [
        'photos',
        'promptAnswers',
        'promptAnswers.prompt',
        'user',
        'user.personalityAnswers',
        'user.personalityAnswers.question',
      ],
    });

    if (!profile) {
      throw new NotFoundException('Profile not found');
    }

    return profile;
  }

  async updateProfile(
    userId: string,
    updateProfileDto: UpdateProfileDto,
  ): Promise<Profile> {
    const profile = await this.profileRepository.findOne({
      where: { userId },
    });

    if (!profile) {
      throw new NotFoundException('Profile not found');
    }

    // Collect all text fields that need moderation
    const textsToModerate: { field: string; text: string }[] = [];

    if (updateProfileDto.bio) {
      textsToModerate.push({ field: 'bio', text: updateProfileDto.bio });
    }
    if (updateProfileDto.pseudo) {
      textsToModerate.push({ field: 'pseudo', text: updateProfileDto.pseudo });
    }
    if (updateProfileDto.jobTitle) {
      textsToModerate.push({
        field: 'jobTitle',
        text: updateProfileDto.jobTitle,
      });
    }
    if (updateProfileDto.company) {
      textsToModerate.push({
        field: 'company',
        text: updateProfileDto.company,
      });
    }
    if (updateProfileDto.education) {
      textsToModerate.push({
        field: 'education',
        text: updateProfileDto.education,
      });
    }
    if (updateProfileDto.favoriteSong) {
      textsToModerate.push({
        field: 'favoriteSong',
        text: updateProfileDto.favoriteSong,
      });
    }

    // Moderate all text fields in batch
    if (textsToModerate.length > 0) {
      const moderationResults =
        await this.moderationService.moderateTextContentBatch(
          textsToModerate.map((item) => item.text),
        );

      // Check if any field was blocked
      const blockedFields = moderationResults
        .map((result, index) => ({ result, field: textsToModerate[index] }))
        .filter(({ result }) => !result.approved);

      if (blockedFields.length > 0) {
        const reasons = blockedFields
          .map(({ result, field }) => `${field.field}: ${result.reason}`)
          .join('; ');
        throw new BadRequestException(`Profile fields rejected: ${reasons}`);
      }
    }

    // Handle legacy age field - convert to birthDate if provided
    if (updateProfileDto.age && !updateProfileDto.birthDate) {
      const today = new Date();
      const birthYear = today.getFullYear() - updateProfileDto.age;
      updateProfileDto.birthDate = `${birthYear}-01-01`;
    }
    // Remove age from the DTO since it's not a database field
    if ('age' in updateProfileDto) {
      delete updateProfileDto.age;
    }

    // Handle legacy field mappings
    if (updateProfileDto.job && !updateProfileDto.jobTitle) {
      updateProfileDto.jobTitle = updateProfileDto.job;
      delete updateProfileDto.job;
    }

    if (updateProfileDto.school && !updateProfileDto.education) {
      updateProfileDto.education = updateProfileDto.school;
      delete updateProfileDto.school;
    }

    // Convert birthDate string to Date object
    if (updateProfileDto.birthDate) {
      (updateProfileDto as any).birthDate = new Date(
        updateProfileDto.birthDate,
      );
    }

    Object.assign(profile, updateProfileDto);
    await this.profileRepository.save(profile);

    // Check if profile is now complete after the update
    await this.updateProfileCompletionStatus(userId);

    return this.getProfile(userId);
  }

  async getPersonalityQuestions(): Promise<PersonalityQuestion[]> {
    return this.personalityQuestionRepository.find({
      where: { isActive: true },
      order: { order: 'ASC' },
    });
  }

  async submitPersonalityAnswers(
    userId: string,
    answersDto: SubmitPersonalityAnswersDto,
  ): Promise<void> {
    const { answers } = answersDto;

    // Validate that all required questions are answered
    const requiredQuestions = await this.personalityQuestionRepository.find({
      where: { isActive: true, isRequired: true },
    });

    const answeredQuestionIds = new Set(answers.map((a) => a.questionId));
    const missingRequired = requiredQuestions.filter(
      (q) => !answeredQuestionIds.has(q.id),
    );

    if (missingRequired.length > 0) {
      throw new BadRequestException({
        message: `Missing answers for required questions: ${missingRequired.map((q) => q.question).join(', ')}`,
        missingQuestions: missingRequired.map((q) => q.id),
      });
    }

    // Moderate text answers and multiple choice answers
    const textsToModerate: string[] = [];
    answers.forEach((answer) => {
      if (answer.textAnswer) {
        textsToModerate.push(answer.textAnswer);
      }
      if (
        answer.multipleChoiceAnswer &&
        answer.multipleChoiceAnswer.length > 0
      ) {
        textsToModerate.push(...answer.multipleChoiceAnswer);
      }
    });

    if (textsToModerate.length > 0) {
      const moderationResults =
        await this.moderationService.moderateTextContentBatch(textsToModerate);

      // Check if any answer was blocked
      const blockedAnswers = moderationResults
        .map((result, index) => ({ result, index }))
        .filter(({ result }) => !result.approved);

      if (blockedAnswers.length > 0) {
        const reasons = blockedAnswers
          .map(({ result, index }) => `Answer ${index + 1}: ${result.reason}`)
          .join('; ');
        throw new BadRequestException(
          `Some questionnaire answers contain inappropriate content: ${reasons}`,
        );
      }
    }

    try {
      // Delete existing answers
      await this.personalityAnswerRepository.delete({ userId });

      // Create new answers
      const answerEntities = answers.map((answer) => {
        return this.personalityAnswerRepository.create({
          userId,
          questionId: answer.questionId,
          textAnswer: answer.textAnswer,
          numericAnswer: answer.numericAnswer,
          booleanAnswer: answer.booleanAnswer,
          multipleChoiceAnswer: answer.multipleChoiceAnswer,
        });
      });

      await this.personalityAnswerRepository.save(answerEntities);

      // Check if profile is now complete
      await this.updateProfileCompletionStatus(userId);
    } catch (error) {
      // Log the error for debugging
      console.error(
        'Error saving personality answers for user',
        userId,
        ':',
        error,
      );
      throw new BadRequestException({
        message: 'Failed to save personality answers: ' + error.message,
        error: error?.message || error,
      });
    }
  }

  async uploadPhotos(
    userId: string,
    files: Express.Multer.File[],
  ): Promise<Photo[]> {
    const profile = await this.profileRepository.findOne({
      where: { userId },
      relations: ['photos'],
    });

    if (!profile) {
      throw new NotFoundException('Profile not found');
    }

    // Validate maximum photos requirement (6 max total)
    const currentPhotosCount = profile.photos?.length || 0;
    const totalPhotos = currentPhotosCount + files.length;
    if (totalPhotos > 6) {
      throw new BadRequestException(
        `Maximum 6 photos allowed. You currently have ${currentPhotosCount} photos.`,
      );
    }

    // Validate at least one file is provided
    if (files.length === 0) {
      throw new BadRequestException('At least one photo is required');
    }

    console.log('Received files for upload:', files);

    // Create photo entities with initial approval status as false
    const photoEntities = files.map((file, index) => {
      return this.photoRepository.create({
        profileId: profile.id,
        url: `/uploads/photos/${file.filename}`,
        filename: file.filename,
        mimeType: file.mimetype,
        fileSize: file.size,
        order: currentPhotosCount + index + 1,
        isPrimary: currentPhotosCount === 0 && index === 0, // First photo is primary if no photos exist
        isApproved: false, // Start as unapproved, will be moderated
      });
    });
    console.log('Photo entities to be saved:', photoEntities);
    const savedPhotos = await this.photoRepository.save(photoEntities);

    // Trigger moderation for each photo asynchronously
    // We don't await this so the upload response is fast
    savedPhotos.forEach((photo) => {
      this.moderationService.moderatePhoto(photo.id).catch((error) => {
        console.error(`Error moderating photo ${photo.id}:`, error.message);
      });
    });

    // Check if profile is now complete after upload
    await this.updateProfileCompletionStatus(userId);

    return savedPhotos;
  }

  async setPrimaryPhoto(userId: string, photoId: string): Promise<Photo> {
    const profile = await this.profileRepository.findOne({
      where: { userId },
      relations: ['photos'],
    });

    if (!profile) {
      throw new NotFoundException('Profile not found');
    }

    const photo = profile.photos?.find((p) => p.id === photoId);
    if (!photo) {
      throw new NotFoundException('Photo not found');
    }

    // Remove primary status from all other photos
    await this.photoRepository.update(
      { profileId: profile.id },
      { isPrimary: false },
    );

    // Set this photo as primary
    photo.isPrimary = true;
    return this.photoRepository.save(photo);
  }

  async updatePhotoOrder(
    userId: string,
    photoId: string,
    newOrder: number,
  ): Promise<Photo> {
    const profile = await this.profileRepository.findOne({
      where: { userId },
      relations: ['photos'],
    });

    if (!profile) {
      throw new NotFoundException('Profile not found');
    }

    const photo = profile.photos?.find((p) => p.id === photoId);
    if (!photo) {
      throw new NotFoundException('Photo not found');
    }

    const totalPhotos = profile.photos?.length || 0;
    if (newOrder < 1 || newOrder > totalPhotos) {
      throw new BadRequestException(
        `Invalid order. Must be between 1 and ${totalPhotos}`,
      );
    }

    const currentOrder = photo.order;

    // If the order hasn't changed, return the photo as is
    if (currentOrder === newOrder) {
      return photo;
    }

    // Update the orders of other photos
    if (newOrder < currentOrder) {
      // Moving photo to an earlier position - shift others down
      await this.photoRepository
        .createQueryBuilder()
        .update(Photo)
        .set({ order: () => '"order" + 1' })
        .where('profileId = :profileId', { profileId: profile.id })
        .andWhere('order >= :newOrder', { newOrder })
        .andWhere('order < :currentOrder', { currentOrder })
        .execute();
    } else {
      // Moving photo to a later position - shift others up
      await this.photoRepository
        .createQueryBuilder()
        .update(Photo)
        .set({ order: () => '"order" - 1' })
        .where('profileId = :profileId', { profileId: profile.id })
        .andWhere('order > :currentOrder', { currentOrder })
        .andWhere('order <= :newOrder', { newOrder })
        .execute();
    }

    // Update the target photo's order
    photo.order = newOrder;
    return this.photoRepository.save(photo);
  }

  async getPrompts(): Promise<Prompt[]> {
    // Return ALL active prompts so users can select any 3 of them
    // Users must select exactly 3 prompts to answer for profile completion
    return this.promptRepository.find({
      where: { isActive: true },
      order: { isRequired: 'DESC', order: 'ASC' },
    });
  }

  async getUserPromptAnswers(userId: string): Promise<PromptAnswer[]> {
    const profile = await this.profileRepository.findOne({
      where: { userId },
      relations: ['promptAnswers', 'promptAnswers.prompt'],
    });

    if (!profile) {
      throw new NotFoundException('Profile not found');
    }

    return profile.promptAnswers || [];
  }

  async submitPromptAnswers(
    userId: string,
    promptAnswersDto: SubmitPromptAnswersDto,
  ): Promise<void> {
    const { answers } = promptAnswersDto;

    // Moderate all prompt answers
    const textsToModerate = answers.map((a) => a.answer);
    const moderationResults =
      await this.moderationService.moderateTextContentBatch(textsToModerate);

    // Check if any answer was blocked
    const blockedAnswers = moderationResults
      .map((result, index) => ({ result, index }))
      .filter(({ result }) => !result.approved);

    if (blockedAnswers.length > 0) {
      const reasons = blockedAnswers
        .map(({ result, index }) => `Answer ${index + 1}: ${result.reason}`)
        .join('; ');
      throw new BadRequestException(
        `Some prompt answers contain inappropriate content: ${reasons}`,
      );
    }

    // Validate that answered prompts exist and are active
    const allPrompts = await this.promptRepository.find({
      where: { isActive: true },
    });
    const activePromptIds = new Set(allPrompts.map((p) => p.id));

    const invalidAnswers = answers.filter(
      (a) => !activePromptIds.has(a.promptId),
    );

    if (invalidAnswers.length > 0) {
      throw new BadRequestException(
        'Some prompts are invalid or inactive: ' +
          invalidAnswers.map((a) => a.promptId).join(', '),
      );
    }

    const profile = await this.profileRepository.findOne({
      where: { userId },
    });

    if (!profile) {
      throw new NotFoundException('Profile not found');
    }

    try {
      // Delete existing prompt answers
      await this.promptAnswerRepository.delete({ profileId: profile.id });

      // Create new prompt answers
      const answerEntities = answers.map((answer, index) => {
        return this.promptAnswerRepository.create({
          profileId: profile.id,
          promptId: answer.promptId,
          answer: answer.answer,
          order: index + 1, // Set order field which is required by the entity
        });
      });

      await this.promptAnswerRepository.save(answerEntities);

      // Check if profile is now complete
      await this.updateProfileCompletionStatus(userId);
    } catch (error) {
      // Log the error for debugging
      console.error(
        '[submitPromptAnswers] ERROR saving prompt answers for user',
        userId,
        ':',
        error,
      );
      throw new BadRequestException(
        'Failed to save prompt answers: ' + error.message,
      );
    }
  }

  async updatePromptAnswers(
    userId: string,
    updateDto: UpdatePromptAnswersDto,
  ): Promise<PromptAnswer[]> {
    const { answers } = updateDto;

    // Validate exactly 3 answers
    if (answers.length !== 3) {
      throw new BadRequestException('Exactly 3 prompt answers are required');
    }

    // Moderate all prompt answers
    const textsToModerate = answers.map((a) => a.answer);
    const moderationResults =
      await this.moderationService.moderateTextContentBatch(textsToModerate);

    // Check if any answer was blocked
    const blockedAnswers = moderationResults
      .map((result, index) => ({ result, index }))
      .filter(({ result }) => !result.approved);

    if (blockedAnswers.length > 0) {
      const reasons = blockedAnswers
        .map(({ result, index }) => `Answer ${index + 1}: ${result.reason}`)
        .join('; ');
      throw new BadRequestException(
        `Some prompt answers contain inappropriate content: ${reasons}`,
      );
    }

    // Validate that all prompts exist and are active
    const allPrompts = await this.promptRepository.find({
      where: { isActive: true },
    });
    const activePromptIds = new Set(allPrompts.map((p) => p.id));

    const invalidAnswers = answers.filter(
      (a) => !activePromptIds.has(a.promptId),
    );

    if (invalidAnswers.length > 0) {
      throw new BadRequestException(
        'Some prompts are invalid or inactive: ' +
          invalidAnswers.map((a) => a.promptId).join(', '),
      );
    }

    // Get user profile
    const profile = await this.profileRepository.findOne({
      where: { userId },
    });

    if (!profile) {
      throw new NotFoundException('Profile not found');
    }

    try {
      // Delete existing prompt answers
      await this.promptAnswerRepository.delete({ profileId: profile.id });

      // Create new prompt answers
      const answerEntities = answers.map((answer, index) => {
        return this.promptAnswerRepository.create({
          profileId: profile.id,
          promptId: answer.promptId,
          answer: answer.answer,
          order: index + 1,
        });
      });

      await this.promptAnswerRepository.save(answerEntities);

      // Check if profile is now complete
      await this.updateProfileCompletionStatus(userId);

      // Return saved answers with prompt information
      return this.getUserPromptAnswers(userId);
    } catch (error) {
      console.error(
        '[updatePromptAnswers] ERROR updating prompt answers for user',
        userId,
        ':',
        error,
      );
      throw new BadRequestException(
        'Failed to update prompt answers: ' + error.message,
      );
    }
  }

  async deletePhoto(userId: string, photoId: string): Promise<void> {
    const photo = await this.photoRepository.findOne({
      where: { id: photoId },
      relations: ['profile'],
    });

    if (!photo || photo.profile.userId !== userId) {
      throw new NotFoundException('Photo not found');
    }

    await this.photoRepository.remove(photo);

    // Check if profile is still complete
    await this.updateProfileCompletionStatus(userId);
  }

  private async updateProfileCompletionStatus(userId: string): Promise<void> {
    const user = await this.userRepository.findOne({
      where: { id: userId },
      relations: [
        'profile',
        'profile.photos',
        'profile.promptAnswers',
        'personalityAnswers',
      ],
    });

    if (!user || !user.profile) {
      console.log(`[updateProfileCompletionStatus] User or profile not found for userId: ${userId}`);
      return;
    }

    // Check completion criteria from specifications:
    // 1. Minimum 3 photos
    // 2. Exactly 3 prompt answers (aligned with frontend limitation)
    // 3. All required personality questions answered
    // 4. Required profile fields: birthDate and bio
    const hasMinPhotos = (user.profile.photos?.length || 0) >= 3;

    // Check if user has answered exactly 3 prompts (required for completion)
    const promptsCount = user.profile.promptAnswers?.length || 0;
    const hasPromptAnswers = promptsCount === 3;

    const hasRequiredProfileFields = !!(
      user.profile.birthDate && user.profile.bio
    );

    // Get required personality questions count
    const requiredQuestionsCount =
      await this.personalityQuestionRepository.count({
        where: { isActive: true, isRequired: true },
      });

    const hasPersonalityAnswers =
      (user.personalityAnswers?.length || 0) >= requiredQuestionsCount;

    const isProfileCompleted =
      hasMinPhotos &&
      hasPromptAnswers &&
      hasPersonalityAnswers &&
      hasRequiredProfileFields;

    // Onboarding is completed when personality questions are answered
    const isOnboardingCompleted = hasPersonalityAnswers;

    // Log completion status for debugging
    console.log(`[updateProfileCompletionStatus] Completion check for userId: ${userId}`, {
      hasMinPhotos,
      photosCount: user.profile.photos?.length || 0,
      hasPromptAnswers,
      promptsCount,
      hasPersonalityAnswers,
      personalityAnswersCount: user.personalityAnswers?.length || 0,
      requiredQuestionsCount,
      hasRequiredProfileFields,
      hasBirthDate: !!user.profile.birthDate,
      hasBio: !!user.profile.bio,
      isProfileCompleted,
      isOnboardingCompleted,
      currentIsProfileCompleted: user.isProfileCompleted,
      currentIsOnboardingCompleted: user.isOnboardingCompleted,
    });

    // Update user status
    if (
      user.isProfileCompleted !== isProfileCompleted ||
      user.isOnboardingCompleted !== isOnboardingCompleted
    ) {
      console.log(`[updateProfileCompletionStatus] Updating completion flags for userId: ${userId}`, {
        from: { isProfileCompleted: user.isProfileCompleted, isOnboardingCompleted: user.isOnboardingCompleted },
        to: { isProfileCompleted, isOnboardingCompleted },
      });
      user.isProfileCompleted = isProfileCompleted;
      user.isOnboardingCompleted = isOnboardingCompleted;
      await this.userRepository.save(user);
      console.log(`[updateProfileCompletionStatus] Successfully updated completion flags for userId: ${userId}`);
    } else {
      console.log(`[updateProfileCompletionStatus] No changes needed for userId: ${userId}`);
    }
  }

  async getProfileCompletion(userId: string): Promise<{
    isComplete: boolean;
    completionPercentage: number;
    requirements: {
      minimumPhotos: {
        required: number;
        current: number;
        satisfied: boolean;
      };
      minimumPrompts: {
        required: number;
        current: number;
        satisfied: boolean;
        missing: Array<{ id: string; text: string }>;
      };
      personalityQuestionnaire: {
        required: boolean;
        completed: boolean;
        satisfied: boolean;
      };
      basicInfo: boolean;
    };
    missingSteps: string[];
    nextStep: string;
  }> {
    const user = await this.userRepository.findOne({
      where: { id: userId },
      relations: [
        'profile',
        'profile.photos',
        'profile.promptAnswers',
        'personalityAnswers',
      ],
    });

    if (!user || !user.profile) {
      throw new NotFoundException('Profile not found');
    }

    // Debug: Log the user profile data
    console.log('Profile completion debug - user data:', {
      userId: user.id,
      profileId: user.profile.id,
      promptAnswersRaw: user.profile.promptAnswers,
      promptAnswersCount: user.profile.promptAnswers?.length || 0,
    });

    const photosCount = user.profile.photos?.length || 0;
    const hasPhotos = photosCount >= 3;
    const hasRequiredProfileFields = !!(
      user.profile.birthDate && user.profile.bio
    );

    // Check if user has answered exactly 3 prompts (required for completion)
    const promptsCount = user.profile.promptAnswers?.length || 0;
    const hasPrompts = promptsCount === 3;

    // Get available prompts for missing information (only the 3 prompts we offer)
    const availablePrompts = await this.promptRepository.find({
      where: { isActive: true },
      order: { isRequired: 'DESC', order: 'ASC' },
      take: 3,
    });

    const answeredPromptIds = new Set(
      (user.profile.promptAnswers || []).map((a) => a.promptId),
    );

    const missingPrompts = availablePrompts.filter(
      (p) => !answeredPromptIds.has(p.id),
    );

    // Debug: Log prompts validation
    console.log('Prompts validation debug:', {
      userId: user.id,
      requiredPromptsCount: 3,
      promptsCount,
      answeredPromptIds: Array.from(answeredPromptIds),
      availablePromptIds: availablePrompts.map((p) => p.id),
      missingPrompts: missingPrompts.map((p) => ({
        id: p.id,
        text: p.text,
      })),
      hasPrompts,
    });

    const requiredQuestionsCount =
      await this.personalityQuestionRepository.count({
        where: { isActive: true, isRequired: true },
      });

    const hasPersonalityAnswers =
      (user.personalityAnswers?.length || 0) >= requiredQuestionsCount;

    const missingSteps: string[] = [];
    if (!hasPhotos) missingSteps.push('Upload at least 3 photos');
    if (!hasPrompts) {
      if (promptsCount < 3) {
        const missingCount = 3 - promptsCount;
        missingSteps.push(
          `Answer ${missingCount} more prompt${missingCount > 1 ? 's' : ''} (${promptsCount}/3)`,
        );
      } else if (promptsCount > 3) {
        const extraCount = promptsCount - 3;
        missingSteps.push(
          `You have too many prompts (${promptsCount}/3). Please remove ${extraCount} prompt${extraCount > 1 ? 's' : ''}`,
        );
      }
    }
    if (!hasPersonalityAnswers)
      missingSteps.push('Complete personality questionnaire');
    if (!hasRequiredProfileFields) {
      const missingFields = [];
      if (!user.profile.birthDate) missingFields.push('birth date');
      if (!user.profile.bio) missingFields.push('bio');
      missingSteps.push(
        `Complete basic profile information: ${missingFields.join(', ')}`,
      );
    }

    const isComplete =
      hasPhotos &&
      hasPrompts &&
      hasPersonalityAnswers &&
      hasRequiredProfileFields;

    // Calculate completion percentage based on the 4 requirements
    let completed = 0;
    if (hasPhotos) completed++;
    if (hasPrompts) completed++;
    if (hasPersonalityAnswers) completed++;
    if (hasRequiredProfileFields) completed++;
    const completionPercentage = Math.round((completed / 4) * 100);

    // Determine next step based on priority
    let nextStep = '';
    if (!hasRequiredProfileFields) {
      const missingFields = [];
      if (!user.profile.birthDate) missingFields.push('birth date');
      if (!user.profile.bio) missingFields.push('bio');
      nextStep = `Complete basic profile information: ${missingFields.join(', ')}`;
    } else if (!hasPersonalityAnswers) {
      nextStep = 'Complete personality questionnaire';
    } else if (!hasPhotos) {
      nextStep = 'Upload at least 3 photos';
    } else if (!hasPrompts) {
      if (promptsCount < 3) {
        const missingCount = 3 - promptsCount;
        nextStep = `Answer ${missingCount} more prompt${missingCount > 1 ? 's' : ''}`;
      } else if (promptsCount > 3) {
        const extraCount = promptsCount - 3;
        nextStep = `Remove ${extraCount} prompt${extraCount > 1 ? 's' : ''} to have exactly 3`;
      }
    } else {
      nextStep = 'Profile is complete!';
    }

    return {
      isComplete,
      completionPercentage,
      requirements: {
        minimumPhotos: {
          required: 3,
          current: photosCount,
          satisfied: hasPhotos,
        },
        minimumPrompts: {
          required: 3,
          current: promptsCount,
          satisfied: hasPrompts,
          missing: missingPrompts.map((p) => ({
            id: p.id,
            text: p.text,
          })),
        },
        personalityQuestionnaire: {
          required: true,
          completed: hasPersonalityAnswers,
          satisfied: hasPersonalityAnswers,
        },
        basicInfo: hasRequiredProfileFields,
      },
      missingSteps,
      nextStep,
    };
  }

  async isProfileVisible(userId: string): Promise<boolean> {
    const user = await this.userRepository.findOne({
      where: { id: userId },
      select: ['isProfileCompleted'],
    });

    return user?.isProfileCompleted ?? false;
  }

  async updateProfileStatus(
    userId: string,
    statusDto: UpdateProfileStatusDto,
  ): Promise<void> {
    const user = await this.userRepository.findOne({
      where: { id: userId },
      relations: [
        'profile',
        'profile.photos',
        'profile.promptAnswers',
        'personalityAnswers',
      ],
    });

    if (!user || !user.profile) {
      throw new NotFoundException('Profile not found');
    }

    // If trying to set profile as visible, validate that profile is complete
    if (statusDto.isVisible) {
      // Check all completion requirements
      const hasMinPhotos = (user.profile.photos?.length || 0) >= 3;

      // Check if user has exactly 3 prompt answers (required for completion)
      const promptsCount = user.profile.promptAnswers?.length || 0;
      const hasPromptAnswers = promptsCount === 3;

      const hasRequiredProfileFields = !!(
        user.profile.birthDate && user.profile.bio
      );

      // Get required personality questions count
      const requiredQuestionsCount =
        await this.personalityQuestionRepository.count({
          where: { isActive: true, isRequired: true },
        });

      const hasPersonalityAnswers =
        (user.personalityAnswers?.length || 0) >= requiredQuestionsCount;

      const isProfileComplete =
        hasMinPhotos &&
        hasPromptAnswers &&
        hasPersonalityAnswers &&
        hasRequiredProfileFields;

      if (!isProfileComplete) {
        // Build detailed error message with missing requirements
        const missingRequirements: string[] = [];
        if (!hasMinPhotos) {
          missingRequirements.push(
            `Need ${3 - (user.profile.photos?.length || 0)} more photo(s)`,
          );
        }
        if (!hasPromptAnswers) {
          if (promptsCount < 3) {
            const missingCount = 3 - promptsCount;
            missingRequirements.push(
              `Need to answer ${missingCount} more prompt${missingCount > 1 ? 's' : ''} (${promptsCount}/3)`,
            );
          } else if (promptsCount > 3) {
            const extraCount = promptsCount - 3;
            missingRequirements.push(
              `Need to remove ${extraCount} prompt${extraCount > 1 ? 's' : ''} to have exactly 3 (${promptsCount}/3)`,
            );
          }
        }
        if (!hasPersonalityAnswers) {
          missingRequirements.push(
            'Need to complete personality questionnaire',
          );
        }
        if (!hasRequiredProfileFields) {
          const missing = [];
          if (!user.profile.birthDate) missing.push('birth date');
          if (!user.profile.bio) missing.push('bio');
          missingRequirements.push(`Need to provide: ${missing.join(', ')}`);
        }

        throw new BadRequestException({
          message:
            'Profile must be complete before it can be made visible. Please complete all required fields.',
          code: 'PROFILE_INCOMPLETE',
          missingRequirements,
        });
      }
    }

    // Update profile visibility
    user.profile.isVisible = statusDto.isVisible;
    await this.profileRepository.save(user.profile);

    // Also update the completion status to keep it in sync
    await this.updateProfileCompletionStatus(userId);
  }
}
