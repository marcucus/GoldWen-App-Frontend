# UI Modération - Guide d'Utilisation

Ce document décrit comment utiliser les composants UI de modération automatique.

## Composants Disponibles

### 1. ModerationStatusBadge
Badge pour afficher le statut de modération d'un contenu.

**Usage:**
```dart
ModerationStatusBadge(
  moderationResult: moderationResult,
  showLabel: true,  // Afficher le texte du statut
  compact: false,   // Mode compact (icône seulement)
)
```

**Statuts affichés:**
- ✅ **Approuvé** (vert) - Contenu validé
- ⏳ **En attente** (orange) - Modération en cours
- 🚫 **Bloqué** (rouge) - Contenu bloqué

### 2. ModerationFlagsWidget
Widget pour afficher les catégories/labels de blocage.

**Usage:**
```dart
ModerationFlagsWidget(
  flags: moderationResult.flags,
  showConfidence: true,  // Afficher le score de confiance
)
```

### 3. ModerationBlockedContent
Widget complet pour afficher un contenu bloqué avec raisons et option d'appel.

**Usage:**
```dart
ModerationBlockedContent(
  moderationResult: moderationResult,
  resourceType: 'message', // 'message', 'photo', ou 'bio'
  onAppeal: () {
    // Action quand l'utilisateur fait appel
  },
)
```

### 4. ModerationHistoryPage
Page complète pour l'historique de modération.

**Navigation:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const ModerationHistoryPage(),
  ),
);
```

## Intégration dans les Messages

Les messages de chat affichent automatiquement:
1. **Message bloqué** - Affiche un avertissement avec les raisons
2. **Message en attente** - Badge compact en orange
3. **Message approuvé** - Affichage normal sans badge

**Exemple de données:**
```json
{
  "id": "msg-123",
  "content": "Hello!",
  "moderationResult": {
    "status": "blocked",
    "flags": [
      {
        "name": "Spam",
        "confidence": 95.0
      }
    ],
    "moderatedAt": "2024-01-15T10:00:00Z",
    "moderator": "ai"
  }
}
```

## Intégration dans les Profils

### Photos de Profil
Les photos incluent un champ `moderationResult`:

```json
{
  "id": "photo-123",
  "url": "https://...",
  "moderationResult": {
    "status": "blocked",
    "flags": [
      {
        "name": "Explicit Nudity",
        "confidence": 98.5
      }
    ]
  }
}
```

### Biographie
Le profil inclut `bioModerationResult`:

```json
{
  "bio": "Mon texte de bio",
  "bioModerationResult": {
    "status": "approved",
    "flags": []
  }
}
```

## API de Modération

### Obtenir le statut
```dart
final result = await ModerationService.getModerationStatus(
  resourceType: 'message',
  resourceId: 'msg-123',
);
```

### Obtenir l'historique
```dart
final history = await ModerationService.getModerationHistory(
  page: 1,
  limit: 20,
);
```

### Faire appel d'une décision
```dart
final success = await ModerationService.appealModerationDecision(
  resourceType: 'message',
  resourceId: 'msg-123',
  reason: 'Ce message est approprié car...',
);
```

## Tests

Tous les composants sont testés:
- `test/moderation_models_test.dart` - Tests des modèles
- `test/moderation_service_test.dart` - Tests du service
- `test/moderation_widgets_test.dart` - Tests des widgets

## Personnalisation

Les couleurs et styles respectent le thème de l'application:
- **Approuvé**: `AppColors.successGreen`
- **En attente**: `AppColors.warningAmber`
- **Bloqué**: `AppColors.errorRed`
- **Drapeaux**: `AppColors.errorRed` avec opacité
