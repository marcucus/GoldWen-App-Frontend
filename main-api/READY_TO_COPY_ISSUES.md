# 📋 Issues GitHub Prêtes à Copier-Coller

Ce fichier contient les 15 issues formatées et prêtes à être créées dans GitHub. Copie-colle chaque section dans une nouvelle issue GitHub.

---

## Issue #1: Implémentation complète de la gestion des photos de profil

**Priorité**: Critique 🔥  
**Estimation**: 5-7 jours  
**Labels**: `critical`, `enhancement`, `frontend`, `photos-management`, `api-integration`

### 📝 Description

Développer un système complet de gestion des photos de profil incluant l'upload, la validation du minimum requis (3 photos), la réorganisation par drag & drop, et la gestion de la photo principale.

### ✅ Fonctionnalités requises

- [ ] Upload de photos via image_picker
- [ ] Validation et forçage de 3 photos minimum
- [ ] Interface drag & drop pour réorganiser les photos
- [ ] Système de définition de photo principale
- [ ] Compression et redimensionnement automatique
- [ ] Interface de suppression/remplacement des photos

### 🔗 Routes Backend

```http
POST /api/v1/profiles/me/photos
Content-Type: multipart/form-data
Body: photos (max 6 fichiers)

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

PUT /api/v1/profiles/me/photos/:photoId/order
Body: {
  "newOrder": number
}

PUT /api/v1/profiles/me/photos/:photoId/primary

DELETE /api/v1/profiles/me/photos/:photoId
```

### 🎯 Critères d'acceptation

- L'utilisateur peut uploader jusqu'à 6 photos
- Le système empêche la progression sans 3 photos minimum
- Les photos peuvent être réorganisées par glisser-déposer
- Une photo principale peut être définie
- Les photos sont compressées automatiquement

### 🔗 Références

- Analyse source: [`FRONTEND_FEATURES_ANALYSIS.md`](../FRONTEND_FEATURES_ANALYSIS.md)
- Documentation API: [`API_ROUTES_DOCUMENTATION.md`](../API_ROUTES_DOCUMENTATION.md)

---

## Issue #2: Système de prompts textuels obligatoires

**Priorité**: Critique 🔥  
**Estimation**: 4-5 jours  
**Labels**: `critical`, `enhancement`, `frontend`, `prompts-system`, `api-integration`

### 📝 Description

Implémenter le système de prompts textuels avec validation stricte de 3 réponses obligatoires, interface élégante d'affichage, et possibilité de modification.

### ✅ Fonctionnalités requises

- [ ] Interface de sélection et réponse à 3 prompts obligatoires
- [ ] Validation empêchant la progression sans 3 réponses
- [ ] Affichage élégant des prompts dans les profils
- [ ] Interface de modification des prompts choisis

### 🔗 Routes Backend

```http
GET /api/v1/profiles/prompts
Response: [
  {
    "id": "string",
    "text": "string",
    "category": "string"
  }
]

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

PUT /api/v1/profiles/me/prompt-answers
Body: {
  "answers": [
    {
      "promptId": "string (UUID)",
      "answer": "string (max 300 caractères)"
    }
  ]
}

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

### 🎯 Critères d'acceptation

- L'utilisateur doit répondre à exactement 3 prompts
- Les réponses sont limitées à 300 caractères
- Le profil est bloqué sans 3 réponses validées
- Les prompts peuvent être modifiés après création

### 🔗 Références

- Analyse source: [`FRONTEND_FEATURES_ANALYSIS.md`](../FRONTEND_FEATURES_ANALYSIS.md)
- Documentation API: [`API_ROUTES_DOCUMENTATION.md`](../API_ROUTES_DOCUMENTATION.md)

---

## Issue #3: Logique de sélection quotidienne avec limitations d'abonnement

**Priorité**: Critique 🔥  
**Estimation**: 6-8 jours  
**Labels**: `critical`, `enhancement`, `frontend`, `matching-logic`, `api-integration`

### 📝 Description

Implémenter la logique stricte de sélection quotidienne avec limitation à 1 choix pour les utilisateurs gratuits, 3 choix pour les abonnés, messages de confirmation, et masquage des profils après sélection.

### ✅ Fonctionnalités requises

- [ ] Limitation stricte 1 choix gratuit / 3 choix premium
- [ ] Message de confirmation "Votre choix est fait. Revenez demain..."
- [ ] Masquage des autres profils après choix effectué
- [ ] Refresh quotidien automatique à midi
- [ ] Persistance des sélections pour éviter les doublons

### 🔗 Routes Backend

```http
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

### 🎯 Critères d'acceptation

- Les utilisateurs gratuits ne peuvent faire qu'1 choix par jour
- Les abonnés premium peuvent faire 3 choix par jour
- Les autres profils disparaissent après sélection
- Nouvelle sélection générée automatiquement à midi
- Les choix précédents sont persistés

### 🔗 Références

- Analyse source: [`FRONTEND_FEATURES_ANALYSIS.md`](../FRONTEND_FEATURES_ANALYSIS.md)
- Documentation API: [`API_ROUTES_DOCUMENTATION.md`](../API_ROUTES_DOCUMENTATION.md)

---

## Issue #4: Système de match unidirectionnel avec acceptation de chat

**Priorité**: Critique 🔥  
**Estimation**: 7-9 jours  
**Labels**: `critical`, `enhancement`, `frontend`, `matching-logic`, `chat-system`, `notifications`

### 📝 Description

Implémenter le système de match unidirectionnel où le chat devient accessible quand A choisit B OU B choisit A, avec demande d'acceptation de chat et notifications appropriées.

### ✅ Fonctionnalités requises

- [ ] Match unidirectionnel pour accès chat (A choisit B OU B choisit A)
- [ ] Interface d'acceptation/refus de chat avec profil de l'autre
- [ ] Notification "Félicitations ! Vous avez un match avec [Prénom]"
- [ ] Page listant les matches obtenus
- [ ] Distinction claire sélections vs matches vs conversations actives

### 🔗 Routes Backend

```http
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

### 🎯 Critères d'acceptation

- Le chat est accessible dès qu'une personne choisit l'autre
- Interface claire pour accepter/refuser une demande de chat
- Notifications envoyées lors des nouveaux matches
- Distinction visuelle entre matches en attente et conversations actives

### 🔗 Références

- Analyse source: [`FRONTEND_FEATURES_ANALYSIS.md`](../FRONTEND_FEATURES_ANALYSIS.md)
- Documentation API: [`API_ROUTES_DOCUMENTATION.md`](../API_ROUTES_DOCUMENTATION.md)

---

## Issue #5: Validation stricte du profil complet

**Priorité**: Critique 🔥  
**Estimation**: 3-4 jours  
**Labels**: `critical`, `enhancement`, `frontend`, `profile-validation`, `api-integration`

### 📝 Description

Implémenter une validation stricte empêchant la visibilité du profil tant que les conditions ne sont pas remplies : 3 photos + 3 prompts + questionnaire de personnalité complété.

### ✅ Fonctionnalités requises

- [ ] Profil invisible tant que incomplet
- [ ] Indicateur de progression visuel
- [ ] Messages de guidage clairs pour compléter
- [ ] Blocage de l'accès aux fonctionnalités principales

### 🔗 Routes Backend

```http
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

PUT /api/v1/profiles/me/status
Body: {
  "status?": "string",
  "completed": boolean
}
```

### 🎯 Critères d'acceptation

- Le profil n'apparaît pas dans les sélections s'il est incomplet
- Barre de progression affichée clairement
- Messages d'instruction pour chaque étape manquante
- Accès aux fonctionnalités bloqué jusqu'à complétion

### 🔗 Références

- Analyse source: [`FRONTEND_FEATURES_ANALYSIS.md`](../FRONTEND_FEATURES_ANALYSIS.md)
- Documentation API: [`API_ROUTES_DOCUMENTATION.md`](../API_ROUTES_DOCUMENTATION.md)

---

## Issue #6: Conformité RGPD - Consentement et gestion des données

**Priorité**: Critique 🔥  
**Estimation**: 6-8 jours  
**Labels**: `critical`, `enhancement`, `frontend`, `rgpd-compliance`, `api-integration`

### 📝 Description

Implémenter toutes les fonctionnalités obligatoires pour la conformité RGPD : consentement explicite, politique de confidentialité, export de données, suppression de compte.

### ✅ Fonctionnalités requises

- [ ] Modal de consentement RGPD à l'inscription
- [ ] Page de politique de confidentialité accessible
- [ ] Interface "droit à l'oubli" dans paramètres
- [ ] Export complet des données utilisateur
- [ ] Paramètres de confidentialité et cookies
- [ ] Interface de rectification de toutes les données

### 🔗 Routes Backend

```http
POST /api/v1/users/consent
Body: {
  "dataProcessing": boolean,
  "marketing?": boolean,
  "analytics?": boolean,
  "consentedAt": "ISO date string"
}

GET /api/v1/legal/privacy-policy
Query: version?: string, format?: "html|json"
Response: {
  "content": "string",
  "version": "string",
  "lastUpdated": "ISO date string"
}

GET /api/v1/users/me/export-data
Query: format?: "json|pdf"
Response: Fichier téléchargeable avec toutes les données utilisateur

PUT /api/v1/users/me/privacy-settings
Body: {
  "analytics": boolean,
  "marketing": boolean,
  "functionalCookies": boolean,
  "dataRetention?": number
}

DELETE /api/v1/users/me
Response: {
  "success": boolean,
  "message": "Compte supprimé avec anonymisation complète"
}
```

### 🎯 Critères d'acceptation

- Consentement obligatoire avant utilisation de l'app
- Politique de confidentialité accessible et complète
- Export de données dans format lisible (JSON/PDF)
- Suppression complète avec anonymisation des données
- Paramètres granulaires de confidentialité

### 🔗 Références

- Analyse source: [`FRONTEND_FEATURES_ANALYSIS.md`](../FRONTEND_FEATURES_ANALYSIS.md)
- Documentation API: [`API_ROUTES_DOCUMENTATION.md`](../API_ROUTES_DOCUMENTATION.md)

---

## Issue #7: Expiration automatique des chats après 24h

**Priorité**: Importante ⚡  
**Estimation**: 4-5 jours  
**Labels**: `important`, `enhancement`, `frontend`, `chat-system`, `api-integration`

### 📝 Description

Compléter le système d'expiration automatique des chats avec archivage après 24h, messages système d'expiration, et prévention de nouveaux messages.

### ✅ Fonctionnalités requises

- [ ] Expiration automatique et archivage après 24h
- [ ] Message système "Cette conversation a expiré"
- [ ] Blocage de l'envoi de messages après expiration
- [ ] Job automatique pour marquer les chats expirés

### 🔗 Routes Backend

```http
PUT /api/v1/chat/:chatId/expire

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

### 🎯 Critères d'acceptation

- Les chats s'archivent automatiquement après 24h
- Message système généré automatiquement à l'expiration
- Impossible d'envoyer des messages dans un chat expiré

### 🔗 Références

- Analyse source: [`FRONTEND_FEATURES_ANALYSIS.md`](../FRONTEND_FEATURES_ANALYSIS.md)
- Documentation API: [`API_ROUTES_DOCUMENTATION.md`](../API_ROUTES_DOCUMENTATION.md)

---

## Issue #8: Système complet de notifications push

**Priorité**: Importante ⚡  
**Estimation**: 5-6 jours  
**Labels**: `important`, `enhancement`, `frontend`, `notifications`, `api-integration`

### 📝 Description

Compléter l'implémentation des notifications push avec notification quotidienne à midi, notifications de match, gestion des permissions et paramètres utilisateur.

### ✅ Fonctionnalités requises

- [ ] Notification quotidienne à midi "Votre sélection GoldWen du jour est arrivée !"
- [ ] Notifications automatiques pour nouveaux matches
- [ ] Interface de gestion des permissions push
- [ ] Paramètres utilisateur pour activer/désactiver par type

### 🔗 Routes Backend

```http
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

PUT /api/v1/notifications/settings
Body: {
  "dailySelection?": boolean,
  "newMatch?": boolean,
  "newMessage?": boolean,
  "chatExpiring?": boolean,
  "subscription?": boolean
}

POST /api/v1/users/me/push-tokens
Body: {
  "token": "string",
  "platform": "ios|android|web",
  "appVersion?": "string",
  "deviceId?": "string"
}

DELETE /api/v1/users/me/push-tokens
Body: {
  "token": "string"
}
```

### 🎯 Critères d'acceptation

- Notification quotidienne envoyée automatiquement à 12h
- Notifications immédiates pour les nouveaux matches
- Interface de gestion des permissions native
- Paramètres granulaires par type de notification

### 🔗 Références

- Analyse source: [`FRONTEND_FEATURES_ANALYSIS.md`](../FRONTEND_FEATURES_ANALYSIS.md)
- Documentation API: [`API_ROUTES_DOCUMENTATION.md`](../API_ROUTES_DOCUMENTATION.md)

---

## Issue #9: Page de matches et historique des sélections

**Priorité**: Importante ⚡  
**Estimation**: 4-5 jours  
**Labels**: `important`, `enhancement`, `frontend`, `matching-logic`, `api-integration`

### 📝 Description

Créer une page dédiée aux matches obtenus (différente de la sélection quotidienne) et une page d'historique des sélections passées pour consultation.

### ✅ Fonctionnalités requises

- [ ] Page listant tous les matches obtenus
- [ ] Historique des sélections passées avec dates
- [ ] Distinction visuelle entre matches en attente et actifs
- [ ] Pagination pour l'historique

### 🔗 Routes Backend

```http
GET /api/v1/matching/matches/:matchId
Response: {
  "id": "string",
  "targetUser": "User profile object",
  "status": "MatchStatus enum",
  "matchedAt": "ISO date string",
  "chatId?": "string"
}

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

### 🎯 Critères d'acceptation

- Page de matches séparée de la sélection quotidienne
- Historique accessible avec pagination
- Statuts des matches clairement identifiés

### 🔗 Références

- Analyse source: [`FRONTEND_FEATURES_ANALYSIS.md`](../FRONTEND_FEATURES_ANALYSIS.md)
- Documentation API: [`API_ROUTES_DOCUMENTATION.md`](../API_ROUTES_DOCUMENTATION.md)

---

## Issue #10: Page de signalement et modération

**Priorité**: Importante ⚡  
**Estimation**: 4-5 jours  
**Labels**: `important`, `enhancement`, `frontend`, `api-integration`

### 📝 Description

Créer une interface complète de signalement pour profils et messages inappropriés, avec catégories de signalement et suivi des demandes.

### ✅ Fonctionnalités requises

- [ ] Interface de signalement de profil/message
- [ ] Catégories de signalement (contenu inapproprié, harcèlement, etc.)
- [ ] Système de preuves/captures d'écran
- [ ] Historique des signalements soumis

### 🔗 Routes Backend

```http
POST /api/v1/reports
Body: {
  "targetUserId": "string (UUID)",
  "type": "inappropriate_content|harassment|fake_profile|spam|other",
  "reason": "string (max 500 caractères)",
  "messageId?": "string (UUID, optionnel)",
  "chatId?": "string (UUID, optionnel)",
  "evidence?": "string[] (URLs, optionnel)"
}

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

### 🎯 Critères d'acceptation

- Interface intuitive de signalement accessible depuis profils/chats
- Formulaire complet avec types de signalement prédéfinis
- Possibilité d'ajouter des preuves
- Suivi du statut des signalements soumis

### 🔗 Références

- Analyse source: [`FRONTEND_FEATURES_ANALYSIS.md`](../FRONTEND_FEATURES_ANALYSIS.md)
- Documentation API: [`API_ROUTES_DOCUMENTATION.md`](../API_ROUTES_DOCUMENTATION.md)

---

## Issue #11: Fonctionnalité premium "Qui m'a sélectionné"

**Priorité**: Normale 🔧  
**Estimation**: 3-4 jours  
**Labels**: `normal`, `enhancement`, `frontend`, `matching-logic`, `api-integration`

### 📝 Description

Implémenter la fonctionnalité premium permettant de voir qui a sélectionné l'utilisateur, avec vérification de l'abonnement et interface dédiée.

### ✅ Fonctionnalités requises

- [ ] Page "Qui m'a sélectionné" pour abonnés premium
- [ ] Vérification automatique de l'abonnement
- [ ] Interface de mise à niveau pour utilisateurs gratuits
- [ ] Affichage des profils ayant sélectionné l'utilisateur

### 🔗 Routes Backend

```http
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

GET /api/v1/subscriptions/features
Response: {
  "whoLikedMe": boolean,
  "unlimitedChats": boolean,
  "extendChats": boolean,
  "priorityProfile": boolean
}
```

### 🎯 Critères d'acceptation

- Fonctionnalité accessible uniquement aux abonnés premium
- Message de mise à niveau pour utilisateurs gratuits
- Liste des profils ayant liké avec date de sélection

### 🔗 Références

- Analyse source: [`FRONTEND_FEATURES_ANALYSIS.md`](../FRONTEND_FEATURES_ANALYSIS.md)
- Documentation API: [`API_ROUTES_DOCUMENTATION.md`](../API_ROUTES_DOCUMENTATION.md)

---

## Issue #12: Système de feedback utilisateur

**Priorité**: Normale 🔧  
**Estimation**: 2-3 jours  
**Labels**: `normal`, `enhancement`, `frontend`, `api-integration`

### 📝 Description

Implémenter un système de feedback permettant aux utilisateurs de signaler des bugs, suggérer des fonctionnalités ou donner leur avis général sur l'application.

### ✅ Fonctionnalités requises

- [ ] Interface de feedback avec catégories (bug, feature, général)
- [ ] Formulaire avec évaluation optionnelle (1-5 étoiles)
- [ ] Collecte automatique de métadonnées (version app, page, etc.)
- [ ] Confirmation d'envoi et remerciement

### 🔗 Routes Backend

```http
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

### 🎯 Critères d'acceptation

- Formulaire accessible depuis les paramètres
- Catégorisation claire du feedback
- Métadonnées collectées automatiquement
- Confirmation d'envoi utilisateur

### 🔗 Références

- Analyse source: [`FRONTEND_FEATURES_ANALYSIS.md`](../FRONTEND_FEATURES_ANALYSIS.md)
- Documentation API: [`API_ROUTES_DOCUMENTATION.md`](../API_ROUTES_DOCUMENTATION.md)

---

## Issue #13: Optimisations performances et cache intelligent

**Priorité**: Normale 🔧  
**Estimation**: 5-6 jours  
**Labels**: `normal`, `enhancement`, `frontend`, `performance`

### 📝 Description

Implémenter des optimisations de performance incluant lazy loading des images, cache intelligent des profils, et préchargement des contenus.

### ✅ Fonctionnalités requises

- [ ] Images lazy loading avec placeholders
- [ ] Cache intelligent des profils et images consultés
- [ ] Préchargement des prochains profils en arrière-plan
- [ ] Optimisation mémoire pour les images

### 🔗 Routes Backend

```http
GET /api/v1/profiles/me/photos
Headers:
  Cache-Control: public, max-age=3600
  ETag: "version-hash"
Response: Photos avec headers de cache appropriés

GET /api/v1/matching/daily-selection?preload=true
Response: {
  "profiles": "User[]",
  "preloadedProfiles": "User[]",
  "metadata": {
    "cacheExpiry": "ISO date string"
  }
}
```

### 🎯 Critères d'acceptation

- Images chargées progressivement avec effet de fondu
- Cache local des profils consultés récemment
- Préchargement invisible des prochains profils
- Réduction significative de l'utilisation mémoire

### 🔗 Références

- Analyse source: [`FRONTEND_FEATURES_ANALYSIS.md`](../FRONTEND_FEATURES_ANALYSIS.md)
- Documentation API: [`API_ROUTES_DOCUMENTATION.md`](../API_ROUTES_DOCUMENTATION.md)

---

## Issue #14: Fonctionnalités d'accessibilité

**Priorité**: Normale 🔧  
**Estimation**: 4-5 jours  
**Labels**: `normal`, `enhancement`, `frontend`, `accessibility`

### 📝 Description

Implémenter les fonctionnalités d'accessibilité pour rendre l'app utilisable par tous, incluant support des lecteurs d'écran, navigation clavier, et préférences visuelles.

### ✅ Fonctionnalités requises

- [ ] Support complet des lecteurs d'écran avec labels sémantiques
- [ ] Validation et ajustement du contraste des couleurs
- [ ] Navigation alternative au clavier/switch control
- [ ] Support des préférences système (taille de police, mouvement réduit)

### 🔗 Routes Backend

```http
GET /api/v1/users/me/accessibility-settings
Response: {
  "fontSize": "small|medium|large|xlarge",
  "highContrast": boolean,
  "reducedMotion": boolean,
  "screenReader": boolean
}

PUT /api/v1/users/me/accessibility-settings
Body: {
  "fontSize": "small|medium|large|xlarge",
  "highContrast": boolean,
  "reducedMotion": boolean,
  "screenReader": boolean
}
```

### 🎯 Critères d'acceptation

- App entièrement navigable avec lecteur d'écran
- Contraste suffisant pour malvoyants (WCAG 2.1 AA)
- Navigation possible sans écran tactile
- Respect des préférences système d'accessibilité

### 🔗 Références

- Analyse source: [`FRONTEND_FEATURES_ANALYSIS.md`](../FRONTEND_FEATURES_ANALYSIS.md)
- Documentation API: [`API_ROUTES_DOCUMENTATION.md`](../API_ROUTES_DOCUMENTATION.md)

---

## Issue #15: Améliorations UX/UI avancées

**Priorité**: Normale 🔧  
**Estimation**: 6-7 jours  
**Labels**: `normal`, `enhancement`, `frontend`, `ux-improvements`

### 📝 Description

Implémenter des améliorations UX/UI avancées incluant états de chargement cohérents, gestion d'erreurs robuste, mode hors-ligne basique, et animations fluides.

### ✅ Fonctionnalités requises

- [ ] Skeletons et spinners cohérents partout
- [ ] Messages d'erreur informatifs avec actions de récupération
- [ ] Mode hors-ligne basique (cache, messages d'information)
- [ ] Animations fluides pour les transitions
- [ ] Micro-interactions et confirmations visuelles

### 🔗 Routes Backend

```
Amélioration de toutes les routes existantes avec:
- Codes d'erreur HTTP standardisés
- Messages d'erreur descriptifs
- Headers de cache appropriés
- Optimisation des temps de réponse
```

### 🎯 Critères d'acceptation

- États de chargement cohérents sur toute l'app
- Messages d'erreur clairs avec suggestions d'actions
- Fonctionnalité limitée en mode hors-ligne
- Animations fluides sans impact sur les performances
- Feedback visuel pour toutes les interactions utilisateur

### 🔗 Références

- Analyse source: [`FRONTEND_FEATURES_ANALYSIS.md`](../FRONTEND_FEATURES_ANALYSIS.md)
- Documentation API: [`API_ROUTES_DOCUMENTATION.md`](../API_ROUTES_DOCUMENTATION.md)

---

## 📊 Résumé

**Total**: 15 issues créées  
**Estimation globale**: 67-86 jours de développement  
**Routes backend impliquées**: 54 routes  

Les issues sont organisées par priorité et peuvent être créées dans GitHub en utilisant les milestones suggérés dans le guide de création.