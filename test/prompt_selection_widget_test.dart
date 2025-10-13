import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/core/models/profile.dart';
import 'package:goldwen_app/features/profile/widgets/prompt_selection_widget.dart';

void main() {
  group('PromptSelectionWidget Tests', () {
    final mockPrompts = [
      Prompt(
        id: '1',
        text: 'Ce qui me rend vraiment heureux(se), c\'est...',
        category: 'personality',
        active: true,
      ),
      Prompt(
        id: '2',
        text: 'Je ne peux pas vivre sans...',
        category: 'lifestyle',
        active: true,
      ),
      Prompt(
        id: '3',
        text: 'Ma passion secrète est...',
        category: 'interests',
        active: true,
      ),
      Prompt(
        id: '4',
        text: 'Mon endroit préféré pour réfléchir est...',
        category: 'personality',
        active: true,
      ),
    ];

    testWidgets('Should display search bar', (WidgetTester tester) async {
      List<String> selectedIds = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PromptSelectionWidget(
              availablePrompts: mockPrompts,
              selectedPromptIds: selectedIds,
              onSelectionChanged: (newSelection) {
                selectedIds = newSelection;
              },
              maxSelection: 3,
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Rechercher un prompt...'), findsOneWidget);
    });

    testWidgets('Should display all prompts', (WidgetTester tester) async {
      List<String> selectedIds = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PromptSelectionWidget(
              availablePrompts: mockPrompts,
              selectedPromptIds: selectedIds,
              onSelectionChanged: (newSelection) {
                selectedIds = newSelection;
              },
              maxSelection: 3,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display all mock prompts
      expect(find.text('Ce qui me rend vraiment heureux(se), c\'est...'), findsOneWidget);
      expect(find.text('Je ne peux pas vivre sans...'), findsOneWidget);
      expect(find.text('Ma passion secrète est...'), findsOneWidget);
      expect(find.text('Mon endroit préféré pour réfléchir est...'), findsOneWidget);
    });

    testWidgets('Should display selection counter', (WidgetTester tester) async {
      List<String> selectedIds = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PromptSelectionWidget(
              availablePrompts: mockPrompts,
              selectedPromptIds: selectedIds,
              onSelectionChanged: (newSelection) {
                selectedIds = newSelection;
              },
              maxSelection: 3,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('0/3'), findsOneWidget);
    });

    testWidgets('Should update selection counter when prompt selected', (WidgetTester tester) async {
      List<String> selectedIds = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return PromptSelectionWidget(
                  availablePrompts: mockPrompts,
                  selectedPromptIds: selectedIds,
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      selectedIds = newSelection;
                    });
                  },
                  maxSelection: 3,
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on first prompt
      await tester.tap(find.text('Ce qui me rend vraiment heureux(se), c\'est...'));
      await tester.pumpAndSettle();

      // Counter should show 1/3
      expect(find.text('1/3'), findsOneWidget);
    });

    testWidgets('Should filter prompts by search', (WidgetTester tester) async {
      List<String> selectedIds = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PromptSelectionWidget(
              availablePrompts: mockPrompts,
              selectedPromptIds: selectedIds,
              onSelectionChanged: (newSelection) {
                selectedIds = newSelection;
              },
              maxSelection: 3,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter search text
      await tester.enterText(find.byType(TextField), 'passion');
      await tester.pumpAndSettle();

      // Should only show the prompt with "passion"
      expect(find.text('Ma passion secrète est...'), findsOneWidget);
      expect(find.text('Ce qui me rend vraiment heureux(se), c\'est...'), findsNothing);
      expect(find.text('Je ne peux pas vivre sans...'), findsNothing);
    });

    testWidgets('Should not allow more than max selections', (WidgetTester tester) async {
      List<String> selectedIds = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return PromptSelectionWidget(
                  availablePrompts: mockPrompts,
                  selectedPromptIds: selectedIds,
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      selectedIds = newSelection;
                    });
                  },
                  maxSelection: 3,
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Select 3 prompts
      await tester.tap(find.text('Ce qui me rend vraiment heureux(se), c\'est...'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Je ne peux pas vivre sans...'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Ma passion secrète est...'));
      await tester.pumpAndSettle();

      expect(find.text('3/3'), findsOneWidget);

      // Try to select 4th prompt - should show snackbar
      await tester.tap(find.text('Mon endroit préféré pour réfléchir est...'));
      await tester.pumpAndSettle();

      // Should still be 3/3 and show warning snackbar
      expect(find.text('3/3'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('Should deselect when tapping selected prompt', (WidgetTester tester) async {
      List<String> selectedIds = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return PromptSelectionWidget(
                  availablePrompts: mockPrompts,
                  selectedPromptIds: selectedIds,
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      selectedIds = newSelection;
                    });
                  },
                  maxSelection: 3,
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Select a prompt
      await tester.tap(find.text('Ce qui me rend vraiment heureux(se), c\'est...'));
      await tester.pumpAndSettle();
      expect(find.text('1/3'), findsOneWidget);

      // Tap again to deselect
      await tester.tap(find.text('Ce qui me rend vraiment heureux(se), c\'est...'));
      await tester.pumpAndSettle();
      expect(find.text('0/3'), findsOneWidget);
    });
  });

  group('Prompt Model Tests', () {
    test('Prompt fromJson should parse correctly', () {
      final json = {
        'id': 'test-id',
        'text': 'Test question',
        'category': 'personality',
        'isActive': true,
      };

      final prompt = Prompt.fromJson(json);

      expect(prompt.id, 'test-id');
      expect(prompt.text, 'Test question');
      expect(prompt.category, 'personality');
      expect(prompt.active, true);
    });

    test('Prompt toJson should serialize correctly', () {
      final prompt = Prompt(
        id: 'test-id',
        text: 'Test question',
        category: 'personality',
        active: true,
      );

      final json = prompt.toJson();

      expect(json['id'], 'test-id');
      expect(json['text'], 'Test question');
      expect(json['category'], 'personality');
      expect(json['active'], true);
    });
  });
}
