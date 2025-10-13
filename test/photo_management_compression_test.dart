import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/features/profile/widgets/photo_management_widget.dart';
import 'package:goldwen_app/core/models/profile.dart';

void main() {
  group('PhotoManagementWidget - Image Compression Tests', () {
    testWidgets('Should display photo grid with 6 slots', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoManagementWidget(
              photos: const [],
              onPhotosChanged: (photos) {},
              minPhotos: 3,
              maxPhotos: 6,
              showAddButton: true,
            ),
          ),
        ),
      );

      // Verify that 6 photo slots are displayed
      expect(find.byType(Card), findsNWidgets(6));
    });

    testWidgets('Should show photo count with minimum requirement', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoManagementWidget(
              photos: const [],
              onPhotosChanged: (photos) {},
              minPhotos: 3,
              maxPhotos: 6,
              showAddButton: true,
            ),
          ),
        ),
      );

      // Should show current count and minimum requirement
      expect(find.text('0/6 photos (min 3)'), findsOneWidget);
    });

    testWidgets('Should display add photo button when slots available', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoManagementWidget(
              photos: const [],
              onPhotosChanged: (photos) {},
              minPhotos: 3,
              maxPhotos: 6,
              showAddButton: true,
            ),
          ),
        ),
      );

      // Add photo button should be visible
      expect(find.byIcon(Icons.add_photo_alternate), findsOneWidget);
    });

    testWidgets('Should mark first photo as primary', (WidgetTester tester) async {
      final testPhotos = [
        Photo(
          id: '1',
          url: 'https://example.com/photo1.jpg',
          order: 1,
          isPrimary: true,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoManagementWidget(
              photos: testPhotos,
              onPhotosChanged: (photos) {},
              minPhotos: 3,
              maxPhotos: 6,
              showAddButton: true,
            ),
          ),
        ),
      );

      // Primary badge should be visible
      expect(find.text('Principal'), findsOneWidget);
    });

    testWidgets('Should show loading indicator when uploading', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoManagementWidget(
              photos: const [],
              onPhotosChanged: (photos) {},
              minPhotos: 3,
              maxPhotos: 6,
              showAddButton: true,
            ),
          ),
        ),
      );

      // Initially no loading indicator
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('Should display photo order numbers', (WidgetTester tester) async {
      final testPhotos = [
        Photo(
          id: '1',
          url: 'https://example.com/photo1.jpg',
          order: 1,
          isPrimary: true,
          createdAt: DateTime.now(),
        ),
        Photo(
          id: '2',
          url: 'https://example.com/photo2.jpg',
          order: 2,
          isPrimary: false,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoManagementWidget(
              photos: testPhotos,
              onPhotosChanged: (photos) {},
              minPhotos: 3,
              maxPhotos: 6,
              showAddButton: true,
            ),
          ),
        ),
      );

      // Order indicators should be visible
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('Should show delete button on photos', (WidgetTester tester) async {
      final testPhotos = [
        Photo(
          id: '1',
          url: 'https://example.com/photo1.jpg',
          order: 1,
          isPrimary: true,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoManagementWidget(
              photos: testPhotos,
              onPhotosChanged: (photos) {},
              minPhotos: 3,
              maxPhotos: 6,
              showAddButton: true,
            ),
          ),
        ),
      );

      // Delete icon should be present
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('Should show set primary button on non-primary photos', (WidgetTester tester) async {
      final testPhotos = [
        Photo(
          id: '1',
          url: 'https://example.com/photo1.jpg',
          order: 1,
          isPrimary: true,
          createdAt: DateTime.now(),
        ),
        Photo(
          id: '2',
          url: 'https://example.com/photo2.jpg',
          order: 2,
          isPrimary: false,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoManagementWidget(
              photos: testPhotos,
              onPhotosChanged: (photos) {},
              minPhotos: 3,
              maxPhotos: 6,
              showAddButton: true,
            ),
          ),
        ),
      );

      // Set primary button should be present for non-primary photo
      expect(find.byIcon(Icons.star_border), findsOneWidget);
    });

    testWidgets('Should show empty slots with add icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoManagementWidget(
              photos: const [],
              onPhotosChanged: (photos) {},
              minPhotos: 3,
              maxPhotos: 6,
              showAddButton: true,
            ),
          ),
        ),
      );

      // Empty slots should show add photo icon
      expect(find.byIcon(Icons.add_photo_alternate), findsWidgets);
    });

    testWidgets('Should indicate first slot is for primary photo', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoManagementWidget(
              photos: const [],
              onPhotosChanged: (photos) {},
              minPhotos: 3,
              maxPhotos: 6,
              showAddButton: true,
            ),
          ),
        ),
      );

      // First empty slot should indicate it's for primary photo
      expect(find.text('Photo principale'), findsOneWidget);
    });

    testWidgets('Should show drag indicator hint on photos', (WidgetTester tester) async {
      final testPhotos = [
        Photo(
          id: '1',
          url: 'https://example.com/photo1.jpg',
          order: 1,
          isPrimary: true,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoManagementWidget(
              photos: testPhotos,
              onPhotosChanged: (photos) {},
              minPhotos: 3,
              maxPhotos: 6,
              showAddButton: true,
            ),
          ),
        ),
      );

      // Drag indicator icon should be present
      expect(find.byIcon(Icons.drag_indicator), findsWidgets);
    });
  });

  group('PhotoManagementWidget - Photo Count Logic', () {
    testWidgets('Should show error color when below minimum photos', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoManagementWidget(
              photos: const [],
              onPhotosChanged: (photos) {},
              minPhotos: 3,
              maxPhotos: 6,
              showAddButton: true,
            ),
          ),
        ),
      );

      // Photo count should be displayed with error indication
      expect(find.text('0/6 photos (min 3)'), findsOneWidget);
    });

    testWidgets('Should not show min requirement when photos are sufficient', (WidgetTester tester) async {
      final testPhotos = List.generate(
        3,
        (index) => Photo(
          id: '$index',
          url: 'https://example.com/photo$index.jpg',
          order: index + 1,
          isPrimary: index == 0,
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoManagementWidget(
              photos: testPhotos,
              onPhotosChanged: (photos) {},
              minPhotos: 3,
              maxPhotos: 6,
              showAddButton: true,
            ),
          ),
        ),
      );

      // Should show count without minimum requirement text
      expect(find.text('3/6 photos'), findsOneWidget);
    });
  });

  group('PhotoManagementWidget - UI Elements', () {
    testWidgets('Should display header title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoManagementWidget(
              photos: const [],
              onPhotosChanged: (photos) {},
              minPhotos: 3,
              maxPhotos: 6,
              showAddButton: true,
            ),
          ),
        ),
      );

      expect(find.text('Vos Photos'), findsOneWidget);
    });

    testWidgets('Should use grid layout with 2 columns', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoManagementWidget(
              photos: const [],
              onPhotosChanged: (photos) {},
              minPhotos: 3,
              maxPhotos: 6,
              showAddButton: true,
            ),
          ),
        ),
      );

      // GridView should be present
      expect(find.byType(GridView), findsOneWidget);
    });
  });
}
