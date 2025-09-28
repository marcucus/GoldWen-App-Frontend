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

import {
  UpdateProfileDto,
  SubmitPersonalityAnswersDto,
  SubmitPromptAnswersDto,
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

    // Simplified version without image processing for now
    const photoEntities = files.map((file, index) => {
      return this.photoRepository.create({
        profileId: profile.id,
        url: `/uploads/photos/${file.filename}`,
        filename: file.filename,
        mimeType: file.mimetype,
        fileSize: file.size,
        order: currentPhotosCount + index + 1,
        isPrimary: currentPhotosCount === 0 && index === 0, // First photo is primary if no photos exist
        isApproved: true, // Auto-approve for MVP
      });
    });
    console.log('Photo entities to be saved:', photoEntities);
    const savedPhotos = await this.photoRepository.save(photoEntities);

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
    return this.promptRepository.find({
      where: { isActive: true },
      order: { order: 'ASC' },
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

    // Get required prompts to validate answers
    const requiredPrompts = await this.promptRepository.find({
      where: { isActive: true, isRequired: true },
    });
    console.log('[submitPromptAnswers] Required prompts:', requiredPrompts.map(p => ({ id: p.id, text: p.text })));

    console.log('[submitPromptAnswers] Answers received:', answers);

    // Validate that all required prompts are answered
    const answeredPromptIds = new Set(answers.map((a) => a.promptId));
    console.log('[submitPromptAnswers] Answered prompt IDs:', Array.from(answeredPromptIds));
    const missingRequired = requiredPrompts.filter(
      (p) => !answeredPromptIds.has(p.id),
    );
    console.log('[submitPromptAnswers] Missing required prompts:', missingRequired.map(p => ({ id: p.id, text: p.text })));

    if (missingRequired.length > 0) {
      console.warn('[submitPromptAnswers] ERROR: Missing answers for required prompts:', missingRequired.map((p) => p.text));
      throw new BadRequestException({
        message: `Missing answers for required prompts: ${missingRequired.map((p) => p.text).join(', ')}`,
        missingPrompts: missingRequired.map((p) => p.id),
      });
    }

    // Validate that answered prompts exist and are active
    const allPrompts = await this.promptRepository.find({
      where: { isActive: true },
    });
    const activePromptIds = new Set(allPrompts.map((p) => p.id));
    console.log('[submitPromptAnswers] All active prompt IDs:', Array.from(activePromptIds));

    const invalidAnswers = answers.filter(
      (a) => !activePromptIds.has(a.promptId),
    );
    console.log('[submitPromptAnswers] Invalid answers:', invalidAnswers);

    if (invalidAnswers.length > 0) {
      console.warn('[submitPromptAnswers] ERROR: Some prompts are invalid or inactive:', invalidAnswers.map((a) => a.promptId));
      throw new BadRequestException(
        'Some prompts are invalid or inactive: ' +
          invalidAnswers.map((a) => a.promptId).join(', '),
      );
    }

    const profile = await this.profileRepository.findOne({
      where: { userId },
    });

    if (!profile) {
      console.error('[submitPromptAnswers] ERROR: Profile not found for user', userId);
      throw new NotFoundException('Profile not found');
    }

    try {
      // Delete existing prompt answers
      console.log('[submitPromptAnswers] Deleting existing prompt answers for profileId:', profile.id);
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

      console.log('[submitPromptAnswers] Saving prompt answers:', {
        userId,
        profileId: profile.id,
        answersCount: answerEntities.length,
        answers: answerEntities.map(a => ({ promptId: a.promptId, answer: a.answer })),
      });

      const savedAnswers = await this.promptAnswerRepository.save(answerEntities);
      
      console.log('[submitPromptAnswers] Prompt answers saved successfully:', {
        userId,
        savedCount: savedAnswers.length,
        savedIds: savedAnswers.map(a => a.id),
      });

      // Check if profile is now complete
      await this.updateProfileCompletionStatus(userId);
    } catch (error) {
      // Log the error for debugging
      console.error('[submitPromptAnswers] ERROR saving prompt answers for user', userId, ':', error);
      throw new BadRequestException(
        'Failed to save prompt answers: ' + error.message,
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
      return;
    }

    // Check completion criteria from specifications:
    // 1. Minimum 3 photos
    // 2. All required prompt answers
    // 3. All required personality questions answered
    // 4. Required profile fields: birthDate (gender and interestedInGenders are optional for now)
    const hasMinPhotos = (user.profile.photos?.length || 0) >= 3;

    // Get required prompts count and validate answers
    const requiredPrompts = await this.promptRepository.find({
      where: { isActive: true, isRequired: true },
    });

    const answeredPromptIds = new Set(
      (user.profile.promptAnswers || []).map((a) => a.promptId),
    );

    const missingRequiredPrompts = requiredPrompts.filter(
      (p) => !answeredPromptIds.has(p.id),
    );

    const hasPromptAnswers = missingRequiredPrompts.length === 0;

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

    // Update user status
    if (
      user.isProfileCompleted !== isProfileCompleted ||
      user.isOnboardingCompleted !== isOnboardingCompleted
    ) {
      user.isProfileCompleted = isProfileCompleted;
      user.isOnboardingCompleted = isOnboardingCompleted;
      await this.userRepository.save(user);
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
      promptAnswers: {
        required: number;
        current: number;
        satisfied: boolean;
        missing: Array<{ id: string; text: string }>;
      };
      personalityQuestionnaire: boolean;
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

    // Get required prompts and check if user has answered all of them
    const requiredPrompts = await this.promptRepository.find({
      where: { isActive: true, isRequired: true },
    });

    // Debug: Log all prompts for verification
    const allPrompts = await this.promptRepository.find({
      where: { isActive: true },
    });
    
    console.log('All active prompts in database:', {
      totalActive: allPrompts.length,
      requiredPrompts: allPrompts.filter(p => p.isRequired).map(p => ({ id: p.id, text: p.text, isRequired: p.isRequired, order: p.order })),
      optionalPrompts: allPrompts.filter(p => !p.isRequired).map(p => ({ id: p.id, text: p.text, isRequired: p.isRequired, order: p.order })),
      totalRequired: requiredPrompts.length,
    });

    const answeredPromptIds = new Set(
      (user.profile.promptAnswers || []).map((a) => a.promptId),
    );

    const missingRequiredPrompts = requiredPrompts.filter(
      (p) => !answeredPromptIds.has(p.id),
    );

    const hasPrompts = missingRequiredPrompts.length === 0;
    const promptsCount = user.profile.promptAnswers?.length || 0;
    const requiredPromptsCount = requiredPrompts.length;

    // Debug: Log prompts validation
    console.log('Prompts validation debug:', {
      userId: user.id,
      requiredPromptsCount,
      promptsCount,
      answeredPromptIds: Array.from(answeredPromptIds),
      requiredPromptIds: requiredPrompts.map(p => p.id),
      missingRequiredPrompts: missingRequiredPrompts.map(p => ({ id: p.id, text: p.text })),
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
      const missingPromptTexts = missingRequiredPrompts
        .map((p) => p.text)
        .slice(0, 3) // Show max 3 for readability
        .join(', ');
      const moreCount = missingRequiredPrompts.length - 3;
      const moreText = moreCount > 0 ? ` and ${moreCount} more` : '';
      missingSteps.push(
        `Answer required prompts: ${missingPromptTexts}${moreText}`,
      );
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
      const missingCount = missingRequiredPrompts.length;
      nextStep = `Answer ${missingCount} required prompt${missingCount > 1 ? 's' : ''}`;
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
        promptAnswers: {
          required: requiredPromptsCount,
          current: promptsCount,
          satisfied: hasPrompts,
          missing: missingRequiredPrompts.map((p) => ({
            id: p.id,
            text: p.text,
          })),
        },
        personalityQuestionnaire: hasPersonalityAnswers,
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
      relations: ['profile'],
    });

    if (!user || !user.profile) {
      throw new NotFoundException('Profile not found');
    }

    // Update user status
    if (statusDto.status) {
      user.status = statusDto.status as any; // Will be validated by enum
    }

    // Force update completion status if requested
    if (statusDto.completed) {
      user.isProfileCompleted = true;
      user.isOnboardingCompleted = true;
    } else {
      // Recalculate completion status
      await this.updateProfileCompletionStatus(userId);
      return; // updateProfileCompletionStatus already saves the user
    }

    await this.userRepository.save(user);
  }
}
