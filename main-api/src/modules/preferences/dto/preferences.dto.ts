import { IsBoolean, IsOptional, IsEnum, IsNumber } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { FontSize, Gender } from '../../../common/enums';

export class NotificationPreferencesDto {
  @ApiProperty({ description: 'Daily selection notifications', example: true })
  dailySelection: boolean;

  @ApiProperty({ description: 'New match notifications', example: true })
  newMatches: boolean;

  @ApiProperty({ description: 'New message notifications', example: true })
  newMessages: boolean;

  @ApiProperty({ description: 'Chat expiring notifications', example: true })
  chatExpiring: boolean;

  @ApiProperty({
    description: 'Subscription update notifications',
    example: true,
  })
  subscriptionUpdates: boolean;

  @ApiProperty({ description: 'Marketing email notifications', example: false })
  marketingEmails: boolean;

  @ApiProperty({ description: 'Push notifications enabled', example: true })
  pushNotifications: boolean;

  @ApiProperty({ description: 'Email notifications enabled', example: true })
  emailNotifications: boolean;
}

export class PrivacyPreferencesDto {
  @ApiProperty({ description: 'Analytics tracking consent', example: false })
  analytics: boolean;

  @ApiProperty({
    description: 'Marketing communications consent',
    example: false,
  })
  marketing: boolean;

  @ApiProperty({ description: 'Functional cookies consent', example: true })
  functionalCookies: boolean;

  @ApiPropertyOptional({ description: 'Data retention period in days' })
  dataRetention?: number;
}

export class AccessibilityPreferencesDto {
  @ApiProperty({
    enum: FontSize,
    description: 'Font size preference',
    example: FontSize.MEDIUM,
  })
  fontSize: FontSize;

  @ApiProperty({ description: 'High contrast mode enabled', example: false })
  highContrast: boolean;

  @ApiProperty({ description: 'Reduced motion enabled', example: false })
  reducedMotion: boolean;

  @ApiProperty({ description: 'Screen reader support enabled', example: false })
  screenReader: boolean;
}

export class MatchingFiltersDto {
  @ApiPropertyOptional({ description: 'Minimum age preference', example: 25 })
  ageMin?: number;

  @ApiPropertyOptional({ description: 'Maximum age preference', example: 35 })
  ageMax?: number;

  @ApiPropertyOptional({
    description: 'Maximum distance in kilometers',
    example: 50,
  })
  maxDistance?: number;

  @ApiPropertyOptional({
    enum: Gender,
    isArray: true,
    description: 'Preferred genders',
    example: [Gender.WOMAN],
  })
  preferredGenders?: Gender[];

  @ApiPropertyOptional({ description: 'Show me in discovery', example: true })
  showMeInDiscovery?: boolean;
}

export class UserPreferencesDto {
  @ApiProperty({ type: NotificationPreferencesDto })
  notifications: NotificationPreferencesDto;

  @ApiProperty({ type: PrivacyPreferencesDto })
  privacy: PrivacyPreferencesDto;

  @ApiProperty({ type: AccessibilityPreferencesDto })
  accessibility: AccessibilityPreferencesDto;

  @ApiProperty({ type: MatchingFiltersDto })
  filters: MatchingFiltersDto;
}

export class UpdateNotificationPreferencesDto {
  @ApiPropertyOptional({ description: 'Daily selection notifications' })
  @IsOptional()
  @IsBoolean()
  dailySelection?: boolean;

  @ApiPropertyOptional({ description: 'New match notifications' })
  @IsOptional()
  @IsBoolean()
  newMatches?: boolean;

  @ApiPropertyOptional({ description: 'New message notifications' })
  @IsOptional()
  @IsBoolean()
  newMessages?: boolean;

  @ApiPropertyOptional({ description: 'Chat expiring notifications' })
  @IsOptional()
  @IsBoolean()
  chatExpiring?: boolean;

  @ApiPropertyOptional({ description: 'Subscription update notifications' })
  @IsOptional()
  @IsBoolean()
  subscriptionUpdates?: boolean;

  @ApiPropertyOptional({ description: 'Marketing email notifications' })
  @IsOptional()
  @IsBoolean()
  marketingEmails?: boolean;

  @ApiPropertyOptional({ description: 'Push notifications enabled' })
  @IsOptional()
  @IsBoolean()
  pushNotifications?: boolean;

  @ApiPropertyOptional({ description: 'Email notifications enabled' })
  @IsOptional()
  @IsBoolean()
  emailNotifications?: boolean;
}

export class UpdatePrivacyPreferencesDto {
  @ApiPropertyOptional({ description: 'Analytics tracking consent' })
  @IsOptional()
  @IsBoolean()
  analytics?: boolean;

  @ApiPropertyOptional({ description: 'Marketing communications consent' })
  @IsOptional()
  @IsBoolean()
  marketing?: boolean;

  @ApiPropertyOptional({ description: 'Functional cookies consent' })
  @IsOptional()
  @IsBoolean()
  functionalCookies?: boolean;

  @ApiPropertyOptional({ description: 'Data retention period in days' })
  @IsOptional()
  @IsNumber()
  dataRetention?: number;
}

export class UpdateAccessibilityPreferencesDto {
  @ApiPropertyOptional({ enum: FontSize, description: 'Font size preference' })
  @IsOptional()
  @IsEnum(FontSize)
  fontSize?: FontSize;

  @ApiPropertyOptional({ description: 'High contrast mode enabled' })
  @IsOptional()
  @IsBoolean()
  highContrast?: boolean;

  @ApiPropertyOptional({ description: 'Reduced motion enabled' })
  @IsOptional()
  @IsBoolean()
  reducedMotion?: boolean;

  @ApiPropertyOptional({ description: 'Screen reader support enabled' })
  @IsOptional()
  @IsBoolean()
  screenReader?: boolean;
}

export class UpdateMatchingFiltersDto {
  @ApiPropertyOptional({ description: 'Minimum age preference' })
  @IsOptional()
  @IsNumber()
  ageMin?: number;

  @ApiPropertyOptional({ description: 'Maximum age preference' })
  @IsOptional()
  @IsNumber()
  ageMax?: number;

  @ApiPropertyOptional({ description: 'Maximum distance in kilometers' })
  @IsOptional()
  @IsNumber()
  maxDistance?: number;

  @ApiPropertyOptional({
    enum: Gender,
    isArray: true,
    description: 'Preferred genders',
  })
  @IsOptional()
  @IsEnum(Gender, { each: true })
  preferredGenders?: Gender[];

  @ApiPropertyOptional({ description: 'Show me in discovery' })
  @IsOptional()
  @IsBoolean()
  showMeInDiscovery?: boolean;
}

export class UpdateUserPreferencesDto {
  @ApiPropertyOptional({ type: UpdateNotificationPreferencesDto })
  @IsOptional()
  notifications?: UpdateNotificationPreferencesDto;

  @ApiPropertyOptional({ type: UpdatePrivacyPreferencesDto })
  @IsOptional()
  privacy?: UpdatePrivacyPreferencesDto;

  @ApiPropertyOptional({ type: UpdateAccessibilityPreferencesDto })
  @IsOptional()
  accessibility?: UpdateAccessibilityPreferencesDto;

  @ApiPropertyOptional({ type: UpdateMatchingFiltersDto })
  @IsOptional()
  filters?: UpdateMatchingFiltersDto;
}
