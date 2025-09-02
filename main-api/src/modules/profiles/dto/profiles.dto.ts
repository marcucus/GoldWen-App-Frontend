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
  MaxLength,
  IsEnum,
  IsDateString,
  Min,
  Max,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Gender } from '../../../common/enums';

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
  @MaxLength(500)
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

  @ApiProperty()
  @IsString()
  @MaxLength(300)
  answer: string;
}

export class SubmitPromptAnswersDto {
  @ApiProperty({ type: [PromptAnswerDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PromptAnswerDto)
  @ArrayMinSize(3)
  answers: PromptAnswerDto[];
}
