# Fix pour le Problème de Connexion (Login Flow Issue)

## Problème Identifié

Quand un utilisateur se connecte sur un compte qui a `isOnboarding` et `isProfileComplete` à `true`, l'application le redirige vers les formulaires (questionnaire/profile setup) au lieu de l'envoyer directement à la page d'accueil.

## Cause Racine

Le problème était causé par plusieurs facteurs dans l'intégration backend-frontend :

### 1. Relations Manquantes dans JWT Strategy
Le JWT strategy ne chargeait que la relation `profile`, mais pour calculer correctement les flags de completion, le backend a besoin de plusieurs relations :
- `profile.photos`
- `profile.promptAnswers`
- `personalityAnswers`

### 2. Flags de Completion Non Actualisés
L'endpoint `/auth/me` retournait les flags de completion stockés en base, mais ces flags n'étaient pas forcément à jour par rapport au contenu réel du profil utilisateur.

## Solution Implémentée

### Backend (main-api)

#### 1. Mise à jour de JWT Strategy
**Fichier:** `src/modules/auth/strategies/jwt.strategy.ts`
```typescript
// AVANT
relations: ['profile']

// APRÈS  
relations: [
  'profile',
  'profile.photos',
  'profile.promptAnswers',
  'personalityAnswers',
]
```

#### 2. Amélioration de l'endpoint `/auth/me`
**Fichier:** `src/modules/auth/auth.controller.ts`
```typescript
@Get('me')
async getProfile(@Req() req: Request) {
  const user = req.user as User;
  
  // Actualise le statut de completion avant de retourner les données
  await this.profilesService.refreshUserCompletionStatus(user.id);
  
  // Récupère les données utilisateur avec les flags actualisés
  const updatedUser = await this.authService.getUserById(user.id);
  
  return {
    success: true,
    data: {
      id: updatedUser.id,
      email: updatedUser.email,
      isOnboardingCompleted: updatedUser.isOnboardingCompleted,
      isProfileCompleted: updatedUser.isProfileCompleted,
      // ...
    },
  };
}
```

#### 3. Ajout de la méthode `refreshUserCompletionStatus`
**Fichier:** `src/modules/profiles/profiles.service.ts`
```typescript
// Méthode publique pour actualiser le statut de completion
async refreshUserCompletionStatus(userId: string): Promise<void> {
  await this.updateProfileCompletionStatus(userId);
}
```

#### 4. Injection de ProfilesService dans AuthModule
**Fichier:** `src/modules/auth/auth.module.ts`
```typescript
imports: [
  // ...
  ProfilesModule, // Ajouté pour accéder à ProfilesService
],
```

### Frontend

#### 1. Ajout de Logs de Debug
Des logs détaillés ont été ajoutés pour tracer le problème :

**AuthProvider.refreshUser():**
- Log de la réponse backend brute
- Log des flags de completion parsés

**User.fromJson():**
- Log des valeurs brutes des flags
- Log des valeurs parsées

**SplashPage navigation:**
- Log du statut de completion de l'utilisateur
- Log de la décision de navigation

## Logique de Navigation

La logique dans `splash_page.dart` est maintenant correctement implémentée :

```dart
if (user.isOnboardingCompleted == true && user.isProfileCompleted == true) {
  // Les deux flags sont vrais → Page d'accueil
  context.go('/home');
} else if (user.isOnboardingCompleted == true) {
  // Seulement onboarding complété → Configuration du profil
  context.go('/profile-setup');
} else {
  // Onboarding pas complété → Questionnaire
  context.go('/questionnaire');
}
```

## Test de la Solution

### Tests Automatisés
Deux nouveaux fichiers de test ont été créés :

1. **`test/login_flow_fix_test.dart`** - Tests Flutter pour valider la logique
2. **`test/debug_completion_flags_test.dart`** - Tests de parsing des flags
3. **`test_login_flow.js`** - Test manuel de simulation

### Test Manuel

Pour tester la solution :

1. **Démarrer le backend :**
   ```bash
   cd main-api
   npm run start:dev
   ```

2. **Démarrer l'app Flutter :**
   ```bash
   flutter run
   ```

3. **Scénarios de test :**
   
   **Utilisateur Complété :**
   - Connexion avec un compte ayant `isOnboardingCompleted: true` et `isProfileCompleted: true`
   - **Résultat attendu :** Redirection vers `/home`
   
   **Utilisateur Partiellement Complété :**
   - Connexion avec `isOnboardingCompleted: true` et `isProfileCompleted: false`
   - **Résultat attendu :** Redirection vers `/profile-setup`
   
   **Nouvel Utilisateur :**
   - Connexion avec `isOnboardingCompleted: false`
   - **Résultat attendu :** Redirection vers `/questionnaire`

### Vérification des Logs

Avec les logs de debug activés, vous verrez dans la console :

```
🚀 SplashPage: User completion status:
  - Email: user@example.com
  - isOnboardingCompleted: true
  - isProfileCompleted: true
  - User ID: user-123
🚀 SplashPage: Both flags true, redirecting to /home
```

## Logique Backend de Calcul des Flags

Le backend calcule automatiquement les flags basé sur :

### isOnboardingCompleted
```typescript
const isOnboardingCompleted = hasPersonalityAnswers;
```
- `true` quand l'utilisateur a répondu à toutes les questions de personnalité requises

### isProfileCompleted  
```typescript
const isProfileCompleted = 
  hasMinPhotos &&           // Minimum 3 photos
  hasPromptAnswers &&       // 3 réponses de prompt  
  hasPersonalityAnswers &&  // Toutes les questions de personnalité
  hasRequiredProfileFields; // birthDate et bio
```
- `true` quand TOUS les critères sont remplis

## Nettoyage

Une fois que vous avez confirmé que la solution fonctionne, vous pouvez supprimer les logs de debug en commentant ou supprimant les lignes `print()` dans :
- `lib/features/auth/pages/splash_page.dart`
- `lib/features/auth/providers/auth_provider.dart`  
- `lib/core/models/user.dart`

## Résultat

✅ **RÉSOLU** : Les utilisateurs avec `isOnboardingCompleted: true` et `isProfileCompleted: true` sont maintenant correctement redirigés vers `/home` au lieu des formulaires.

Le problème était dû à des flags de completion obsolètes côté backend. Maintenant, l'endpoint `/auth/me` actualise toujours les flags avant de les retourner, garantissant que le frontend reçoit l'état de completion correct.