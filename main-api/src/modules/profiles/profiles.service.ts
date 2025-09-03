import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

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
      // Remove age from the DTO since it's not a database field
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
      throw new BadRequestException(
        `Missing answers for required questions: ${missingRequired.map((q) => q.question).join(', ')}`,
      );
    }

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

    // Validate minimum photos requirement
    const totalPhotos = (profile.photos?.length || 0) + files.length;
    if (totalPhotos < 3) {
      throw new BadRequestException('Minimum 3 photos required');
    }

    // Create photo entities
    const photoEntities = files.map((file, index) => {
      return this.photoRepository.create({
        profileId: profile.id,
        url: `/uploads/photos/${file.filename}`,
        filename: file.filename,
        mimeType: file.mimetype,
        fileSize: file.size,
        order: (profile.photos?.length || 0) + index + 1,
        isPrimary: (profile.photos?.length || 0) === 0 && index === 0,
        isApproved: true, // Auto-approve for MVP, can be changed later
      });
    });

    const savedPhotos = await this.photoRepository.save(photoEntities);

    // Check if profile is now complete
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

  async getPrompts(): Promise<Prompt[]> {
    return this.promptRepository.find({
      where: { isActive: true },
      order: { order: 'ASC' },
    });
  }

  async submitPromptAnswers(
    userId: string,
    promptAnswersDto: SubmitPromptAnswersDto,
  ): Promise<void> {
    const { answers } = promptAnswersDto;

    // Validate that 3 prompts are answered (as required by specifications)
    if (answers.length !== 3) {
      throw new BadRequestException('Exactly 3 prompt answers are required');
    }

    const profile = await this.profileRepository.findOne({
      where: { userId },
    });

    if (!profile) {
      throw new NotFoundException('Profile not found');
    }

    // Delete existing prompt answers
    await this.promptAnswerRepository.delete({ profileId: profile.id });

    // Create new prompt answers
    const answerEntities = answers.map((answer) => {
      return this.promptAnswerRepository.create({
        profileId: profile.id,
        promptId: answer.promptId,
        answer: answer.answer,
      });
    });

    await this.promptAnswerRepository.save(answerEntities);

    // Check if profile is now complete
    await this.updateProfileCompletionStatus(userId);
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
    // 2. 3 prompt answers
    // 3. All required personality questions answered
    // 4. Required profile fields: birthDate (gender and interestedInGenders are optional for now)
    const hasMinPhotos = (user.profile.photos?.length || 0) >= 3;
    const hasPromptAnswers = (user.profile.promptAnswers?.length || 0) >= 3;
    const hasRequiredProfileFields = !!(
      user.profile.birthDate &&
      user.profile.bio
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
    isCompleted: boolean;
    hasPhotos: boolean;
    hasPrompts: boolean;
    hasPersonalityAnswers: boolean;
    hasRequiredProfileFields: boolean;
    missingSteps: string[];
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

    const hasPhotos = (user.profile.photos?.length || 0) >= 3;
    const hasPrompts = (user.profile.promptAnswers?.length || 0) >= 3;
    const hasRequiredProfileFields = !!(
      user.profile.birthDate &&
      user.profile.gender &&
      user.profile.interestedInGenders &&
      user.profile.interestedInGenders.length > 0
    );

    const requiredQuestionsCount =
      await this.personalityQuestionRepository.count({
        where: { isActive: true, isRequired: true },
      });

    const hasPersonalityAnswers =
      (user.personalityAnswers?.length || 0) >= requiredQuestionsCount;

    const missingSteps: string[] = [];
    if (!hasPhotos) missingSteps.push('Upload at least 3 photos');
    if (!hasPrompts) missingSteps.push('Answer 3 prompts');
    if (!hasPersonalityAnswers)
      missingSteps.push('Complete personality questionnaire');
    if (!hasRequiredProfileFields) {
      const missingFields = [];
      if (!user.profile.birthDate) missingFields.push('birth date');
      if (!user.profile.gender) missingFields.push('gender');
      if (
        !user.profile.interestedInGenders ||
        user.profile.interestedInGenders.length === 0
      )
        missingFields.push('interested genders');
      missingSteps.push(
        `Complete basic profile information: ${missingFields.join(', ')}`,
      );
    }

    return {
      isCompleted:
        hasPhotos &&
        hasPrompts &&
        hasPersonalityAnswers &&
        hasRequiredProfileFields,
      hasPhotos,
      hasPrompts,
      hasPersonalityAnswers,
      hasRequiredProfileFields,
      missingSteps,
    };
  }
}
