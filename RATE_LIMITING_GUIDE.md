# Rate Limiting - Guide d'utilisation Frontend

## Vue d'ensemble

Cette implémentation fournit une gestion complète des erreurs de rate limiting côté frontend pour l'application GoldWen, conformément aux spécifications du cahier des charges (§5 - Sécurité).

## Fonctionnalités

### 1. Détection automatique des limites de taux
- Extraction des headers X-RateLimit (Limit, Remaining, Reset)
- Support du header Retry-After
- Détection du brute force sur les tentatives de login

### 2. UI/UX claire pour l'utilisateur
- Dialog avec compte à rebours en temps réel
- Messages contextuels selon le type de limitation
- Bouton de réessai automatique après expiration
- Banner d'avertissement quand on approche des limites

### 3. Gestion spécifique du brute force login
- Détection des 5 tentatives échouées
- Message de sécurité explicite
- Compte à rebours de 15 minutes par défaut

## Utilisation

### Méthode 1 : Gestion automatique avec ErrorHandler (Recommandé)

```dart
import 'package:goldwen_app/core/utils/error_handler.dart';

Future<void> makeApiCall() async {
  try {
    final result = await ApiService.someMethod();
    // Traiter le résultat
  } catch (e) {
    // Gère automatiquement les erreurs de rate limiting
    final handled = await ErrorHandler.handleApiError(
      context,
      e,
      onRetry: () => makeApiCall(),
    );
    
    if (!handled) {
      // Gérer les autres types d'erreurs
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }
}
```

### Méthode 2 : Gestion manuelle

```dart
import 'package:goldwen_app/core/services/api_service.dart';
import 'package:goldwen_app/core/widgets/rate_limit_dialog.dart';

Future<void> login() async {
  try {
    await ApiService.login(email: email, password: password);
  } catch (e) {
    if (e is ApiException && e.isRateLimitError) {
      // Afficher le dialog de rate limiting
      await RateLimitDialog.show(
        context,
        e,
        onRetry: () => login(),
      );
    } else {
      // Gérer les autres erreurs
      setState(() {
        errorMessage = e.toString();
      });
    }
  }
}
```

### Affichage du banner d'avertissement

```dart
import 'package:goldwen_app/core/widgets/rate_limit_dialog.dart';

@override
Widget build(BuildContext context) {
  return Column(
    children: [
      // Afficher un avertissement si proche de la limite
      if (rateLimitInfo != null)
        RateLimitWarningBanner(
          rateLimitInfo: rateLimitInfo,
          onDismiss: () {
            setState(() {
              rateLimitInfo = null;
            });
          },
        ),
      // Reste de l'UI
    ],
  );
}
```

## Format des réponses Backend

### Réponse 429 - Rate Limit Exceeded

Le backend doit retourner une réponse avec les headers suivants :

```
HTTP/1.1 429 Too Many Requests
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1704067200
Retry-After: 300
Content-Type: application/json

{
  "success": false,
  "error": "RATE_LIMIT_EXCEEDED",
  "message": "Trop de requêtes, réessayez plus tard",
  "retryAfter": 300
}
```

### Réponse 429 - Brute Force Login

Pour les tentatives de login échouées (après 5 tentatives) :

```
HTTP/1.1 429 Too Many Requests
Retry-After: 900
Content-Type: application/json

{
  "success": false,
  "error": "BRUTE_FORCE_DETECTED",
  "message": "Trop de tentatives de login",
  "retryAfter": 900
}
```

## Types de limitations selon les spécifications

D'après le backend (BACKEND_ISSUES_READY.md #12) :

1. **Rate limiting global** : 100 req/min par IP
   - Header : `X-RateLimit-Limit: 100`
   - Header : `X-RateLimit-Remaining: 25`

2. **Endpoints sensibles** : 20 req/min
   - Appliqué sur /auth/login, /auth/register, etc.

3. **Brute force login** : 5 tentatives par 15min
   - Code : `BRUTE_FORCE_DETECTED`
   - Retry-After : 900 secondes (15 min)

## Structure des classes

### RateLimitInfo

```dart
class RateLimitInfo {
  final int? limit;              // Limite maximale de requêtes
  final int? remaining;          // Requêtes restantes
  final DateTime? resetTime;     // Heure de réinitialisation
  final int? retryAfterSeconds;  // Secondes avant réessai
  
  bool get hasData;              // Vérifie si des données sont présentes
  bool get isNearLimit;          // Vérifie si proche de la limite (< 20%)
  String getRetryMessage();      // Message formaté pour l'utilisateur
}
```

### ApiException (étendu)

```dart
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? code;
  final Map<String, dynamic>? errors;
  final RateLimitInfo? rateLimitInfo;  // NOUVEAU
  
  bool get isRateLimitError;  // NOUVEAU - vérifie si statusCode == 429
}
```

## Tests

Des tests complets sont fournis pour :

- `test/rate_limit_test.dart` - Tests du modèle RateLimitInfo et ApiException
- `test/rate_limit_dialog_test.dart` - Tests du widget RateLimitDialog
- `test/error_handler_test.dart` - Tests de l'ErrorHandler

Exécuter les tests :
```bash
flutter test test/rate_limit_test.dart
flutter test test/rate_limit_dialog_test.dart
flutter test test/error_handler_test.dart
```

## Critères d'acceptation ✅

- [x] Gestion affichage headers X-RateLimit dans les requêtes
- [x] UI/UX pour informer l'utilisateur de la limite atteinte
- [x] Gestion des cas de blocage login (après 5 tentatives)
- [x] UX claire pour retry/attente
- [x] Expérience utilisateur claire en cas de rate limiting
- [x] Tests unitaires

## Exemples de messages utilisateur

### Rate Limit Global
```
Titre: "Limite de requêtes atteinte"
Message: "Vous avez dépassé la limite de 100 requêtes.
Réessayez dans 2 minutes et 30 secondes"
```

### Brute Force Login
```
Titre: "Trop de tentatives de connexion"
Message: "Pour votre sécurité, votre compte a été temporairement bloqué 
après plusieurs tentatives de connexion échouées.
Réessayez dans 15 minutes"
```

### Avertissement (Banner)
```
"Attention
Il vous reste 15 requêtes sur 100."
```

## Points d'attention

1. **Pas de modification backend** : Cette implémentation est purement frontend et s'intègre avec le backend existant
2. **Gestion du temps** : Les comptes à rebours sont mis à jour en temps réel
3. **Accessibilité** : Les messages sont clairs et en français
4. **Non-bloquant** : L'utilisateur peut comprendre et attendre ou faire autre chose
5. **Testable** : Tous les composants ont des tests unitaires

## Intégration avec le reste de l'app

Le système est automatiquement intégré dans :
- `lib/features/auth/pages/email_auth_page.dart` - Page de connexion/inscription
- Peut être facilement ajouté à d'autres pages via `ErrorHandler`

Pour ajouter à d'autres parties de l'app :
1. Importer `ErrorHandler`
2. Wrapper les appels API dans un try-catch
3. Appeler `ErrorHandler.handleApiError()` dans le catch
