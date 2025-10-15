import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/features/profile/widgets/favorite_song_widget.dart';

void main() {
  group('FavoriteSongWidget Tests', () {
    testWidgets('Should display empty state initially', (WidgetTester tester) async {
      String? capturedSong;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FavoriteSongWidget(
              favoriteSong: null,
              onChanged: (song) {
                capturedSong = song;
              },
            ),
          ),
        ),
      );

      expect(find.text('Morceau/Artiste préféré'), findsOneWidget);
      expect(find.text('Optionnel'), findsOneWidget);
      expect(find.byIcon(Icons.music_note), findsOneWidget);
    });

    testWidgets('Should display existing favorite song', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FavoriteSongWidget(
              favoriteSong: 'Bohemian Rhapsody - Queen (Spotify)',
              onChanged: (song) {},
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Bohemian Rhapsody - Queen'), findsOneWidget);
    });

    testWidgets('Should update song when text is entered', (WidgetTester tester) async {
      String? capturedSong;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FavoriteSongWidget(
              favoriteSong: null,
              onChanged: (song) {
                capturedSong = song;
              },
            ),
          ),
        ),
      );

      // Find and enter text in the text field
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, 'Yesterday - The Beatles');
      await tester.pump();

      expect(capturedSong, 'Yesterday - The Beatles');
    });

    testWidgets('Should display platform chips', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FavoriteSongWidget(
              favoriteSong: null,
              onChanged: (song) {},
            ),
          ),
        ),
      );

      expect(find.text('Aucune'), findsOneWidget);
      expect(find.text('Apple Music'), findsOneWidget);
      expect(find.text('Spotify'), findsOneWidget);
      expect(find.text('Deezer'), findsOneWidget);
    });

    testWidgets('Should select platform and update song', (WidgetTester tester) async {
      String? capturedSong;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FavoriteSongWidget(
              favoriteSong: null,
              onChanged: (song) {
                capturedSong = song;
              },
            ),
          ),
        ),
      );

      // Enter song text
      await tester.enterText(find.byType(TextField), 'Imagine - John Lennon');
      await tester.pump();

      // Select Spotify platform
      await tester.tap(find.text('Spotify'));
      await tester.pump();

      expect(capturedSong, 'Imagine - John Lennon (Spotify)');
    });

    testWidgets('Should clear song when clear button is pressed', (WidgetTester tester) async {
      String? capturedSong;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FavoriteSongWidget(
              favoriteSong: 'Test Song',
              onChanged: (song) {
                capturedSong = song;
              },
            ),
          ),
        ),
      );

      await tester.pump();

      // Find clear button
      final clearButton = find.byIcon(Icons.clear);
      expect(clearButton, findsOneWidget);

      // Tap clear button
      await tester.tap(clearButton);
      await tester.pump();

      expect(capturedSong, isNull);
    });

    testWidgets('Should show preview when song is entered', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FavoriteSongWidget(
              favoriteSong: null,
              onChanged: (song) {},
            ),
          ),
        ),
      );

      // Enter song text
      await tester.enterText(find.byType(TextField), 'Song - Artist');
      await tester.pump();

      // Should show check icon and preview
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Song - Artist'), findsWidgets);
    });

    testWidgets('Should parse and display platform from existing favorite song', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FavoriteSongWidget(
              favoriteSong: 'Test Song - Artist (Deezer)',
              onChanged: (song) {},
            ),
          ),
        ),
      );

      await tester.pump();

      // The Deezer chip should be selected
      final deezerChip = find.ancestor(
        of: find.text('Deezer'),
        matching: find.byType(ChoiceChip),
      );
      
      expect(deezerChip, findsOneWidget);
      
      final ChoiceChip chip = tester.widget(deezerChip);
      expect(chip.selected, isTrue);
    });

    testWidgets('Should handle platform switch correctly', (WidgetTester tester) async {
      String? capturedSong;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FavoriteSongWidget(
              favoriteSong: null,
              onChanged: (song) {
                capturedSong = song;
              },
            ),
          ),
        ),
      );

      // Enter song text
      await tester.enterText(find.byType(TextField), 'Song');
      await tester.pump();

      // Select Spotify
      await tester.tap(find.text('Spotify'));
      await tester.pump();
      expect(capturedSong, 'Song (Spotify)');

      // Switch to Apple Music
      await tester.tap(find.text('Apple Music'));
      await tester.pump();
      expect(capturedSong, 'Song (Apple Music)');

      // Switch to Aucune (none)
      await tester.tap(find.text('Aucune'));
      await tester.pump();
      expect(capturedSong, 'Song');
    });

    testWidgets('Should not include platform if "Aucune" is selected', (WidgetTester tester) async {
      String? capturedSong;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FavoriteSongWidget(
              favoriteSong: null,
              onChanged: (song) {
                capturedSong = song;
              },
            ),
          ),
        ),
      );

      // Enter song text
      await tester.enterText(find.byType(TextField), 'Song Name');
      await tester.pump();

      // "Aucune" is selected by default, so no platform should be included
      expect(capturedSong, 'Song Name');
      expect(capturedSong!.contains('('), isFalse);
    });
  });
}
