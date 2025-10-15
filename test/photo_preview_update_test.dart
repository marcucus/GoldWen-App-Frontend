import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/features/profile/widgets/photo_management_widget.dart';
import 'package:goldwen_app/core/models/profile.dart';

void main() {
  group('PhotoManagementWidget - Preview Update Tests', () {
    testWidgets('Should update preview when photos prop changes', (WidgetTester tester) async {
      // Initial empty state
      List<Photo> photos = [];
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoManagementWidget(
              photos: photos,
              onPhotosChanged: (updatedPhotos) {},
              minPhotos: 3,
              maxPhotos: 6,
              showAddButton: true,
            ),
          ),
        ),
      );

      // Verify initial state: no photos
      expect(find.text('0/6 photos (min 3)'), findsOneWidget);
      expect(find.text('Photo principale'), findsOneWidget);

      // Update photos list (simulating adding a photo via ProfileProvider)
      photos = [
        Photo(
          id: '1',
          url: 'https://example.com/photo1.jpg',
          order: 1,
          isPrimary: true,
          createdAt: DateTime.now(),
        ),
      ];

      // Rebuild widget with updated photos
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoManagementWidget(
              photos: photos,
              onPhotosChanged: (updatedPhotos) {},
              minPhotos: 3,
              maxPhotos: 6,
              showAddButton: true,
            ),
          ),
        ),
      );

      // Verify updated state: 1 photo displayed
      expect(find.text('1/6 photos (min 3)'), findsOneWidget);
      expect(find.text('Principal'), findsOneWidget);
      expect(find.text('1'), findsOneWidget); // Order indicator
    });

    testWidgets('Should update preview when multiple photos are added', (WidgetTester tester) async {
      // Start with no photos
      List<Photo> photos = [];
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoManagementWidget(
              photos: photos,
              onPhotosChanged: (updatedPhotos) {},
              minPhotos: 3,
              maxPhotos: 6,
              showAddButton: true,
            ),
          ),
        ),
      );

      expect(find.text('0/6 photos (min 3)'), findsOneWidget);

      // Add 3 photos
      photos = List.generate(
        3,
        (index) => Photo(
          id: '${index + 1}',
          url: 'https://example.com/photo${index + 1}.jpg',
          order: index + 1,
          isPrimary: index == 0,
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoManagementWidget(
              photos: photos,
              onPhotosChanged: (updatedPhotos) {},
              minPhotos: 3,
              maxPhotos: 6,
              showAddButton: true,
            ),
          ),
        ),
      );

      // Verify all 3 photos are displayed
      expect(find.text('3/6 photos'), findsOneWidget); // No min warning
      expect(find.text('Principal'), findsOneWidget); // First photo is primary
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('Should update preview when a photo is removed', (WidgetTester tester) async {
      // Start with 3 photos
      List<Photo> photos = List.generate(
        3,
        (index) => Photo(
          id: '${index + 1}',
          url: 'https://example.com/photo${index + 1}.jpg',
          order: index + 1,
          isPrimary: index == 0,
          createdAt: DateTime.now(),
        ),
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoManagementWidget(
              photos: photos,
              onPhotosChanged: (updatedPhotos) {},
              minPhotos: 3,
              maxPhotos: 6,
              showAddButton: true,
            ),
          ),
        ),
      );

      expect(find.text('3/6 photos'), findsOneWidget);

      // Remove one photo
      photos = photos.sublist(0, 2);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoManagementWidget(
              photos: photos,
              onPhotosChanged: (updatedPhotos) {},
              minPhotos: 3,
              maxPhotos: 6,
              showAddButton: true,
            ),
          ),
        ),
      );

      // Verify updated count
      expect(find.text('2/6 photos (min 3)'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsNothing); // Third photo removed
    });

    testWidgets('Should handle reaching maximum photos', (WidgetTester tester) async {
      // Start with 5 photos
      List<Photo> photos = List.generate(
        5,
        (index) => Photo(
          id: '${index + 1}',
          url: 'https://example.com/photo${index + 1}.jpg',
          order: index + 1,
          isPrimary: index == 0,
          createdAt: DateTime.now(),
        ),
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoManagementWidget(
              photos: photos,
              onPhotosChanged: (updatedPhotos) {},
              minPhotos: 3,
              maxPhotos: 6,
              showAddButton: true,
            ),
          ),
        ),
      );

      expect(find.text('5/6 photos'), findsOneWidget);
      expect(find.byIcon(Icons.add_photo_alternate), findsWidgets); // Add button still visible

      // Add sixth photo to reach maximum
      photos.add(
        Photo(
          id: '6',
          url: 'https://example.com/photo6.jpg',
          order: 6,
          isPrimary: false,
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoManagementWidget(
              photos: photos,
              onPhotosChanged: (updatedPhotos) {},
              minPhotos: 3,
              maxPhotos: 6,
              showAddButton: true,
            ),
          ),
        ),
      );

      // Verify maximum reached
      expect(find.text('6/6 photos'), findsOneWidget);
      // Header add button should not be visible when at max
      expect(find.byIcon(Icons.add_photo_alternate), findsNothing);
    });

    testWidgets('Should preserve primary photo indicator after update', (WidgetTester tester) async {
      List<Photo> photos = [
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
              photos: photos,
              onPhotosChanged: (updatedPhotos) {},
              minPhotos: 3,
              maxPhotos: 6,
              showAddButton: true,
            ),
          ),
        ),
      );

      // Verify primary badge is shown on first photo
      expect(find.text('Principal'), findsOneWidget);

      // Add another photo
      photos.add(
        Photo(
          id: '3',
          url: 'https://example.com/photo3.jpg',
          order: 3,
          isPrimary: false,
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoManagementWidget(
              photos: photos,
              onPhotosChanged: (updatedPhotos) {},
              minPhotos: 3,
              maxPhotos: 6,
              showAddButton: true,
            ),
          ),
        ),
      );

      // Verify primary badge is still shown and count updated
      expect(find.text('Principal'), findsOneWidget);
      expect(find.text('3/6 photos'), findsOneWidget);
    });
  });
}
