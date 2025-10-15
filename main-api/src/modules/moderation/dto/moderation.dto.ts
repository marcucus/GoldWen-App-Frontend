import { IsString, IsNotEmpty, IsOptional } from 'class-validator';

export class ModerateTextDto {
  @IsString()
  @IsNotEmpty()
  text: string;
}

export class ModerateTextBatchDto {
  @IsString({ each: true })
  @IsNotEmpty({ each: true })
  texts: string[];
}

export class ModerateImageDto {
  @IsString()
  @IsNotEmpty()
  imagePath: string;
}

export class ModerateImageUrlDto {
  @IsString()
  @IsNotEmpty()
  imageUrl: string;
}

export class PhotoModerationStatusDto {
  @IsString()
  @IsNotEmpty()
  photoId: string;
}

export class PhotoModerationWebhookDto {
  @IsString()
  @IsNotEmpty()
  photoId: string;

  @IsString()
  @IsOptional()
  userId?: string;

  @IsString()
  @IsOptional()
  action?: 'uploaded' | 'updated';
}
