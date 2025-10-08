import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/core/services/api_service.dart';
import 'package:goldwen_app/core/utils/error_handler.dart';

void main() {
  group('ErrorHandler', () {
    testWidgets('should handle rate limit errors with dialog', (WidgetTester tester) async {
      final exception = ApiException(
        statusCode: 429,
        message: 'Too many requests',
        code: 'RATE_LIMIT_EXCEEDED',
        rateLimitInfo: RateLimitInfo(
          retryAfterSeconds: 60,
        ),
      );

      bool handled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  handled = await ErrorHandler.handleApiError(
                    context,
                    exception,
                  );
                },
                child: const Text('Test'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Test'));
      await tester.pumpAndSettle();

      // Should have shown dialog
      expect(handled, isTrue);
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('should not handle non-rate-limit errors', (WidgetTester tester) async {
      final exception = ApiException(
        statusCode: 400,
        message: 'Bad request',
        code: 'VALIDATION_ERROR',
      );

      bool handled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  handled = await ErrorHandler.handleApiError(
                    context,
                    exception,
                  );
                },
                child: const Text('Test'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Test'));
      await tester.pumpAndSettle();

      // Should not have shown dialog
      expect(handled, isFalse);
      expect(find.byType(AlertDialog), findsNothing);
    });

    test('should get error message from ApiException', () {
      final exception = ApiException(
        statusCode: 400,
        message: 'Invalid input',
        code: 'VALIDATION_ERROR',
      );

      final message = ErrorHandler.getErrorMessage(exception);
      expect(message, equals('Invalid input'));
    });

    test('should get error message with retry info for rate limit', () {
      final exception = ApiException(
        statusCode: 429,
        message: 'Rate limit exceeded',
        code: 'RATE_LIMIT_EXCEEDED',
        rateLimitInfo: RateLimitInfo(
          retryAfterSeconds: 60,
        ),
      );

      final message = ErrorHandler.getErrorMessage(exception);
      expect(message, contains('Rate limit exceeded'));
      expect(message, contains('1 minute'));
    });

    test('should handle generic exceptions', () {
      final exception = Exception('Something went wrong');
      final message = ErrorHandler.getErrorMessage(exception);
      expect(message, equals('Something went wrong'));
    });

    test('should handle unknown errors', () {
      final message = ErrorHandler.getErrorMessage('unknown error');
      expect(message, equals('Une erreur inattendue est survenue'));
    });

    testWidgets('should show error snackbar', (WidgetTester tester) async {
      final exception = ApiException(
        statusCode: 500,
        message: 'Server error',
        code: 'SERVER_ERROR',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ErrorHandler.showErrorSnackBar(context, exception);
                },
                child: const Text('Show Error'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Error'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Server error'), findsOneWidget);
    });

    testWidgets('should show rate limit warning snackbar when near limit', (WidgetTester tester) async {
      final rateLimitInfo = RateLimitInfo(
        limit: 100,
        remaining: 10, // Less than 20% - should trigger warning
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ErrorHandler.showRateLimitWarning(context, rateLimitInfo);
                },
                child: const Text('Show Warning'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Warning'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Il vous reste 10 requête'), findsOneWidget);
    });

    testWidgets('should not show warning when not near limit', (WidgetTester tester) async {
      final rateLimitInfo = RateLimitInfo(
        limit: 100,
        remaining: 50, // 50% - should not trigger warning
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ErrorHandler.showRateLimitWarning(context, rateLimitInfo);
                },
                child: const Text('Show Warning'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Warning'));
      await tester.pumpAndSettle();

      // Should not show snackbar
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('should call onRetry when provided', (WidgetTester tester) async {
      final exception = ApiException(
        statusCode: 429,
        message: 'Too many requests',
        code: 'RATE_LIMIT_EXCEEDED',
        rateLimitInfo: RateLimitInfo(
          retryAfterSeconds: 0, // Can retry immediately
        ),
      );

      bool retryWasCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  await ErrorHandler.handleApiError(
                    context,
                    exception,
                    onRetry: () {
                      retryWasCalled = true;
                    },
                  );
                },
                child: const Text('Test'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Test'));
      await tester.pumpAndSettle();

      // Find and tap retry button
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();

      expect(retryWasCalled, isTrue);
    });

    testWidgets('should respect showDialog parameter', (WidgetTester tester) async {
      final exception = ApiException(
        statusCode: 429,
        message: 'Too many requests',
        code: 'RATE_LIMIT_EXCEEDED',
      );

      bool handled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  handled = await ErrorHandler.handleApiError(
                    context,
                    exception,
                    showDialog: false,
                  );
                },
                child: const Text('Test'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Test'));
      await tester.pumpAndSettle();

      // Should not show dialog when showDialog is false
      expect(handled, isFalse);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
