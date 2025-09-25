# GoldWen Backend API - Complete Routes Documentation

Cette documentation complète liste toutes les routes API disponibles dans le backend GoldWen avec leurs variables attendues et types de données.

**Base URL**: `http://localhost:3000/api/v1`

## Index des Routes

- [Routes d'Application](#routes-dapplication)
- [Routes d'Authentification](#routes-dauthentification)
- [Routes Utilisateurs](#routes-utilisateurs)
- [Routes Profils](#routes-profils)
- [Routes Questions Personnalité](#routes-questions-personnalité)
- [Routes Matching](#routes-matching)
- [Routes Chat](#routes-chat)
- [Routes Conversations](#routes-conversations)
- [Routes Notifications](#routes-notifications)
- [Routes Abonnements](#routes-abonnements)
- [Routes Signalements](#routes-signalements)
- [Routes Légales](#routes-légales)
- [Routes Feedback](#routes-feedback)
- [Routes Admin](#routes-admin)
- [Types et Enums](#types-et-enums)

---

## Routes d'Application

### GET /
**Description**: Message d'accueil API  
**Authentification**: Aucune  
**Réponse**: Message de bienvenue en texte

### GET /health
**Description**: Vérification de la santé du service  
**Authentification**: Aucune  
**Réponse**:
```json
{
  "status": "ok",
  "uptime": "number",
  "timestamp": "ISO date string"
}
```

---

## Routes d'Authentification

**Préfixe**: `/auth`

### POST /auth/register
**Description**: Inscription d'un nouvel utilisateur  
**Authentification**: Aucune  
**Body**:
```json
{
  "email": "string (email)",
  "password": "string (min 6 caractères)",
  "firstName": "string",
  "lastName?": "string (optionnel)"
}
```
**Réponse**:
```json
{
  "success": "boolean",
  "message": "string",
  "data": {
    "user": {
      "id": "string",
      "email": "string",
      "isOnboardingCompleted": "boolean",
      "isProfileCompleted": "boolean"
    },
    "accessToken": "string"
  }
}
```

### POST /auth/login
**Description**: Connexion avec email et mot de passe  
**Authentification**: Aucune  
**Body**:
```json
{
  "email": "string (email)",
  "password": "string (min 6 caractères)"
}
```
**Réponse**: Même format que `/register`

### POST /auth/social-login
**Description**: Connexion sociale (Google/Apple)  
**Authentification**: Aucune  
**Body**:
```json
{
  "socialId": "string",
  "provider": "string (google|apple)",
  "email": "string (email)",
  "firstName": "string",
  "lastName?": "string (optionnel)",
  "profilePicture?": "string (URL, optionnel)"
}
```

### GET /auth/google
**Description**: Initier la connexion OAuth Google  
**Authentification**: Aucune  

### POST /auth/google
**Description**: Authentification Google avec token ID  
**Authentification**: Aucune  
**Body**:
```json
{
  "idToken": "string"
}
```

### GET /auth/google/callback
**Description**: Callback OAuth Google  
**Authentification**: Aucune  

### GET /auth/apple
**Description**: Initier la connexion OAuth Apple  
**Authentification**: Aucune  

### POST /auth/apple
**Description**: Authentification Apple avec token d'identité  
**Authentification**: Aucune  
**Body**:
```json
{
  "identityToken": "string",
  "user?": {
    "email?": "string",
    "name?": {
      "firstName?": "string",
      "lastName?": "string"
    }
  }
}
```

### GET /auth/apple/callback
**Description**: Callback OAuth Apple  
**Authentification**: Aucune  

### POST /auth/forgot-password
**Description**: Demander une réinitialisation de mot de passe  
**Authentification**: Aucune  
**Body**:
```json
{
  "email": "string (email)"
}
```

### POST /auth/reset-password
**Description**: Réinitialiser le mot de passe avec token  
**Authentification**: Aucune  
**Body**:
```json
{
  "token": "string",
  "newPassword": "string (min 6 caractères)"
}
```

### POST /auth/change-password
**Description**: Changer le mot de passe (utilisateur connecté)  
**Authentification**: Bearer Token  
**Body**:
```json
{
  "currentPassword": "string",
  "newPassword": "string (min 6 caractères)"
}
```

### POST /auth/verify-email
**Description**: Vérifier l'adresse email  
**Authentification**: Aucune  
**Body**:
```json
{
  "token": "string"
}
```

### GET /auth/me
**Description**: Obtenir le profil utilisateur actuel  
**Authentification**: Bearer Token  
**Réponse**:
```json
{
  "success": "boolean",
  "data": {
    "id": "string",
    "email": "string",
    "isOnboardingCompleted": "boolean",
    "isProfileCompleted": "boolean",
    "isEmailVerified": "boolean",
    "profile": "Profile object"
  }
}
```

---

## Routes Utilisateurs

**Préfixe**: `/users`  
**Authentification**: Bearer Token (toutes les routes)

### GET /users/me
**Description**: Obtenir le profil utilisateur complet  
**Réponse**:
```json
{
  "success": "boolean",
  "data": {
    "id": "string",
    "email": "string",
    "status": "UserStatus enum",
    "isEmailVerified": "boolean",
    "isOnboardingCompleted": "boolean",
    "isProfileCompleted": "boolean",
    "notificationsEnabled": "boolean",
    "lastLoginAt": "ISO date string",
    "createdAt": "ISO date string",
    "profile": "Profile object"
  }
}
```

### PUT /users/me
**Description**: Mettre à jour le profil utilisateur  
**Body**:
```json
{
  "firstName?": "string (optionnel)",
  "lastName?": "string (optionnel)",
  "fcmToken?": "string (optionnel)",
  "notificationsEnabled?": "boolean (optionnel, défaut: true)",
  "isOnboardingCompleted?": "boolean (optionnel, défaut: false)",
  "isProfileCompleted?": "boolean (optionnel, défaut: false)"
}
```

### PUT /users/me/settings
**Description**: Mettre à jour les paramètres utilisateur  
**Body**:
```json
{
  "notificationsEnabled?": "boolean (optionnel, défaut: true)",
  "emailNotifications?": "boolean (optionnel, défaut: true)",
  "pushNotifications?": "boolean (optionnel, défaut: true)"
}
```

### GET /users/me/stats
**Description**: Obtenir les statistiques utilisateur  
**Réponse**:
```json
{
  "success": "boolean",
  "data": {
    "totalMatches": "number",
    "activeChats": "number",
    "profileViews": "number",
    "loginStreak": "number"
  }
}
```

### PUT /users/me/deactivate
**Description**: Désactiver le compte utilisateur  

### POST /users/me/prompts
**Description**: Soumettre les réponses aux prompts  
**Body**:
```json
{
  "answers": [
    {
      "promptId": "string (UUID)",
      "answer": "string"
    }
  ]
}
```
**Note**: Exactement 3 réponses requises

### POST /users/me/photos
**Description**: Uploader des photos utilisateur (endpoint structure prêt)  
**Note**: Nécessite implémentation multipart/form-data

### DELETE /users/me/photos/:photoId
**Description**: Supprimer une photo utilisateur  
**Paramètres**: `photoId` (string)

### DELETE /users/me
**Description**: Supprimer le compte utilisateur  

### POST /users/me/push-tokens
**Description**: Enregistrer un token push device  
**Body**:
```json
{
  "token": "string",
  "platform": "Platform enum (ios|android|web)",
  "appVersion?": "string (optionnel)",
  "deviceId?": "string (optionnel)"
}
```

### DELETE /users/me/push-tokens
**Description**: Supprimer un token push device  
**Body**:
```json
{
  "token": "string"
}
```

### POST /users/consent
**Description**: Enregistrer le consentement RGPD utilisateur  
**Authentification**: Bearer Token  
**Body**:
```json
{
  "dataProcessing": "boolean",
  "marketing": "boolean (optionnel)",
  "analytics": "boolean (optionnel)",
  "consentedAt": "ISO date string"
}
```

### GET /users/me/export-data
**Description**: Exporter toutes les données utilisateur (RGPD)  
**Authentification**: Bearer Token  
**Query Parameters**:
- `format?`: string (json|pdf, défaut: json)
**Réponse**: Fichier téléchargeable avec toutes les données utilisateur

### PUT /users/me/privacy-settings
**Description**: Gérer les paramètres de confidentialité et cookies  
**Authentification**: Bearer Token  
**Body**:
```json
{
  "analytics": "boolean",
  "marketing": "boolean",
  "functionalCookies": "boolean",
  "dataRetention": "number (jours, optionnel)"
}
```

### GET /users/me/accessibility-settings
**Description**: Obtenir les paramètres d'accessibilité utilisateur  
**Authentification**: Bearer Token  

### PUT /users/me/accessibility-settings
**Description**: Mettre à jour les paramètres d'accessibilité  
**Authentification**: Bearer Token  
**Body**:
```json
{
  "fontSize": "string (small|medium|large|xlarge)",
  "highContrast": "boolean",
  "reducedMotion": "boolean",
  "screenReader": "boolean"
}
```

---

## Routes Profils

**Préfixe**: `/profiles`  
**Authentification**: Bearer Token (toutes les routes)

### GET /profiles/me
**Description**: Obtenir le profil utilisateur actuel  

### PUT /profiles/me
**Description**: Mettre à jour le profil utilisateur  
**Body**:
```json
{
  "firstName?": "string (max 50 caractères, optionnel)",
  "lastName?": "string (max 50 caractères, optionnel)",
  "pseudo?": "string (max 30 caractères, optionnel)",
  "birthDate?": "string (format YYYY-MM-DD, optionnel)",
  "gender?": "Gender enum (optionnel)",
  "interestedInGenders?": "Gender[] (array, optionnel)",
  "bio?": "string (max 500 caractères, optionnel)",
  "jobTitle?": "string (max 100 caractères, optionnel)",
  "company?": "string (max 100 caractères, optionnel)",
  "education?": "string (max 100 caractères, optionnel)",
  "location?": "string (max 100 caractères, optionnel)",
  "latitude?": "number (max 8 décimales, optionnel)",
  "longitude?": "number (max 8 décimales, optionnel)",
  "maxDistance?": "number (1-500, optionnel)",
  "minAge?": "number (18-100, optionnel)",
  "maxAge?": "number (18-100, optionnel)",
  "interests?": "string[] (optionnel)",
  "languages?": "string[] (optionnel)",
  "height?": "number (100-250 cm, optionnel)"
}
```

### GET /profiles/completion
**Description**: Obtenir le statut de complétion du profil  
**Réponse**:
```json
{
  "success": "boolean",
  "data": {
    "isComplete": "boolean",
    "completionPercentage": "number (0-100)",
    "missingSteps": "string[]",
    "requirements": {
      "personalityQuestionnaire": "boolean",
      "minimumPhotos": {
        "required": 3,
        "current": "number",
        "satisfied": "boolean"
      },
      "promptAnswers": {
        "required": 3,
        "current": "number",
        "satisfied": "boolean"
      },
      "basicInfo": "boolean"
    },
    "nextStep": "string (prochaine étape recommandée)"
  }
}
```  

### GET /profiles/personality-questions
**Description**: Obtenir les questions du questionnaire de personnalité  

### POST /profiles/me/personality-answers
**Description**: Soumettre les réponses au questionnaire de personnalité  
**Body**:
```json
{
  "answers": [
    {
      "questionId": "string (UUID)",
      "textAnswer?": "string (optionnel)",
      "numericAnswer?": "number (optionnel)",
      "booleanAnswer?": "boolean (optionnel)",
      "multipleChoiceAnswer?": "string[] (optionnel)"
    }
  ]
}
```

### POST /profiles/me/photos
**Description**: Uploader des photos de profil  
**Content-Type**: multipart/form-data  
**Champ**: `photos` (max 6 fichiers)

### DELETE /profiles/me/photos/:photoId
**Description**: Supprimer une photo de profil  
**Paramètres**: `photoId` (string)

### PUT /profiles/me/photos/:photoId/primary
**Description**: Définir une photo comme principale  
**Paramètres**: `photoId` (string)

### PUT /profiles/me/photos/:photoId/order
**Description**: Réorganiser l'ordre des photos de profil  
**Authentification**: Bearer Token  
**Paramètres**: `photoId` (string)  
**Body**:
```json
{
  "newOrder": "number (position dans la liste, min: 1)"
}
```

### GET /profiles/prompts
**Description**: Obtenir les prompts disponibles  

### POST /profiles/me/prompt-answers
**Description**: Soumettre les réponses aux prompts  
**Body**:
```json
{
  "answers": [
    {
      "promptId": "string (UUID)",
      "answer": "string (max 300 caractères)"
    }
  ]
}
```
**Note**: Minimum 3 réponses requises

### PUT /profiles/me/prompt-answers
**Description**: Modifier les réponses aux prompts existantes  
**Authentification**: Bearer Token  
**Body**:
```json
{
  "answers": [
    {
      "promptId": "string (UUID)",
      "answer": "string (max 300 caractères)"
    }
  ]
}
```

### PUT /profiles/me/status
**Description**: Mettre à jour le statut du profil  
**Body**:
```json
{
  "status?": "string (optionnel)",
  "completed": "boolean"
}
```

---

## Routes Questions Personnalité

**Préfixe**: `/personality-questions` (contrôleur racine)

### GET /personality-questions
**Description**: Obtenir les questions du questionnaire de personnalité  
**Authentification**: Aucune  

### POST /personality-answers
**Description**: Soumettre les réponses au questionnaire de personnalité  
**Authentification**: Bearer Token  
**Body**: Même format que `/profiles/me/personality-answers`

---

## Routes Matching

**Préfixe**: `/matching`  
**Authentification**: Bearer Token (toutes les routes)

### GET /matching/daily-selection
**Description**: Obtenir la sélection quotidienne de profils  
**Query Parameters**:
- `preload?`: boolean (défaut: false, charge les prochains profils)
**Réponse**:
```json
{
  "success": "boolean",
  "data": {
    "profiles": "User[] (profils de la sélection)",
    "metadata": {
      "date": "string (YYYY-MM-DD)",
      "choicesRemaining": "number",
      "choicesMade": "number",
      "maxChoices": "number",
      "refreshTime": "ISO date string (prochaine génération)"
    }
  }
}
```  

### POST /matching/daily-selection/generate
**Description**: Générer manuellement la sélection quotidienne (test)  

### POST /matching/choose/:targetUserId
**Description**: Choisir un profil dans la sélection quotidienne  
**Paramètres**: `targetUserId` (string)  
**Body**:
```json
{
  "choice": "string (like|pass)"
}
```
**Réponse**:
```json
{
  "success": "boolean",
  "data": {
    "isMatch": "boolean",
    "matchId?": "string (si match)",
    "choicesRemaining": "number",
    "message": "string (message de confirmation)",
    "canContinue": "boolean (peut continuer à faire des choix)"
  }
}
```

### GET /matching/matches
**Description**: Obtenir les matches utilisateur  
**Query Parameters**:
- `status?`: MatchStatus enum (optionnel)

### GET /matching/matches/:matchId
**Description**: Obtenir les détails d'un match spécifique  
**Paramètres**: `matchId` (string)

### DELETE /matching/matches/:matchId
**Description**: Supprimer un match  
**Paramètres**: `matchId` (string)

### GET /matching/compatibility/:targetUserId
**Description**: Obtenir le score de compatibilité  
**Paramètres**: `targetUserId` (string)

### GET /matching/user-choices
**Description**: Obtenir les choix utilisateur du jour actuel  
**Authentification**: Bearer Token  
**Query Parameters**:
- `date?`: string (format YYYY-MM-DD, défaut: aujourd'hui)
**Réponse**:
```json
{
  "success": "boolean",
  "data": {
    "date": "string (YYYY-MM-DD)",
    "choicesRemaining": "number",
    "choicesMade": "number",
    "maxChoices": "number",
    "choices": [
      {
        "targetUserId": "string",
        "chosenAt": "ISO date string"
      }
    ]
  }
}
```

### GET /matching/pending-matches
**Description**: Obtenir les matches en attente d'acceptation de chat  
**Authentification**: Bearer Token  
**Réponse**:
```json
{
  "success": "boolean",
  "data": [
    {
      "matchId": "string",
      "targetUser": "User profile object",
      "status": "pending",
      "matchedAt": "ISO date string",
      "canInitiateChat": "boolean"
    }
  ]
}
```

### GET /matching/history
**Description**: Obtenir l'historique des sélections passées  
**Authentification**: Bearer Token  
**Query Parameters**:
- `page?`: number (défaut: 1)
- `limit?`: number (défaut: 20)
- `startDate?`: string (YYYY-MM-DD)
- `endDate?`: string (YYYY-MM-DD)

### GET /matching/who-liked-me
**Description**: Voir qui a sélectionné l'utilisateur (fonctionnalité premium)  
**Authentification**: Bearer Token + Premium Subscription  
**Réponse**:
```json
{
  "success": "boolean",
  "data": [
    {
      "userId": "string",
      "user": "User profile object",
      "likedAt": "ISO date string"
    }
  ]
}
```

---

## Routes Chat

**Préfixe**: `/chat`  
**Authentification**: Bearer Token (toutes les routes)

### GET /chat
**Description**: Obtenir tous les chats utilisateur  

### GET /chat/stats
**Description**: Obtenir les statistiques de chat  

### GET /chat/match/:matchId
**Description**: Obtenir le chat par ID de match  
**Paramètres**: `matchId` (string)

### GET /chat/:chatId/messages
**Description**: Obtenir les messages du chat  
**Paramètres**: `chatId` (string)  
**Query Parameters**:
- `page?`: number (défaut: 1, min: 1)
- `limit?`: number (défaut: 50, min: 1, max: 100)

### POST /chat/:chatId/messages
**Description**: Envoyer un message  
**Paramètres**: `chatId` (string)  
**Body**:
```json
{
  "content": "string (max 1000 caractères)",
  "type?": "MessageType enum (optionnel, défaut: TEXT)"
}
```
**Réponse**:
```json
{
  "success": "boolean",
  "data": {
    "messageId": "string",
    "message": "Message object",
    "chat": {
      "id": "string",
      "status": "ChatStatus enum",
      "expiresAt": "ISO date string",
      "timeRemaining": "number (secondes)"
    }
  },
  "error?": "string (si chat expiré ou autre erreur)"
}
```

### PUT /chat/:chatId/messages/read
**Description**: Marquer les messages comme lus  
**Paramètres**: `chatId` (string)

### DELETE /chat/messages/:messageId
**Description**: Supprimer un message  
**Paramètres**: `messageId` (string)

### PUT /chat/:chatId/extend
**Description**: Prolonger le temps d'expiration du chat (fonctionnalité premium)  
**Paramètres**: `chatId` (string)  
**Body**:
```json
{
  "hours?": "number (défaut: 24, min: 1, max: 168)"
}
```

### POST /chat/accept/:matchId
**Description**: Accepter un match et créer/activer le chat  
**Authentification**: Bearer Token  
**Paramètres**: `matchId` (string)  
**Body**:
```json
{
  "accept": "boolean"
}
```
**Réponse**:
```json
{
  "success": "boolean",
  "data": {
    "chatId": "string",
    "match": "Match object",
    "expiresAt": "ISO date string"
  }
}
```

### PUT /chat/:chatId/expire
**Description**: Marquer un chat comme expiré (processus automatique)  
**Authentification**: Bearer Token  
**Paramètres**: `chatId` (string)

---

## Routes Conversations

**Préfixe**: `/conversations`  
**Authentification**: Bearer Token (toutes les routes)

### POST /conversations
**Description**: Créer une conversation pour un match mutuel  
**Body**:
```json
{
  "matchId": "string (UUID)"
}
```

### GET /conversations
**Description**: Obtenir toutes les conversations utilisateur  

### GET /conversations/:id/messages
**Description**: Obtenir les messages de conversation  
**Paramètres**: `id` (string - conversationId)  
**Query Parameters**: Même que `/chat/:chatId/messages`

### POST /conversations/:id/messages
**Description**: Envoyer un message dans la conversation  
**Paramètres**: `id` (string - conversationId)  
**Body**: Même que `/chat/:chatId/messages`

### PUT /conversations/:id/messages/read
**Description**: Marquer les messages comme lus  
**Paramètres**: `id` (string - conversationId)

### DELETE /conversations/:id/messages/:messageId
**Description**: Supprimer un message  
**Paramètres**: `id` (string - conversationId), `messageId` (string)

---

## Routes Notifications

**Préfixe**: `/notifications`  
**Authentification**: Bearer Token (toutes les routes)

### GET /notifications
**Description**: Obtenir les notifications utilisateur  
**Query Parameters**:
- `page?`: number (défaut: 1)
- `limit?`: number (défaut: 20)
- `type?`: NotificationType enum (optionnel)
- `read?`: boolean (optionnel)

### PUT /notifications/:notificationId/read
**Description**: Marquer une notification comme lue  
**Paramètres**: `notificationId` (string)

### PUT /notifications/read-all
**Description**: Marquer toutes les notifications comme lues  

### DELETE /notifications/:notificationId
**Description**: Supprimer une notification  
**Paramètres**: `notificationId` (string)

### PUT /notifications/settings
**Description**: Mettre à jour les paramètres de notification  
**Body**:
```json
{
  "dailySelection?": "boolean (optionnel)",
  "newMatch?": "boolean (optionnel)",
  "newMessage?": "boolean (optionnel)",
  "chatExpiring?": "boolean (optionnel)",
  "subscription?": "boolean (optionnel)"
}
```

### POST /notifications/test
**Description**: Envoyer une notification de test (développement uniquement)  
**Body**:
```json
{
  "title?": "string (défaut: 'Test Notification')",
  "body?": "string (défaut: 'This is a test notification')",
  "type?": "NotificationType enum (défaut: DAILY_SELECTION)"
}
```

### POST /notifications/send-group
**Description**: Envoyer une notification à un groupe d'utilisateurs (admin uniquement)  
**Body**:
```json
{
  "userIds": "string[]",
  "type": "NotificationType enum",
  "title": "string",
  "body": "string",
  "data?": "any (optionnel)"
}
```

### POST /notifications/trigger-daily-selection
**Description**: Déclencher manuellement les notifications de sélection quotidienne (dev uniquement)  
**Body**:
```json
{
  "targetUsers?": "string[] (userIds, optionnel - défaut: tous les utilisateurs)",
  "customMessage?": "string (message personnalisé, optionnel)"
}
```
**Réponse**:
```json
{
  "success": "boolean",
  "data": {
    "notificationsSent": "number",
    "errors": "string[]"
  }
}
```  

---

## Routes Abonnements

**Préfixe**: `/subscriptions`

### GET /subscriptions/plans
**Description**: Obtenir les plans d'abonnement disponibles  
**Authentification**: Aucune  

### POST /subscriptions
**Description**: Créer un nouvel abonnement  
**Authentification**: Bearer Token  
**Body**:
```json
{
  "plan": "SubscriptionPlan enum",
  "revenueCatCustomerId?": "string (optionnel)",
  "revenueCatSubscriptionId?": "string (optionnel)",
  "originalTransactionId?": "string (optionnel)",
  "price?": "number (optionnel)",
  "currency?": "string (optionnel)",
  "purchaseToken?": "string (optionnel)",
  "platform?": "string (optionnel)",
  "metadata?": "any (optionnel)"
}
```

### GET /subscriptions/active
**Description**: Obtenir l'abonnement actif  
**Authentification**: Bearer Token  

### GET /subscriptions
**Description**: Obtenir tous les abonnements utilisateur  
**Authentification**: Bearer Token  

### GET /subscriptions/features
**Description**: Obtenir les fonctionnalités d'abonnement  
**Authentification**: Bearer Token  

### GET /subscriptions/me
**Description**: Obtenir l'abonnement utilisateur actuel  
**Authentification**: Bearer Token  

### GET /subscriptions/tier
**Description**: Obtenir le niveau d'abonnement utilisateur et les fonctionnalités  
**Authentification**: Bearer Token  

### GET /subscriptions/usage
**Description**: Obtenir les statistiques d'utilisation de l'abonnement  
**Authentification**: Bearer Token  
**Réponse**:
```json
{
  "success": "boolean",
  "data": {
    "currentPeriod": {
      "startDate": "string (YYYY-MM-DD)",
      "endDate": "string (YYYY-MM-DD)"
    },
    "dailyChoices": {
      "limit": "number",
      "used": "number",
      "remaining": "number",
      "resetTime": "ISO date string"
    },
    "features": {
      "unlimitedChats": "boolean",
      "whoLikedMe": "boolean",
      "extendChats": "boolean",
      "priorityProfile": "boolean"
    },
    "subscription": {
      "tier": "SubscriptionTier enum",
      "plan": "SubscriptionPlan enum",
      "isActive": "boolean",
      "expiresAt": "ISO date string"
    }
  }
}
```  

### PUT /subscriptions/:subscriptionId/activate
**Description**: Activer un abonnement  
**Authentification**: Bearer Token  
**Paramètres**: `subscriptionId` (string)

### PUT /subscriptions/:subscriptionId/cancel
**Description**: Annuler un abonnement  
**Authentification**: Bearer Token  
**Paramètres**: `subscriptionId` (string)

### PUT /subscriptions/cancel
**Description**: Annuler l'abonnement utilisateur  
**Authentification**: Bearer Token  
**Body**:
```json
{
  "reason?": "string (optionnel)"
}
```

### PUT /subscriptions/:subscriptionId
**Description**: Mettre à jour un abonnement  
**Authentification**: Bearer Token  
**Paramètres**: `subscriptionId` (string)  
**Body**:
```json
{
  "status?": "SubscriptionStatus enum (optionnel)",
  "expiresAt?": "ISO date string (optionnel)",
  "metadata?": "any (optionnel)"
}
```

### POST /subscriptions/restore
**Description**: Restaurer les abonnements  
**Authentification**: Bearer Token  

### DELETE /subscriptions/:id
**Description**: Supprimer/Annuler un abonnement par ID  
**Authentification**: Bearer Token  
**Paramètres**: `id` (string)

### POST /subscriptions/webhook/revenuecat
**Description**: Gérer le webhook RevenueCat  
**Authentification**: Aucune  
**Body**:
```json
{
  "event": {
    "type": "string",
    "id": "string",
    "product_id?": "string (optionnel)",
    "original_transaction_id?": "string (optionnel)",
    "price_in_purchased_currency?": "number (optionnel)",
    "currency?": "string (optionnel)",
    "store?": "string (optionnel)",
    "purchased_at?": "ISO date string (optionnel)",
    "expiration_at?": "ISO date string (optionnel)",
    "subscriber_attributes?": "any (optionnel)"
  },
  "app_user_id": "string",
  "api_version?": "string (optionnel)"
}
```

### GET /subscriptions/admin/stats
**Description**: Obtenir les statistiques d'abonnement (Admin uniquement)  
**Authentification**: Bearer Token + Admin Guard  

---

## Routes Signalements

**Préfixe**: `/reports`  
**Authentification**: Bearer Token (toutes les routes)

### POST /reports
**Description**: Signaler un utilisateur ou contenu inapproprié  
**Body**:
```json
{
  "targetUserId": "string (UUID)",
  "type": "ReportType enum",
  "reason": "string (max 500 caractères)",
  "messageId?": "string (UUID, optionnel)",
  "chatId?": "string (UUID, optionnel)",
  "evidence?": "string[] (URLs, optionnel)"
}
```

### GET /reports/me
**Description**: Obtenir les signalements soumis par l'utilisateur  
**Query Parameters**:
- `page?`: number (défaut: 1)
- `limit?`: number (défaut: 20)
- `status?`: ReportStatus enum

---

## Routes Légales

**Préfixe**: `/legal`  
**Authentification**: Aucune

### GET /legal/privacy-policy
**Description**: Obtenir la politique de confidentialité  
**Query Parameters**:
- `version?`: string (version spécifique, optionnel)
- `format?`: string (html|json, défaut: json)

### GET /legal/terms-of-service
**Description**: Obtenir les conditions d'utilisation  
**Query Parameters**:
- `version?`: string (version spécifique, optionnel)
- `format?`: string (html|json, défaut: json)

---

## Routes Feedback

**Préfixe**: `/feedback`  
**Authentification**: Bearer Token

### POST /feedback
**Description**: Envoyer un feedback utilisateur  
**Body**:
```json
{
  "type": "string (bug|feature|general)",
  "subject": "string (max 100 caractères)",
  "message": "string (max 1000 caractères)",
  "rating?": "number (1-5, optionnel)",
  "metadata?": {
    "page": "string",
    "userAgent": "string",
    "appVersion": "string"
  }
}
```

---

## Routes Admin

**Préfixe**: `/admin`

### POST /admin/auth/login
**Description**: Connexion administrateur  
**Authentification**: Aucune  
**Body**:
```json
{
  "email": "string (email)",
  "password": "string"
}
```

### GET /admin/dashboard
**Description**: Obtenir les statistiques du tableau de bord  
**Authentification**: Bearer Token (JWT)  

### GET /admin/users
**Description**: Obtenir la liste des utilisateurs  
**Authentification**: Bearer Token (JWT)  
**Query Parameters**:
- `page?`: number (défaut: 1, min: 1)
- `limit?`: number (défaut: 20, min: 1)
- `status?`: UserStatus enum (optionnel)
- `search?`: string (optionnel)

### GET /admin/users/:userId
**Description**: Obtenir les détails d'un utilisateur  
**Authentification**: Bearer Token (JWT)  
**Paramètres**: `userId` (string)

### PUT /admin/users/:userId/status
**Description**: Changer le statut d'un utilisateur  
**Authentification**: Bearer Token (JWT)  
**Paramètres**: `userId` (string)  
**Body**:
```json
{
  "status": "UserStatus enum"
}
```

### PATCH /admin/users/:id/suspend
**Description**: Suspendre un utilisateur spécifique  
**Authentification**: Bearer Token (JWT)  
**Paramètres**: `id` (string)

### DELETE /admin/users/:id
**Description**: Supprimer un utilisateur  
**Authentification**: Bearer Token (JWT)  
**Paramètres**: `id` (string)

### GET /admin/reports
**Description**: Obtenir la liste des signalements  
**Authentification**: Bearer Token (JWT)  
**Query Parameters**:
- `page?`: number (défaut: 1, min: 1)
- `limit?`: number (défaut: 20, min: 1)
- `status?`: ReportStatus enum (optionnel)
- `type?`: ReportType enum (optionnel)

### PUT /admin/reports/:reportId
**Description**: Traiter un signalement  
**Authentification**: Bearer Token (JWT)  
**Paramètres**: `reportId` (string)  
**Body**:
```json
{
  "status": "ReportStatus enum",
  "resolution": "string",
  "suspendUser?": "boolean (optionnel)"
}
```

### DELETE /admin/reports/:reportId
**Description**: Supprimer/rejeter un signalement  
**Authentification**: Bearer Token (JWT)  
**Paramètres**: `reportId` (string)

### GET /admin/analytics
**Description**: Obtenir les statistiques de la plateforme  
**Authentification**: Bearer Token (JWT)  

### POST /admin/notifications/broadcast
**Description**: Diffuser une notification  
**Authentification**: Bearer Token (JWT)  
**Body**:
```json
{
  "title": "string",
  "body": "string",
  "type": "NotificationType enum",
  "targetAudience?": "string (optionnel - 'all', 'premium', 'active', etc.)"
}
```

### POST /admin/support/reply
**Description**: Répondre à un ticket de support  
**Authentification**: Bearer Token (JWT)  
**Body**:
```json
{
  "ticketId": "string",
  "reply": "string",
  "status?": "SupportStatus enum (optionnel)",
  "priority?": "SupportPriority enum (optionnel)"
}
```

---

## Types et Enums

### UserStatus
```typescript
enum UserStatus {
  ACTIVE = 'active',
  INACTIVE = 'inactive',
  SUSPENDED = 'suspended',
  DELETED = 'deleted'
}
```

### Gender
```typescript
enum Gender {
  MAN = 'man',
  WOMAN = 'woman',
  NON_BINARY = 'non_binary',
  OTHER = 'other'
}
```

### SubscriptionStatus
```typescript
enum SubscriptionStatus {
  ACTIVE = 'active',
  CANCELLED = 'cancelled',
  EXPIRED = 'expired',
  PENDING = 'pending'
}
```

### SubscriptionPlan
```typescript
enum SubscriptionPlan {
  FREE = 'free',
  GOLDWEN_PLUS = 'goldwen_plus'
}
```

### SubscriptionTier
```typescript
enum SubscriptionTier {
  FREE = 'free',
  PREMIUM = 'premium'
}
```

### MatchStatus
```typescript
enum MatchStatus {
  PENDING = 'pending',
  MATCHED = 'matched',
  REJECTED = 'rejected',
  EXPIRED = 'expired'
}
```

### ChatStatus
```typescript
enum ChatStatus {
  ACTIVE = 'active',
  EXPIRED = 'expired',
  ARCHIVED = 'archived'
}
```

### MessageType
```typescript
enum MessageType {
  TEXT = 'text',
  EMOJI = 'emoji',
  SYSTEM = 'system'
}
```

### NotificationType
```typescript
enum NotificationType {
  DAILY_SELECTION = 'daily_selection',
  NEW_MATCH = 'new_match',
  NEW_MESSAGE = 'new_message',
  CHAT_EXPIRING = 'chat_expiring',
  SUBSCRIPTION_EXPIRED = 'subscription_expired',
  SUBSCRIPTION_RENEWED = 'subscription_renewed',
  SYSTEM = 'system'
}
```

### QuestionType
```typescript
enum QuestionType {
  MULTIPLE_CHOICE = 'multiple_choice',
  SCALE = 'scale',
  BOOLEAN = 'boolean'
}
```

### AdminRole
```typescript
enum AdminRole {
  SUPER_ADMIN = 'super_admin',
  ADMIN = 'admin',
  MODERATOR = 'moderator'
}
```

### ReportStatus
```typescript
enum ReportStatus {
  PENDING = 'pending',
  REVIEWED = 'reviewed',
  RESOLVED = 'resolved',
  DISMISSED = 'dismissed'
}
```

### ReportType
```typescript
enum ReportType {
  INAPPROPRIATE_CONTENT = 'inappropriate_content',
  HARASSMENT = 'harassment',
  FAKE_PROFILE = 'fake_profile',
  SPAM = 'spam',
  OTHER = 'other'
}
```

### Platform (Push Tokens)
```typescript
enum Platform {
  IOS = 'ios',
  ANDROID = 'android',
  WEB = 'web'
}
```

---

## Notes Techniques

1. **Authentification**: Les routes marquées "Bearer Token" nécessitent le header `Authorization: Bearer <token>`

2. **Validation**: Tous les endpoints utilisent une validation strict avec class-validator

3. **Pagination**: Les endpoints de liste supportent généralement `page` et `limit` comme query parameters

4. **Upload de fichiers**: Les endpoints d'upload utilisent `multipart/form-data`

5. **Environnement**: Certaines routes de test ne sont disponibles qu'en développement

6. **API Prefix**: Toutes les routes sont préfixées par `/api/v1` par défaut

7. **Documentation Swagger**: Disponible à `/api/v1/docs` en mode développement

8. **CORS**: Activé pour les requêtes cross-origin

9. **Webhooks**: Les endpoints webhook n'ont pas besoin d'authentification mais peuvent nécessiter une vérification de signature

10. **Erreurs**: Format standardisé des erreurs avec codes HTTP appropriés et messages descriptifs