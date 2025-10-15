import {
  IsString,
  IsOptional,
  IsNumber,
  IsBoolean,
  IsArray,
  ValidateNested,
  IsUUID,
  IsUrl,
  ArrayMinSize,
  ArrayMaxSize,
  MaxLength,
  IsEnum,
  IsDateString,
  Min,
  Max,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Gender } from '../../../common/enums';

export class ProfileResponseDto {
  @ApiProperty({ description: 'Unique profile identifier' })
  id: string;

  @ApiProperty({ description: 'User ID associated with this profile' })
  userId: string;

  @ApiProperty({ description: 'First name' })
  firstName: string;

  @ApiPropertyOptional({ description: 'Last name' })
  lastName?: string;

  @ApiPropertyOptional({ description: 'Username/pseudonym', maxLength: 30 })
  pseudo?: string;

  @ApiPropertyOptional({ description: 'Birth date' })
  birthDate?: Date;

  @ApiPropertyOptional({ enum: Gender, description: 'User gender' })
  gender?: Gender;

  @ApiPropertyOptional({
    enum: Gender,
    isArray: true,
    description: 'Genders the user is interested in',
  })
  interestedInGenders?: Gender[];

  @ApiPropertyOptional({ description: 'User biography', maxLength: 600 })
  bio?: string;

  @ApiPropertyOptional({ description: 'Job title', maxLength: 100 })
  jobTitle?: string;

  @ApiPropertyOptional({ description: 'Company name', maxLength: 100 })
  company?: string;

  @ApiPropertyOptional({ description: 'Education/school', maxLength: 100 })
  education?: string;

  @ApiPropertyOptional({ description: 'Location/city' })
  location?: string;

  @ApiPropertyOptional({ description: 'Latitude coordinate' })
  latitude?: number;

  @ApiPropertyOptional({ description: 'Longitude coordinate' })
  longitude?: number;

  @ApiPropertyOptional({ description: 'Maximum distance for matches (km)' })
  maxDistance?: number;

  @ApiPropertyOptional({ description: 'Minimum age preference' })
  minAge?: number;

  @ApiPropertyOptional({ description: 'Maximum age preference' })
  maxAge?: number;

  @ApiPropertyOptional({
    type: [String],
    description: 'User interests/hobbies',
  })
  interests?: string[];

  @ApiPropertyOptional({
    type: [String],
    description: 'Languages spoken',
  })
  languages?: string[];

  @ApiPropertyOptional({ description: 'Height in centimeters' })
  height?: number;

  @ApiPropertyOptional({ description: 'Favorite song' })
  favoriteSong?: string;

  @ApiProperty({ description: 'Whether profile is verified', default: false })
  isVerified: boolean;

  @ApiProperty({
    description: 'Whether profile is visible to others',
    default: true,
  })
  isVisible: boolean;

  @ApiProperty({ description: 'Whether to show age on profile', default: true })
  showAge: boolean;

  @ApiProperty({
    description: 'Whether to show distance on profile',
    default: true,
  })
  showDistance: boolean;

  @ApiProperty({
    description: 'Whether to show profile in discovery',
    default: true,
  })
  showMeInDiscovery: boolean;

  @ApiProperty({ description: 'Profile creation timestamp' })
  createdAt: Date;

  @ApiProperty({ description: 'Profile last update timestamp' })
  updatedAt: Date;
}

export class UpdateProfileDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(50)
  firstName?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(50)
  lastName?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(30)
  pseudo?: string;

  @ApiPropertyOptional({ description: 'Birth date in YYYY-MM-DD format' })
  @IsOptional()
  @IsDateString()
  birthDate?: string;

  @ApiPropertyOptional({ enum: Gender })
  @IsOptional()
  @IsEnum(Gender)
  gender?: Gender;

  @ApiPropertyOptional({ enum: Gender, isArray: true })
  @IsOptional()
  @IsArray()
  @IsEnum(Gender, { each: true })
  interestedInGenders?: Gender[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(600)
  bio?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(100)
  jobTitle?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(100)
  company?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(100)
  education?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(100)
  location?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 8 })
  latitude?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 8 })
  longitude?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  @Min(1)
  @Max(500)
  maxDistance?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  @Min(18)
  @Max(100)
  minAge?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  @Min(18)
  @Max(100)
  maxAge?: number;

  @ApiPropertyOptional({ type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  interests?: string[];

  @ApiPropertyOptional({ type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  languages?: string[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  @Min(100)
  @Max(250)
  height?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(200)
  favoriteSong?: string;

  // Legacy fields for backwards compatibility
  @ApiPropertyOptional({
    deprecated: true,
    description: 'Use birthDate instead - will be calculated from birthDate',
  })
  @IsOptional()
  @IsNumber()
  age?: number;

  @ApiPropertyOptional({
    deprecated: true,
    description: 'Use jobTitle instead',
  })
  @IsOptional()
  @IsString()
  job?: string;

  @ApiPropertyOptional({
    deprecated: true,
    description: 'Use education instead',
  })
  @IsOptional()
  @IsString()
  school?: string;
}

export class PersonalityAnswerDto {
  @ApiProperty()
  @IsUUID()
  questionId: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  textAnswer?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  numericAnswer?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  booleanAnswer?: boolean;

  @ApiPropertyOptional({ type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  multipleChoiceAnswer?: string[];
}

export class SubmitPersonalityAnswersDto {
  @ApiProperty({ type: [PersonalityAnswerDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PersonalityAnswerDto)
  @ArrayMinSize(1)
  answers: PersonalityAnswerDto[];
}

export class PhotoDto {
  @ApiProperty()
  @IsUrl()
  url: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isMain?: boolean;
}

export class UploadPhotosDto {
  @ApiProperty({ type: [PhotoDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PhotoDto)
  @ArrayMinSize(1)
  photos: PhotoDto[];
}

export class PromptAnswerDto {
  @ApiProperty()
  @IsUUID()
  promptId: string;

  @ApiProperty({
    description: 'Answer text (max 150 characters)',
    maxLength: 150,
  })
  @IsString()
  @MaxLength(150)
  answer: string;
}

export class SubmitPromptAnswersDto {
  @ApiProperty({
    type: [PromptAnswerDto],
    description: 'Array of prompt answers (exactly 3 required)',
  })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PromptAnswerDto)
  @ArrayMinSize(3)
  @ArrayMaxSize(3)
  answers: PromptAnswerDto[];
}

export class UpdatePromptAnswerDto {
  @ApiPropertyOptional({
    description: 'ID of existing answer (optional for updates)',
  })
  @IsOptional()
  @IsUUID()
  id?: string;

  @ApiProperty({ description: 'ID of the prompt being answered' })
  @IsUUID()
  promptId: string;

  @ApiProperty({
    description: 'Answer text (max 150 characters)',
    maxLength: 150,
  })
  @IsString()
  @MaxLength(150)
  answer: string;
}

export class UpdatePromptAnswersDto {
  @ApiProperty({
    type: [UpdatePromptAnswerDto],
    description: 'Array of prompt answers (exactly 3 required)',
  })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => UpdatePromptAnswerDto)
  @ArrayMinSize(3)
  @ArrayMaxSize(3)
  answers: UpdatePromptAnswerDto[];
}

export class UpdateProfileStatusDto {
  @ApiProperty({
    description:
      'Set profile visibility. Profile must be complete to set to true.',
  })
  @IsBoolean()
  isVisible: boolean;
}

export class UpdatePhotoOrderDto {
  @ApiProperty({
    description: 'New order position for the photo (1-6)',
    minimum: 1,
    maximum: 6,
  })
  @IsNumber({ allowNaN: false, allowInfinity: false })
  @Min(1)
  @Max(6)
  newOrder: number;
}
