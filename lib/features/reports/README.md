# Reports Feature - Module 11.1

## Description

Module de signalement permettant aux utilisateurs de signaler des profils ou des messages inappropriés. Le système implémente une prévention des doublons locale et backend, avec une interface utilisateur complète et intuitive.

## Fonctionnalités implémentées

### ✅ Page de signalement (ReportPage)
- Interface plein écran pour soumettre un signalement
- Support du signalement de profil ET de message
- Prévention des doublons avec tracking local (SharedPreferences)
- Gestion des erreurs backend (doublons, rate limiting, etc.)
- Feedback visuel clair (succès/erreur)

### ✅ Formulaire de signalement (ReportFormWidget)
- Widget réutilisable pour le formulaire de signalement
- 4 catégories de signalement :
  - Contenu inapproprié
  - Harcèlement
  - Spam
  - Autre
- Champ de description optionnel (max 500 caractères)
- Design conforme au thème de l'application
- Validation du formulaire

### ✅ Gestion des doublons
- **Tracking local** : Utilise SharedPreferences pour empêcher les multiples signalements du même contenu
- **Gestion backend** : Traite les erreurs de duplication du backend
- **Feedback utilisateur** : Message clair si l'utilisateur a déjà signalé ce contenu

### ✅ Intégration backend
- Utilise le ReportProvider existant
- API POST /reports avec les paramètres attendus
- Gestion des réponses et erreurs

## Structure des fichiers

```
lib/features/reports/
├── pages/
│   ├── report_page.dart          # Page principale de signalement
│   └── user_reports_page.dart    # Historique des signalements (existant)
├── widgets/
│   └── report_form_widget.dart   # Widget formulaire réutilisable
└── examples/
    └── report_page_usage_example.dart  # Exemples d'utilisation
```

## Utilisation

### 1. Signaler un profil utilisateur

```dart
import 'package:goldwen_app/features/reports/pages/report_page.dart';

// Navigation vers la page de signalement
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ReportPage(
      targetUserId: 'user-uuid',
      targetUserName: 'Jean Dupont',
    ),
  ),
);
```

### 2. Signaler un message

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ReportPage(
      targetUserId: 'user-uuid',
      targetUserName: 'Jean Dupont',
      messageId: 'message-uuid',
      chatId: 'chat-uuid',
    ),
  ),
);
```

### 3. Avec gestion du résultat

```dart
final result = await Navigator.push<bool>(
  context,
  MaterialPageRoute(
    builder: (context) => ReportPage(
      targetUserId: userId,
      targetUserName: userName,
    ),
  ),
);

// result = true si le signalement a été envoyé avec succès
if (result == true) {
  // Action après succès
}
```

## API Backend

### Endpoint
```
POST /api/v1/reports
```

### Corps de la requête
```json
{
  "targetUserId": "string (UUID)",
  "type": "inappropriate_content|harassment|spam|other",
  "reason": "string (description)",
  "messageId": "string (UUID, optionnel)",
  "chatId": "string (UUID, optionnel)"
}
```

### Réponse
```json
{
  "success": true,
  "reportId": "string (UUID)"
}
```

### Gestion des erreurs
- **409 Conflict** : L'utilisateur a déjà signalé ce contenu
- **429 Too Many Requests** : Limite quotidienne de signalements atteinte
- **400 Bad Request** : Données invalides

## Critères d'acceptation ✅

- ✅ **Accessible depuis le profil ou le chat** : La page peut être appelée depuis n'importe où avec les bonnes données
- ✅ **Catégories claires et complètes** : 4 catégories avec descriptions et icônes
- ✅ **Envoi au backend fonctionnel** : Intégration complète avec POST /reports
- ✅ **Message de confirmation après soumission** : Dialog de succès avec feedback clair
- ✅ **Utilisateur ne peut pas signaler plusieurs fois le même contenu** : Double protection (locale + backend)

## Architecture technique

### ReportPage
- **État** : Stateful Widget
- **Gestion d'état** : Provider (ReportProvider)
- **Storage local** : SharedPreferences pour tracking des doublons
- **Navigation** : Retourne `true` en cas de succès

### ReportFormWidget
- **Type** : Widget réutilisable
- **Validation** : Form avec GlobalKey
- **Callback** : onSubmit pour la soumission
- **Props** : isSubmitting pour désactiver le formulaire

### Prévention des doublons

1. **Check initial** : Vérifie SharedPreferences au chargement
2. **Affichage conditionnel** : Si déjà signalé, affiche un message au lieu du formulaire
3. **Sauvegarde post-soumission** : Marque comme signalé après succès
4. **Gestion backend** : Traite les erreurs de duplication du backend

Clé de stockage : 
- Profil : `report_user_{userId}`
- Message : `report_message_{messageId}`

## Tests recommandés

### Tests manuels
1. ✅ Signaler un profil avec chaque catégorie
2. ✅ Signaler un message
3. ✅ Tenter de signaler deux fois le même contenu
4. ✅ Vérifier le message de succès
5. ✅ Vérifier la gestion d'erreur réseau
6. ✅ Vérifier que le formulaire est désactivé pendant la soumission

### Tests unitaires (à implémenter)
- Test du widget ReportFormWidget
- Test de la logique de duplication
- Test du ReportProvider.submitReport

## Améliorations futures

- [ ] Possibilité de joindre des captures d'écran (evidence)
- [ ] Historique des signalements soumis dans l'app
- [ ] Notifications sur le statut du signalement
- [ ] Support multilingue complet
- [ ] Analytics sur les types de signalements

## Références

- Spécifications : `specifications.md` - Module 5 (Modération)
- Tâches frontend : `TACHES_FRONTEND.md` - Module 11.1
- Tâches backend : `TACHES_BACKEND.md` - Module 7
- API Routes : `API_ROUTES_DOCUMENTATION.md`
