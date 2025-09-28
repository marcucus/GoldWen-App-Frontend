export enum CacheStrategy {
  NO_CACHE = 'no-cache',
  SHORT_CACHE = 'short', // 5 minutes
  MEDIUM_CACHE = 'medium', // 1 hour
  LONG_CACHE = 'long', // 24 hours
  STATIC_CACHE = 'static', // 7 days
}

export const CacheHeaders = {
  [CacheStrategy.NO_CACHE]: {
    'Cache-Control': 'no-cache, no-store, must-revalidate',
    Pragma: 'no-cache',
    Expires: '0',
  },
  [CacheStrategy.SHORT_CACHE]: {
    'Cache-Control': 'public, max-age=300', // 5 minutes
  },
  [CacheStrategy.MEDIUM_CACHE]: {
    'Cache-Control': 'public, max-age=3600', // 1 hour
  },
  [CacheStrategy.LONG_CACHE]: {
    'Cache-Control': 'public, max-age=86400', // 24 hours
  },
  [CacheStrategy.STATIC_CACHE]: {
    'Cache-Control': 'public, max-age=604800', // 7 days
  },
};

export const ResourceCacheStrategy = {
  // User data - frequently changing
  USER_PROFILE: CacheStrategy.SHORT_CACHE,
  USER_PHOTOS: CacheStrategy.MEDIUM_CACHE,
  USER_PREFERENCES: CacheStrategy.SHORT_CACHE,

  // Matching data - semi-static
  DAILY_SELECTION: CacheStrategy.MEDIUM_CACHE,
  MATCH_RESULTS: CacheStrategy.SHORT_CACHE,

  // Static content
  LEGAL_DOCUMENTS: CacheStrategy.LONG_CACHE,
  APP_CONFIG: CacheStrategy.MEDIUM_CACHE,

  // Real-time data - no cache
  CHAT_MESSAGES: CacheStrategy.NO_CACHE,
  NOTIFICATIONS: CacheStrategy.NO_CACHE,

  // Images and media
  UPLOADED_IMAGES: CacheStrategy.STATIC_CACHE,
  PROFILE_IMAGES: CacheStrategy.LONG_CACHE,
};
