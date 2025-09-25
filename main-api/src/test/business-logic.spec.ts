import { UserStatus, MatchStatus, ChatStatus, SubscriptionTier, NotificationType } from '../common/enums';

describe('Business Logic Core Tests', () => {
  describe('User Profile Completion Logic', () => {
    it('should validate profile completion requirements', () => {
      const profileData = {
        hasPhotos: false,
        photoCount: 0,
        hasPrompts: false,
        promptCount: 0,
        hasPersonalityAnswers: false,
        personalityAnswerCount: 0,
        hasBirthDate: false,
        hasBio: false,
      };

      // Test minimum requirements
      expect(isProfileComplete(profileData)).toBe(false);

      // Add photos (minimum 3 required)
      profileData.hasPhotos = true;
      profileData.photoCount = 3;
      expect(isProfileComplete(profileData)).toBe(false);

      // Add prompts (minimum 3 required)
      profileData.hasPrompts = true;
      profileData.promptCount = 3;
      expect(isProfileComplete(profileData)).toBe(false);

      // Add personality answers (10 required)
      profileData.hasPersonalityAnswers = true;
      profileData.personalityAnswerCount = 10;
      expect(isProfileComplete(profileData)).toBe(false);

      // Add birth date and bio
      profileData.hasBirthDate = true;
      profileData.hasBio = true;
      expect(isProfileComplete(profileData)).toBe(true);
    });

    it('should calculate completion percentage correctly', () => {
      const profileData = {
        hasPhotos: false,
        photoCount: 0,
        hasPrompts: false,
        promptCount: 0,
        hasPersonalityAnswers: false,
        personalityAnswerCount: 0,
        hasBirthDate: false,
        hasBio: false,
      };

      expect(calculateCompletionPercentage(profileData)).toBe(0);

      // Each component is worth 25% (photos, prompts, personality, basic info)
      profileData.hasPhotos = true;
      profileData.photoCount = 3;
      expect(calculateCompletionPercentage(profileData)).toBe(25);

      profileData.hasPrompts = true;
      profileData.promptCount = 3;
      expect(calculateCompletionPercentage(profileData)).toBe(50);

      profileData.hasPersonalityAnswers = true;
      profileData.personalityAnswerCount = 10;
      expect(calculateCompletionPercentage(profileData)).toBe(75);

      profileData.hasBirthDate = true;
      profileData.hasBio = true;
      expect(calculateCompletionPercentage(profileData)).toBe(100);
    });
  });

  describe('Daily Selection Logic', () => {
    it('should enforce daily choice limits correctly', () => {
      // Free tier: 1 choice per day
      const freeUser = {
        tier: SubscriptionTier.FREE,
        dailyChoicesUsed: 0,
        dailyChoicesLimit: 1,
      };

      expect(canMakeChoice(freeUser)).toBe(true);
      expect(getRemainingChoices(freeUser)).toBe(1);

      freeUser.dailyChoicesUsed = 1;
      expect(canMakeChoice(freeUser)).toBe(false);
      expect(getRemainingChoices(freeUser)).toBe(0);

      // Premium tier: 3 choices per day
      const premiumUser = {
        tier: SubscriptionTier.PREMIUM,
        dailyChoicesUsed: 0,
        dailyChoicesLimit: 3,
      };

      expect(canMakeChoice(premiumUser)).toBe(true);
      expect(getRemainingChoices(premiumUser)).toBe(3);

      premiumUser.dailyChoicesUsed = 2;
      expect(canMakeChoice(premiumUser)).toBe(true);
      expect(getRemainingChoices(premiumUser)).toBe(1);

      premiumUser.dailyChoicesUsed = 3;
      expect(canMakeChoice(premiumUser)).toBe(false);
      expect(getRemainingChoices(premiumUser)).toBe(0);
    });

    it('should handle daily selection refresh logic', () => {
      const lastRefresh = new Date('2023-12-01T12:00:00Z');
      const now = new Date('2023-12-02T12:00:00Z');

      expect(shouldRefreshSelection(lastRefresh, now)).toBe(true);

      // Same day, no refresh needed
      const sameDay = new Date('2023-12-01T18:00:00Z');
      expect(shouldRefreshSelection(lastRefresh, sameDay)).toBe(false);
    });
  });

  describe('Match System Logic', () => {
    it('should handle mutual matching correctly', () => {
      const userAChoice = {
        userId: 'user-a',
        targetUserId: 'user-b',
        timestamp: new Date(),
      };

      const userBChoice = {
        userId: 'user-b',
        targetUserId: 'user-a',
        timestamp: new Date(),
      };

      expect(isMutualMatch([userAChoice], userBChoice)).toBe(true);

      const userCChoice = {
        userId: 'user-c',
        targetUserId: 'user-a',
        timestamp: new Date(),
      };

      expect(isMutualMatch([userAChoice], userCChoice)).toBe(false);
    });

    it('should validate match status transitions', () => {
      // Valid transitions
      expect(isValidStatusTransition(MatchStatus.PENDING, MatchStatus.MATCHED)).toBe(true);
      expect(isValidStatusTransition(MatchStatus.PENDING, MatchStatus.REJECTED)).toBe(true);
      expect(isValidStatusTransition(MatchStatus.MATCHED, MatchStatus.EXPIRED)).toBe(true);

      // Invalid transitions
      expect(isValidStatusTransition(MatchStatus.MATCHED, MatchStatus.PENDING)).toBe(false);
      expect(isValidStatusTransition(MatchStatus.REJECTED, MatchStatus.MATCHED)).toBe(false);
    });
  });

  describe('Chat Expiration Logic', () => {
    it('should calculate chat expiration correctly', () => {
      const createdAt = new Date('2023-12-01T12:00:00Z');
      const expiresAt = calculateChatExpiration(createdAt);

      expect(expiresAt.getTime() - createdAt.getTime()).toBe(24 * 60 * 60 * 1000); // 24 hours
    });

    it('should determine if chat is expired', () => {
      const now = new Date('2023-12-02T12:00:00Z');
      const expiredChat = {
        createdAt: new Date('2023-12-01T11:00:00Z'),
        expiresAt: new Date('2023-12-02T11:00:00Z'),
      };

      expect(isChatExpired(expiredChat, now)).toBe(true);

      const activeChat = {
        createdAt: new Date('2023-12-01T13:00:00Z'),
        expiresAt: new Date('2023-12-02T13:00:00Z'),
      };

      expect(isChatExpired(activeChat, now)).toBe(false);
    });

    it('should determine if chat is expiring soon', () => {
      const now = new Date('2023-12-02T11:30:00Z');
      const expiringSoonChat = {
        expiresAt: new Date('2023-12-02T12:00:00Z'),
      };

      expect(isChatExpiringSoon(expiringSoonChat, now)).toBe(true);

      const notExpiringSoonChat = {
        expiresAt: new Date('2023-12-02T13:00:00Z'),
      };

      expect(isChatExpiringSoon(notExpiringSoonChat, now)).toBe(false);
    });
  });

  describe('Notification Logic', () => {
    it('should determine notification types for different events', () => {
      expect(getNotificationTypeForEvent('new_match')).toBe(NotificationType.NEW_MATCH);
      expect(getNotificationTypeForEvent('new_message')).toBe(NotificationType.NEW_MESSAGE);
      expect(getNotificationTypeForEvent('daily_selection')).toBe(NotificationType.DAILY_SELECTION);
      expect(getNotificationTypeForEvent('chat_expiring')).toBe(NotificationType.CHAT_EXPIRING);
    });

    it('should validate notification timing', () => {
      const now = new Date('2023-12-01T12:00:00Z');
      
      // Daily selection should be sent at noon
      expect(isDailySelectionTime(now)).toBe(true);
      
      const morningTime = new Date('2023-12-01T09:00:00Z');
      expect(isDailySelectionTime(morningTime)).toBe(false);
    });
  });

  describe('GDPR Compliance Logic', () => {
    it('should validate data retention periods', () => {
      const userInactive1Year = {
        lastActivity: new Date(Date.now() - 366 * 24 * 60 * 60 * 1000),
      };

      expect(shouldArchiveUserData(userInactive1Year)).toBe(true);

      const recentUser = {
        lastActivity: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
      };

      expect(shouldArchiveUserData(recentUser)).toBe(false);
    });

    it('should handle consent expiration', () => {
      const oldConsent = {
        consentDate: new Date(Date.now() - 400 * 24 * 60 * 60 * 1000), // More than 1 year
      };

      expect(isConsentExpired(oldConsent)).toBe(true);

      const recentConsent = {
        consentDate: new Date(Date.now() - 100 * 24 * 60 * 60 * 1000), // 100 days ago
      };

      expect(isConsentExpired(recentConsent)).toBe(false);
    });
  });
});

// Helper functions for business logic
function isProfileComplete(profile: any): boolean {
  return profile.hasPhotos && 
         profile.photoCount >= 3 &&
         profile.hasPrompts &&
         profile.promptCount >= 3 &&
         profile.hasPersonalityAnswers &&
         profile.personalityAnswerCount >= 10 &&
         profile.hasBirthDate &&
         profile.hasBio;
}

function calculateCompletionPercentage(profile: any): number {
  let percentage = 0;
  
  if (profile.hasPhotos && profile.photoCount >= 3) percentage += 25;
  if (profile.hasPrompts && profile.promptCount >= 3) percentage += 25;
  if (profile.hasPersonalityAnswers && profile.personalityAnswerCount >= 10) percentage += 25;
  if (profile.hasBirthDate && profile.hasBio) percentage += 25;
  
  return percentage;
}

function canMakeChoice(user: any): boolean {
  return user.dailyChoicesUsed < user.dailyChoicesLimit;
}

function getRemainingChoices(user: any): number {
  return Math.max(0, user.dailyChoicesLimit - user.dailyChoicesUsed);
}

function shouldRefreshSelection(lastRefresh: Date, now: Date): boolean {
  return lastRefresh.toDateString() !== now.toDateString();
}

function isMutualMatch(existingChoices: any[], newChoice: any): boolean {
  return existingChoices.some(choice => 
    choice.userId === newChoice.targetUserId && 
    choice.targetUserId === newChoice.userId
  );
}

function isValidStatusTransition(from: MatchStatus, to: MatchStatus): boolean {
  const validTransitions = {
    [MatchStatus.PENDING]: [MatchStatus.MATCHED, MatchStatus.REJECTED],
    [MatchStatus.MATCHED]: [MatchStatus.EXPIRED],
    [MatchStatus.REJECTED]: [],
    [MatchStatus.EXPIRED]: [],
  };

  return validTransitions[from]?.includes(to) || false;
}

function calculateChatExpiration(createdAt: Date): Date {
  return new Date(createdAt.getTime() + 24 * 60 * 60 * 1000);
}

function isChatExpired(chat: any, now: Date): boolean {
  return now > chat.expiresAt;
}

function isChatExpiringSoon(chat: any, now: Date): boolean {
  const timeUntilExpiry = chat.expiresAt.getTime() - now.getTime();
  return timeUntilExpiry > 0 && timeUntilExpiry <= 60 * 60 * 1000; // 1 hour
}

function getNotificationTypeForEvent(event: string): NotificationType {
  const mapping: Record<string, NotificationType> = {
    'new_match': NotificationType.NEW_MATCH,
    'new_message': NotificationType.NEW_MESSAGE,
    'daily_selection': NotificationType.DAILY_SELECTION,
    'chat_expiring': NotificationType.CHAT_EXPIRING,
  };

  return mapping[event];
}

function isDailySelectionTime(date: Date): boolean {
  return date.getHours() === 12 && date.getMinutes() === 0;
}

function shouldArchiveUserData(user: any): boolean {
  const oneYearAgo = new Date(Date.now() - 365 * 24 * 60 * 60 * 1000);
  return user.lastActivity < oneYearAgo;
}

function isConsentExpired(consent: any): boolean {
  const oneYearAgo = new Date(Date.now() - 365 * 24 * 60 * 60 * 1000);
  return consent.consentDate < oneYearAgo;
}