import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:goldwen_app/core/models/models.dart';
import 'package:goldwen_app/features/matching/pages/profile_detail_page.dart';
import 'package:goldwen_app/features/matching/providers/matching_provider.dart';
import 'package:goldwen_app/features/profile/providers/profile_provider.dart';

class DetailMatchingProvider extends MatchingProvider {
  List<Profile> profiles = [];
  Completer<void>? loading;
  int fetches = 0;
  @override
  List<Profile> get dailyProfiles => profiles;
  @override
  Future<void> loadDailySelection() async { fetches++; await loading?.future; }
  @override
  Future<void> loadMatches({int page = 1, int limit = 20, String? status}) async {}
  @override
  Future<void> loadWhoLikedMe() async {}
}

Widget app(DetailMatchingProvider provider, String id) => MultiProvider(
  providers: [
    ChangeNotifierProvider<MatchingProvider>.value(value: provider),
    ChangeNotifierProvider(create: (_) => ProfileProvider()),
  ],
  child: MaterialApp(home: ProfileDetailPage(profileId: id)),
);

void main() {
  testWidgets('detail displays the requested real profile and compatibility', (tester) async {
    final provider = DetailMatchingProvider()..profiles = [Profile(
      id: 'profile-2', userId: 'user-2', pseudo: 'Camille', bio: 'Les randonnées du dimanche',
      isComplete: true, createdAt: DateTime(2026), updatedAt: DateTime(2026),
      compatibilityScore: .87, compatibilityDetails: {'values': .9},
    )];
    await tester.pumpWidget(app(provider, 'profile-2'));
    await tester.pumpAndSettle();
    expect(find.text('Camille'), findsOneWidget);
    expect(find.text('87% compatible'), findsOneWidget);
    expect(find.text('Les randonnées du dimanche'), findsOneWidget);
    expect(find.text('Sophie'), findsNothing);
    expect(provider.fetches, 0);
  });
  testWidgets('cold link shows loading then unavailable without a fake profile', (tester) async {
    final provider = DetailMatchingProvider()..loading = Completer<void>();
    await tester.pumpWidget(app(provider, 'unknown'));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    provider.loading!.complete();
    await tester.pumpAndSettle();
    expect(find.text("Ce profil n'est plus disponible."), findsOneWidget);
    expect(find.text('Sophie'), findsNothing);
    expect(provider.fetches, 1);
  });
  testWidgets('pending profile load may finish after leaving the screen', (tester) async {
    final provider = DetailMatchingProvider()..loading = Completer<void>();
    await tester.pumpWidget(app(provider, 'unknown'));
    await tester.pumpWidget(const SizedBox());
    provider.loading!.complete();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
