# GoldWen API Routes Documentation

Cette documentation liste toutes les routes API disponibles pour le frontend et le service de matching de l'application GoldWen.

## Base URL
- **API Principal**: `http://localhost:3000/api/v1`
- **Service Matching**: `http://localhost:8000/api/v1`
- **Documentation Swagger**: `http://localhost:3000/api/v1/docs`

---

## 🔐 Authentication Routes

### POST /auth/register
**Description**: Inscription d'un nouvel utilisateur  
**Body**:
```json
{
  "email": "user@example.com",
  "password": "password123",
  "firstName": "John",
  "lastName": "Doe"
}
```
**Response**: Token JWT + informations utilisateur

### POST /auth/login
**Description**: Connexion avec email/mot de passe  
**Body**:
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```
**Response**: Token JWT + informations utilisateur

### POST /auth/social-login
**Description**: Connexion sociale (Google/Apple)  
**Body**:
```json
{
  "socialId": "google_user_id_123",
  "provider": "google",
  "email": "user@example.com",
  "firstName": "John",
  "lastName": "Doe"
}
```

### GET /auth/google
**Description**: Redirection vers l'authentification Google

### GET /auth/google/callback
**Description**: Callback OAuth Google

### GET /auth/apple
**Description**: Redirection vers l'authentification Apple

### GET /auth/apple/callback
**Description**: Callback OAuth Apple

### POST /auth/forgot-password
**Description**: Demande de réinitialisation de mot de passe  
**Body**:
```json
{
  "email": "user@example.com"
}
```

### POST /auth/reset-password
**Description**: Réinitialisation du mot de passe avec token  
**Body**:
```json
{
  "token": "reset_token",
  "newPassword": "newpassword123"
}
```

### POST /auth/change-password
**Description**: Changement de mot de passe (authentifié)  
**Headers**: `Authorization: Bearer <token>`  
**Body**:
```json
{
  "currentPassword": "oldpassword",
  "newPassword": "newpassword123"
}
```

### POST /auth/verify-email
**Description**: Vérification de l'adresse email  
**Body**:
```json
{
  "token": "verification_token"
}
```

### GET /auth/me
**Description**: Récupération du profil utilisateur actuel  
**Headers**: `Authorization: Bearer <token>`

---

## 👤 Users Routes

### GET /users/me
**Description**: Récupération du profil utilisateur complet  
**Headers**: `Authorization: Bearer <token>`

### PUT /users/me
**Description**: Mise à jour des informations utilisateur  
**Headers**: `Authorization: Bearer <token>`  
**Body**:
```json
{
  "firstName": "John",
  "lastName": "Doe",
  "fcmToken": "firebase_token",
  "notificationsEnabled": true
}
```

### PUT /users/me/settings
**Description**: Mise à jour des paramètres utilisateur  
**Headers**: `Authorization: Bearer <token>`  
**Body**:
```json
{
  "notificationsEnabled": true,
  "emailNotifications": true,
  "pushNotifications": true
}
```

### GET /users/me/stats
**Description**: Statistiques de l'utilisateur  
**Headers**: `Authorization: Bearer <token>`

### PUT /users/me/deactivate
**Description**: Désactivation du compte utilisateur  
**Headers**: `Authorization: Bearer <token>`

### DELETE /users/me
**Description**: Suppression du compte utilisateur  
**Headers**: `Authorization: Bearer <token>`

---

## 📝 Profiles Routes

### GET /profiles/me
**Description**: Récupération du profil complet avec photos et réponses  
**Headers**: `Authorization: Bearer <token>`

### PUT /profiles/me
**Description**: Mise à jour des informations de profil  
**Headers**: `Authorization: Bearer <token>`  
**Body**:
```json
{
  "birthDate": "1990-01-01",
  "gender": "woman",
  "interestedInGenders": ["man"],
  "bio": "Description de profil",
  "jobTitle": "Développeuse",
  "company": "Tech Corp",
  "education": "Master en Informatique",
  "location": "Paris, France",
  "latitude": 48.8566,
  "longitude": 2.3522,
  "maxDistance": 50,
  "minAge": 25,
  "maxAge": 35,
  "interests": ["voyage", "cuisine", "sport"],
  "languages": ["français", "anglais"],
  "height": 170
}
```

### POST /profiles/me/photos
**Description**: Upload d'une nouvelle photo  
**Headers**: `Authorization: Bearer <token>`  
**Content-Type**: `multipart/form-data`  
**Body**: File upload avec metadata

### PUT /profiles/me/photos/:photoId
**Description**: Mise à jour de l'ordre des photos  
**Headers**: `Authorization: Bearer <token>`

### DELETE /profiles/me/photos/:photoId
**Description**: Suppression d'une photo  
**Headers**: `Authorization: Bearer <token>`

### PUT /profiles/me/photos/:photoId/primary
**Description**: Définir une photo comme principale  
**Headers**: `Authorization: Bearer <token>`

### GET /profiles/questions
**Description**: Récupération des questions de personnalité disponibles

### POST /profiles/me/personality-answers
**Description**: Soumission des réponses au questionnaire de personnalité  
**Headers**: `Authorization: Bearer <token>`  
**Body**:
```json
{
  "answers": [
    {
      "questionId": "uuid",
      "textAnswer": "Réponse textuelle",
      "numericAnswer": 5,
      "booleanAnswer": true,
      "multipleChoiceAnswer": ["option1", "option2"]
    }
  ]
}
```

### GET /profiles/prompts
**Description**: Récupération des prompts disponibles

### POST /profiles/me/prompt-answers
**Description**: Soumission des réponses aux prompts  
**Headers**: `Authorization: Bearer <token>`  
**Body**:
```json
{
  "answers": [
    {
      "promptId": "uuid",
      "answer": "Ma réponse au prompt",
      "order": 1
    }
  ]
}
```

### GET /profiles/:userId
**Description**: Récupération d'un profil public par ID  
**Headers**: `Authorization: Bearer <token>`

---

## 💕 Matching Routes

### GET /matching/daily-selection
**Description**: Récupération de la sélection quotidienne  
**Headers**: `Authorization: Bearer <token>`

### POST /matching/choose/:profileId
**Description**: Choisir un profil de la sélection quotidienne  
**Headers**: `Authorization: Bearer <token>`

### GET /matching/matches
**Description**: Liste des matches de l'utilisateur  
**Headers**: `Authorization: Bearer <token>`  
**Query Parameters**: `page`, `limit`, `status`

### GET /matching/matches/:matchId
**Description**: Détails d'un match spécifique  
**Headers**: `Authorization: Bearer <token>`

### DELETE /matching/matches/:matchId
**Description**: Supprimer un match  
**Headers**: `Authorization: Bearer <token>`

### GET /matching/compatibility/:profileId
**Description**: Calcul de compatibilité avec un profil  
**Headers**: `Authorization: Bearer <token>`

---

## 💬 Chat Routes

### GET /chat/conversations
**Description**: Liste des conversations actives  
**Headers**: `Authorization: Bearer <token>`

### GET /chat/conversations/:chatId
**Description**: Détails d'une conversation  
**Headers**: `Authorization: Bearer <token>`

### GET /chat/conversations/:chatId/messages
**Description**: Messages d'une conversation  
**Headers**: `Authorization: Bearer <token>`  
**Query Parameters**: `page`, `limit`, `before`

### POST /chat/conversations/:chatId/messages
**Description**: Envoyer un message  
**Headers**: `Authorization: Bearer <token>`  
**Body**:
```json
{
  "type": "text",
  "content": "Contenu du message"
}
```

### PUT /chat/conversations/:chatId/messages/:messageId/read
**Description**: Marquer un message comme lu  
**Headers**: `Authorization: Bearer <token>`

### DELETE /chat/conversations/:chatId/messages/:messageId
**Description**: Supprimer un message  
**Headers**: `Authorization: Bearer <token>`

### GET /chat/conversations/:chatId/typing
**Description**: Statut "en train d'écrire"  
**Headers**: `Authorization: Bearer <token>`

### POST /chat/conversations/:chatId/typing
**Description**: Indiquer que l'utilisateur écrit  
**Headers**: `Authorization: Bearer <token>`

---

## 💳 Subscriptions Routes

### GET /subscriptions/plans
**Description**: Liste des plans d'abonnement disponibles

### GET /subscriptions/me
**Description**: Abonnement actuel de l'utilisateur  
**Headers**: `Authorization: Bearer <token>`

### POST /subscriptions/purchase
**Description**: Achat d'un abonnement  
**Headers**: `Authorization: Bearer <token>`  
**Body**:
```json
{
  "plan": "goldwen_plus",
  "platform": "ios",
  "receiptData": "receipt_from_app_store"
}
```

### POST /subscriptions/verify-receipt
**Description**: Vérification d'un reçu d'achat  
**Headers**: `Authorization: Bearer <token>`  
**Body**:
```json
{
  "receiptData": "receipt_string",
  "platform": "ios"
}
```

### PUT /subscriptions/cancel
**Description**: Annulation de l'abonnement  
**Headers**: `Authorization: Bearer <token>`

### POST /subscriptions/restore
**Description**: Restauration d'un abonnement  
**Headers**: `Authorization: Bearer <token>`

### GET /subscriptions/usage
**Description**: Utilisation actuelle des fonctionnalités premium  
**Headers**: `Authorization: Bearer <token>`

---

## 🔔 Notifications Routes

### GET /notifications
**Description**: Liste des notifications de l'utilisateur  
**Headers**: `Authorization: Bearer <token>`  
**Query Parameters**: `page`, `limit`, `type`, `read`

### PUT /notifications/:notificationId/read
**Description**: Marquer une notification comme lue  
**Headers**: `Authorization: Bearer <token>`

### PUT /notifications/read-all
**Description**: Marquer toutes les notifications comme lues  
**Headers**: `Authorization: Bearer <token>`

### DELETE /notifications/:notificationId
**Description**: Supprimer une notification  
**Headers**: `Authorization: Bearer <token>`

### PUT /notifications/settings
**Description**: Mise à jour des paramètres de notification  
**Headers**: `Authorization: Bearer <token>`  
**Body**:
```json
{
  "dailySelection": true,
  "newMatches": true,
  "newMessages": true,
  "chatExpiring": true
}
```

### POST /notifications/test
**Description**: Envoyer une notification de test (dev only)  
**Headers**: `Authorization: Bearer <token>`

---

## 🛡️ Admin Routes

### POST /admin/auth/login
**Description**: Connexion administrateur  
**Body**:
```json
{
  "email": "admin@goldwen.com",
  "password": "admin_password"
}
```

### GET /admin/users
**Description**: Liste des utilisateurs  
**Headers**: `Authorization: Bearer <admin_token>`  
**Query Parameters**: `page`, `limit`, `status`, `search`

### GET /admin/users/:userId
**Description**: Détails d'un utilisateur  
**Headers**: `Authorization: Bearer <admin_token>`

### PUT /admin/users/:userId/status
**Description**: Changer le statut d'un utilisateur  
**Headers**: `Authorization: Bearer <admin_token>`  
**Body**:
```json
{
  "status": "suspended"
}
```

### GET /admin/reports
**Description**: Liste des signalements  
**Headers**: `Authorization: Bearer <admin_token>`  
**Query Parameters**: `page`, `limit`, `status`, `type`

### PUT /admin/reports/:reportId
**Description**: Traiter un signalement  
**Headers**: `Authorization: Bearer <admin_token>`  
**Body**:
```json
{
  "status": "resolved",
  "resolution": "Description de la résolution"
}
```

### GET /admin/analytics
**Description**: Statistiques de la plateforme  
**Headers**: `Authorization: Bearer <admin_token>`

### POST /admin/notifications/broadcast
**Description**: Diffuser une notification à tous les utilisateurs  
**Headers**: `Authorization: Bearer <admin_token>`  
**Body**:
```json
{
  "title": "Titre de la notification",
  "body": "Contenu de la notification",
  "type": "system"
}
```

---

## 🤖 Matching Service Routes (Service Externe - Python)

**Note:** Ces routes sont servies par un service de matching externe qui doit être démarré sur http://localhost:8000.
Le service de matching n'est plus inclus dans ce repository.

### POST /matching-service/calculate-compatibility
**Description**: Calcul de compatibilité entre deux profils  
**Headers**: `X-API-Key: <service_key>`  
**Body**:
```json
{
  "user1Profile": {
    "personalityAnswers": [...],
    "preferences": {...}
  },
  "user2Profile": {
    "personalityAnswers": [...],
    "preferences": {...}
  }
}
```

### POST /matching-service/generate-daily-selection
**Description**: Génération de la sélection quotidienne  
**Headers**: `X-API-Key: <service_key>`  
**Body**:
```json
{
  "userId": "uuid",
  "userProfile": {...},
  "availableProfiles": [...],
  "selectionSize": 5
}
```

### POST /matching-service/batch-compatibility
**Description**: Calcul de compatibilité en lot  
**Headers**: `X-API-Key: <service_key>`  
**Body**:
```json
{
  "baseProfile": {...},
  "profilesToCompare": [...]
}
```

### GET /matching-service/algorithm/stats
**Description**: Statistiques de l'algorithme de matching  
**Headers**: `X-API-Key: <service_key>`

---

## 📊 WebSocket Events

### Connexion
```javascript
const socket = io('ws://localhost:3000/chat', {
  auth: {
    token: 'jwt_token'
  }
});
```

### Events Entrants (du serveur vers le client)
- `new_message`: Nouveau message reçu
- `message_read`: Message marqué comme lu
- `user_typing`: Utilisateur en train d'écrire
- `user_stopped_typing`: Utilisateur a arrêté d'écrire
- `chat_expired`: Conversation expirée
- `new_match`: Nouveau match
- `match_expired`: Match expiré

### Events Sortants (du client vers le serveur)
- `join_chat`: Rejoindre une conversation
- `leave_chat`: Quitter une conversation
- `send_message`: Envoyer un message
- `start_typing`: Commencer à écrire
- `stop_typing`: Arrêter d'écrire
- `read_message`: Marquer comme lu

---

## 🔒 Authentication

### JWT Token
- **Header**: `Authorization: Bearer <token>`
- **Expiration**: 24 heures
- **Refresh**: Pas de refresh token dans MVP, reconnexion requise

### OAuth Flows
- **Google**: OAuth 2.0 avec redirection
- **Apple**: Sign in with Apple avec redirection

### Permissions
- **User**: Accès aux routes utilisateur standards
- **Admin**: Accès aux routes d'administration
- **System**: Communication entre microservices

---

## 📱 Response Format

### Success Response
```json
{
  "success": true,
  "message": "Operation completed successfully",
  "data": {
    // Response data
  }
}
```

### Error Response
```json
{
  "success": false,
  "message": "Error message",
  "code": "ERROR_CODE",
  "errors": [
    // Validation errors array
  ]
}
```

### Pagination Response
```json
{
  "success": true,
  "data": [...],
  "meta": {
    "page": 1,
    "limit": 10,
    "total": 100,
    "totalPages": 10,
    "hasNextPage": true,
    "hasPreviousPage": false
  }
}
```

---

## 🚀 Status Codes

- **200**: OK - Opération réussie
- **201**: Created - Ressource créée
- **400**: Bad Request - Erreur de validation
- **401**: Unauthorized - Authentification requise
- **403**: Forbidden - Permissions insuffisantes
- **404**: Not Found - Ressource introuvable
- **409**: Conflict - Conflit (email déjà utilisé, etc.)
- **422**: Unprocessable Entity - Erreur de logique métier
- **500**: Internal Server Error - Erreur serveur

---

## 🌐 Environment Variables

### API Principal
```bash
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_USERNAME=goldwen
DATABASE_PASSWORD=goldwen_password
DATABASE_NAME=goldwen_db

REDIS_HOST=localhost
REDIS_PORT=6379

JWT_SECRET=your-super-secret-jwt-key
JWT_EXPIRES_IN=24h

GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret

APPLE_CLIENT_ID=your-apple-client-id
APPLE_TEAM_ID=your-apple-team-id
APPLE_KEY_ID=your-apple-key-id
APPLE_PRIVATE_KEY=your-apple-private-key

PORT=3000
NODE_ENV=development
API_PREFIX=api/v1

FCM_SERVER_KEY=your-fcm-server-key
MATCHING_SERVICE_URL=http://localhost:8000
REVENUECAT_API_KEY=your-revenuecat-api-key
```

### Service Matching (Externe)
```bash
# Variables d'environnement pour le service de matching externe
API_HOST=0.0.0.0
API_PORT=8000
API_PREFIX=/api/v1

DATABASE_URL=postgresql://goldwen:password@localhost:5432/goldwen_db
REDIS_URL=redis://localhost:6379

MAIN_API_URL=http://localhost:3000
API_KEY=matching-service-secret-key

LOG_LEVEL=INFO
```

**Note:** Ces variables doivent être configurées dans le repository du service de matching externe.

---

Cette documentation couvre l'ensemble des routes API nécessaires pour le développement du frontend React Native et l'intégration avec le service de matching Python. Chaque route est documentée avec ses paramètres, exemples de requêtes et réponses pour faciliter l'intégration.