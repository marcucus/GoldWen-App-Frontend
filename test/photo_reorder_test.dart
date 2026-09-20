import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/core/models/profile.dart';
import 'package:goldwen_app/core/services/api_service.dart';
import 'package:goldwen_app/features/profile/widgets/photo_management_widget.dart';

import 'support/api_adapter.dart';

void main() {
  testWidgets('dragging a photo onto the next slot changes its order',
      (tester) async {
    ApiService.configureTestAdapter(
      () => ApiAdapter((_) => (200, <String, dynamic>{'success': true})),
    );
    final photos = [
      Photo(
        id: 'first',
        url: 'assets/images/logo_base.png',
        order: 1,
        isPrimary: true,
        createdAt: DateTime(2026),
      ),
      Photo(
        id: 'second',
        url: 'assets/images/logo_light.png',
        order: 2,
        isPrimary: false,
        createdAt: DateTime(2026),
      ),
    ];
    List<Photo>? reordered;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PhotoManagementWidget(
              photos: photos,
              onPhotosChanged: (value) => reordered = List.of(value),
            ),
          ),
        ),
      ),
    );

    final first = find.byKey(const ValueKey('photo_first'));
    final second = find.byKey(const ValueKey('photo_second'));
    final gesture = await tester.startGesture(tester.getCenter(first));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveTo(tester.getCenter(second));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(reordered?.map((photo) => photo.id), ['second', 'first']);
    expect(reordered?.first.isPrimary, isTrue);
    expect(reordered?.last.isPrimary, isFalse);
  });
}
