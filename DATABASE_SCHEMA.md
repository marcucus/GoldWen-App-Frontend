# 🗄️ Schéma Complet de la Base de Données GoldWen

## Vue d'ensemble

GoldWen est une application de rencontres moderne basée sur des sélections quotidiennes et un système de compatibilité avancé. Cette documentation présente le schéma complet de la base de données PostgreSQL avec TypeORM.

**Dernière mise à jour**: 19 septembre 2025

---

## 📋 Table des Matières

1. [Entités Principales](#entités-principales)
2. [Médias et Contenu](#médias-et-contenu)
3. [Système de Personnalité](#système-de-personnalité)
4. [Système de Matching](#système-de-matching)
5. [Système de Chat](#système-de-chat)
6. [Système de Notifications](#système-de-notifications)
7. [Système d'Abonnement](#système-dabonnement)
8. [Modération et Support](#modération-et-support)
9. [Relations et Contraintes](#relations-et-contraintes)
10. [Enums et Types](#enums-et-types)

---

## 👥 Entités Principales

### 1. Users (Utilisateurs)

**Table**: `users`

| Colonne | Type | Contraintes | Description |
|---------|------|-------------|-------------|
| `id` | uuid | PK | Identifiant unique |
| `email` | varchar | UNIQUE, NOT NULL | Email utilisateur |
| `passwordHash` | varchar | NULL | Hash du mot de passe |
| `socialId` | varchar | NULL | ID du provider social |
| `socialProvider` | varchar | NULL | Provider (google/apple) |
| `status` | enum | DEFAULT 'active' | Statut utilisateur |
| `isEmailVerified` | boolean | DEFAULT false | Email vérifié |
| `emailVerificationToken` | varchar | NULL | Token de vérification |
| `resetPasswordToken` | varchar | NULL | Token reset password |
| `resetPasswordExpires` | timestamp | NULL | Expiration token reset |
| `isOnboardingCompleted` | boolean | DEFAULT false | Onboarding terminé |
| `isProfileCompleted` | boolean | DEFAULT false | Profil complété |
| `lastLoginAt` | timestamp | NULL | Dernière connexion |
| `lastActiveAt` | timestamp | NULL | Dernière activité |
| `fcmToken` | varchar | NULL | Token FCM |
| `notificationsEnabled` | boolean | DEFAULT true | Notifications activées |
| `googleId` | varchar | NULL | ID Google |
| `createdAt` | timestamp | NOT NULL | Date de création |
| `updatedAt` | timestamp | NOT NULL | Date de modification |

**Index**:
- `users_email_idx` (UNIQUE)
- `users_social_idx` (socialId, socialProvider, UNIQUE)

### 2. Profiles (Profils)

**Table**: `profiles`

| Colonne | Type | Contraintes | Description |
|---------|------|-------------|-------------|
| `id` | uuid | PK | Identifiant unique |
| `userId` | uuid | FK, NOT NULL, INDEX | Référence vers users |
| `firstName` | varchar | NOT NULL | Prénom |
| `lastName` | varchar | NULL | Nom de famille |
| `pseudo` | varchar | NULL | Pseudonyme |
| `birthDate` | date | NULL | Date de naissance |
| `gender` | enum | NULL | Genre |
| `interestedInGenders` | enum[] | NULL | Genres d'intérêt |
| `bio` | text | NULL | Biographie |
| `jobTitle` | varchar | NULL | Titre du poste |
| `company` | varchar | NULL | Entreprise |
| `education` | varchar | NULL | Éducation |
| `location` | varchar | NULL | Localisation |
| `latitude` | decimal(10,8) | NULL | Latitude GPS |
| `longitude` | decimal(11,8) | NULL | Longitude GPS |
| `maxDistance` | integer | NULL | Distance max (km) |
| `minAge` | integer | NULL | Âge minimum |
| `maxAge` | integer | NULL | Âge maximum |
| `interests` | text[] | DEFAULT '{}' | Centres d'intérêt |
| `languages` | text[] | DEFAULT '{}' | Langues parlées |
| `height` | integer | NULL | Taille (cm) |
| `isVerified` | boolean | DEFAULT false | Profil vérifié |
| `isVisible` | boolean | DEFAULT true | Profil visible |
| `showAge` | boolean | DEFAULT true | Afficher l'âge |
| `showDistance` | boolean | DEFAULT true | Afficher la distance |
| `createdAt` | timestamp | NOT NULL | Date de création |
| `updatedAt` | timestamp | NOT NULL | Date de modification |

---

## 📸 Médias et Contenu

### 3. Photos

**Table**: `photos`

| Colonne | Type | Contraintes | Description |
|---------|------|-------------|-------------|
| `id` | uuid | PK | Identifiant unique |
| `profileId` | uuid | FK, NOT NULL | Référence vers profiles |
| `url` | varchar | NOT NULL | URL de la photo |
| `filename` | varchar | NOT NULL | Nom du fichier |
| `order` | integer | NOT NULL, INDEX | Ordre d'affichage |
| `isPrimary` | boolean | DEFAULT false | Photo principale |
| `width` | integer | NULL | Largeur en pixels |
| `height` | integer | NULL | Hauteur en pixels |
| `fileSize` | integer | NULL | Taille en octets |
| `mimeType` | varchar | NULL | Type MIME |
| `isApproved` | boolean | DEFAULT false | Photo approuvée |
| `rejectionReason` | text | NULL | Raison du rejet |
| `createdAt` | timestamp | NOT NULL | Date de création |
| `updatedAt` | timestamp | NOT NULL | Date de modification |

### 4. Prompts (Questions)

**Table**: `prompts`

| Colonne | Type | Contraintes | Description |
|---------|------|-------------|-------------|
| `id` | uuid | PK | Identifiant unique |
| `text` | varchar | NOT NULL | Texte de la question |
| `order` | integer | NOT NULL | Ordre d'affichage |
| `isActive` | boolean | DEFAULT true | Question active |
| `category` | varchar | NULL | Catégorie |
| `placeholder` | varchar | NULL | Texte placeholder |
| `maxLength` | integer | DEFAULT 500 | Longueur max réponse |
| `createdAt` | timestamp | NOT NULL | Date de création |
| `updatedAt` | timestamp | NOT NULL | Date de modification |

### 5. Prompt Answers (Réponses aux Questions)

**Table**: `prompt_answers`

| Colonne | Type | Contraintes | Description |
|---------|------|-------------|-------------|
| `id` | uuid | PK | Identifiant unique |
| `profileId` | uuid | FK, NOT NULL, INDEX | Référence vers profiles |
| `promptId` | uuid | FK, NOT NULL, INDEX | Référence vers prompts |
| `answer` | text | NOT NULL | Réponse utilisateur |
| `order` | integer | NOT NULL | Ordre d'affichage |
| `createdAt` | timestamp | NOT NULL | Date de création |
| `updatedAt` | timestamp | NOT NULL | Date de modification |

---

## 🧠 Système de Personnalité

### 6. Personality Questions (Questions de Personnalité)

**Table**: `personality_questions`

| Colonne | Type | Contraintes | Description |
|---------|------|-------------|-------------|
| `id` | uuid | PK | Identifiant unique |
| `question` | varchar | NOT NULL | Texte de la question |
| `type` | enum | NOT NULL | Type de question |
| `options` | json | NULL | Options pour QCM |
| `minValue` | integer | NULL | Valeur min (échelle) |
| `maxValue` | integer | NULL | Valeur max (échelle) |
| `order` | integer | NOT NULL | Ordre d'affichage |
| `isActive` | boolean | DEFAULT true | Question active |
| `isRequired` | boolean | DEFAULT false | Question obligatoire |
| `category` | varchar | NULL | Catégorie |
| `description` | text | NULL | Description |
| `createdAt` | timestamp | NOT NULL | Date de création |
| `updatedAt` | timestamp | NOT NULL | Date de modification |

### 7. Personality Answers (Réponses de Personnalité)

**Table**: `personality_answers`

| Colonne | Type | Contraintes | Description |
|---------|------|-------------|-------------|
| `id` | uuid | PK | Identifiant unique |
| `userId` | uuid | FK, NOT NULL, INDEX | Référence vers users |
| `questionId` | uuid | FK, NOT NULL, INDEX | Référence vers personality_questions |
| `textAnswer` | text | NULL | Réponse textuelle |
| `numericAnswer` | integer | NULL | Réponse numérique |
| `booleanAnswer` | boolean | NULL | Réponse booléenne |
| `multipleChoiceAnswer` | text[] | NULL | Réponse QCM |
| `createdAt` | timestamp | NOT NULL | Date de création |
| `updatedAt` | timestamp | NOT NULL | Date de modification |

---

## 💕 Système de Matching

### 8. Daily Selections (Sélections Quotidiennes)

**Table**: `daily_selections`

| Colonne | Type | Contraintes | Description |
|---------|------|-------------|-------------|
| `id` | uuid | PK | Identifiant unique |
| `userId` | uuid | FK, NOT NULL, INDEX | Référence vers users |
| `selectionDate` | date | NOT NULL | Date de sélection |
| `selectedProfileIds` | uuid[] | NOT NULL | Profils sélectionnés |
| `chosenProfileIds` | uuid[] | DEFAULT '{}' | Profils choisis |
| `choicesUsed` | integer | DEFAULT 0 | Choix utilisés |
| `maxChoicesAllowed` | integer | DEFAULT 1 | Choix max autorisés |
| `isNotificationSent` | boolean | DEFAULT false | Notification envoyée |
| `createdAt` | timestamp | NOT NULL | Date de création |
| `updatedAt` | timestamp | NOT NULL | Date de modification |

### 9. Matches

**Table**: `matches`

| Colonne | Type | Contraintes | Description |
|---------|------|-------------|-------------|
| `id` | uuid | PK | Identifiant unique |
| `user1Id` | uuid | FK, NOT NULL, INDEX | Référence vers users |
| `user2Id` | uuid | FK, NOT NULL, INDEX | Référence vers users |
| `status` | enum | DEFAULT 'matched' | Statut du match |
| `compatibilityScore` | decimal(5,2) | NULL | Score de compatibilité |
| `matchedAt` | timestamp | NULL | Date du match |
| `expiredAt` | timestamp | NULL | Date d'expiration |
| `createdAt` | timestamp | NOT NULL | Date de création |
| `updatedAt` | timestamp | NOT NULL | Date de modification |

---

## 💬 Système de Chat

### 10. Chats

**Table**: `chats`

| Colonne | Type | Contraintes | Description |
|---------|------|-------------|-------------|
| `id` | uuid | PK | Identifiant unique |
| `matchId` | uuid | FK, NOT NULL, INDEX | Référence vers matches |
| `status` | enum | DEFAULT 'active' | Statut du chat |
| `expiresAt` | timestamp | NOT NULL | Date d'expiration |
| `lastMessageAt` | timestamp | NULL | Dernier message |
| `messageCount` | integer | DEFAULT 0 | Nombre de messages |
| `createdAt` | timestamp | NOT NULL | Date de création |
| `updatedAt` | timestamp | NOT NULL | Date de modification |

### 11. Messages

**Table**: `messages`

| Colonne | Type | Contraintes | Description |
|---------|------|-------------|-------------|
| `id` | uuid | PK | Identifiant unique |
| `chatId` | uuid | FK, NOT NULL, INDEX | Référence vers chats |
| `senderId` | uuid | FK, NOT NULL, INDEX | Référence vers users |
| `type` | enum | DEFAULT 'text' | Type de message |
| `content` | text | NOT NULL | Contenu du message |
| `isRead` | boolean | DEFAULT false | Message lu |
| `readAt` | timestamp | NULL | Date de lecture |
| `editedAt` | timestamp | NULL | Date d'édition |
| `isDeleted` | boolean | DEFAULT false | Message supprimé |
| `createdAt` | timestamp | NOT NULL | Date de création |
| `updatedAt` | timestamp | NOT NULL | Date de modification |

---

## 🔔 Système de Notifications

### 12. Notifications

**Table**: `notifications`

| Colonne | Type | Contraintes | Description |
|---------|------|-------------|-------------|
| `id` | uuid | PK | Identifiant unique |
| `userId` | uuid | FK, NOT NULL, INDEX | Référence vers users |
| `type` | enum | NOT NULL | Type de notification |
| `title` | varchar | NOT NULL | Titre |
| `body` | text | NOT NULL | Corps du message |
| `data` | json | NULL | Données additionnelles |
| `isRead` | boolean | DEFAULT false | Notification lue |
| `readAt` | timestamp | NULL | Date de lecture |
| `isSent` | boolean | DEFAULT false | Notification envoyée |
| `sentAt` | timestamp | NULL | Date d'envoi |
| `scheduledFor` | timestamp | NULL | Programmée pour |
| `retryCount` | integer | DEFAULT 0 | Nombre de tentatives |
| `createdAt` | timestamp | NOT NULL | Date de création |
| `updatedAt` | timestamp | NOT NULL | Date de modification |

### 13. Notification Preferences (Préférences de Notification)

**Table**: `notification_preferences`

| Colonne | Type | Contraintes | Description |
|---------|------|-------------|-------------|
| `id` | uuid | PK | Identifiant unique |
| `userId` | uuid | FK, UNIQUE, NOT NULL | Référence vers users |
| `dailySelection` | boolean | DEFAULT true | Sélections quotidiennes |
| `newMatches` | boolean | DEFAULT true | Nouveaux matchs |
| `newMessages` | boolean | DEFAULT true | Nouveaux messages |
| `chatExpiring` | boolean | DEFAULT true | Chat expirant |
| `subscriptionUpdates` | boolean | DEFAULT true | Mises à jour abonnement |
| `marketingEmails` | boolean | DEFAULT false | Emails marketing |
| `pushNotifications` | boolean | DEFAULT true | Notifications push |
| `emailNotifications` | boolean | DEFAULT true | Notifications email |
| `createdAt` | timestamp | NOT NULL | Date de création |
| `updatedAt` | timestamp | NOT NULL | Date de modification |

### 14. Push Tokens

**Table**: `push_tokens`

| Colonne | Type | Contraintes | Description |
|---------|------|-------------|-------------|
| `id` | uuid | PK | Identifiant unique |
| `userId` | uuid | FK, NOT NULL, INDEX | Référence vers users |
| `token` | varchar | UNIQUE, NOT NULL | Token push |
| `platform` | enum | NOT NULL | Plateforme (ios/android) |
| `appVersion` | varchar | NULL | Version de l'app |
| `deviceId` | varchar | NULL | ID de l'appareil |
| `isActive` | boolean | DEFAULT true | Token actif |
| `lastUsedAt` | timestamp | NULL | Dernière utilisation |
| `createdAt` | timestamp | NOT NULL | Date de création |
| `updatedAt` | timestamp | NOT NULL | Date de modification |

**Index**:
- `push_tokens_token_idx` (UNIQUE)
- `push_tokens_user_platform_idx` (userId, platform)

---

## 💳 Système d'Abonnement

### 15. Subscriptions (Abonnements)

**Table**: `subscriptions`

| Colonne | Type | Contraintes | Description |
|---------|------|-------------|-------------|
| `id` | uuid | PK | Identifiant unique |
| `userId` | uuid | FK, NOT NULL, INDEX | Référence vers users |
| `plan` | enum | NOT NULL | Plan d'abonnement |
| `status` | enum | DEFAULT 'pending' | Statut de l'abonnement |
| `startDate` | timestamp | NOT NULL | Date de début |
| `expiresAt` | timestamp | NOT NULL | Date d'expiration |
| `cancelledAt` | timestamp | NULL | Date d'annulation |
| `revenueCatCustomerId` | varchar | NULL | ID client RevenueCat |
| `revenueCatSubscriptionId` | varchar | NULL | ID abonnement RevenueCat |
| `originalTransactionId` | varchar | NULL | ID transaction originale |
| `price` | decimal(10,2) | NULL | Prix |
| `currency` | varchar | NULL | Devise |
| `purchaseToken` | varchar | NULL | Token d'achat |
| `platform` | varchar | NULL | Plateforme (ios/android) |
| `metadata` | json | NULL | Métadonnées |
| `createdAt` | timestamp | NOT NULL | Date de création |
| `updatedAt` | timestamp | NOT NULL | Date de modification |

---

## 🛡️ Modération et Support

### 16. Reports (Signalements)

**Table**: `reports`

| Colonne | Type | Contraintes | Description |
|---------|------|-------------|-------------|
| `id` | uuid | PK | Identifiant unique |
| `reporterId` | uuid | FK, NOT NULL, INDEX | Utilisateur signalant |
| `reportedUserId` | uuid | FK, NOT NULL, INDEX | Utilisateur signalé |
| `type` | enum | NOT NULL | Type de signalement |
| `status` | enum | DEFAULT 'pending' | Statut du signalement |
| `reason` | varchar | NOT NULL | Raison |
| `description` | text | NULL | Description détaillée |
| `evidence` | text | NULL | Preuves (URLs) |
| `reviewedById` | uuid | FK, NULL | Admin ayant traité |
| `reviewedAt` | timestamp | NULL | Date de traitement |
| `reviewNotes` | text | NULL | Notes de révision |
| `resolution` | text | NULL | Résolution |
| `createdAt` | timestamp | NOT NULL | Date de création |
| `updatedAt` | timestamp | NOT NULL | Date de modification |

### 17. Support Tickets (Tickets de Support)

**Table**: `support_tickets`

| Colonne | Type | Contraintes | Description |
|---------|------|-------------|-------------|
| `id` | uuid | PK | Identifiant unique |
| `userId` | uuid | FK, NOT NULL | Référence vers users |
| `subject` | varchar | NOT NULL | Sujet |
| `message` | text | NOT NULL | Message |
| `status` | enum | DEFAULT 'pending' | Statut |
| `priority` | enum | DEFAULT 'medium' | Priorité |
| `category` | varchar | NULL | Catégorie |
| `adminReply` | text | NULL | Réponse admin |
| `repliedBy` | varchar | NULL | Email admin |
| `repliedAt` | timestamp | NULL | Date de réponse |
| `createdAt` | timestamp | NOT NULL | Date de création |
| `updatedAt` | timestamp | NOT NULL | Date de modification |

### 18. Admins (Administrateurs)

**Table**: `admins`

| Colonne | Type | Contraintes | Description |
|---------|------|-------------|-------------|
| `id` | uuid | PK | Identifiant unique |
| `email` | varchar | UNIQUE, NOT NULL | Email admin |
| `passwordHash` | varchar | NOT NULL | Hash du mot de passe |
| `firstName` | varchar | NOT NULL | Prénom |
| `lastName` | varchar | NOT NULL | Nom |
| `role` | enum | DEFAULT 'moderator' | Rôle admin |
| `isActive` | boolean | DEFAULT true | Admin actif |
| `lastLoginAt` | timestamp | NULL | Dernière connexion |
| `resetPasswordToken` | varchar | NULL | Token reset password |
| `resetPasswordExpires` | timestamp | NULL | Expiration token |
| `createdAt` | timestamp | NOT NULL | Date de création |
| `updatedAt` | timestamp | NOT NULL | Date de modification |

---

## 🔗 Relations et Contraintes

### Relations One-to-One (1:1)

```
User ↔ Profile
- User.profile → Profile.user
- Cascade: true

User ↔ NotificationPreferences  
- User.notificationPreferences → NotificationPreferences.user
- Cascade: CASCADE

Match ↔ Chat
- Match.chat → Chat.match
- Cascade: true
```

### Relations One-to-Many (1:N)

```
User → PersonalityAnswers
- User.personalityAnswers → PersonalityAnswer.user
- Cascade: CASCADE

User → DailySelections
- User.dailySelections → DailySelection.user
- Cascade: CASCADE

User → Subscriptions
- User.subscriptions → Subscription.user
- Cascade: CASCADE

User → Notifications
- User.notifications → Notification.user
- Cascade: CASCADE

User → PushTokens
- User.pushTokens → PushToken.user
- Cascade: CASCADE

Profile → Photos
- Profile.photos → Photo.profile
- Cascade: CASCADE

Profile → PromptAnswers
- Profile.promptAnswers → PromptAnswer.profile
- Cascade: CASCADE

Chat → Messages
- Chat.messages → Message.chat
- Cascade: CASCADE

PersonalityQuestion → PersonalityAnswers
- PersonalityQuestion.answers → PersonalityAnswer.question
- Cascade: CASCADE

Prompt → PromptAnswers
- Prompt.answers → PromptAnswer.prompt
- Cascade: CASCADE
```

### Relations Many-to-One (N:1)

```
Match → User (user1 et user2)
- Match.user1 ← User.matchesAsUser1
- Match.user2 ← User.matchesAsUser2
- Cascade: CASCADE

Message → User (sender)
- Message.sender ← User.sentMessages
- Cascade: CASCADE

Report → User (reporter et reportedUser)
- Report.reporter ← User.reportsSubmitted
- Report.reportedUser ← User.reportsReceived
- Cascade: CASCADE

Report → Admin (reviewedBy)
- Report.reviewedBy ← Admin
```

---

## 📊 Enums et Types

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

### SupportStatus
```typescript
enum SupportStatus {
  PENDING = 'pending',
  IN_PROGRESS = 'in_progress',
  RESOLVED = 'resolved',
  CLOSED = 'closed'
}
```

### SupportPriority
```typescript
enum SupportPriority {
  LOW = 'low',
  MEDIUM = 'medium',
  HIGH = 'high',
  URGENT = 'urgent'
}
```

### Platform
```typescript
enum Platform {
  IOS = 'ios',
  ANDROID = 'android'
}
```

---

## 🎯 Caractéristiques Techniques

### Base de Données
- **Type**: PostgreSQL
- **ORM**: TypeORM
- **Identifiants**: UUID pour toutes les clés primaires
- **Encoding**: UTF-8

### Sécurité
- Hash des mots de passe avec bcrypt
- Tokens JWT pour l'authentification
- Tokens de vérification email sécurisés
- Validation des entrées utilisateur

### Performance
- Index sur les colonnes fréquemment utilisées
- Index composites pour les requêtes complexes
- Pagination pour les listes importantes
- Mise en cache des requêtes courantes

### Scalabilité
- Architecture modulaire
- Séparation des préoccupations
- Relations optimisées avec cascade
- Support multi-tenant potentiel

### Géolocalisation
- Coordonnées GPS précises (latitude/longitude)
- Calcul de distance géographique
- Filtrage par zone géographique
- Support des préférences de distance

### Monitoring
- Horodatage automatique (createdAt/updatedAt)
- Tracking des activités utilisateur
- Logs d'audit pour les actions importantes
- Métriques de performance

---

## 📈 Métriques et Analytics

Le schéma permet de collecter diverses métriques:

- **Engagement**: Activité utilisateur, fréquence de connexion
- **Matching**: Taux de match, scores de compatibilité
- **Monétisation**: Conversions premium, rétention abonnés
- **Modération**: Signalements, actions administratives
- **Performance**: Temps de réponse, utilisation des features

---

## 🚀 Évolutions Futures

Le schéma est conçu pour supporter les évolutions suivantes:

1. **Nouvelles features**:
   - Stories temporaires
   - Appels vidéo
   - Événements en groupe
   - Vérification d'identité avancée

2. **Optimisations**:
   - Sharding horizontal
   - Read replicas
   - Cache distribué
   - CDN pour les médias

3. **Analytics avancées**:
   - Machine learning
   - Recommandations personnalisées
   - Détection de fraude
   - Analyse comportementale

---

*Ce schéma représente l'architecture complète de GoldWen à la date du 19 septembre 2025. Pour toute question ou modification, consultez l'équipe de développement.*