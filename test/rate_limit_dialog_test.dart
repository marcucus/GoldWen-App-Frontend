import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/core/services/api_service.dart';
import 'package:goldwen_app/core/widgets/rate_limit_dialog.dart';
import 'package:goldwen_app/core/theme/app_theme.dart';

void main() {
  group('RateLimitDialog', () {
    testWidgets('should display rate limit error with countdown', (WidgetTester tester) async {
      final exception = ApiException(
        statusCode: 429,
        message: 'Too many requests',
        code: 'RATE_LIMIT_EXCEEDED',
        rateLimitInfo: RateLimitInfo(
          limit: 100,
          remaining: 0,
          retryAfterSeconds: 60,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  RateLimitDialog.show(context, exception);
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Limite de requêtes atteinte'), findsOneWidget);
      
      // Verify countdown is shown
      expect(find.textContaining('seconde'), findsOneWidget);
    });

    testWidgets('should display brute force login error', (WidgetTester tester) async {
      final exception = ApiException(
        statusCode: 429,
        message: 'Trop de tentatives de login',
        code: 'BRUTE_FORCE_DETECTED',
        rateLimitInfo: RateLimitInfo(
          retryAfterSeconds: 900, // 15 minutes
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  RateLimitDialog.show(context, exception);
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify specific title for brute force
      expect(find.text('Trop de tentatives de connexion'), findsOneWidget);
      expect(find.textContaining('sécurité'), findsOneWidget);
    });

    testWidgets('should show retry button when countdown is complete', (WidgetTester tester) async {
      final exception = ApiException(
        statusCode: 429,
        message: 'Too many requests',
        code: 'RATE_LIMIT_EXCEEDED',
        rateLimitInfo: RateLimitInfo(
          retryAfterSeconds: 0, // Already can retry
        ),
      );

      bool retryWasCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  RateLimitDialog.show(
                    context,
                    exception,
                    onRetry: () {
                      retryWasCalled = true;
                    },
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify retry button is shown
      expect(find.text('Réessayer'), findsOneWidget);
      
      // Tap retry button
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();

      expect(retryWasCalled, isTrue);
    });

    testWidgets('should not show retry button during countdown', (WidgetTester tester) async {
      final exception = ApiException(
        statusCode: 429,
        message: 'Too many requests',
        code: 'RATE_LIMIT_EXCEEDED',
        rateLimitInfo: RateLimitInfo(
          retryAfterSeconds: 60,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  RateLimitDialog.show(
                    context,
                    exception,
                    onRetry: () {},
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify retry button is NOT shown during countdown
      expect(find.text('Réessayer'), findsNothing);
      expect(find.text('Compris'), findsOneWidget);
    });

    testWidgets('should update countdown every second', (WidgetTester tester) async {
      final exception = ApiException(
        statusCode: 429,
        message: 'Too many requests',
        code: 'RATE_LIMIT_EXCEEDED',
        rateLimitInfo: RateLimitInfo(
          retryAfterSeconds: 3,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  RateLimitDialog.show(context, exception);
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Initial countdown
      expect(find.textContaining('3 seconde'), findsOneWidget);

      // Wait 1 second
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('2 seconde'), findsOneWidget);

      // Wait another second
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('1 seconde'), findsOneWidget);
    });
  });

  group('RateLimitWarningBanner', () {
    testWidgets('should show warning when near limit', (WidgetTester tester) async {
      final rateLimitInfo = RateLimitInfo(
        limit: 100,
        remaining: 15, // 15% remaining - should trigger warning
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RateLimitWarningBanner(
              rateLimitInfo: rateLimitInfo,
            ),
          ),
        ),
      );

      expect(find.text('Attention'), findsOneWidget);
      expect(find.textContaining('Il vous reste 15 requête'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('should not show when not near limit', (WidgetTester tester) async {
      final rateLimitInfo = RateLimitInfo(
        limit: 100,
        remaining: 50, // 50% remaining - should not trigger warning
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RateLimitWarningBanner(
              rateLimitInfo: rateLimitInfo,
            ),
          ),
        ),
      );

      expect(find.text('Attention'), findsNothing);
    });

    testWidgets('should call onDismiss when close button is tapped', (WidgetTester tester) async {
      final rateLimitInfo = RateLimitInfo(
        limit: 100,
        remaining: 10,
      );

      bool dismissWasCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RateLimitWarningBanner(
              rateLimitInfo: rateLimitInfo,
              onDismiss: () {
                dismissWasCalled = true;
              },
            ),
          ),
        ),
      );

      // Find and tap close button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(dismissWasCalled, isTrue);
    });

    testWidgets('should handle singular vs plural correctly', (WidgetTester tester) async {
      final rateLimitInfo = RateLimitInfo(
        limit: 100,
        remaining: 1, // singular
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RateLimitWarningBanner(
              rateLimitInfo: rateLimitInfo,
            ),
          ),
        ),
      );

      // Should use singular form
      expect(find.textContaining('Il vous reste 1 requête sur'), findsOneWidget);
      expect(find.textContaining('requêtes'), findsNothing); // Should not have plural
    });
  });
}
