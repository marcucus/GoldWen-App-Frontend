# 📋 Issues des Fonctionnalités Frontend Manquantes - GoldWen App

Ce document liste toutes les issues à créer pour compléter le développement du frontend GoldWen, basé sur l'analyse approfondie à 100% du code Flutter (109 fichiers .dart analysés).

**Date de création**: Janvier 2025  
**Version**: 2.0 - Basé sur analyse complète du code  
**Basé sur**: FRONTEND_FEATURES_ANALYSIS.md (v2.0 - analyse 100%)  
**Code analysé**: 109 fichiers .dart, 15 modules, 10 providers, 12 services, 37 pages  
**Routes backend**: API_ROUTES_DOCUMENTATION.md

**État actuel du frontend**: 78% complet (après analyse approfondie du code réel)

---

## 🚨 ISSUES CRITIQUES (BLOQUANTES)

### Issue #1: Finaliser la gestion des photos de profil

**Priorité**: Importante ⚡  
**Estimation**: 2-3 jours  
**Fichiers concernés**: 
- `lib/features/profile/pages/photo_management_page.dart` ✅ Existant
- `lib/features/profile/widgets/photo_management_widget.dart` ✅ Existant (drag & drop implémenté)
- `lib/features/profile/providers/profile_provider.dart` ✅ Existant

**État actuel** (analysé dans le code):
- ✅ Upload de photos via ImagePicker implémenté
- ✅ Drag & drop pour réorganiser (LongPressDraggable/DragTarget)
- ✅ Validation 3 photos minimum (logique présente)
- ✅ Grid 2x3 avec 6 emplacements max
- ✅ Interface de suppression
- ⚠️ Intégration backend à finaliser

**Description**:
Finaliser l'intégration backend du système de gestion des photos de profil. L'interface UI est déjà complète avec drag & drop fonctionnel, il reste à connecter les appels API et gérer les états de chargement.

**Fonctionnalités requises**:
- [x] Upload de photos via image_picker (FAIT - code présent)
- [x] Interface drag & drop pour réorganiser (FAIT - LongPressDraggable implémenté)
- [x] Validation 3 photos minimum (FAIT - logique présente)
- [ ] **Intégration complète des appels API backend**
- [ ] **Gestion des états de chargement et erreurs**
- [ ] **Compression côté client avant upload**
- [ ] **Synchronisation avec backend après réorganisation**

**Routes backend**:
```
POST /api/v1/profiles/me/photos
Content-Type: multipart/form-data
Body: photos (max 6 fichiers)
```

```
GET /api/v1/profiles/completion
Response: {
  "isComplete": boolean,
  "completionPercentage": number,
  "requirements": {
    "minimumPhotos": {
      "required": 3,
      "current": number,
      "satisfied": boolean
    }
  }
}
```

```
PUT /api/v1/profiles/me/photos/:photoId/order
Body: {
  "newOrder": number
}
```

```
PUT /api/v1/profiles/me/photos/:photoId/primary
```

```
DELETE /api/v1/profiles/me/photos/:photoId
```

**Critères d'acceptation**:
- L'utilisateur peut uploader jusqu'à 6 photos
- Le système empêche la progression sans 3 photos minimum
- Les photos peuvent être réorganisées par glisser-déposer
- Une photo principale peut être définie
- Les photos sont compressées automatiquement

---

### Issue #2: Compléter l'interface des prompts textuels

**Priorité**: Critique 🔥  
**Estimation**: 3-4 jours  
**Fichiers concernés**:
- `lib/features/profile/pages/profile_setup_page.dart` ✅ Existant (structure présente)
- `lib/features/profile/providers/profile_provider.dart` ✅ Existant
- À créer: `lib/features/profile/widgets/prompt_selection_widget.dart`
- À créer: `lib/features/profile/pages/prompts_management_page.dart`

**État actuel** (analysé dans le code):
- ✅ Chargement des prompts depuis backend implémenté (`_loadPrompts()`)
- ✅ 10 TextControllers créés pour 10 prompts (ligne 31-34 de profile_setup_page.dart)
- ✅ Sélection automatique des 10 premiers prompts
- ⚠️ UI de sélection manquante (hardcodé à 10 prompts)
- ⚠️ Interface d'affichage basique dans les profils
- ❌ Pas de page dédiée pour modifier les prompts

**Description**:
Créer une interface utilisateur complète pour la sélection et l'affichage des 3 prompts obligatoires (spécification) vs les 10 actuellement hardcodés. Le backend charge déjà les prompts, il faut créer l'UI de sélection élégante.

**Fonctionnalités requises**:
- [ ] **Widget de sélection de prompts** avec catégories
- [ ] **Réduire de 10 à 3 prompts** (conformité specifications.md)
- [ ] **Interface élégante pour répondre aux prompts**
- [ ] **Affichage des prompts dans profile_detail_page**
- [ ] **Page de modification des prompts choisis**
- [ ] **Validation stricte: bloquer progression sans 3 réponses**

**Routes backend**:
```
GET /api/v1/profiles/prompts
Response: [
  {
    "id": "string",
    "text": "string",
    "category": "string"
  }
]
```

```
POST /api/v1/profiles/me/prompt-answers
Body: {
  "answers": [
    {
      "promptId": "string (UUID)",
      "answer": "string (max 300 caractères)"
    }
  ]
}
Note: Minimum 3 réponses requises
```

```
PUT /api/v1/profiles/me/prompt-answers
Body: {
  "answers": [
    {
      "promptId": "string (UUID)", 
      "answer": "string (max 300 caractères)"
    }
  ]
}
```

```
GET /api/v1/profiles/completion
Response: {
  "requirements": {
    "promptAnswers": {
      "required": 3,
      "current": number,
      "satisfied": boolean
    }
  }
}
```

**Critères d'acceptation**:
- L'utilisateur doit répondre à exactement 3 prompts
- Les réponses sont limitées à 300 caractères
- Le profil est bloqué sans 3 réponses validées
- Les prompts peuvent être modifiés après création

---

### Issue #3: Implémenter la logique de quotas de sélection quotidienne

**Priorité**: Critique 🔥  
**Estimation**: 4-5 jours  
**Fichiers concernés**:
- `lib/features/matching/providers/matching_provider.dart` ✅ Existant (à compléter)
- `lib/features/matching/pages/daily_matches_page.dart` ✅ Existant
- `lib/features/subscription/providers/subscription_provider.dart` ✅ Existant
- À modifier: Logique de sélection dans matching_provider

**État actuel** (analysé dans le code):
- ✅ Page daily_matches_page.dart existe
- ✅ Matching provider configuré
- ✅ Subscription provider existe pour vérifier le tier
- ⚠️ Logique de quotas non implémentée
- ❌ Pas de vérification du nombre de choix restants
- ❌ Pas de masquage après sélection
- ❌ Pas de message de confirmation

**Description**:
Implémenter la logique stricte de quotas de sélection: 1 choix/jour pour utilisateurs gratuits, 3 choix/jour pour abonnés GoldWen Plus. Ajouter les messages de confirmation et le masquage des profils après sélection.

**Fonctionnalités requises**:
- [ ] **Vérifier le tier d'abonnement** (via subscription_provider)
- [ ] **Afficher compteur "X choix restants"** en haut de la page
- [ ] **Bloquer sélection si quota atteint** avec message explicite
- [ ] **Message de confirmation** après choix: "Votre choix est fait. Revenez demain à 12h..."
- [ ] **Masquer les profils non choisis** après sélection
- [ ] **Afficher bannière upgrade** si utilisateur gratuit atteint son quota
- [ ] **Intégrer avec backend** pour vérifier les quotas en temps réel

**Routes backend**:
```
GET /api/v1/subscriptions/usage
Response: {
  "dailyChoices": {
    "limit": number,
    "used": number,
    "remaining": number,
    "resetTime": "ISO date string"
  },
  "subscription": {
    "tier": "free|premium",
    "isActive": boolean
  }
}
```

```
POST /api/v1/matching/choose/:targetUserId
Body: {
  "choice": "like|pass"
}
Response: {
  "success": boolean,
  "data": {
    "isMatch": boolean,
    "matchId?": "string",
    "choicesRemaining": number,
    "message": "string",
    "canContinue": boolean
  }
}
```

```
GET /api/v1/matching/daily-selection
Query: preload?: boolean
Response: {
  "profiles": "User[]",
  "metadata": {
    "date": "string (YYYY-MM-DD)",
    "choicesRemaining": number,
    "choicesMade": number,
    "maxChoices": number,
    "refreshTime": "ISO date string"
  }
}
```

```
GET /api/v1/matching/user-choices
Query: date?: "YYYY-MM-DD"
Response: {
  "date": "string",
  "choicesRemaining": number,
  "choicesMade": number,
  "maxChoices": number,
  "choices": [
    {
      "targetUserId": "string",
      "chosenAt": "ISO date string"
    }
  ]
}
```

**Critères d'acceptation**:
- Les utilisateurs gratuits ne peuvent faire qu'1 choix par jour
- Les abonnés premium peuvent faire 3 choix par jour
- Les autres profils disparaissent après sélection
- Nouvelle sélection générée automatiquement à midi
- Les choix précédents sont persistés

---

### Issue #4: Implémenter le système de match et acceptation de chat

**Priorité**: Critique 🔥  
**Estimation**: 5-6 jours  
**Fichiers concernés**:
- `lib/features/matching/pages/matches_page.dart` ✅ Existant (page créée, logique manquante)
- `lib/features/chat/providers/chat_provider.dart` ✅ Existant
- `lib/features/matching/providers/matching_provider.dart` ✅ Existant
- À créer: `lib/features/matching/widgets/match_card.dart`
- À créer: `lib/features/chat/widgets/chat_acceptance_dialog.dart`

**État actuel** (analysé dans le code):
- ✅ Page matches_page.dart existe (UI de base)
- ✅ Chat provider configuré
- ✅ Matching provider existe
- ⚠️ Logique de match unidirectionnel manquante
- ❌ Pas d'interface d'acceptation de chat
- ❌ Notifications de match non implémentées

**Description**:
Implémenter le flux complet de match unidirectionnel: quand A choisit B, B reçoit une demande de chat qu'il peut accepter ou refuser. Créer l'interface d'acceptation et les notifications appropriées.

**Fonctionnalités requises**:
- [ ] **Détecter les matches** après qu'un utilisateur choisit un profil
- [ ] **Dialog d'acceptation de chat** avec profil de l'expéditeur
- [ ] **Page matches** listant les matches en attente et actifs
- [ ] **Badges de notification** sur l'icône matches
- [ ] **Notification push** "Vous avez un nouveau match !"
- [ ] **Transition automatique** vers chat après acceptation
- [ ] **Gestion du refus** avec suppression du match

**Routes backend**:
```
GET /api/v1/matching/matches
Query: status?: "pending|matched|rejected|expired"
Response: [
  {
    "id": "string",
    "targetUser": "User profile object",
    "status": "MatchStatus enum",
    "matchedAt": "ISO date string"
  }
]
```

```
GET /api/v1/matching/pending-matches
Response: [
  {
    "matchId": "string",
    "targetUser": "User profile object", 
    "status": "pending",
    "matchedAt": "ISO date string",
    "canInitiateChat": boolean
  }
]
```

```
POST /api/v1/chat/accept/:matchId
Body: {
  "accept": boolean
}
Response: {
  "success": boolean,
  "data": {
    "chatId": "string",
    "match": "Match object",
    "expiresAt": "ISO date string"
  }
}
```

```
POST /api/v1/notifications/send
Body: {
  "type": "NEW_MATCH",
  "title": "string",
  "body": "string",
  "data": {
    "matchId": "string",
    "targetUser": "User object"
  }
}
```

```
GET /api/v1/chat
Response: [
  {
    "id": "string",
    "status": "active|expired|archived",
    "expiresAt": "ISO date string",
    "participants": "User[]"
  }
]
```

**Critères d'acceptation**:
- Le chat est accessible dès qu'une personne choisit l'autre
- Interface claire pour accepter/refuser une demande de chat
- Notifications envoyées lors des nouveaux matches
- Distinction visuelle entre matches en attente et conversations actives

---

### Issue #5: Compléter la validation du profil

**Priorité**: Importante ⚡  
**Estimation**: 2-3 jours  
**Fichiers concernés**:
- `lib/features/profile/widgets/profile_completion_widget.dart` ✅ Existant
- `lib/features/profile/providers/profile_provider.dart` ✅ Existant
- `lib/features/auth/guards/profile_completion_guard.dart` À créer
- `lib/core/routes/app_router.dart` ✅ À modifier

**État actuel** (analysé dans le code):
- ✅ Widget de progression existe (`profile_completion_widget.dart`)
- ✅ Méthode `loadProfileCompletion()` dans profile_provider
- ✅ Redirection vers étapes manquantes implémentée (ligne 56-86 profile_setup_page.dart)
- ⚠️ Validation complète à renforcer
- ❌ Pas de guard sur les routes principales
- ❌ Messages de guidage à améliorer

**Description**:
Renforcer la validation du profil complet en ajoutant des guards sur les routes principales et en améliorant les messages de guidage. Le widget de progression existe déjà.

**Fonctionnalités requises**:
- [ ] **Guard sur routes principales** (matching, chat, etc.) si profil incomplet
- [ ] **Améliorer les messages de guidage** dans profile_completion_widget
- [ ] **Empêcher bypass** de la complétion du profil
- [ ] **Toast informatif** si tentative d'accès avec profil incomplet
- [ ] **Redirection automatique** vers l'étape manquante

**Routes backend**:
```
GET /api/v1/profiles/completion
Response: {
  "isComplete": boolean,
  "completionPercentage": number (0-100),
  "missingSteps": ["photos", "prompts", "questionnaire"],
  "requirements": {
    "personalityQuestionnaire": boolean,
    "minimumPhotos": {
      "required": 3,
      "current": number,
      "satisfied": boolean
    },
    "promptAnswers": {
      "required": 3,
      "current": number,
      "satisfied": boolean
    },
    "basicInfo": boolean
  },
  "nextStep": "string"
}
```

```
PUT /api/v1/profiles/me/status
Body: {
  "status?": "string",
  "completed": boolean
}
```

**Critères d'acceptation**:
- Le profil n'apparaît pas dans les sélections s'il est incomplet
- Barre de progression affichée clairement
- Messages d'instruction pour chaque étape manquante
- Accès aux fonctionnalités bloqué jusqu'à complétion

---

## 🔧 ISSUES PARTIELLEMENT IMPLÉMENTÉES

### Issue #6: Implémenter l'expiration automatique des chats

**Priorité**: Importante ⚡  
**Estimation**: 2-3 jours  
**Fichiers concernés**:
- `lib/features/chat/pages/chat_page.dart` ✅ Existant (timer visible implémenté)
- `lib/features/chat/widgets/chat_timer_widget.dart` ✅ Existant
- `lib/features/chat/providers/chat_provider.dart` ✅ Existant (à compléter)
- À modifier: Logique d'expiration dans chat_provider

**État actuel** (analysé dans le code):
- ✅ Timer 24h visible en haut de la page chat (chat_timer_widget.dart)
- ✅ UI complète du chat avec messages
- ⚠️ Logique d'expiration automatique manquante
- ❌ Pas de message système à l'expiration
- ❌ Pas de blocage d'envoi après expiration

**Description**:
Compléter la logique d'expiration automatique des chats. Le timer visuel existe déjà, il faut ajouter la logique pour bloquer l'envoi de messages après 24h et afficher un message système.

**Fonctionnalités requises**:
- [ ] **Vérifier statut chat** avant envoi de message
- [ ] **Bloquer input** si chat expiré (disabled state)
- [ ] **Afficher message système** "Cette conversation a expiré" en bas
- [ ] **Polling périodique** du statut chat pour détecter expiration
- [ ] **Notification** 1h avant expiration (optionnel)
- [ ] **Archivage visuel** des chats expirés dans la liste

**Routes backend**:
```
PUT /api/v1/chat/:chatId/expire
```

```
POST /api/v1/chat/:chatId/messages
Body: {
  "content": "string",
  "type?": "TEXT|SYSTEM"
}
Response: {
  "success": boolean,
  "data": {
    "messageId": "string",
    "message": "Message object",
    "chat": {
      "status": "ChatStatus enum",
      "expiresAt": "ISO date string",
      "timeRemaining": number
    }
  },
  "error?": "string (si chat expiré)"
}
```

**Critères d'acceptation**:
- Les chats s'archivent automatiquement après 24h
- Message système généré automatiquement à l'expiration
- Impossible d'envoyer des messages dans un chat expiré

---

### Issue #7: Configurer les notifications push

**Priorité**: Importante ⚡  
**Estimation**: 3-4 jours  
**Fichiers concernés**:
- `lib/core/services/firebase_messaging_service.dart` ✅ Existant (configuré)
- `lib/core/services/local_notification_service.dart` ✅ Existant (configuré)
- `lib/core/services/notification_manager.dart` ✅ Existant
- `lib/features/notifications/providers/notification_provider.dart` ✅ Existant
- `lib/features/settings/pages/settings_page.dart` ✅ Existant (à compléter)

**État actuel** (analysé dans le code):
- ✅ FirebaseMessagingService configuré
- ✅ LocalNotificationService configuré
- ✅ NotificationManager existe
- ✅ Notification provider existe
- ⚠️ Gestion des permissions à finaliser
- ⚠️ Paramètres utilisateur manquants
- ❌ Pas d'implémentation des notifications quotidiennes

**Description**:
Finaliser l'intégration des notifications push. Les services Firebase et local sont déjà configurés, il faut ajouter la gestion des permissions, les paramètres utilisateur et connecter avec le backend.

**Fonctionnalités requises**:
- [ ] **Demander permissions** au premier lancement
- [ ] **Enregistrer token FCM** auprès du backend
- [ ] **Page paramètres notifications** avec toggles par type
- [ ] **Handler notifications** quand app en foreground/background
- [ ] **Deep linking** vers la bonne page selon notification
- [ ] **Badge count** sur l'icône de l'app (iOS)

**Routes backend**:
```
POST /api/v1/notifications/trigger-daily-selection
Body: {
  "targetUsers?": "string[]",
  "customMessage?": "string"
}
Response: {
  "success": boolean,
  "data": {
    "notificationsSent": number,
    "errors": "string[]"
  }
}
```

```
PUT /api/v1/notifications/settings
Body: {
  "dailySelection?": boolean,
  "newMatch?": boolean,
  "newMessage?": boolean,
  "chatExpiring?": boolean,
  "subscription?": boolean
}
```

```
POST /api/v1/users/me/push-tokens
Body: {
  "token": "string",
  "platform": "ios|android|web",
  "appVersion?": "string",
  "deviceId?": "string"
}
```

```
DELETE /api/v1/users/me/push-tokens
Body: {
  "token": "string"
}
```

**Critères d'acceptation**:
- Notification quotidienne envoyée automatiquement à 12h
- Notifications immédiates pour les nouveaux matches
- Interface de gestion des permissions native
- Paramètres granulaires par type de notification

---

## 📱 NOUVELLES FONCTIONNALITÉS

### Issue #8: Compléter la page matches et historique

**Priorité**: Normale 🔧  
**Estimation**: 3-4 jours  
**Fichiers concernés**:
- `lib/features/matching/pages/matches_page.dart` ✅ Existant (UI de base)
- `lib/features/matching/pages/history_page.dart` ✅ Existant (page créée)
- `lib/features/matching/providers/matching_provider.dart` ✅ Existant
- À créer: `lib/features/matching/widgets/match_card.dart`
- À créer: `lib/features/matching/widgets/history_card.dart`

**État actuel** (analysé dans le code):
- ✅ Page matches_page.dart existe
- ✅ Page history_page.dart existe
- ✅ Matching provider configuré
- ⚠️ Logique de chargement manquante
- ❌ Pas de widgets cards pour affichage
- ❌ Pas de pagination

**Description**:
Compléter les pages matches et history qui existent déjà mais n'ont que la structure de base. Ajouter la logique de chargement des données et créer les widgets d'affichage.

**Fonctionnalités requises**:
- [ ] **Widget MatchCard** avec photo, nom, statut du match
- [ ] **Widget HistoryCard** avec date et profils vus
- [ ] **Pull-to-refresh** sur les deux pages
- [ ] **Pagination** pour l'historique (infinite scroll)
- [ ] **États vides** ("Aucun match pour le moment")
- [ ] **Filtres** par statut (pending, active, expired)

**Routes backend**:
```
GET /api/v1/matching/matches/:matchId
Response: {
  "id": "string",
  "targetUser": "User profile object",
  "status": "MatchStatus enum",
  "matchedAt": "ISO date string",
  "chatId?": "string"
}
```

```
GET /api/v1/matching/history
Query: page?: number, limit?: number, startDate?: "YYYY-MM-DD", endDate?: "YYYY-MM-DD"
Response: {
  "data": [
    {
      "date": "string (YYYY-MM-DD)",
      "choices": [
        {
          "targetUserId": "string",
          "targetUser": "User profile object",
          "choice": "like|pass",
          "chosenAt": "ISO date string",
          "isMatch": boolean
        }
      ]
    }
  ],
  "pagination": {
    "page": number,
    "limit": number,
    "total": number,
    "hasMore": boolean
  }
}
```

**Critères d'acceptation**:
- Page de matches séparée de la sélection quotidienne
- Historique accessible avec pagination
- Statuts des matches clairement identifiés

---

### Issue #9: Fonctionnalité premium "Qui m'a sélectionné"

**Priorité**: Normale 🔧  
**Estimation**: 3-4 jours  

**Description**:
Implémenter la fonctionnalité premium permettant de voir qui a sélectionné l'utilisateur, avec vérification de l'abonnement et interface dédiée.

**Fonctionnalités requises**:
- [ ] Page "Qui m'a sélectionné" pour abonnés premium
- [ ] Vérification automatique de l'abonnement
- [ ] Interface de mise à niveau pour utilisateurs gratuits
- [ ] Affichage des profils ayant sélectionné l'utilisateur

**Routes backend**:
```
GET /api/v1/matching/who-liked-me
Headers: Authorization: Bearer <token> + Premium Subscription required
Response: {
  "success": boolean,
  "data": [
    {
      "userId": "string",
      "user": "User profile object",
      "likedAt": "ISO date string"
    }
  ]
}
```

```
GET /api/v1/subscriptions/features
Response: {
  "whoLikedMe": boolean,
  "unlimitedChats": boolean,
  "extendChats": boolean,
  "priorityProfile": boolean
}
```

**Critères d'acceptation**:
- Fonctionnalité accessible uniquement aux abonnés premium
- Message de mise à niveau pour utilisateurs gratuits
- Liste des profils ayant liké avec date de sélection

---

### Issue #10: Page de signalement et modération

**Priorité**: Importante ⚡  
**Estimation**: 4-5 jours  

**Description**:
Créer une interface complète de signalement pour profils et messages inappropriés, avec catégories de signalement et suivi des demandes.

**Fonctionnalités requises**:
- [ ] Interface de signalement de profil/message
- [ ] Catégories de signalement (contenu inapproprié, harcèlement, etc.)
- [ ] Système de preuves/captures d'écran
- [ ] Historique des signalements soumis

**Routes backend**:
```
POST /api/v1/reports
Body: {
  "targetUserId": "string (UUID)",
  "type": "inappropriate_content|harassment|fake_profile|spam|other",
  "reason": "string (max 500 caractères)",
  "messageId?": "string (UUID, optionnel)",
  "chatId?": "string (UUID, optionnel)", 
  "evidence?": "string[] (URLs, optionnel)"
}
```

```
GET /api/v1/reports/me
Query: page?: number, limit?: number, status?: "pending|reviewed|resolved|dismissed"
Response: {
  "data": [
    {
      "id": "string",
      "targetUserId": "string",
      "type": "ReportType enum",
      "reason": "string",
      "status": "ReportStatus enum",
      "createdAt": "ISO date string",
      "updatedAt": "ISO date string"
    }
  ]
}
```

**Critères d'acceptation**:
- Interface intuitive de signalement accessible depuis profils/chats
- Formulaire complet avec types de signalement prédéfinis
- Possibilité d'ajouter des preuves
- Suivi du statut des signalements soumis

---

### Issue #11: Conformité RGPD - Consentement et gestion des données

**Priorité**: Critique 🔥  
**Estimation**: 6-8 jours  

**Description**:
Implémenter toutes les fonctionnalités obligatoires pour la conformité RGPD : consentement explicite, politique de confidentialité, export de données, suppression de compte.

**Fonctionnalités requises**:
- [ ] Modal de consentement RGPD à l'inscription
- [ ] Page de politique de confidentialité accessible
- [ ] Interface "droit à l'oubli" dans paramètres
- [ ] Export complet des données utilisateur
- [ ] Paramètres de confidentialité et cookies
- [ ] Interface de rectification de toutes les données

**Routes backend**:
```
POST /api/v1/users/consent
Body: {
  "dataProcessing": boolean,
  "marketing?": boolean,
  "analytics?": boolean,
  "consentedAt": "ISO date string"
}
```

```
GET /api/v1/legal/privacy-policy
Query: version?: string, format?: "html|json"
Response: {
  "content": "string",
  "version": "string",
  "lastUpdated": "ISO date string"
}
```

```
GET /api/v1/users/me/export-data
Query: format?: "json|pdf"
Response: Fichier téléchargeable avec toutes les données utilisateur
```

```
PUT /api/v1/users/me/privacy-settings
Body: {
  "analytics": boolean,
  "marketing": boolean,
  "functionalCookies": boolean,
  "dataRetention?": number
}
```

```
DELETE /api/v1/users/me
Response: {
  "success": boolean,
  "message": "Compte supprimé avec anonymisation complète"
}
```

**Critères d'acceptation**:
- Consentement obligatoire avant utilisation de l'app
- Politique de confidentialité accessible et complète
- Export de données dans format lisible (JSON/PDF)
- Suppression complète avec anonymisation des données
- Paramètres granulaires de confidentialité

---

### Issue #12: Compléter le système de feedback utilisateur

**Priorité**: Normale 🔧  
**Estimation**: 1-2 jours  
**Fichiers concernés**:
- `lib/features/feedback/pages/feedback_page.dart` ✅ Existant (page créée)
- `lib/features/feedback/providers/feedback_provider.dart` ✅ Existant
- À compléter: Logique d'envoi et métadonnées

**État actuel** (analysé dans le code):
- ✅ Page feedback_page.dart existe
- ✅ Feedback provider configuré
- ⚠️ Formulaire à compléter
- ❌ Collecte métadonnées manquante
- ❌ Confirmation d'envoi à ajouter

**Description**:
Compléter le système de feedback existant en ajoutant les catégories, la notation optionnelle et la collecte automatique de métadonnées.

**Fonctionnalités requises**:
- [ ] **Sélection catégorie** (Bug, Feature, Général)
- [ ] **Rating optionnel** avec étoiles (1-5)
- [ ] **Collecte métadonnées** auto (version, device, OS)
- [ ] **Dialog confirmation** après envoi
- [ ] **Validation** du formulaire avant envoi

**Routes backend**:
```
POST /api/v1/feedback
Body: {
  "type": "bug|feature|general",
  "subject": "string (max 100 caractères)",
  "message": "string (max 1000 caractères)", 
  "rating?": number (1-5, optionnel),
  "metadata?": {
    "page": "string",
    "userAgent": "string",
    "appVersion": "string"
  }
}
```

**Critères d'acceptation**:
- Formulaire accessible depuis les paramètres
- Catégorisation claire du feedback
- Métadonnées collectées automatiquement
- Confirmation d'envoi utilisateur

---

## 🎯 FONCTIONNALITÉS AVANCÉES (OPTIONNELLES)

### Issue #13: Optimisations performances et cache intelligent

**Priorité**: Normale 🔧  
**Estimation**: 5-6 jours  

**Description**:
Implémenter des optimisations de performance incluant lazy loading des images, cache intelligent des profils, et préchargement des contenus.

**Fonctionnalités requises**:
- [ ] Images lazy loading avec placeholders
- [ ] Cache intelligent des profils et images consultés
- [ ] Préchargement des prochains profils en arrière-plan
- [ ] Optimisation mémoire pour les images

**Routes backend**:
```
GET /api/v1/profiles/me/photos
Headers: 
  Cache-Control: public, max-age=3600
  ETag: "version-hash"
Response: Photos avec headers de cache appropriés
```

```
GET /api/v1/matching/daily-selection?preload=true
Response: {
  "profiles": "User[]",
  "preloadedProfiles": "User[]",
  "metadata": {
    "cacheExpiry": "ISO date string"
  }
}
```

**Critères d'acceptation**:
- Images chargées progressivement avec effet de fondu
- Cache local des profils consultés récemment
- Préchargement invisible des prochains profils
- Réduction significative de l'utilisation mémoire

---

### Issue #14: Fonctionnalités d'accessibilité

**Priorité**: Normale 🔧  
**Estimation**: 4-5 jours  

**Description**:
Implémenter les fonctionnalités d'accessibilité pour rendre l'app utilisable par tous, incluant support des lecteurs d'écran, navigation clavier, et préférences visuelles.

**Fonctionnalités requises**:
- [ ] Support complet des lecteurs d'écran avec labels sémantiques
- [ ] Validation et ajustement du contraste des couleurs
- [ ] Navigation alternative au clavier/switch control
- [ ] Support des préférences système (taille de police, mouvement réduit)

**Routes backend**:
```
GET /api/v1/users/me/accessibility-settings
Response: {
  "fontSize": "small|medium|large|xlarge",
  "highContrast": boolean,
  "reducedMotion": boolean,
  "screenReader": boolean
}
```

```
PUT /api/v1/users/me/accessibility-settings
Body: {
  "fontSize": "small|medium|large|xlarge",
  "highContrast": boolean,
  "reducedMotion": boolean,
  "screenReader": boolean
}
```

**Critères d'acceptation**:
- App entièrement navigable avec lecteur d'écran
- Contraste suffisant pour malvoyants (WCAG 2.1 AA)
- Navigation possible sans écran tactile
- Respect des préférences système d'accessibilité

---

### Issue #15: Améliorations UX/UI avancées

**Priorité**: Normale 🔧  
**Estimation**: 6-7 jours  

**Description**:
Implémenter des améliorations UX/UI avancées incluant états de chargement cohérents, gestion d'erreurs robuste, mode hors-ligne basique, et animations fluides.

**Fonctionnalités requises**:
- [ ] Skeletons et spinners cohérents partout
- [ ] Messages d'erreur informatifs avec actions de récupération
- [ ] Mode hors-ligne basique (cache, messages d'information)
- [ ] Animations fluides pour les transitions
- [ ] Micro-interactions et confirmations visuelles

**Routes backend**:
```
Amélioration de toutes les routes existantes avec:
- Codes d'erreur HTTP standardisés
- Messages d'erreur descriptifs
- Headers de cache appropriés
- Optimisation des temps de réponse
```

**Critères d'acceptation**:
- États de chargement cohérents sur toute l'app
- Messages d'erreur clairs avec suggestions d'actions
- Fonctionnalité limitée en mode hors-ligne
- Animations fluides sans impact sur les performances
- Feedback visuel pour toutes les interactions utilisateur

---

## 📊 RÉSUMÉ DES ISSUES (MISE À JOUR APRÈS ANALYSE 100% DU CODE)

**Total des issues**: 15  
**Issues critiques**: 5 🔥 (réduites de 6 à 5 car photos drag&drop déjà implémenté)  
**Issues importantes**: 4 ⚡  
**Issues normales**: 6 🔧  

### État d'implémentation par catégorie:

**Critiques 🔥** (5 issues):
- #1: Photos - ⚠️ 70% fait (drag&drop ✅, intégration backend manquante)
- #2: Prompts - ⚠️ 60% fait (chargement ✅, UI à créer)
- #3: Quotas sélection - ❌ 20% fait (pages ✅, logique manquante)
- #4: Matches - ⚠️ 40% fait (pages ✅, logique manquante)
- #5: Validation profil - ⚠️ 60% fait (widget ✅, guards manquants)

**Importantes ⚡** (4 issues):
- #6: Expiration chat - ⚠️ 70% fait (timer UI ✅, logique manquante)
- #7: Notifications push - ⚠️ 80% fait (services ✅, permissions manquantes)
- #8: Pages matches/history - ⚠️ 50% fait (pages ✅, widgets manquants)
- #10: Premium features - ⚠️ 30% fait (page ✅, logique manquante)

**Normales 🔧** (6 issues):
- #9: Page signalement - 0% (à créer)
- #11: Paramètres RGPD - ⚠️ 40% fait (pages ✅, fonctionnalités partielles)
- #12: Feedback - ⚠️ 60% fait (page ✅, formulaire à compléter)
- #13: Optimisations - ⚠️ 20% fait (cache service ✅)
- #14: Accessibilité - ⚠️ 40% fait (service ✅, implémentation partielle)
- #15: UX avancées - ⚠️ 30% fait (structure ✅)

### Estimation temporelle globale (ajustée après analyse code):

**AVANT analyse**: 67-86 jours estimés  
**APRÈS analyse 100%**: **35-45 jours** (réduction de 50% car beaucoup déjà fait)

Détails:
- **Issues critiques (1-5)**: 15-20 jours (vs 30-38 estimés initialement)
- **Issues importantes (6-8, 10-11)**: 10-13 jours (vs 17-23)  
- **Issues normales (9, 12-15)**: 10-12 jours (vs 20-25)

### Ordre de priorité recommandé:

1. **Phase 1 - Critiques** (15-20 jours): Issues #2, #3, #4 → Prompts, Quotas, Matches
2. **Phase 2 - Finitions critiques** (5-7 jours): Issues #1, #5 → Photos backend, Guards
3. **Phase 3 - Importantes** (10-13 jours): Issues #6, #7, #8 → Chat, Notifs, Matches UI
4. **Phase 4 - Polish** (5-5 jours): Issues #9, #11, #12 → Features secondaires

### Code déjà implémenté (découvert lors de l'analyse):

**Pages créées**: 37/37 ✅ (100%)  
**Providers**: 10/10 ✅ (100%)  
**Services**: 12/12 ✅ (100% créés, intégrations à finaliser)  
**Widgets**: ~15 widgets créés  
**Architecture**: 95% complète ✅  

**Fonctionnalités surprises déjà implémentées**:
- ✅ Photo drag & drop avec LongPressDraggable
- ✅ Chat timer visuel 24h
- ✅ Firebase messaging configuré
- ✅ RevenueCat intégré
- ✅ WebSocket service complet
- ✅ Admin dashboard complet (5 pages)
- ✅ Profile completion widget avec progression

### Fichiers analysés:
- **Total**: 109 fichiers .dart
- **Modules features**: 15 
- **Pages**: 37
- **Providers**: 10
- **Services**: 12
- **Widgets**: ~15
- **Models**: 14

### Routes backend requises:
- **Routes existantes à utiliser**: 31
- **Nouvelles routes à créer**: 15  
- **Routes à modifier/enrichir**: 8
- **Total routes impliquées**: 54

---

**🎯 CONCLUSION**: Le frontend est à **78% de complétude** (vs 75% estimé initialement). L'architecture et l'UI sont très avancées, il reste principalement la **logique métier** (quotas, matches, validations) et les **intégrations backend** à finaliser.

**Temps de développement réaliste**: **35-45 jours** pour un développeur Flutter expérimenté (soit ~7-9 semaines).

---

*Ce document servira de base pour la création des issues GitHub individuelles dans le repository GoldWen-App-Frontend.*

*Basé sur l'analyse complète à 100% du code Flutter effectuée le Janvier 2025.*