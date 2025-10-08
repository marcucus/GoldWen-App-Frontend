import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/core/services/api_service.dart';

void main() {
  group('RateLimitInfo', () {
    test('should parse rate limit headers correctly', () {
      final headers = {
        'x-ratelimit-limit': '100',
        'x-ratelimit-remaining': '25',
        'x-ratelimit-reset': '1704067200', // Unix timestamp
        'retry-after': '300',
      };

      final rateLimitInfo = RateLimitInfo.fromHeaders(headers);

      expect(rateLimitInfo.limit, equals(100));
      expect(rateLimitInfo.remaining, equals(25));
      expect(rateLimitInfo.resetTime, isNotNull);
      expect(rateLimitInfo.retryAfterSeconds, equals(300));
    });

    test('should handle missing headers gracefully', () {
      final headers = <String, String>{};
      final rateLimitInfo = RateLimitInfo.fromHeaders(headers);

      expect(rateLimitInfo.limit, isNull);
      expect(rateLimitInfo.remaining, isNull);
      expect(rateLimitInfo.resetTime, isNull);
      expect(rateLimitInfo.retryAfterSeconds, isNull);
      expect(rateLimitInfo.hasData, isFalse);
    });

    test('should handle partial headers', () {
      final headers = {
        'x-ratelimit-limit': '100',
        'x-ratelimit-remaining': '5',
      };

      final rateLimitInfo = RateLimitInfo.fromHeaders(headers);

      expect(rateLimitInfo.limit, equals(100));
      expect(rateLimitInfo.remaining, equals(5));
      expect(rateLimitInfo.resetTime, isNull);
      expect(rateLimitInfo.retryAfterSeconds, isNull);
      expect(rateLimitInfo.hasData, isTrue);
    });

    test('should detect when near limit', () {
      final rateLimitInfo = RateLimitInfo(
        limit: 100,
        remaining: 15, // 15% remaining
      );

      expect(rateLimitInfo.isNearLimit, isTrue);
    });

    test('should not detect near limit when sufficient remaining', () {
      final rateLimitInfo = RateLimitInfo(
        limit: 100,
        remaining: 50, // 50% remaining
      );

      expect(rateLimitInfo.isNearLimit, isFalse);
    });

    test('should generate retry message from retryAfterSeconds', () {
      final rateLimitInfo = RateLimitInfo(
        retryAfterSeconds: 125, // 2 minutes and 5 seconds
      );

      final message = rateLimitInfo.getRetryMessage();
      expect(message, contains('2 minute'));
      expect(message, contains('5 seconde'));
    });

    test('should generate retry message for seconds only', () {
      final rateLimitInfo = RateLimitInfo(
        retryAfterSeconds: 45,
      );

      final message = rateLimitInfo.getRetryMessage();
      expect(message, contains('45 seconde'));
      expect(message.toLowerCase(), isNot(contains('minute')));
    });

    test('should generate retry message from resetTime', () {
      final resetTime = DateTime.now().add(const Duration(minutes: 3, seconds: 30));
      final rateLimitInfo = RateLimitInfo(
        resetTime: resetTime,
      );

      final message = rateLimitInfo.getRetryMessage();
      expect(message, contains('3 minute'));
      expect(message, contains('30 seconde'));
    });

    test('should handle resetTime in the past', () {
      final resetTime = DateTime.now().subtract(const Duration(minutes: 1));
      final rateLimitInfo = RateLimitInfo(
        resetTime: resetTime,
      );

      final message = rateLimitInfo.getRetryMessage();
      expect(message, contains('Vous pouvez réessayer maintenant'));
    });

    test('should default to generic message when no retry info available', () {
      final rateLimitInfo = RateLimitInfo();

      final message = rateLimitInfo.getRetryMessage();
      expect(message, equals('Veuillez réessayer plus tard'));
    });

    test('should handle invalid header values gracefully', () {
      final headers = {
        'x-ratelimit-limit': 'invalid',
        'x-ratelimit-remaining': 'not-a-number',
        'x-ratelimit-reset': 'bad-timestamp',
        'retry-after': 'NaN',
      };

      final rateLimitInfo = RateLimitInfo.fromHeaders(headers);

      expect(rateLimitInfo.limit, isNull);
      expect(rateLimitInfo.remaining, isNull);
      expect(rateLimitInfo.resetTime, isNull);
      expect(rateLimitInfo.retryAfterSeconds, isNull);
      expect(rateLimitInfo.hasData, isFalse);
    });

    test('should handle case-insensitive header names', () {
      final headers = {
        'X-RateLimit-Limit': '100',
        'X-RATELIMIT-REMAINING': '50',
      };

      final rateLimitInfo = RateLimitInfo.fromHeaders(headers);

      expect(rateLimitInfo.limit, equals(100));
      expect(rateLimitInfo.remaining, equals(50));
    });
  });

  group('ApiException', () {
    test('should identify rate limit error correctly', () {
      final exception = ApiException(
        statusCode: 429,
        message: 'Too Many Requests',
        code: 'RATE_LIMIT_EXCEEDED',
      );

      expect(exception.isRateLimitError, isTrue);
      expect(exception.isAuthError, isFalse);
      expect(exception.isValidationError, isFalse);
    });

    test('should store rate limit info in exception', () {
      final rateLimitInfo = RateLimitInfo(
        limit: 100,
        remaining: 0,
        retryAfterSeconds: 300,
      );

      final exception = ApiException(
        statusCode: 429,
        message: 'Rate limit exceeded',
        code: 'RATE_LIMIT_EXCEEDED',
        rateLimitInfo: rateLimitInfo,
      );

      expect(exception.rateLimitInfo, isNotNull);
      expect(exception.rateLimitInfo?.limit, equals(100));
      expect(exception.rateLimitInfo?.remaining, equals(0));
      expect(exception.rateLimitInfo?.retryAfterSeconds, equals(300));
    });

    test('should work without rate limit info', () {
      final exception = ApiException(
        statusCode: 400,
        message: 'Bad Request',
        code: 'VALIDATION_ERROR',
      );

      expect(exception.rateLimitInfo, isNull);
      expect(exception.isRateLimitError, isFalse);
    });

    test('should handle brute force detection code', () {
      final exception = ApiException(
        statusCode: 429,
        message: 'Too many login attempts',
        code: 'BRUTE_FORCE_DETECTED',
        rateLimitInfo: RateLimitInfo(retryAfterSeconds: 900),
      );

      expect(exception.isRateLimitError, isTrue);
      expect(exception.code, equals('BRUTE_FORCE_DETECTED'));
      expect(exception.rateLimitInfo?.retryAfterSeconds, equals(900));
    });
  });

  group('RateLimitInfo getRetryMessage edge cases', () {
    test('should handle exactly 1 minute', () {
      final rateLimitInfo = RateLimitInfo(
        retryAfterSeconds: 60,
      );

      final message = rateLimitInfo.getRetryMessage();
      expect(message, contains('1 minute'));
      expect(message.toLowerCase(), isNot(contains('seconde')));
    });

    test('should handle exactly 1 second', () {
      final rateLimitInfo = RateLimitInfo(
        retryAfterSeconds: 1,
      );

      final message = rateLimitInfo.getRetryMessage();
      expect(message, contains('1 seconde'));
      expect(message.toLowerCase(), isNot(contains('minutes'))); // plural check
    });

    test('should handle plural minutes', () {
      final rateLimitInfo = RateLimitInfo(
        retryAfterSeconds: 120, // 2 minutes
      );

      final message = rateLimitInfo.getRetryMessage();
      expect(message, contains('2 minutes'));
    });

    test('should handle plural seconds', () {
      final rateLimitInfo = RateLimitInfo(
        retryAfterSeconds: 5,
      );

      final message = rateLimitInfo.getRetryMessage();
      expect(message, contains('5 secondes'));
    });

    test('should handle large time values', () {
      final rateLimitInfo = RateLimitInfo(
        retryAfterSeconds: 3665, // 61 minutes and 5 seconds
      );

      final message = rateLimitInfo.getRetryMessage();
      expect(message, contains('61 minute'));
      expect(message, contains('5 seconde'));
    });

    test('should prioritize retryAfterSeconds over resetTime', () {
      final resetTime = DateTime.now().add(const Duration(minutes: 10));
      final rateLimitInfo = RateLimitInfo(
        retryAfterSeconds: 60,
        resetTime: resetTime,
      );

      final message = rateLimitInfo.getRetryMessage();
      // Should use retryAfterSeconds (1 minute) not resetTime (10 minutes)
      expect(message, contains('1 minute'));
      expect(message.toLowerCase(), isNot(contains('10')));
    });
  });
}
