# Guide des Processus Frontend-Backend GoldWen

Ce document décrit tous les processus d'interaction entre le frontend (application Flutter) et le backend de GoldWen, de l'inscription à l'utilisation complète de l'application.

## Table des Matières

1. [Architecture Générale](#architecture-générale)
2. [Processus d'Authentification](#processus-dauthentification)
3. [Processus d'Onboarding](#processus-donboarding)
4. [Gestion des Profils](#gestion-des-profils)
5. [Système de Matching](#système-de-matching)
6. [Messagerie et Chat](#messagerie-et-chat)
7. [Système d'Abonnements](#système-dabonnements)
8. [Notifications](#notifications)
9. [Administration](#administration)
10. [Gestion des Erreurs](#gestion-des-erreurs)

---

## Architecture Générale

### Services Backend
- **API Principal** : `http://localhost:3000/api/v1` (Node.js/Express)
- **Service de Matching** : `http://localhost:8000/api/v1` (Python/FastAPI)
- **WebSocket Chat** : `ws://localhost:3000/chat` (Temps réel)

### Frontend Flutter
- **ApiService** : Service principal pour les appels REST API
- **MatchingServiceApi** : Service dédié au système de matching
- **WebSocketService** : Service pour la messagerie temps réel
- **Providers** : Gestion d'état avec Provider pattern

---

## Processus d'Authentification

### 1. Inscription par Email

**Frontend → Backend :**
```
1. L'utilisateur saisit ses informations dans EmailAuthPage
2. Frontend valide les données localement
3. Appel API : POST /auth/register
   {
     "email": "user@example.com",
     "password": "password123",
     "firstName": "John",
     "lastName": "Doe"
   }
4. Backend crée l'utilisateur et retourne un token JWT
5. Frontend stocke le token et redirige vers le questionnaire
```

**Flux détaillé :**
1. **Validation locale** : Email format, mot de passe fort
2. **Appel d'inscription** : Création du compte utilisateur
3. **Réception du token** : JWT avec expiration 24h
4. **Stockage sécurisé** : Token sauvegardé localement
5. **Redirection** : Vers le questionnaire de personnalité

### 2. Connexion Sociale Google

**Frontend → Backend :**
```
1. L'utilisateur clique sur "Se connecter avec Google"
2. Frontend initie OAuth avec Google
3. Google retourne les informations utilisateur
4. Appel API : POST /auth/social-login
   {
     "socialId": "google_user_id_123",
     "provider": "google",
     "email": "user@example.com",
     "firstName": "John",
     "lastName": "Doe"
   }
5. Backend vérifie/crée l'utilisateur et retourne un token
```

**Flux OAuth détaillé :**
1. **Redirection Google** : `GET /auth/google`
2. **Autorisation utilisateur** : Sur la plateforme Google
3. **Callback** : `GET /auth/google/callback` avec code d'autorisation
4. **Échange de token** : Backend échange le code contre un token Google
5. **Création/connexion** : Utilisateur créé ou connecté selon l'existence
6. **Token JWT** : Généré et retourné au frontend

### 3. Connexion Sociale Apple

**Frontend → Backend :**
```
1. L'utilisateur clique sur "Se connecter avec Apple"
2. Frontend initie Sign in with Apple
3. Apple retourne les informations utilisateur (limitées)
4. Appel API : POST /auth/social-login
   {
     "socialId": "apple_user_id_456",
     "provider": "apple",
     "email": "user@privaterelay.appleid.com",
     "firstName": "John"
   }
5. Backend traite la connexion Apple spécifique
```

**Spécificités Apple :**
- **Email privé** : Peut être un relay Apple
- **Données limitées** : Nom complet seulement au premier login
- **Identifiant unique** : Stable pour l'application

### 4. Connexion Email/Mot de Passe

**Frontend → Backend :**
```
1. L'utilisateur saisit email/mot de passe
2. Validation locale des champs
3. Appel API : POST /auth/login
   {
     "email": "user@example.com",
     "password": "password123"
   }
4. Backend vérifie les credentials
5. Retour du token JWT si valide
```

### 5. Récupération de Mot de Passe

**Frontend → Backend :**
```
1. L'utilisateur clique "Mot de passe oublié"
2. Saisie de l'email
3. Appel API : POST /auth/forgot-password
   { "email": "user@example.com" }
4. Backend envoie un email avec token de reset
5. L'utilisateur clique le lien dans l'email
6. Redirection vers formulaire de nouveau mot de passe
7. Appel API : POST /auth/reset-password
   {
     "token": "reset_token_123",
     "newPassword": "newpassword456"
   }
```

---

## Processus d'Onboarding

### 1. Questionnaire de Personnalité

**Frontend → Backend :**
```
1. Affichage des 10 questions de personnalité
2. L'utilisateur répond progressivement
3. Validation locale de chaque réponse
4. À la fin, soumission globale :
   POST /profiles/me/personality-answers
   [
     {
       "questionId": 1,
       "answer": "Je suis motivé par la créativité...",
       "category": "motivation"
     },
     // ... autres réponses
   ]
5. Backend analyse et calcule le profil de personnalité
```

**Questions couvertes :**
- Motivation et valeurs personnelles
- Style de communication
- Gestion des conflits
- Attentes relationnelles
- Vision d'avenir
- Préférences d'humour

### 2. Création du Profil Complet

**Étapes séquentielles :**

#### Étape 1 : Informations de Base
```
PUT /profiles/me
{
  "bio": "Description personnelle...",
  "age": 29,
  "location": "Paris, France",
  "job": "Designer",
  "education": "Master"
}
```

#### Étape 2 : Upload de Photos
```
POST /profiles/me/photos (multipart/form-data)
- Minimum 3 photos requises
- Maximum 6 photos autorisées
- Formats : JPEG, PNG
- Taille max : 10MB par photo
```

#### Étape 3 : Réponses aux Prompts
```
POST /profiles/me/prompt-answers
[
  {
    "promptId": 1,
    "answer": "Mon plat réconfort c'est..."
  },
  {
    "promptId": 2,
    "answer": "Je suis fier de..."
  },
  {
    "promptId": 3,
    "answer": "Mon idée d'un premier rendez-vous..."
  }
]
```

#### Étape 4 : Validation et Activation
```
PUT /profiles/me/status
{
  "status": "active",
  "completed": true
}
```

---

## Gestion des Profils

### 1. Consultation du Profil Personnel

**Frontend → Backend :**
```
GET /users/me
→ Retourne les informations utilisateur complètes

GET /profiles/me
→ Retourne le profil détaillé avec photos et réponses
```

### 2. Modification du Profil

**Frontend → Backend :**
```
PUT /users/me
{
  "firstName": "John",
  "email": "newemail@example.com"
}

PUT /profiles/me
{
  "bio": "Nouvelle description...",
  "location": "Lyon, France"
}
```

### 3. Gestion des Photos

**Ajout de photos :**
```
POST /profiles/me/photos
(multipart/form-data avec fichiers)
```

**Suppression de photos :**
```
DELETE /profiles/me/photos/:photoId
```

**Réorganisation :**
```
PUT /profiles/me/photos/order
{
  "photoIds": [3, 1, 4, 2, 5]
}
```

### 4. Paramètres Utilisateur

**Frontend → Backend :**
```
PUT /users/me/settings
{
  "notificationsEnabled": true,
  "ageRange": { "min": 25, "max": 35 },
  "maxDistance": 30,
  "showOnlineStatus": false
}
```

---

## Système de Matching

### 1. Sélection Quotidienne

**Frontend → Backend :**
```
1. Chaque jour à midi, notification envoyée
2. L'utilisateur ouvre l'app
3. GET /matching/daily-selection
   → Retourne 3-5 profils sélectionnés
4. Affichage des profils avec scores de compatibilité
```

**Réponse type :**
```json
{
  "profiles": [
    {
      "userId": "user123",
      "compatibilityScore": 87,
      "profile": {
        "photos": [...],
        "bio": "...",
        "prompts": [...]
      },
      "sharedInterests": ["voyage", "cuisine"],
      "personalityMatch": {
        "communication": 0.9,
        "values": 0.8
      }
    }
  ],
  "selectionDate": "2025-01-15",
  "remainingSelections": 1
}
```

### 2. Processus de Sélection

**Frontend → Backend :**
```
1. L'utilisateur consulte un profil détaillé
2. Décision : Sélectionner ou Passer
3. POST /matching/select
   {
     "selectedUserId": "user123",
     "action": "select" // ou "pass"
   }
4. Backend enregistre la sélection
5. Si match mutuel → Création de conversation
```

### 3. Calcul de Compatibilité

**Service de Matching Python :**
```
1. Backend principal → Service Matching
2. POST /compatibility/calculate
   {
     "userId1": "user123",
     "userId2": "user456",
     "includeDetails": true
   }
3. Service analyse les profils de personnalité
4. Retourne score et détails de compatibilité
```

---

## Messagerie et Chat

### 1. Établissement de la Connexion

**WebSocket Flow :**
```
1. Match confirmé → Conversation créée
2. Frontend établit connexion WebSocket
3. ws://localhost:3000/chat?token=jwt_token
4. Backend authentifie et joint l'utilisateur à la room
```

### 2. Envoi de Messages

**Frontend → Backend (WebSocket) :**
```
{
  "type": "message",
  "conversationId": "conv123",
  "content": "Salut ! Comment ça va ?",
  "timestamp": "2025-01-15T14:30:00Z"
}
```

**Backend → Frontend (WebSocket) :**
```
{
  "type": "message_received",
  "messageId": "msg456",
  "conversationId": "conv123",
  "senderId": "user123",
  "content": "Salut ! Comment ça va ?",
  "timestamp": "2025-01-15T14:30:00Z"
}
```

### 3. Indicateurs de Frappe

**Frontend → Backend :**
```
{
  "type": "typing_start",
  "conversationId": "conv123"
}

{
  "type": "typing_stop",
  "conversationId": "conv123"
}
```

### 4. Historique des Messages

**REST API Fallback :**
```
GET /chat/conversations/:conversationId/messages
→ Retourne l'historique complet des messages
```

### 5. Expiration des Conversations

**Système automatique :**
```
1. Conversations expiring après 24h sans activité
2. Notification 2h avant expiration
3. Possibilité d'extension avec abonnement
4. Archivage automatique après expiration
```

---

## Système d'Abonnements

### 1. Consultation des Plans

**Frontend → Backend :**
```
GET /subscriptions/plans
→ Retourne la liste des plans disponibles avec prix
```

**Réponse type :**
```json
{
  "plans": [
    {
      "id": "goldwen_plus_monthly",
      "name": "GoldWen Plus",
      "price": 19.99,
      "currency": "EUR",
      "duration": "monthly",
      "features": [
        "3 sélections par jour",
        "Chat illimité",
        "Voir qui vous a sélectionné",
        "Profil prioritaire"
      ]
    }
  ]
}
```

### 2. Processus d'Achat

**Frontend → Backend :**
```
1. L'utilisateur choisit un plan
2. Redirection vers le système de paiement (Stripe/Apple/Google)
3. Après paiement, callback avec reçu
4. POST /subscriptions/verify-receipt
   {
     "platform": "apple", // ou "google", "stripe"
     "receiptData": "base64_receipt",
     "productId": "goldwen_plus_monthly"
   }
5. Backend vérifie auprès du provider
6. Activation de l'abonnement
```

### 3. Gestion de l'Abonnement

**Consultation du statut :**
```
GET /subscriptions/me
→ Retourne l'abonnement actuel et son statut
```

**Annulation :**
```
PUT /subscriptions/cancel
{
  "reason": "too_expensive" // optionnel
}
```

**Restauration :**
```
POST /subscriptions/restore
→ Vérifie et restaure les achats existants
```

### 4. Contrôle d'Accès aux Fonctionnalités

**Frontend → Backend :**
```
GET /subscriptions/usage
→ Retourne l'utilisation actuelle des fonctionnalités

{
  "dailySelections": {
    "used": 1,
    "limit": 3,
    "resetTime": "2025-01-16T12:00:00Z"
  },
  "chatExtensions": {
    "used": 0,
    "limit": 10
  }
}
```

---

## Notifications

### 1. Configuration des Notifications

**Frontend → Backend :**
```
POST /notifications/register-device
{
  "deviceToken": "fcm_token_123",
  "platform": "ios", // ou "android"
  "appVersion": "1.0.0"
}
```

### 2. Types de Notifications

**Sélection Quotidienne :**
```
{
  "type": "daily_selection",
  "title": "Votre sélection du jour est prête !",
  "body": "3 nouveaux profils compatibles vous attendent",
  "scheduledTime": "12:00"
}
```

**Nouveau Match :**
```
{
  "type": "new_match",
  "title": "Vous avez un match !",
  "body": "Sophie a aussi flashé sur vous",
  "data": {
    "conversationId": "conv123",
    "matchedUserId": "user456"
  }
}
```

**Message Reçu :**
```
{
  "type": "new_message",
  "title": "Nouveau message de Sophie",
  "body": "Salut ! Comment ça va ?",
  "data": {
    "conversationId": "conv123",
    "senderId": "user456"
  }
}
```

**Expiration de Chat :**
```
{
  "type": "chat_expiring",
  "title": "Votre conversation expire bientôt",
  "body": "Plus que 2h pour discuter avec Sophie",
  "data": {
    "conversationId": "conv123",
    "expiresAt": "2025-01-16T14:00:00Z"
  }
}
```

### 3. Paramètres de Notification

**Frontend → Backend :**
```
PUT /users/me/notification-settings
{
  "dailySelection": true,
  "newMatches": true,
  "newMessages": true,
  "chatExpiring": false,
  "marketing": false,
  "quietHours": {
    "start": "22:00",
    "end": "08:00"
  }
}
```

---

## Administration

### 1. Authentification Admin

**Frontend Admin → Backend :**
```
POST /admin/auth/login
{
  "email": "admin@goldwen.com",
  "password": "admin_password",
  "role": "admin"
}
```

### 2. Gestion des Utilisateurs

**Liste des utilisateurs :**
```
GET /admin/users?page=1&limit=20&status=active
→ Retourne la liste paginée des utilisateurs
```

**Détails d'un utilisateur :**
```
GET /admin/users/:userId
→ Informations complètes pour modération
```

**Actions de modération :**
```
PUT /admin/users/:userId/status
{
  "status": "suspended", // active, suspended, banned
  "reason": "Violation des conditions d'utilisation",
  "duration": "7d" // pour suspension temporaire
}
```

### 3. Gestion des Signalements

**Liste des signalements :**
```
GET /admin/reports?status=pending
→ Signalements en attente de traitement
```

**Traitement d'un signalement :**
```
PUT /admin/reports/:reportId
{
  "status": "resolved",
  "action": "warning_sent",
  "notes": "Premier avertissement envoyé à l'utilisateur"
}
```

### 4. Analytics et Métriques

**Dashboard principal :**
```
GET /admin/analytics
→ KPIs principaux de l'application

{
  "activeUsers": 1250,
  "newRegistrations": 45,
  "dailyMatches": 123,
  "messagesSent": 890,
  "subscriptionRate": 12.5
}
```

---

## Gestion des Erreurs

### 1. Types d'Erreurs

**Erreurs d'Authentification (401) :**
```json
{
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Token expiré ou invalide",
    "details": {
      "expiredAt": "2025-01-15T14:00:00Z"
    }
  }
}
```

**Erreurs de Validation (400/422) :**
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Données invalides",
    "fields": {
      "email": "Format d'email invalide",
      "password": "Mot de passe trop faible"
    }
  }
}
```

**Erreurs de Limite (429) :**
```json
{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Trop de tentatives, réessayez plus tard",
    "retryAfter": 300
  }
}
```

### 2. Stratégies de Récupération

**Retry Automatique :**
- Erreurs réseau (timeout, connexion)
- Erreurs serveur temporaires (5xx)
- Backoff exponentiel : 1s, 2s, 4s, 8s

**Fallback Modes :**
- Mode hors ligne pour consultation du profil
- Cache local pour les conversations récentes
- Synchronisation différée des actions

**Gestion des Tokens :**
```
1. Détection de token expiré (401)
2. Tentative de refresh automatique
3. Si échec → Redirection vers login
4. Conservation de l'état pour reprise après login
```

### 3. Logging et Monitoring

**Logs Frontend :**
- Erreurs API avec contexte
- Actions utilisateur importantes
- Performance des écrans
- Crashes et exceptions

**Logs Backend :**
- Requêtes API avec trace ID
- Erreurs de traitement
- Métriques de performance
- Événements de sécurité

---

## Flux Complets d'Utilisation

### Nouveau Utilisateur (Inscription Google)

```
1. WelcomePage → Clic "Se connecter avec Google"
2. OAuth Google → Autorisation
3. POST /auth/social-login → Compte créé
4. Redirection vers QuestionnairePersonality
5. 10 questions → POST /profiles/me/personality-answers
6. ProfileSetup (4 étapes) → Profil complet
7. PUT /profiles/me/status → Profil activé
8. Redirection vers DailySelection
9. GET /matching/daily-selection → Première sélection
```

### Utilisateur Existant (Utilisation Quotidienne)

```
1. Notification à midi → "Sélection prête"
2. Ouverture app → Auto-login avec token stocké
3. GET /matching/daily-selection → Nouveaux profils
4. Consultation + sélection → POST /matching/select
5. Si match → WebSocket connexion + conversation
6. Chat temps réel → Messages via WebSocket
7. GET /subscriptions/usage → Vérification limites
```

### Processus d'Abonnement

```
1. Limite atteinte → Écran upgrade
2. GET /subscriptions/plans → Affichage des options
3. Sélection plan → Redirection paiement
4. Paiement réussi → POST /subscriptions/verify-receipt
5. Abonnement activé → Fonctionnalités débloquées
6. Retour à l'app avec nouvelles capacités
```

---

Ce document couvre l'ensemble des interactions entre le frontend Flutter et le backend de GoldWen. Pour plus de détails techniques, consultez :
- `API_ROUTES.md` : Documentation complète des endpoints
- `BACKEND_INTEGRATION.md` : Détails d'implémentation technique
- `specifications.md` : Spécifications fonctionnelles complètes