# Tests - Daily Selection Refresh Feature

## Vue d'ensemble
Ce dossier contient les tests pour la fonctionnalité de refresh quotidien de la sélection.

## Fichiers de test

### 1. `daily_selection_refresh_test.dart`
Tests unitaires pour la logique de refresh quotidien.

**Coverage:**
- `hasNewSelectionAvailable()` - Détection de nouvelle sélection
- `getTimeUntilNextRefresh()` - Calcul du temps restant
- `getNextRefreshCountdown()` - Formatage du countdown
- Logique basée sur midi (noon-based logic)
- Gestion du refreshTime
- Cas limites et edge cases

**Tests:** 15+ tests unitaires

### 2. `daily_selection_refresh_ui_test.dart`
Tests de widgets pour les composants UI du refresh quotidien.

**Coverage:**
- Badge "Nouvelle sélection disponible !"
- Timer de compte à rebours
- Styles et couleurs
- Accessibilité (reduced motion, high contrast)
- États vides et d'erreur
- Labels sémantiques

**Tests:** 20+ tests de widgets

**Important:** Ce fichier nécessite la génération de mocks avec la commande ci-dessous.

## Exécution des tests

### Prérequis
1. Flutter SDK installé (>= 3.13.0)
2. Dépendances installées: `flutter pub get`

### Générer les mocks (requis pour les tests de widgets)
```bash
# Depuis la racine du projet
flutter pub run build_runner build --delete-conflicting-outputs
```

Cette commande génère le fichier `daily_selection_refresh_ui_test.mocks.dart` nécessaire pour les tests de widgets.

### Exécuter tous les tests du projet
```bash
flutter test
```

### Exécuter uniquement les tests de refresh quotidien
```bash
# Tests unitaires
flutter test test/daily_selection_refresh_test.dart

# Tests de widgets
flutter test test/daily_selection_refresh_ui_test.dart

# Les deux
flutter test test/daily_selection_refresh_test.dart test/daily_selection_refresh_ui_test.dart
```

### Exécuter avec coverage
```bash
flutter test --coverage

# Voir le rapport de coverage (nécessite lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html  # macOS
xdg-open coverage/html/index.html  # Linux
```

### Exécuter en mode watch (re-run automatique)
```bash
flutter test --watch
```

## Résultats attendus

### Tests unitaires
```
✓ DailySelection model correctly parses quota metadata
✓ SubscriptionUsage model correctly parses daily choices data
✓ Handles missing quota fields gracefully
✓ hasNewSelectionAvailable() returns true when no selection exists
✓ returns true when selection is expired
✓ returns false when selection is still valid and recent
✓ getTimeUntilNextRefresh() returns Duration until tomorrow noon
✓ returns Duration until today noon when before noon today
✓ getNextRefreshCountdown() formats countdown correctly for days
✓ formats countdown correctly for hours and minutes
✓ formats countdown correctly for minutes only
✓ DailySelection.isExpired returns true when past expiresAt
✓ calculates correct noon time for today
✓ handles midnight boundary correctly
... et plus
```

### Tests de widgets
```
✓ displays "Nouvelle sélection disponible !" badge when new selection
✓ displays countdown timer when no new selection is available
✓ does not display badge when no new selection is available
✓ updates countdown display on timer tick
✓ badge has proper styling with green gradient
✓ countdown timer has proper styling
✓ respects reduced motion preference
✓ respects high contrast mode
✓ displays correct header title
... et plus
```

## Structure des tests

### Tests unitaires (Pattern)
```dart
group('Nom du groupe', () {
  test('Description du comportement attendu', () {
    // Arrange: Préparer les données
    
    // Act: Exécuter l'action
    
    // Assert: Vérifier le résultat
  });
});
```

### Tests de widgets (Pattern)
```dart
testWidgets('Description du comportement UI', (WidgetTester tester) async {
  // Setup mocks
  when(mockProvider.method()).thenReturn(value);
  
  // Build widget tree
  await tester.pumpWidget(createTestWidget());
  await tester.pumpAndSettle();
  
  // Verify UI elements
  expect(find.text('Expected text'), findsOneWidget);
});
```

## Debugging des tests

### Afficher les logs
```bash
flutter test --verbose
```

### Debugging avec breakpoints
1. Ouvrir le fichier de test dans VS Code
2. Placer un breakpoint (clic sur la marge gauche)
3. Lancer en mode debug: `F5` ou `Run > Start Debugging`
4. Choisir "Dart & Flutter" dans la liste des debuggers

### Debugging d'un test spécifique
```dart
test('mon test', () {
  debugger(); // Arrêt ici en mode debug
  // ... reste du test
});
```

## Troubleshooting

### Erreur: "Mock file not found"
**Solution:** Générer les mocks avec:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Erreur: "Provider not found"
**Solution:** Vérifier que le widget de test est bien enveloppé dans MultiProvider avec tous les providers requis.

### Tests flaky (instables)
**Solution:** 
- Utiliser `pumpAndSettle()` au lieu de `pump()` pour attendre les animations
- Ajouter des delays appropriés avec `await tester.pump(Duration(...))`
- Vérifier les conditions de race avec les timers

### Tests lents
**Solution:**
- Réduire le nombre de `pumpAndSettle()` 
- Utiliser `pump()` avec des durées spécifiques
- Désactiver les animations en test: `WidgetsBinding.instance.disableAnimations = true;`

## Meilleures pratiques

### 1. Tests unitaires
- ✅ Tester une seule chose par test
- ✅ Utiliser des noms descriptifs
- ✅ Suivre le pattern Arrange-Act-Assert
- ✅ Tester les cas limites et erreurs
- ✅ Garder les tests rapides (<100ms)

### 2. Tests de widgets
- ✅ Utiliser des mocks pour isoler le widget testé
- ✅ Vérifier les éléments visibles avec `find.*`
- ✅ Tester l'accessibilité (semantics)
- ✅ Tester les différents états (loading, error, empty, success)
- ✅ Utiliser `pumpAndSettle()` après les changements d'état

### 3. Mocks
- ✅ Configurer tous les comportements nécessaires dans `setUp()`
- ✅ Utiliser `when().thenReturn()` pour le happy path
- ✅ Utiliser `when().thenThrow()` pour les erreurs
- ✅ Vérifier les appels avec `verify()` si nécessaire

## Contribution

Lors de l'ajout de nouvelles fonctionnalités:
1. Écrire les tests en premier (TDD) ou en parallèle
2. Viser >80% de coverage sur le nouveau code
3. Inclure tests unitaires ET tests de widgets
4. Tester les cas limites et erreurs
5. Documenter les tests complexes

## Références

- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [Widget Testing](https://docs.flutter.dev/cookbook/testing/widget/introduction)
- Guide de test manuel: `../MANUAL_TESTING_DAILY_REFRESH.md`
- Résumé technique: `../DAILY_REFRESH_IMPLEMENTATION_SUMMARY.md`

## Questions fréquentes

### Q: Pourquoi certains tests échouent localement mais passent en CI?
**R:** Vérifier les différences de timezone, les mocks, et les dépendances de temps (DateTime.now()).

### Q: Comment tester du code qui utilise DateTime.now()?
**R:** Utiliser l'injection de dépendances ou mocker le Clock dans les tests.

### Q: Les tests de widgets sont très lents?
**R:** Utiliser `pump()` au lieu de `pumpAndSettle()` quand possible, et désactiver les animations.

### Q: Comment tester les timers et les delays?
**R:** Utiliser `FakeAsync` ou mocker les timers pour contrôler le temps.

## Support

En cas de problème:
1. Consulter la section Troubleshooting ci-dessus
2. Vérifier les logs avec `--verbose`
3. Consulter la documentation Flutter
4. Vérifier les issues GitHub du projet

---

**Dernière mise à jour:** Octobre 2025
**Version:** 1.0
