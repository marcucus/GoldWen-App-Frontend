export enum UserStatus {
  ACTIVE = 'active',
  INACTIVE = 'inactive',
  SUSPENDED = 'suspended',
  DELETED = 'deleted',
}

export enum Gender {
  MAN = 'man',
  WOMAN = 'woman',
  NON_BINARY = 'non_binary',
  OTHER = 'other',
}

export enum SubscriptionStatus {
  ACTIVE = 'active',
  CANCELLED = 'cancelled',
  EXPIRED = 'expired',
  PENDING = 'pending',
}

export enum SubscriptionPlan {
  FREE = 'free',
  GOLDWEN_PLUS = 'goldwen_plus',
}

export enum SubscriptionTier {
  FREE = 'free',
  PREMIUM = 'premium',
}

export enum MatchStatus {
  PENDING = 'pending',
  MATCHED = 'matched',
  REJECTED = 'rejected',
  EXPIRED = 'expired',
}

export enum ChatStatus {
  ACTIVE = 'active',
  EXPIRED = 'expired',
  ARCHIVED = 'archived',
}

export enum MessageType {
  TEXT = 'text',
  EMOJI = 'emoji',
  SYSTEM = 'system',
}

export enum NotificationType {
  DAILY_SELECTION = 'daily_selection',
  NEW_MATCH = 'new_match',
  NEW_MESSAGE = 'new_message',
  CHAT_EXPIRING = 'chat_expiring',
  SUBSCRIPTION_EXPIRED = 'subscription_expired',
  SUBSCRIPTION_RENEWED = 'subscription_renewed',
  SYSTEM = 'system',
}

export enum QuestionType {
  MULTIPLE_CHOICE = 'multiple_choice',
  SCALE = 'scale',
  BOOLEAN = 'boolean',
}

export enum AdminRole {
  SUPER_ADMIN = 'super_admin',
  ADMIN = 'admin',
  MODERATOR = 'moderator',
}

export enum UserRole {
  USER = 'user',
  MODERATOR = 'moderator',
  ADMIN = 'admin',
}

export enum ReportStatus {
  PENDING = 'pending',
  REVIEWED = 'reviewed',
  RESOLVED = 'resolved',
  DISMISSED = 'dismissed',
}

export enum ReportType {
  INAPPROPRIATE_CONTENT = 'inappropriate_content',
  HARASSMENT = 'harassment',
  FAKE_PROFILE = 'fake_profile',
  SPAM = 'spam',
  OTHER = 'other',
}

export enum FontSize {
  SMALL = 'small',
  MEDIUM = 'medium',
  LARGE = 'large',
  XLARGE = 'xlarge',
}

// Export new enums
export * from './error-codes.enum';
export * from './cache-strategy.enum';
