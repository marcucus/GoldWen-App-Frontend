export enum StandardErrorCode {
  // Authentication errors (401)
  UNAUTHORIZED = 'UNAUTHORIZED',
  TOKEN_EXPIRED = 'TOKEN_EXPIRED',
  INVALID_CREDENTIALS = 'INVALID_CREDENTIALS',
  ACCOUNT_LOCKED = 'ACCOUNT_LOCKED',

  // Authorization errors (403)
  FORBIDDEN = 'FORBIDDEN',
  INSUFFICIENT_PERMISSIONS = 'INSUFFICIENT_PERMISSIONS',
  SUBSCRIPTION_REQUIRED = 'SUBSCRIPTION_REQUIRED',

  // Validation errors (400)
  VALIDATION_ERROR = 'VALIDATION_ERROR',
  INVALID_INPUT = 'INVALID_INPUT',
  MISSING_REQUIRED_FIELD = 'MISSING_REQUIRED_FIELD',
  INVALID_FILE_FORMAT = 'INVALID_FILE_FORMAT',
  FILE_TOO_LARGE = 'FILE_TOO_LARGE',

  // Not found errors (404)
  RESOURCE_NOT_FOUND = 'RESOURCE_NOT_FOUND',
  USER_NOT_FOUND = 'USER_NOT_FOUND',
  PROFILE_NOT_FOUND = 'PROFILE_NOT_FOUND',
  CONVERSATION_NOT_FOUND = 'CONVERSATION_NOT_FOUND',

  // Conflict errors (409)
  RESOURCE_ALREADY_EXISTS = 'RESOURCE_ALREADY_EXISTS',
  EMAIL_ALREADY_EXISTS = 'EMAIL_ALREADY_EXISTS',
  PHONE_ALREADY_EXISTS = 'PHONE_ALREADY_EXISTS',

  // Rate limiting (429)
  RATE_LIMIT_EXCEEDED = 'RATE_LIMIT_EXCEEDED',
  TOO_MANY_REQUESTS = 'TOO_MANY_REQUESTS',
  DAILY_QUOTA_EXCEEDED = 'DAILY_QUOTA_EXCEEDED',
  QUOTA_LIMIT_REACHED = 'QUOTA_LIMIT_REACHED',

  // Server errors (500)
  INTERNAL_SERVER_ERROR = 'INTERNAL_SERVER_ERROR',
  DATABASE_ERROR = 'DATABASE_ERROR',
  EXTERNAL_SERVICE_ERROR = 'EXTERNAL_SERVICE_ERROR',

  // Service unavailable (503)
  SERVICE_UNAVAILABLE = 'SERVICE_UNAVAILABLE',
  MAINTENANCE_MODE = 'MAINTENANCE_MODE',
}

export const ErrorRecoveryActions = {
  [StandardErrorCode.UNAUTHORIZED]: 'Please log in again',
  [StandardErrorCode.TOKEN_EXPIRED]:
    'Your session has expired. Please log in again.',
  [StandardErrorCode.INVALID_CREDENTIALS]:
    'Please check your email and password',
  [StandardErrorCode.ACCOUNT_LOCKED]:
    'Your account has been locked. Please contact support.',

  [StandardErrorCode.FORBIDDEN]:
    'You do not have permission to access this resource',
  [StandardErrorCode.INSUFFICIENT_PERMISSIONS]:
    'Please upgrade your account or contact support',
  [StandardErrorCode.SUBSCRIPTION_REQUIRED]:
    'This feature requires a premium subscription',

  [StandardErrorCode.VALIDATION_ERROR]: 'Please check your input and try again',
  [StandardErrorCode.INVALID_INPUT]: 'Please correct the highlighted fields',
  [StandardErrorCode.MISSING_REQUIRED_FIELD]:
    'Please fill in all required fields',
  [StandardErrorCode.INVALID_FILE_FORMAT]:
    'Please upload a valid file format (JPG, PNG)',
  [StandardErrorCode.FILE_TOO_LARGE]: 'Please upload a smaller file (max 5MB)',

  [StandardErrorCode.RESOURCE_NOT_FOUND]:
    'The requested resource was not found',
  [StandardErrorCode.USER_NOT_FOUND]: 'User account not found',
  [StandardErrorCode.PROFILE_NOT_FOUND]: 'Profile not found',
  [StandardErrorCode.CONVERSATION_NOT_FOUND]: 'Conversation not found',

  [StandardErrorCode.RESOURCE_ALREADY_EXISTS]: 'This resource already exists',
  [StandardErrorCode.EMAIL_ALREADY_EXISTS]:
    'An account with this email already exists',
  [StandardErrorCode.PHONE_ALREADY_EXISTS]:
    'An account with this phone number already exists',

  [StandardErrorCode.RATE_LIMIT_EXCEEDED]:
    'Too many requests. Please try again in a few minutes.',
  [StandardErrorCode.TOO_MANY_REQUESTS]: 'Please slow down and try again later',
  [StandardErrorCode.DAILY_QUOTA_EXCEEDED]:
    'Vous avez utilisé tous vos choix quotidiens. Revenez demain !',
  [StandardErrorCode.QUOTA_LIMIT_REACHED]:
    'Quota quotidien atteint. Passez à GoldWen Plus pour plus de choix.',

  [StandardErrorCode.INTERNAL_SERVER_ERROR]:
    'Something went wrong. Please try again later.',
  [StandardErrorCode.DATABASE_ERROR]:
    'Database temporarily unavailable. Please try again.',
  [StandardErrorCode.EXTERNAL_SERVICE_ERROR]:
    'External service error. Please try again later.',

  [StandardErrorCode.SERVICE_UNAVAILABLE]: 'Service is temporarily unavailable',
  [StandardErrorCode.MAINTENANCE_MODE]:
    'We are currently performing maintenance. Please try again later.',
};
