# Gestion des Quotas de Choix Quotidiens - Documentation Complète

## Vue d'ensemble

Ce document décrit l'implémentation complète du système de gestion des quotas de choix quotidiens dans l'application GoldWen, conformément aux spécifications v1.1 et aux requirements de l'issue frontend.

## Fonctionnalités Implémentées

### 1. Quotas par Type d'Abonnement

- **Utilisateurs Gratuits**: 1 choix par jour
- **Utilisateurs GoldWen Plus**: 3 choix par jour
- Les quotas sont appliqués côté client et côté serveur

### 2. Affichage du Nombre de Choix Restants

#### Localisation
- **Page de sélection quotidienne** (`daily_matches_page.dart`)
- Widget `_buildSelectionInfo()` affiche le compteur

#### Informations Affichées
- Nombre de choix restants / Maximum (ex: "2/3")
- Badge "PLUS" pour les utilisateurs premium
- Suggestion "GoldWen Plus: 3 choix/jour" pour les utilisateurs gratuits
- **Nouveau**: Temps restant avant le reset (ex: "Reset: dans 4h15")

### 3. Blocage UI si Quota Atteint

#### Comportement
- Bouton "Choisir" désactivé quand quota = 0
- Message de limite atteinte affiché
- Profils masqués après épuisement du quota
- État "Sélection terminée" avec icon de validation

#### Messages Contextuels
- **Sélection terminée**: "Votre choix est fait. Revenez demain pour de nouveaux profils."
- **Avec reset time**: "Prochaine sélection : demain à 12:00"
- **Premium users**: "Nouvelle sélection dans 4h15"

### 4. Prompt d'Upgrade pour Utilisateurs Gratuits

#### SubscriptionLimitReachedDialog
- Affiche le quota utilisé (1/1)
- **Nouveau**: Affiche le temps avant reset
- Liste les avantages de GoldWen Plus:
  - 3 sélections par jour au lieu d'1
  - Chat illimité avec vos matches
  - Voir qui vous a sélectionné
  - Profil prioritaire
- Boutons d'action: "Plus tard" / "Passer à Plus"

#### SubscriptionPromoBanner
- Bannière non-intrusive
- Message personnalisable
- Navigation vers page d'abonnement au clic

### 5. Intégration API

#### Endpoints Utilisés

**GET /api/v1/subscriptions/usage**
```json
{
  "dailyChoices": {
    "used": 1,
    "limit": 3,
    "remaining": 2,
    "resetTime": "2025-01-16T12:00:00Z"
  },
  "subscription": {
    "tier": "premium",
    "isActive": true
  }
}
```

**GET /api/v1/matching/daily-selection**
```json
{
  "profiles": [...],
  "metadata": {
    "choicesRemaining": 2,
    "choicesMade": 1,
    "maxChoices": 3,
    "refreshTime": "2025-01-16T12:00:00Z"
  }
}
```

**POST /api/v1/matching/choose/:profileId**
```json
{
  "success": true,
  "data": {
    "isMatch": false,
    "choicesRemaining": 1,
    "message": "Votre choix est fait",
    "canContinue": true
  }
}
```

### 6. Reset Automatique

#### Mécanique
- Reset géré par le backend (selon specs: minuit ou midi)
- Frontend vérifie l'expiration via `DailySelection.isExpired`
- Rafraîchissement automatique lors de la reprise de l'app
- Listener `WidgetsBindingObserver` pour détecter le retour à l'app

#### Implementation
```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    matchingProvider.refreshSelectionIfNeeded();
  }
}
```

### 7. Format d'Affichage du Reset Time

#### Logique de Formatage (`_formatResetTime()`)
- **< 1 heure**: "45min"
- **< 24 heures**: "4h15"
- **Jour suivant**: "demain à 12:00"

#### Localisation d'Affichage
- Section info de sélection (quand quota = 0)
- État de sélection terminée
- Dialog de limite atteinte
- Messages d'erreur

## Architecture des Composants

### Modèles de Données

#### DailySelection
```dart
class DailySelection {
  final int choicesRemaining;  // Choix restants
  final int choicesMade;        // Choix effectués
  final int maxChoices;         // Maximum selon tier
  final DateTime? refreshTime;  // Prochaine disponibilité
  
  bool get canSelectMore => choicesRemaining > 0;
  bool get isSelectionComplete => choicesMade >= maxChoices;
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
```

#### SubscriptionUsage
```dart
class SubscriptionUsage {
  final int dailyChoicesUsed;   // Via dailyChoices.used
  final int dailyChoicesLimit;  // Via dailyChoices.limit
  final DateTime resetDate;     // Via dailyChoices.resetTime
  
  int get remainingChoices => (dailyChoicesLimit - dailyChoicesUsed).clamp(0, dailyChoicesLimit);
  bool get hasRemainingChoices => dailyChoicesUsed < dailyChoicesLimit;
}
```

### Provider Logic

#### MatchingProvider
```dart
class MatchingProvider {
  // Getters basés sur DailySelection ou SubscriptionUsage
  int get maxSelections;
  int get remainingSelections;
  bool get canSelectMore;
  bool get isSelectionComplete;
  
  // Actions
  Future<void> loadDailySelection();
  Future<Map<String, dynamic>?> selectProfile(...);
  void refreshSelectionIfNeeded();
  
  // Helpers
  String? _formatResetTime(DateTime resetTime);
}
```

### UI Components

#### Daily Matches Page
- `_buildSelectionInfo()`: Compteur de choix
- `_buildSelectionCompleteState()`: État quota épuisé
- `_buildProfileCard()`: Carte de profil avec boutons
- `_showChoiceConfirmation()`: Dialog de confirmation
- `_formatResetTime()`: Formatage du temps

#### Subscription Widgets
- `SubscriptionPromoBanner`: Bannière upgrade
- `SubscriptionLimitReachedDialog`: Dialog limite atteinte
- `SubscriptionStatusIndicator`: Badge status premium

## Tests

### Tests Unitaires

**daily_selection_quota_test.dart**
- Parsing des métadonnées de quota
- Calculs de choix restants
- Détection de sélection complète
- Gestion des données manquantes

**daily_quota_ui_test.dart**
- Formatage du reset time
- Logique d'affichage selon tier
- États de sélection

**subscription_integration_test.dart**
- Widgets de subscription
- Dialog de limite
- Bannières upgrade

### Scénarios de Test

1. **Utilisateur gratuit - 1er choix**
   - Affiche "1/1" choix restants
   - Permet la sélection
   - Après sélection: masque profils, affiche message

2. **Utilisateur gratuit - Quota atteint**
   - Bouton désactivé
   - Affiche reset time
   - Propose upgrade

3. **Utilisateur premium - 3 choix**
   - Affiche "3/3" avec badge PLUS
   - Permet 3 sélections
   - Après 3e: affiche message sans upgrade prompt

4. **Reprise app après reset**
   - Détecte quota reseté
   - Recharge sélection automatiquement

## Messages d'Erreur

### Quota Épuisé - Utilisateur Gratuit
```
"Vous avez atteint votre limite quotidienne. Nouvelle sélection dans 4h15 
ou passez à GoldWen Plus pour 3 choix/jour !"
```

### Quota Épuisé - Utilisateur Premium
```
"Limite quotidienne de sélections atteinte. Nouvelle sélection dans 4h15."
```

### Profil Déjà Sélectionné
```
"Profil déjà sélectionné"
```

## UX et Accessibilité

### Sémantique
- Labels accessibles pour lecteurs d'écran
- Hints pour actions disponibles
- Annonces d'état (quota restant, limite atteinte)

### Animations
- Respect de `reducedMotion`
- Fade-in progressif des éléments
- Slide-in pour les cartes

### Feedback Visuel
- Codes couleur (vert=disponible, gris=épuisé)
- Icons contextuels (check, horloge, étoile)
- Badges et compteurs bien visibles

## Points d'Attention

### Compatibilité Backend
- Support de formats API multiples (metadata wrapper ou direct)
- Fallback sur valeurs par défaut si données manquantes
- Gestion gracieuse des erreurs 404 (utilisateur sans subscription)

### Performance
- Préchargement des images de profils
- Cache des données de quota
- Refresh minimal (uniquement si nécessaire)

### Edge Cases Gérés
- Données backend manquantes → defaults (1 choix gratuit)
- Network failures → messages clairs
- Expiration pendant utilisation → auto-refresh
- Double sélection → prévention

## Conformité Spécifications

✅ **Cahier des Charges v1.1**
- Quotas respectés (1 gratuit / 3 Plus)
- Messages conformes ("Revenez demain...")
- UI claire selon type utilisateur

✅ **Requirements Issue**
- API `/subscriptions/usage` intégrée
- UI/UX claire par type utilisateur
- Reset automatique géré
- Tests unitaires complets
- Impossible de dépasser quota

## Améliorations Apportées

Par rapport à l'implémentation de base:

1. **Affichage du temps de reset** (nouveau)
2. **Messages contextuels** avec temps restant
3. **Auto-refresh au resume** de l'app
4. **Tests supplémentaires** pour UI logic
5. **Documentation complète** de l'implémentation

## Fichiers Modifiés/Créés

### Modifiés
- `lib/features/matching/pages/daily_matches_page.dart`
- `lib/features/matching/providers/matching_provider.dart`
- `lib/features/subscription/widgets/subscription_banner.dart`
- `test/subscription_integration_test.dart`

### Créés
- `test/daily_quota_ui_test.dart`
- `QUOTA_MANAGEMENT_DOCUMENTATION.md` (ce fichier)

## Maintenance Future

### À Surveiller
- Changements de fuseau horaire utilisateur
- Modifications de format API backend
- Évolution des tiers d'abonnement

### Extensibilité
- Facile d'ajouter de nouveaux tiers (ex: "GoldWen X" avec 5 choix)
- Modulaire pour différentes stratégies de reset
- Adaptable à d'autres types de quotas (super likes, boosts, etc.)
