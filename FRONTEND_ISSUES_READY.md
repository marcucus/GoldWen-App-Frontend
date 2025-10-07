# 📋 Issues Frontend GoldWen - Prêtes pour Implémentation (COMPLÈTES)

**Basé sur**: specifications.md (Cahier des Charges v1.1) + Analyse du code Flutter  
**Date**: Janvier 2025  
**État du frontend**: 78% complet  
**Issues**: 15 issues complètes (critiques + importantes + normales + V2)

Ce document contient **TOUTES** les issues frontend (15 au total) avec les routes backend correspondantes et le comportement attendu pour une implémentation directe.

---

## 🚨 ISSUES CRITIQUES (BLOQUANTES MVP)

### Issue Frontend #1: Compléter l'interface des prompts textuels (3 prompts obligatoires)

**Priorité**: Critique 🔥  
**Estimation**: 3-4 jours  
**Module**: Onboarding et Profil (specifications.md §4.1)  
**Fichiers concernés**: 
- `lib/features/profile/pages/profile_setup_page.dart` (modifier)
- `lib/features/profile/widgets/prompt_selection_widget.dart` (créer)
- `lib/features/profile/providers/profile_provider.dart` (modifier)

**Contexte (specifications.md):**
> "L'utilisateur doit répondre à 3 'prompts' textuels pour finaliser son profil."  
> "Le profil n'est pas visible par les autres tant que ces conditions ne sont pas remplies."

**Description:**
Créer l'interface utilisateur pour permettre à l'utilisateur de sélectionner et répondre à exactement 3 prompts textuels. Le chargement backend est déjà implémenté, il faut créer l'UI de sélection et de saisie.

**État actuel du code:**
- ✅ Chargement des prompts depuis backend (`_loadPrompts()`)
- ⚠️ Actuellement configuré pour 10 prompts (à réduire à 3)
- ❌ Pas d'UI de sélection élégante
- ❌ Pas de page dédiée pour modifier les prompts

**Comportement attendu:**

1. **Affichage de la liste des prompts disponibles**
   - Afficher les prompts par catégories (Valeurs, Loisirs, Vie quotidienne, etc.)
   - L'utilisateur peut parcourir et sélectionner 3 prompts
   - Indication visuelle des prompts déjà sélectionnés

2. **Saisie des réponses**
   - Pour chaque prompt sélectionné, afficher un champ texte (max 300 caractères)
   - Compteur de caractères visible
   - Validation: bloquer progression si moins de 3 réponses

3. **Modification ultérieure**
   - Page accessible depuis les paramètres du profil
   - Possibilité de changer les prompts choisis

**Routes Backend:**

```typescript
// 1. Récupérer la liste des prompts disponibles
GET /api/v1/profiles/prompts
Headers: {
  Authorization: "Bearer {token}"
}
Response: {
  "prompts": [
    {
      "id": "uuid",
      "text": "Ce qui me fait vibrer dans la vie...",
      "category": "values",
      "order": 1
    },
    {
      "id": "uuid",
      "text": "Mon activité préférée le week-end...",
      "category": "hobbies",
      "order": 2
    }
    // ... plus de prompts
  ]
}

// 2. Soumettre les réponses aux prompts
POST /api/v1/profiles/me/prompt-answers
Headers: {
  Authorization: "Bearer {token}",
  Content-Type: "application/json"
}
Body: {
  "answers": [
    {
      "promptId": "uuid-prompt-1",
      "answer": "Découvrir de nouvelles cultures et voyager à travers le monde"
    },
    {
      "promptId": "uuid-prompt-2", 
      "answer": "Randonner en montagne avec mon chien"
    },
    {
      "promptId": "uuid-prompt-3",
      "answer": "Cuisiner des plats exotiques pour mes amis"
    }
  ]
}
Response: {
  "success": true,
  "data": {
    "promptAnswers": [...], // Les 3 réponses enregistrées
    "profileCompletion": {
      "isComplete": boolean,
      "percentage": 100
    }
  }
}
Errors:
- 400: Moins de 3 réponses ou réponse trop longue (>300 chars)
- 401: Token invalide

// 3. Modifier les prompts existants
PUT /api/v1/profiles/me/prompt-answers
Headers: {
  Authorization: "Bearer {token}",
  Content-Type: "application/json"
}
Body: {
  "answers": [
    // Même structure que POST
  ]
}
Response: {
  "success": true,
  "data": {
    "promptAnswers": [...] // Les nouvelles réponses
  }
}

// 4. Vérifier la complétion du profil
GET /api/v1/profiles/completion
Headers: {
  Authorization: "Bearer {token}"
}
Response: {
  "isComplete": boolean,
  "completionPercentage": number,
  "requirements": {
    "personalityQuestionnaire": { "satisfied": true },
    "minimumPhotos": { "required": 3, "current": 3, "satisfied": true },
    "promptAnswers": { "required": 3, "current": 0, "satisfied": false }
  },
  "nextStep": "prompt-answers" // Si incomplet
}
```

**Critères d'acceptation:**
- [ ] Widget de sélection de prompts avec catégories
- [ ] Exactement 3 prompts sélectionnables (pas plus, pas moins)
- [ ] Champs texte avec validation (max 300 caractères)
- [ ] Impossible de passer à l'étape suivante sans 3 réponses complètes
- [ ] Page de modification accessible depuis les paramètres
- [ ] Appel correct des routes backend
- [ ] Gestion des erreurs avec messages utilisateur

---

### Issue Frontend #2: Implémenter la logique de quotas de sélection quotidienne

**Priorité**: Critique 🔥  
**Estimation**: 4-5 jours  
**Module**: Rituel Quotidien et Matching (specifications.md §4.2)  
**Fichiers concernés**:
- `lib/features/matching/providers/matching_provider.dart` (modifier)
- `lib/features/matching/pages/daily_matches_page.dart` (modifier)
- `lib/features/subscription/providers/subscription_provider.dart` (utiliser)

**Contexte (specifications.md):**
> "Un utilisateur gratuit peut appuyer sur un bouton 'Choisir' sur un seul profil. Une fois le choix fait, un message de confirmation apparaît et les autres profils de la journée disparaissent."  
> "Un utilisateur abonné GoldWen Plus peut 'Choisir' jusqu'à 3 profils dans sa sélection quotidienne."

**Description:**
Implémenter la logique stricte de quotas: 1 choix/jour gratuit, 3 choix/jour pour abonnés Plus. Afficher le compteur, bloquer après quota atteint, et masquer les profils non choisis.

**État actuel du code:**
- ✅ Page `daily_matches_page.dart` existe
- ✅ Matching provider configuré
- ✅ Subscription provider existe
- ❌ Logique de quotas non implémentée
- ❌ Pas de compteur de choix restants
- ❌ Pas de masquage après sélection

**Comportement attendu:**

1. **Affichage de la sélection quotidienne**
   - Au chargement, afficher le nombre de choix restants en haut: "2 choix restants aujourd'hui"
   - Afficher 3-5 profils avec bouton "Choisir" sur chacun

2. **Après un choix**
   - Décrémenter le compteur visuellement
   - Si quota atteint (0 choix restants):
     - Masquer tous les profils non choisis
     - Afficher message: "Votre choix est fait. Revenez demain à 12h pour de nouveaux profils !"
     - Si gratuit, afficher bannière: "Passez à GoldWen Plus pour 3 choix par jour"

3. **Vérification temps réel**
   - Vérifier le quota avant chaque tentative de sélection
   - Bloquer le bouton "Choisir" si quota atteint
   - Rafraîchir le quota en arrière-plan

**Routes Backend:**

```typescript
// 1. Récupérer la sélection quotidienne avec métadonnées
GET /api/v1/matching/daily-selection
Headers: {
  Authorization: "Bearer {token}"
}
Query params: {
  preload?: boolean // Pour précharger les images
}
Response: {
  "profiles": [
    {
      "id": "uuid",
      "firstName": "Sophie",
      "age": 29,
      "photos": [...],
      "prompts": [...],
      "compatibilityScore": 85
    }
    // 3-5 profils
  ],
  "metadata": {
    "date": "2025-01-15",
    "choicesRemaining": 1, // Nombre de choix restants
    "choicesMade": 0, // Nombre de choix déjà faits
    "maxChoices": 1, // Maximum pour ce tier (1 gratuit, 3 Plus)
    "refreshTime": "2025-01-16T12:00:00Z", // Prochaine sélection
    "userTier": "free" // ou "plus"
  }
}

// 2. Vérifier l'usage quotidien et le tier
GET /api/v1/subscriptions/usage
Headers: {
  Authorization: "Bearer {token}"
}
Response: {
  "dailyChoices": {
    "limit": 1, // ou 3 pour Plus
    "used": 0,
    "remaining": 1,
    "resetTime": "2025-01-16T12:00:00Z"
  },
  "subscription": {
    "tier": "free", // ou "plus"
    "isActive": true,
    "expiresAt": null // ou date pour Plus
  }
}

// 3. Effectuer un choix (like)
POST /api/v1/matching/choose/:targetUserId
Headers: {
  Authorization: "Bearer {token}",
  Content-Type: "application/json"
}
Body: {
  "choice": "like" // ou "pass" (pass ne compte pas dans le quota)
}
Response: {
  "success": true,
  "data": {
    "isMatch": true, // Si l'autre a aussi choisi
    "matchId": "uuid", // Si match
    "choicesRemaining": 0, // Nombre de choix restants après cette action
    "message": "Votre choix est fait. Revenez demain à 12h !",
    "canContinue": false, // false si quota atteint
    "upgradePrompt": "Passez à GoldWen Plus pour 3 choix par jour" // Si tier=free
  }
}
Errors:
- 403: Quota quotidien atteint
  {
    "error": "QUOTA_EXCEEDED",
    "message": "Vous avez atteint votre limite quotidienne. Revenez demain ou passez à GoldWen Plus.",
    "details": {
      "choicesToday": 1,
      "maxChoices": 1,
      "tier": "free",
      "resetTime": "2025-01-16T12:00:00Z"
    }
  }
- 404: Profil non trouvé ou pas dans la sélection du jour

// 4. Récupérer l'historique des choix
GET /api/v1/matching/user-choices
Headers: {
  Authorization: "Bearer {token}"
}
Query params: {
  date?: "2025-01-15" // Optionnel, défaut = aujourd'hui
}
Response: {
  "date": "2025-01-15",
  "choicesRemaining": 0,
  "choicesMade": 1,
  "maxChoices": 1,
  "choices": [
    {
      "targetUserId": "uuid",
      "choice": "like",
      "madeAt": "2025-01-15T14:30:00Z",
      "isMatch": true
    }
  ]
}
```

**Critères d'acceptation:**
- [ ] Compteur "X choix restants" affiché en haut de la page
- [ ] Bouton "Choisir" désactivé si quota atteint
- [ ] Message de confirmation après choix
- [ ] Masquage des profils non choisis si quota atteint
- [ ] Bannière upgrade pour utilisateurs gratuits
- [ ] Vérification quota en temps réel via API
- [ ] Gestion erreur 403 (quota dépassé) avec message clair
- [ ] Affichage du temps restant avant reset (12h lendemain)

---

### Issue Frontend #3: Implémenter le flux de match et acceptation de chat

**Priorité**: Critique 🔥  
**Estimation**: 5-6 jours  
**Module**: Messagerie et Interaction (specifications.md §4.3)  
**Fichiers concernés**:
- `lib/features/matching/pages/matches_page.dart` (modifier)
- `lib/features/chat/providers/chat_provider.dart` (modifier)
- `lib/features/matching/widgets/match_card.dart` (créer)
- `lib/features/chat/widgets/chat_acceptance_dialog.dart` (créer)

**Contexte (specifications.md):**
> "Une conversation (chat) est créée uniquement lorsque l'Utilisateur A choisit l'Utilisateur B, et que l'Utilisateur B choisit l'Utilisateur A."  
> "Les deux utilisateurs reçoivent une notification de match : 'Félicitations! Vous avez un match avec [Prénom]'."

**Description:**
Implémenter le système de match mutuel: quand un utilisateur reçoit un choix, afficher une demande qu'il peut accepter ou refuser pour démarrer le chat.

**État actuel du code:**
- ✅ Page `matches_page.dart` existe (UI basique)
- ✅ Chat provider configuré
- ❌ Logique de match non implémentée
- ❌ Pas de dialog d'acceptation
- ❌ Notifications de match manquantes

**Comportement attendu:**

1. **Réception d'un match**
   - Notification push: "Félicitations ! Vous avez un match avec Sophie"
   - Badge sur l'onglet "Matches"
   - Dans la page matches, afficher la carte du match en attente

2. **Acceptation/Refus**
   - Dialog avec photo et profil de la personne
   - Boutons "Accepter" et "Refuser"
   - Si accepté: transition vers le chat avec timer 24h
   - Si refusé: match supprimé

3. **Liste des matches**
   - Onglet "En attente" (matches non acceptés)
   - Onglet "Actifs" (chats en cours)
   - Badge avec nombre de matches en attente

**Routes Backend:**

```typescript
// 1. Récupérer la liste des matches
GET /api/v1/matching/matches
Headers: {
  Authorization: "Bearer {token}"
}
Query params: {
  status?: "pending" | "active" | "rejected" | "expired"
}
Response: {
  "matches": [
    {
      "id": "match-uuid",
      "targetUser": {
        "id": "uuid",
        "firstName": "Sophie",
        "age": 29,
        "photos": [...],
        "prompts": [...]
      },
      "status": "pending", // ou "active", "rejected", "expired"
      "matchedAt": "2025-01-15T14:30:00Z",
      "canInitiateChat": true, // true si l'autre a accepté ou pas encore répondu
      "chatId": null // null si pending, uuid si active
    }
  ],
  "metadata": {
    "pendingCount": 2,
    "activeCount": 1,
    "totalCount": 3
  }
}

// 2. Récupérer les matches en attente seulement
GET /api/v1/matching/pending-matches
Headers: {
  Authorization: "Bearer {token}"
}
Response: {
  "pendingMatches": [
    {
      "matchId": "uuid",
      "targetUser": {
        "id": "uuid",
        "firstName": "Marc",
        "age": 34,
        "photos": [...],
        "prompts": [...],
        "bio": "..."
      },
      "matchedAt": "2025-01-15T10:00:00Z",
      "expiresAt": "2025-01-22T10:00:00Z" // 7 jours pour répondre
    }
  ]
}

// 3. Accepter ou refuser un match
POST /api/v1/chat/accept/:matchId
Headers: {
  Authorization: "Bearer {token}",
  Content-Type: "application/json"
}
Body: {
  "accept": true // ou false pour refuser
}
Response (si accept=true): {
  "success": true,
  "data": {
    "chatId": "chat-uuid",
    "match": {
      "id": "match-uuid",
      "status": "active",
      "targetUser": {...}
    },
    "chat": {
      "id": "chat-uuid",
      "status": "active",
      "createdAt": "2025-01-15T15:00:00Z",
      "expiresAt": "2025-01-16T15:00:00Z", // 24h après création
      "timeRemaining": 86400 // secondes
    }
  }
}
Response (si accept=false): {
  "success": true,
  "data": {
    "matchId": "match-uuid",
    "status": "rejected",
    "message": "Match refusé"
  }
}
Errors:
- 404: Match non trouvé
- 400: Match déjà accepté/refusé

// 4. Récupérer les chats actifs
GET /api/v1/chat
Headers: {
  Authorization: "Bearer {token}"
}
Response: {
  "chats": [
    {
      "id": "chat-uuid",
      "matchId": "match-uuid",
      "status": "active", // ou "expired", "archived"
      "participants": [
        {
          "id": "uuid",
          "firstName": "Sophie",
          "photos": [...]
        }
      ],
      "createdAt": "2025-01-15T15:00:00Z",
      "expiresAt": "2025-01-16T15:00:00Z",
      "timeRemaining": 82800, // secondes
      "lastMessage": {
        "content": "Salut !",
        "sentAt": "2025-01-15T15:05:00Z"
      }
    }
  ]
}
```

**Critères d'acceptation:**
- [ ] Page matches avec onglets "En attente" et "Actifs"
- [ ] Badge sur l'onglet avec nombre de matches en attente
- [ ] Dialog d'acceptation avec profil complet
- [ ] Boutons "Accepter" et "Refuser" fonctionnels
- [ ] Transition automatique vers chat après acceptation
- [ ] Notification push lors d'un nouveau match
- [ ] Appel correct des routes backend
- [ ] Gestion des erreurs

---

### Issue Frontend #4: Compléter l'expiration automatique des chats

**Priorité**: Importante ⚡  
**Estimation**: 2-3 jours  
**Module**: Messagerie et Interaction (specifications.md §4.3)  
**Fichiers concernés**:
- `lib/features/chat/pages/chat_page.dart` (modifier)
- `lib/features/chat/widgets/chat_timer_widget.dart` (utiliser)
- `lib/features/chat/providers/chat_provider.dart` (modifier)

**Contexte (specifications.md):**
> "La fenêtre de chat affiche un minuteur bien visible en haut, démarrant à '24:00:00'."  
> "À la fin des 24 heures, le chat est archivé et devient inaccessible. Un message système indique 'Cette conversation a expiré'."

**Description:**
Compléter la logique d'expiration des chats. Le timer UI existe déjà, il faut ajouter le blocage de l'envoi après expiration et afficher le message système.

**État actuel du code:**
- ✅ Timer visuel implémenté (`chat_timer_widget.dart`)
- ✅ UI du chat complète
- ❌ Pas de blocage d'envoi après expiration
- ❌ Pas de message système affiché
- ❌ Pas de polling du statut

**Comportement attendu:**

1. **Pendant le chat actif**
   - Timer décompte visible en haut
   - Possibilité d'envoyer des messages

2. **À l'expiration (24h)**
   - Input de message désactivé (grayed out)
   - Message système en bas: "Cette conversation a expiré"
   - Timer affiche "00:00:00"

3. **Dans la liste des chats**
   - Chats expirés affichés avec badge "Expiré"
   - Icône différente pour chats expirés

**Routes Backend:**

```typescript
// 1. Envoyer un message (avec vérification expiration)
POST /api/v1/chat/:chatId/messages
Headers: {
  Authorization: "Bearer {token}",
  Content-Type: "application/json"
}
Body: {
  "content": "Salut ! Comment ça va ?",
  "type": "TEXT" // ou "EMOJI"
}
Response (succès): {
  "success": true,
  "data": {
    "messageId": "uuid",
    "message": {
      "id": "uuid",
      "chatId": "chat-uuid",
      "senderId": "uuid",
      "content": "Salut ! Comment ça va ?",
      "type": "TEXT",
      "sentAt": "2025-01-15T16:00:00Z",
      "status": "sent"
    },
    "chat": {
      "status": "active",
      "expiresAt": "2025-01-16T15:00:00Z",
      "timeRemaining": 79200
    }
  }
}
Response (chat expiré): {
  "success": false,
  "error": "CHAT_EXPIRED",
  "message": "Cette conversation a expiré. Vous ne pouvez plus envoyer de messages.",
  "data": {
    "chatId": "chat-uuid",
    "status": "expired",
    "expiredAt": "2025-01-16T15:00:00Z"
  }
}
Status: 403 (Forbidden)

// 2. Récupérer l'état du chat
GET /api/v1/chat/:chatId
Headers: {
  Authorization: "Bearer {token}"
}
Response: {
  "chat": {
    "id": "chat-uuid",
    "status": "active", // ou "expired", "archived"
    "createdAt": "2025-01-15T15:00:00Z",
    "expiresAt": "2025-01-16T15:00:00Z",
    "timeRemaining": 79200, // secondes, 0 si expiré
    "participants": [...],
    "systemMessage": null // ou "Cette conversation a expiré" si expiré
  }
}

// 3. Récupérer les messages (inclut les messages système)
GET /api/v1/chat/:chatId/messages
Headers: {
  Authorization: "Bearer {token}"
}
Query params: {
  page?: 1,
  limit?: 50
}
Response: {
  "messages": [
    {
      "id": "uuid",
      "chatId": "chat-uuid",
      "senderId": "uuid",
      "content": "Salut !",
      "type": "TEXT",
      "sentAt": "2025-01-15T16:00:00Z"
    },
    {
      "id": "uuid-system",
      "chatId": "chat-uuid",
      "senderId": null, // null pour message système
      "content": "Cette conversation a expiré",
      "type": "SYSTEM",
      "sentAt": "2025-01-16T15:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 50,
    "total": 25
  },
  "chat": {
    "status": "expired",
    "timeRemaining": 0
  }
}
```

**Critères d'acceptation:**
- [ ] Input désactivé quand chat expiré
- [ ] Message système "Cette conversation a expiré" affiché
- [ ] Timer affiche "00:00:00" à l'expiration
- [ ] Badge "Expiré" dans la liste des chats
- [ ] Polling périodique (toutes les 60s) du statut du chat
- [ ] Gestion erreur 403 si tentative d'envoi dans chat expiré
- [ ] Notification 1h avant expiration (optionnel)

---

### Issue Frontend #5: Finaliser l'intégration backend de la gestion des photos

**Priorité**: Importante ⚡  
**Estimation**: 2-3 jours  
**Module**: Onboarding et Profil (specifications.md §4.1)  
**Fichiers concernés**:
- `lib/features/profile/widgets/photo_management_widget.dart` (modifier)
- `lib/features/profile/providers/profile_provider.dart` (modifier)

**Contexte (specifications.md):**
> "L'utilisateur doit télécharger un minimum de 3 photos."

**Description:**
Finaliser l'intégration backend du système de photos. Le drag & drop est déjà implémenté, il faut connecter les appels API.

**État actuel du code:**
- ✅ Upload UI implémenté (ImagePicker)
- ✅ Drag & drop implémenté (LongPressDraggable)
- ✅ Validation 3 photos minimum
- ⚠️ Intégration backend à finaliser

**Comportement attendu:**

1. **Upload**
   - Sélection depuis galerie ou appareil photo
   - Compression côté client avant upload
   - Progress indicator pendant upload
   - Ajout dans la grille après succès

2. **Réorganisation**
   - Drag & drop pour changer l'ordre
   - Appel backend pour synchroniser l'ordre

3. **Suppression**
   - Bouton X sur chaque photo
   - Confirmation si < 3 photos après suppression

**Routes Backend:**

```typescript
// 1. Upload de photos
POST /api/v1/profiles/me/photos
Headers: {
  Authorization: "Bearer {token}",
  Content-Type: "multipart/form-data"
}
Body: FormData {
  photos: File[] // Max 6 fichiers, formats: JPG, PNG, HEIC
}
Response: {
  "success": true,
  "data": {
    "photos": [
      {
        "id": "photo-uuid-1",
        "url": "https://cdn.goldwen.com/photos/uuid.jpg",
        "thumbnailUrl": "https://cdn.goldwen.com/photos/uuid_thumb.jpg",
        "order": 0,
        "isPrimary": true
      },
      {
        "id": "photo-uuid-2",
        "url": "https://cdn.goldwen.com/photos/uuid2.jpg",
        "thumbnailUrl": "https://cdn.goldwen.com/photos/uuid2_thumb.jpg",
        "order": 1,
        "isPrimary": false
      }
    ],
    "profileCompletion": {
      "photos": { "required": 3, "current": 2, "satisfied": false }
    }
  }
}
Errors:
- 400: Fichier trop grand (>10MB) ou format invalide
- 400: Nombre maximum atteint (6 photos)

// 2. Réorganiser les photos
PUT /api/v1/profiles/me/photos/reorder
Headers: {
  Authorization: "Bearer {token}",
  Content-Type: "application/json"
}
Body: {
  "photoOrder": [
    { "photoId": "uuid-1", "order": 0 }, // Photo principale (ordre 0)
    { "photoId": "uuid-2", "order": 1 },
    { "photoId": "uuid-3", "order": 2 }
  ]
}
Response: {
  "success": true,
  "data": {
    "photos": [...] // Liste mise à jour
  }
}

// 3. Définir la photo principale
PUT /api/v1/profiles/me/photos/:photoId/primary
Headers: {
  Authorization: "Bearer {token}"
}
Response: {
  "success": true,
  "data": {
    "photoId": "uuid",
    "isPrimary": true,
    "photos": [...] // Liste complète avec isPrimary mis à jour
  }
}

// 4. Supprimer une photo
DELETE /api/v1/profiles/me/photos/:photoId
Headers: {
  Authorization: "Bearer {token}"
}
Response: {
  "success": true,
  "data": {
    "deletedPhotoId": "uuid",
    "remainingPhotos": 2,
    "profileCompletion": {
      "photos": { "required": 3, "current": 2, "satisfied": false }
    }
  }
}
Errors:
- 400: Impossible de supprimer si seulement 3 photos (minimum requis)
```

**Critères d'acceptation:**
- [ ] Upload fonctionnel avec progress indicator
- [ ] Compression côté client avant upload (package image)
- [ ] Réorganisation synchronisée avec backend
- [ ] Suppression avec confirmation
- [ ] Blocage suppression si seulement 3 photos
- [ ] Gestion des erreurs (taille, format, quota)
- [ ] États de chargement cohérents

---

---

### Issue Frontend #6: Configurer les notifications push complètes

**Priorité**: Importante ⚡  
**Estimation**: 3-4 jours  
**Module**: Notifications (specifications.md §4.2, §4.3)  
**Fichiers concernés**:
- `lib/core/services/firebase_messaging_service.dart` (modifier)
- `lib/core/providers/notification_provider.dart` (créer)
- `lib/features/settings/pages/notification_settings_page.dart` (modifier)

**Contexte (specifications.md):**
> "Chaque jour à 12h00, une notification push est envoyée."  
> "Les deux utilisateurs reçoivent une notification de match."

**Description:**
Finaliser la configuration des notifications push Firebase avec gestion des permissions, préférences utilisateur, et navigation deep linking.

**État actuel du code:**
- ✅ Firebase messaging service configuré
- ✅ Structure de base présente
- ❌ Gestion permissions manquante
- ❌ Préférences utilisateur non implémentées
- ❌ Deep linking non configuré

**Comportement attendu:**

1. **Demande de permission au premier lancement**
   - Dialog natif iOS/Android
   - Explication claire de la valeur des notifications
   - Enregistrement du token FCM

2. **Types de notifications**
   - Sélection quotidienne (12h)
   - Nouveau match
   - Nouveau message
   - Chat expire bientôt (1h avant)
   - Chat accepté

3. **Préférences utilisateur**
   - Page paramètres avec toggles par type
   - Synchronisation avec backend
   - Respect des choix utilisateur

4. **Deep linking**
   - Tap notification → navigation vers page appropriée
   - Gestion en foreground et background

**Routes Backend:**

```typescript
// 1. Enregistrer token FCM
POST /api/v1/users/me/push-tokens
Headers: {
  Authorization: "Bearer ******"
}
Body: {
  "token": "fcm-token-string",
  "platform": "ios", // ou "android"
  "appVersion": "1.0.0",
  "deviceId": "device-uuid"
}
Response: {
  "success": true,
  "data": {
    "tokenId": "uuid",
    "registeredAt": "2025-01-15T10:00:00Z"
  }
}

// 2. Supprimer token FCM (déconnexion)
DELETE /api/v1/users/me/push-tokens/:token
Headers: {
  Authorization: "Bearer ******"
}
Response: {
  "success": true
}

// 3. Gérer préférences notifications
PUT /api/v1/notifications/settings
Headers: {
  Authorization: "Bearer ******"
}
Body: {
  "dailySelection": true,
  "newMatch": true,
  "newMessage": true,
  "chatExpiring": false,
  "subscription": true
}
Response: {
  "success": true,
  "data": {
    "settings": {
      "dailySelection": true,
      "newMatch": true,
      "newMessage": true,
      "chatExpiring": false,
      "subscription": true
    }
  }
}

// 4. Récupérer préférences
GET /api/v1/notifications/settings
Headers: {
  Authorization: "Bearer ******"
}
Response: {
  "settings": {
    "dailySelection": true,
    "newMatch": true,
    "newMessage": true,
    "chatExpiring": false,
    "subscription": true
  }
}
```

**Critères d'acceptation:**
- [ ] Demande permission au premier lancement
- [ ] Token FCM enregistré automatiquement
- [ ] Notifications reçues pour les 5 types
- [ ] Page préférences fonctionnelle
- [ ] Deep linking vers bonnes pages
- [ ] Gestion foreground/background
- [ ] Badge count mis à jour
- [ ] Tests sur iOS et Android réels

---

### Issue Frontend #7: Compléter pages matches et historique

**Priorité**: Normale 🔧  
**Estimation**: 3-4 jours  
**Module**: Matching (specifications.md §4.2)  
**Fichiers concernés**:
- `lib/features/matching/pages/matches_page.dart` (modifier)
- `lib/features/matching/pages/match_history_page.dart` (créer)
- `lib/features/matching/widgets/match_card.dart` (créer)

**Contexte (specifications.md):**
> "Si aucun profil n'est choisi, la sélection reste disponible jusqu'à la prochaine actualisation."

**Description:**
Créer les pages permettant de voir ses matches actuels et l'historique de ses sélections quotidiennes passées.

**État actuel du code:**
- ✅ Page matches existe (UI basique)
- ❌ Onglets En attente/Actifs manquants
- ❌ Page historique non créée
- ❌ Widgets de cartes manquants

**Comportement attendu:**

1. **Page Matches (onglets)**
   - Onglet "En attente": Matches non encore acceptés
   - Onglet "Actifs": Chats en cours
   - Badge avec nombre en attente

2. **Page Historique**
   - Liste des sélections quotidiennes passées
   - Filtre par date
   - Indication si profil choisi ou passé

**Routes Backend:**

```typescript
// 1. Récupérer matches
GET /api/v1/matching/matches
Headers: {
  Authorization: "Bearer ******"
}
Query: {
  status?: "pending" | "active" | "all"
}
Response: {
  "matches": [
    {
      "id": "match-uuid",
      "targetUser": {
        "id": "uuid",
        "firstName": "Sophie",
        "age": 29,
        "photos": [...]
      },
      "status": "pending",
      "matchedAt": "2025-01-15T14:30:00Z",
      "chatId": null
    }
  ],
  "metadata": {
    "pendingCount": 2,
    "activeCount": 1
  }
}

// 2. Récupérer historique sélections
GET /api/v1/matching/history
Headers: {
  Authorization: "Bearer ******"
}
Query: {
  page?: 1,
  limit?: 20,
  startDate?: "2025-01-01",
  endDate?: "2025-01-31"
}
Response: {
  "history": [
    {
      "date": "2025-01-15",
      "profiles": [
        {
          "id": "uuid",
          "firstName": "Marc",
          "photos": [...],
          "chosen": true,
          "isMatch": true
        }
      ],
      "choicesMade": 1,
      "maxChoices": 1
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 45
  }
}
```

**Critères d'acceptation:**
- [ ] Onglets fonctionnels sur page matches
- [ ] Badge avec nombre en attente
- [ ] Page historique avec liste des sélections
- [ ] Filtre par date
- [ ] Indication visuelle choix/match
- [ ] Pagination si plus de 20 jours

---

### Issue Frontend #8: Implémenter fonctionnalité premium "Qui m'a sélectionné"

**Priorité**: Normale 🔧 (V2)  
**Estimation**: 2-3 jours  
**Module**: Subscriptions (specifications.md §4.4)  
**Fichiers concernés**:
- `lib/features/matching/pages/who_liked_me_page.dart` (créer)
- `lib/features/subscription/providers/subscription_provider.dart` (utiliser)

**Contexte (specifications.md):**
> "Des bannières non-intrusives dans l'application promeuvent GoldWen Plus."

**Description:**
Page premium montrant qui a sélectionné l'utilisateur, accessible uniquement aux abonnés Plus.

**Comportement attendu:**

1. **Pour utilisateurs gratuits**
   - Badge flouté avec nombre
   - Bannière upgrade
   - Tap → page abonnement

2. **Pour abonnés Plus**
   - Liste des utilisateurs ayant sélectionné
   - Possibilité de voir profil complet
   - Choix direct depuis cette page

**Routes Backend:**

```typescript
// Récupérer qui m'a sélectionné (Premium)
GET /api/v1/matching/who-liked-me
Headers: {
  Authorization: "Bearer ******"
}
Response (si Premium): {
  "users": [
    {
      "id": "uuid",
      "firstName": "Sophie",
      "age": 29,
      "photos": [...],
      "selectedAt": "2025-01-15T10:00:00Z"
    }
  ],
  "count": 5
}
Response (si gratuit - 403): {
  "error": "PREMIUM_REQUIRED",
  "message": "Cette fonctionnalité nécessite GoldWen Plus",
  "count": 5, // Nombre flouté
  "upgradeUrl": "/subscription"
}
```

**Critères d'acceptation:**
- [ ] Page créée avec liste
- [ ] Vérification abonnement
- [ ] Badge flouté pour gratuits
- [ ] Bannière upgrade
- [ ] Navigation vers profils
- [ ] Possibilité de choisir depuis cette page

---

### Issue Frontend #9: Page de signalement et modération

**Priorité**: Normale 🔧  
**Estimation**: 2-3 jours  
**Module**: Modération (specifications.md §4.5)  
**Fichiers concernés**:
- `lib/features/moderation/pages/report_page.dart` (créer)
- `lib/features/moderation/widgets/report_form.dart` (créer)
- `lib/core/services/moderation_service.dart` (créer)

**Contexte (specifications.md):**
> "Outils de signalement de comportements inappropriés."

**Description:**
Interface pour signaler profils ou messages inappropriés avec catégories et description.

**Comportement attendu:**

1. **Depuis profil**
   - Bouton "Signaler" dans menu
   - Formulaire avec catégories
   - Confirmation anonyme

2. **Depuis chat**
   - Bouton dans header
   - Possibilité de joindre messages

3. **Catégories**
   - Photos inappropriées
   - Propos offensants
   - Spam/Arnaque
   - Faux profil
   - Autre

**Routes Backend:**

```typescript
// 1. Signaler un profil
POST /api/v1/reports/profile/:userId
Headers: {
  Authorization: "Bearer ******"
}
Body: {
  "category": "inappropriate_photos",
  "description": "Description du problème",
  "evidence": ["message-id-1", "message-id-2"] // Optionnel
}
Response: {
  "success": true,
  "data": {
    "reportId": "uuid",
    "status": "submitted",
    "message": "Merci pour votre signalement. Nous allons l'examiner."
  }
}

// 2. Signaler un message
POST /api/v1/reports/message/:messageId
Headers: {
  Authorization: "Bearer ******"
}
Body: {
  "category": "offensive",
  "description": "Message offensant"
}
Response: {
  "success": true,
  "data": {
    "reportId": "uuid",
    "status": "submitted"
  }
}

// 3. Bloquer un utilisateur
POST /api/v1/users/block/:userId
Headers: {
  Authorization: "Bearer ******"
}
Response: {
  "success": true,
  "data": {
    "blockedUserId": "uuid",
    "blockedAt": "2025-01-15T10:00:00Z"
  }
}
```

**Critères d'acceptation:**
- [ ] Page signalement accessible depuis profil
- [ ] Formulaire avec catégories
- [ ] Champ description optionnel
- [ ] Confirmation d'envoi
- [ ] Blocage utilisateur fonctionnel
- [ ] Messages bloqués ne s'affichent plus

---

### Issue Frontend #10: Conformité RGPD - Consentement et données

**Priorité**: Importante ⚡  
**Estimation**: 3-4 jours  
**Module**: RGPD (specifications.md Annexe A)  
**Fichiers concernés**:
- `lib/features/settings/pages/privacy_settings_page.dart` (modifier)
- `lib/features/settings/pages/data_export_page.dart` (créer)
- `lib/features/auth/pages/consent_page.dart` (créer)

**Contexte (specifications.md Annexe A):**
> "Conformité RGPD : consentement explicite, droit à l'oubli, export des données."

**Description:**
Implémenter les fonctionnalités RGPD: consentement, export des données, suppression de compte.

**Comportement attendu:**

1. **Consentement initial**
   - Page lors de l'inscription
   - Explications claires
   - Opt-in obligatoire pour données essentielles
   - Opt-in optionnel pour marketing

2. **Export de données**
   - Page dans paramètres
   - Bouton "Télécharger mes données"
   - Email avec lien de téléchargement
   - Format JSON

3. **Suppression de compte**
   - Page dédiée avec avertissement
   - Confirmation par mot de passe
   - Délai de grâce 30 jours

**Routes Backend:**

```typescript
// 1. Consentement
POST /api/v1/users/me/consent
Headers: {
  Authorization: "Bearer ******"
}
Body: {
  "essentialData": true, // Obligatoire
  "personalityData": true, // Obligatoire
  "photoProcessing": true, // Obligatoire
  "marketing": false, // Optionnel
  "analytics": true // Optionnel
}
Response: {
  "success": true,
  "data": {
    "consents": {...},
    "consentedAt": "2025-01-15T10:00:00Z"
  }
}

// 2. Demander export données
POST /api/v1/users/me/data-export
Headers: {
  Authorization: "Bearer ******"
}
Response: {
  "success": true,
  "data": {
    "requestId": "uuid",
    "status": "processing",
    "estimatedTime": "24 heures",
    "message": "Vous recevrez un email avec un lien de téléchargement"
  }
}

// 3. Télécharger export
GET /api/v1/users/me/data-export/:requestId/download
Headers: {
  Authorization: "Bearer ******"
}
Response: JSON file with all user data

// 4. Demander suppression compte
DELETE /api/v1/users/me
Headers: {
  Authorization: "Bearer ******"
}
Body: {
  "password": "user-password",
  "reason": "Optionnel",
  "immediateDelete": false // true pour immédiat, false pour 30j grâce
}
Response: {
  "success": true,
  "data": {
    "status": "scheduled_deletion",
    "deletionDate": "2025-02-14T10:00:00Z",
    "message": "Votre compte sera supprimé dans 30 jours. Vous pouvez annuler avant."
  }
}

// 5. Annuler suppression
POST /api/v1/users/me/cancel-deletion
Headers: {
  Authorization: "Bearer ******"
}
Response: {
  "success": true,
  "message": "Suppression annulée"
}
```

**Critères d'acceptation:**
- [ ] Page consentement lors inscription
- [ ] Page export données dans paramètres
- [ ] Email avec lien téléchargement
- [ ] Page suppression compte avec confirmation
- [ ] Délai grâce 30 jours
- [ ] Possibilité annuler suppression
- [ ] Conformité RGPD complète

---

### Issue Frontend #11: Système de feedback utilisateur

**Priorité**: Normale 🔧  
**Estimation**: 2-3 jours  
**Module**: Support (specifications.md §4.5)  
**Fichiers concernés**:
- `lib/features/support/pages/feedback_page.dart` (modifier)
- `lib/features/support/widgets/feedback_form.dart` (créer)

**Contexte (specifications.md):**
> "Système de support intégré."

**Description:**
Page de feedback permettant aux utilisateurs de signaler bugs, suggérer fonctionnalités ou donner leur avis.

**Comportement attendu:**

1. **Formulaire**
   - Catégorie (bug/feature/général)
   - Sujet (max 100 chars)
   - Description
   - Rating optionnel (1-5 étoiles)

2. **Métadonnées auto**
   - Version app
   - Plateforme (iOS/Android)
   - Page actuelle
   - User ID

3. **Confirmation**
   - Message remerciement
   - ID de ticket
   - Temps réponse estimé

**Routes Backend:**

```typescript
// Envoyer feedback
POST /api/v1/feedback
Headers: {
  Authorization: "Bearer ******"
}
Body: {
  "type": "bug" | "feature" | "general",
  "subject": "string (max 100)",
  "description": "string",
  "rating": 1-5, // Optionnel
  "metadata": {
    "appVersion": "1.0.0",
    "platform": "ios",
    "currentPage": "/daily-selection"
  }
}
Response: {
  "success": true,
  "data": {
    "ticketId": "FEED-12345",
    "message": "Merci pour votre retour !",
    "estimatedResponseTime": "48 heures"
  }
}
```

**Critères d'acceptation:**
- [ ] Page feedback accessible depuis paramètres
- [ ] Formulaire avec catégories
- [ ] Rating optionnel
- [ ] Métadonnées auto-collectées
- [ ] Confirmation avec ticket ID
- [ ] Envoi réussi

---

### Issue Frontend #12: Optimisations performances et cache

**Priorité**: Normale 🔧  
**Estimation**: 3-4 jours  
**Module**: Performance (specifications.md §5)  
**Fichiers concernés**:
- `lib/core/services/cache_service.dart` (modifier)
- `lib/core/services/image_cache_service.dart` (créer)
- `lib/features/matching/providers/matching_provider.dart` (optimiser)
- `lib/core/utils/debouncer.dart` (créer)

**Contexte (specifications.md §5):**
> "Performance : temps de réponse API < 500ms."  
> "L'application doit être fluide et rapide, même avec connexion 3G."

**Description:**
Implémenter une stratégie de cache multi-niveaux et d'optimisations pour garantir une expérience utilisateur fluide même avec une connexion lente. Le cache doit minimiser les appels API redondants tout en gardant les données à jour. Les images doivent être préchargées intelligemment pour éviter les temps de chargement visibles par l'utilisateur.

**État actuel du code:**
- ✅ `CacheService` existe avec méthodes de base
- ⚠️ Pas de cache images intelligent
- ⚠️ Pas de stratégie de préchargement
- ❌ Pas de lazy loading sur les listes
- ❌ Pas de debouncing sur les recherches
- ❌ Pas de gestion de la taille du cache

**Comportement attendu:**

1. **Cache données API (multi-niveaux)**
   - **Cache mémoire** : Données de session (profils vus, état UI)
   - **Cache disque** : Sélection quotidienne (24h), préférences utilisateur
   - **Stratégie de rafraîchissement** : 
     - TTL configurables par type de données
     - Invalidation manuelle sur pull-to-refresh
     - Synchronisation en arrière-plan

2. **Cache images intelligent**
   - **Préchargement** : Images de la sélection quotidienne en arrière-plan
   - **Priorités** : Photo principale > autres photos > photos profils de chat
   - **Compression** : Images redimensionnées selon taille écran
   - **Nettoyage automatique** : 
     - Limite 150MB de cache
     - LRU (Least Recently Used) pour suppression
     - Nettoyage au démarrage si > 200MB

3. **Optimisations listes et scrolling**
   - **Lazy loading** : Chargement progressif avec `ListView.builder`
   - **Keep alive** : Garder state des items visibles avec `AutomaticKeepAliveClientMixin`
   - **Pagination** : Charger 10 items à la fois pour listes longues (historique)

4. **Optimisations interactions**
   - **Debouncing** : Recherche avec délai 500ms
   - **Throttling** : Limitation requêtes API (max 1/seconde)
   - **Optimistic updates** : UI mise à jour immédiatement, synchronisation backend en arrière-plan

5. **Monitoring performances**
   - Tracking temps chargement pages (Firebase Performance)
   - Alertes si temps > 3s
   - Métriques cache hit rate

**Code Flutter d'exemple:**

```dart
// lib/core/services/image_cache_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  final CacheManager _cacheManager = DefaultCacheManager();
  
  // Précharger images de la sélection quotidienne
  Future<void> preloadDailySelectionImages(List<String> imageUrls) async {
    final futures = imageUrls.map((url) async {
      try {
        await _cacheManager.downloadFile(url);
      } catch (e) {
        debugPrint('Failed to preload image: $url');
      }
    });
    
    await Future.wait(futures);
  }

  // Nettoyer cache si trop volumineux
  Future<void> cleanCacheIfNeeded() async {
    final store = await _cacheManager.store.getAllObjects();
    final totalSize = store.fold<int>(
      0,
      (sum, file) => sum + (file.length ?? 0),
    );
    
    // Si > 150MB, nettoyer les plus anciens
    if (totalSize > 150 * 1024 * 1024) {
      await _cacheManager.emptyCache();
    }
  }

  // Obtenir image avec fallback
  ImageProvider getCachedImage(String url) {
    return CachedNetworkImageProvider(url);
  }
}

// lib/core/utils/debouncer.dart
import 'dart:async';
import 'dart:ui';

class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({this.milliseconds = 500});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

// Usage dans recherche
class SearchWidget extends StatefulWidget {
  @override
  _SearchWidgetState createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  final _debouncer = Debouncer(milliseconds: 500);
  
  void _onSearchChanged(String query) {
    _debouncer.run(() {
      // Appel API seulement après 500ms d'inactivité
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    // Logique de recherche
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }
}

// lib/core/services/cache_service.dart (amélioré)
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Cache avec TTL
  Future<void> setWithTTL(
    String key,
    dynamic value,
    Duration ttl,
  ) async {
    final data = {
      'value': value,
      'expiresAt': DateTime.now().add(ttl).millisecondsSinceEpoch,
    };
    await _prefs?.setString(key, json.encode(data));
  }

  // Récupérer du cache avec vérification TTL
  T? getWithTTL<T>(String key) {
    final cached = _prefs?.getString(key);
    if (cached == null) return null;

    try {
      final data = json.decode(cached);
      final expiresAt = data['expiresAt'] as int;
      
      if (DateTime.now().millisecondsSinceEpoch > expiresAt) {
        // Expiré, supprimer
        _prefs?.remove(key);
        return null;
      }

      return data['value'] as T;
    } catch (e) {
      return null;
    }
  }

  // Cache sélection quotidienne (24h)
  Future<void> cacheDailySelection(List<dynamic> profiles) async {
    await setWithTTL(
      'daily_selection',
      profiles,
      Duration(hours: 24),
    );
  }

  List<dynamic>? getCachedDailySelection() {
    return getWithTTL<List<dynamic>>('daily_selection');
  }
}
```

**Optimisation ListView avec lazy loading:**

```dart
class MatchHistoryPage extends StatefulWidget {
  @override
  _MatchHistoryPageState createState() => _MatchHistoryPageState();
}

class _MatchHistoryPageState extends State<MatchHistoryPage> {
  final ScrollController _scrollController = ScrollController();
  List<Match> _matches = [];
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadMatches();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMatches();
    }
  }

  Future<void> _loadMatches() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final newMatches = await _matchService.getMatches(
        page: _currentPage,
        perPage: 10,
      );

      setState(() {
        _matches.addAll(newMatches);
        _currentPage++;
        _hasMore = newMatches.length == 10;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _matches.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _matches.length) {
          return Center(child: CircularProgressIndicator());
        }
        return MatchTile(match: _matches[index]);
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
```

**Routes Backend (pour monitoring):**

```typescript
// Monitoring des performances (optionnel)
GET /api/v1/monitoring/cache-stats
Headers: {
  Authorization: "Bearer {token}"
}
Response: {
  "cacheHitRate": 0.75,
  "avgResponseTime": 320,
  "imageCacheSize": "142MB",
  "apiCacheSizeMemory": "15MB",
  "apiCacheSizeDisk": "45MB"
}
```

**Critères d'acceptation:**
- [ ] Cache API avec TTL configurables implémenté
- [ ] Images de sélection quotidienne préchargées automatiquement
- [ ] Cache images limité à 150MB avec nettoyage LRU
- [ ] Lazy loading sur toutes les listes longues (>10 items)
- [ ] Debouncing 500ms sur recherches
- [ ] Optimistic updates sur actions utilisateur
- [ ] Temps chargement sélection quotidienne < 2s (avec cache)
- [ ] Temps chargement sélection quotidienne < 5s (première fois, avec préchargement)
- [ ] Cache hit rate > 70% après 1 semaine d'utilisation
- [ ] App fluide même avec connexion 3G (testé)
- [ ] Monitoring Firebase Performance intégré

---

### Issue Frontend #13: Fonctionnalités d'accessibilité complètes

**Priorité**: Normale 🔧  
**Estimation**: 2-3 jours  
**Module**: Accessibilité (specifications.md §7)  
**Fichiers concernés**:
- `lib/core/services/accessibility_service.dart` (modifier)
- `lib/core/theme/accessible_theme.dart` (créer)
- Tous les widgets dans `lib/features/` (ajouter Semantics)
- `lib/features/settings/pages/accessibility_settings_page.dart` (créer)

**Contexte (specifications.md §7):**
> "Accessibilité : support VoiceOver/TalkBack pour les utilisateurs malvoyants."  
> "L'application doit être utilisable par tous, conformément aux standards WCAG 2.1 niveau AA."

**Description:**
Implémenter un support complet d'accessibilité pour permettre aux utilisateurs avec handicaps visuels, auditifs ou moteurs d'utiliser pleinement l'application. Cela inclut le support des lecteurs d'écran (VoiceOver sur iOS, TalkBack sur Android), un mode contraste élevé, des tailles de texte ajustables, et des alternatives aux gestes complexes.

**État actuel du code:**
- ⚠️ `AccessibilityService` existe mais peu utilisé
- ❌ Pas de Semantics sur la plupart des widgets
- ❌ Pas de mode contraste élevé
- ❌ Pas d'alternatives aux swipes/drag & drop
- ❌ Pas de page paramètres accessibilité
- ❌ Images sans descriptions alternatives

**Comportement attendu:**

1. **Support lecteurs d'écran (VoiceOver/TalkBack)**
   - **Semantic labels** : Tous les boutons, images et actions doivent avoir des labels descriptifs
   - **Navigation logique** : Ordre de lecture cohérent (haut → bas, gauche → droite)
   - **Annonces contextuelles** : "Match !", "Nouveau message", "Sélection quotidienne prête"
   - **Hints** : Instructions d'utilisation ("Appuyez pour voir le profil complet")
   - **States** : "Sélectionné", "Chargement", "Désactivé"

2. **Mode contraste élevé**
   - **Palette couleurs** : Contraste min 7:1 (WCAG AAA)
   - **Textes** : Noir sur blanc ou blanc sur noir
   - **Boutons** : Bordures épaisses (2px) et couleurs vives
   - **Focus visible** : Indicateur clair sur élément actif
   - **Icônes** : Versions haute visibilité

3. **Tailles de texte ajustables**
   - **Respect paramètres système** : Flutter MediaQuery.textScaleFactor
   - **Support jusqu'à 200%** : Mise en page adapté aux grands textes
   - **Pas de débordement** : Layout flexible avec Expanded/Flexible

4. **Alternatives gestes complexes**
   - **Swipe gauche/droite** → Boutons "❤️" et "❌" visibles en mode accessibilité
   - **Drag & drop photos** → Boutons de réorganisation (↑↓)
   - **Long press** → Menu contextuel avec bouton d'accès
   - **Double tap** → Bouton d'action principale

5. **Page paramètres accessibilité**
   - Toggle mode contraste élevé
   - Toggle mode boutons (au lieu de swipes)
   - Slider taille texte (100%-200%)
   - Toggle animations réduites
   - Toggle vibrations haptiques

6. **Annonces Live Regions**
   - Notifications de match en temps réel
   - Erreurs de validation de formulaires
   - Statuts de chargement

**Code Flutter d'exemple:**

```dart
// lib/core/services/accessibility_service.dart
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilityService extends ChangeNotifier {
  static final AccessibilityService _instance = AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();

  SharedPreferences? _prefs;
  
  bool _highContrastMode = false;
  bool _buttonModeEnabled = false;
  bool _reducedAnimations = false;
  double _textScaleFactor = 1.0;

  bool get highContrastMode => _highContrastMode;
  bool get buttonModeEnabled => _buttonModeEnabled;
  bool get reducedAnimations => _reducedAnimations;
  double get textScaleFactor => _textScaleFactor;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _highContrastMode = _prefs?.getBool('high_contrast_mode') ?? false;
    _buttonModeEnabled = _prefs?.getBool('button_mode_enabled') ?? false;
    _reducedAnimations = _prefs?.getBool('reduced_animations') ?? false;
    _textScaleFactor = _prefs?.getDouble('text_scale_factor') ?? 1.0;
    notifyListeners();
  }

  Future<void> setHighContrastMode(bool enabled) async {
    _highContrastMode = enabled;
    await _prefs?.setBool('high_contrast_mode', enabled);
    notifyListeners();
  }

  Future<void> setButtonMode(bool enabled) async {
    _buttonModeEnabled = enabled;
    await _prefs?.setBool('button_mode_enabled', enabled);
    notifyListeners();
  }

  Future<void> setTextScaleFactor(double factor) async {
    _textScaleFactor = factor;
    await _prefs?.setDouble('text_scale_factor', factor);
    notifyListeners();
  }

  // Annoncer message aux lecteurs d'écran
  void announce(String message, {TextDirection textDirection = TextDirection.ltr}) {
    SemanticsService.announce(message, textDirection);
  }
}

// lib/core/theme/accessible_theme.dart
import 'package:flutter/material.dart';

class AccessibleTheme {
  static ThemeData getHighContrastTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: Colors.black,
      scaffoldBackgroundColor: Colors.white,
      
      // Texte noir sur fond blanc
      textTheme: const TextTheme(
        headline1: TextStyle(
          color: Colors.black,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        bodyText1: TextStyle(
          color: Colors.black,
          fontSize: 18,
        ),
        bodyText2: TextStyle(
          color: Colors.black,
          fontSize: 16,
        ),
      ),
      
      // Boutons avec bordures épaisses
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.black, width: 3),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      
      // Focus visible
      focusColor: Colors.blue,
      hoverColor: Colors.blue.withOpacity(0.1),
    );
  }
}

// Exemple : Widget de profil avec accessibilité
class ProfileCardAccessible extends StatelessWidget {
  final Profile profile;
  final VoidCallback onLike;
  final VoidCallback onPass;

  const ProfileCardAccessible({
    required this.profile,
    required this.onLike,
    required this.onPass,
  });

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService();
    
    return Semantics(
      label: 'Profil de ${profile.firstName}, ${profile.age} ans, ${profile.city}',
      child: Column(
        children: [
          // Image avec description
          Semantics(
            label: 'Photo de profil de ${profile.firstName}',
            image: true,
            child: Image.network(profile.photoUrl),
          ),
          
          // Informations
          Semantics(
            label: 'Bio: ${profile.bio}',
            readOnly: true,
            child: Text(profile.bio),
          ),
          
          // Prompts avec Semantics
          ...profile.prompts.map((prompt) => Semantics(
            label: '${prompt.question}: ${prompt.answer}',
            readOnly: true,
            child: PromptWidget(prompt: prompt),
          )),
          
          // Boutons en mode accessibilité
          if (accessibilityService.buttonModeEnabled)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Semantics(
                  label: 'Passer ce profil',
                  button: true,
                  onTapHint: 'Appuyez pour passer',
                  child: ElevatedButton.icon(
                    onPressed: onPass,
                    icon: Icon(Icons.close),
                    label: Text('Passer'),
                  ),
                ),
                Semantics(
                  label: 'J\'aime ce profil',
                  button: true,
                  onTapHint: 'Appuyez pour aimer',
                  child: ElevatedButton.icon(
                    onPressed: () {
                      onLike();
                      accessibilityService.announce(
                        'Profil de ${profile.firstName} aimé',
                      );
                    },
                    icon: Icon(Icons.favorite),
                    label: Text('J\'aime'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// Page paramètres accessibilité
class AccessibilitySettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final service = AccessibilityService();
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Accessibilité'),
      ),
      body: ListView(
        children: [
          Semantics(
            label: 'Mode contraste élevé',
            toggled: service.highContrastMode,
            child: SwitchListTile(
              title: Text('Mode contraste élevé'),
              subtitle: Text('Couleurs haute visibilité'),
              value: service.highContrastMode,
              onChanged: (value) => service.setHighContrastMode(value),
            ),
          ),
          
          Semantics(
            label: 'Mode boutons',
            toggled: service.buttonModeEnabled,
            child: SwitchListTile(
              title: Text('Mode boutons'),
              subtitle: Text('Boutons au lieu de swipes'),
              value: service.buttonModeEnabled,
              onChanged: (value) => service.setButtonMode(value),
            ),
          ),
          
          Semantics(
            label: 'Taille du texte: ${service.textScaleFactor.toStringAsFixed(1)}',
            slider: true,
            child: ListTile(
              title: Text('Taille du texte'),
              subtitle: Slider(
                value: service.textScaleFactor,
                min: 1.0,
                max: 2.0,
                divisions: 10,
                label: '${(service.textScaleFactor * 100).round()}%',
                onChanged: (value) => service.setTextScaleFactor(value),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Intégration dans MaterialApp:**

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService();
    
    return MaterialApp(
      theme: accessibilityService.highContrastMode
          ? AccessibleTheme.getHighContrastTheme()
          : AppTheme.lightTheme,
      
      // Respecter les paramètres système
      builder: (context, child) {
        final mediaQueryData = MediaQuery.of(context);
        final scaleFactor = accessibilityService.textScaleFactor;
        
        return MediaQuery(
          data: mediaQueryData.copyWith(
            textScaleFactor: mediaQueryData.textScaleFactor * scaleFactor,
          ),
          child: child!,
        );
      },
      
      home: HomePage(),
    );
  }
}
```

**Critères d'acceptation:**
- [ ] Tous les widgets interactifs ont des Semantics labels
- [ ] Toutes les images ont des descriptions alternatives
- [ ] Navigation VoiceOver/TalkBack logique sur toutes les pages
- [ ] Mode contraste élevé fonctionnel avec ratio ≥7:1
- [ ] Tailles de texte ajustables de 100% à 200% sans débordement
- [ ] Mode boutons comme alternative aux swipes
- [ ] Boutons de réorganisation pour alternative au drag & drop
- [ ] Page paramètres accessibilité complète
- [ ] Annonces Live Regions pour événements importants (match, message)
- [ ] Focus visible sur tous les éléments interactifs
- [ ] Tests réussis avec VoiceOver (iOS) et TalkBack (Android)
- [ ] Conformité WCAG 2.1 niveau AA vérifiée

---

### Issue Frontend #14: Améliorations UX/UI avancées

**Priorité**: Normale 🔧  
**Estimation**: 4-5 jours  
**Module**: UX/UI (specifications.md §7)  
**Fichiers concernés**:
- `lib/core/theme/animations.dart` (créer)
- `lib/core/services/haptic_service.dart` (créer)
- `lib/features/onboarding/widgets/onboarding_tips.dart` (créer)
- `lib/core/theme/dark_theme.dart` (finaliser)
- `lib/features/matching/widgets/profile_card_animated.dart` (modifier)

**Contexte (specifications.md §7):**
> "Technologie Calme ('Calm Technology') : Design minimaliste, couleurs douces, animations subtiles."  
> "L'application doit être agréable visuellement et facile à prendre en main."

**Description:**
Améliorer l'expérience utilisateur avec des animations fluides, un feedback haptique approprié, un mode sombre complet, des micro-interactions engageantes et un onboarding contextuel avec tips. L'objectif est de rendre l'application non seulement fonctionnelle mais aussi délicieuse à utiliser tout en respectant les principes de "Calm Technology".

**État actuel du code:**
- ✅ Thème clair avec couleurs douces implémenté
- ⚠️ Thème sombre existant mais incomplet
- ❌ Pas d'animations de transition entre pages
- ❌ Pas de feedback haptique sur interactions importantes
- ❌ Pas de micro-interactions (like button animation, etc.)
- ❌ Pas de tips contextuels pour onboarding
- ❌ Pas d'animations de chargement custom

**Comportement attendu:**

1. **Animations fluides et subtiles (Calm Technology)**
   - Transitions de pages : Slide de droite à gauche (250ms, Curves.easeInOut)
   - Card flip : Animation 3D quand l'utilisateur explore les photos
   - Like animation : Cœur qui pulse lors du like
   - Match celebration : Confetti + cœurs lors d'un match
   - Skeleton loading : Shimmer effect pendant chargement
   - Pull-to-refresh : Animation custom avec logo GoldWen

2. **Feedback haptique**
   - Light impact : Swipe
   - Medium impact : Like/pass
   - Heavy impact : Match  
   - Selection : Paramètres
   - Success/Error patterns

3. **Mode sombre OLED-friendly**
   - Pure black (#000000) pour backgrounds
   - Contraste ≥4.5:1
   - Transition douce

4. **Onboarding contextuel**
   - First-time tips avec coach marks
   - Progress tracking
   - Completion celebration
   - In-app hints contextuels

5. **Micro-interactions**
   - Button press : Scale 0.95
   - Notification badge pulse
   - Empty states personnalisés
   - Success toasts animés

**Code Flutter (complet dans backup):**

**Critères d'acceptation:**
- [ ] Transitions fluides 250ms toutes pages
- [ ] Like button animation pulse
- [ ] Match celebration confetti + vibration
- [ ] Skeleton shimmer loading
- [ ] Pull-to-refresh custom
- [ ] Haptic feedback toutes actions
- [ ] Mode sombre OLED contraste ≥4.5:1
- [ ] Tips première utilisation
- [ ] Progress bar onboarding
- [ ] Empty states illustrations
- [ ] Micro-interactions boutons
- [ ] Pinch zoom photos
- [ ] Animations Calm Technology
- [ ] Tests utilisateurs validés (5+)

---


### Issue Frontend #15: Tests et validation complète

**Priorité**: Importante ⚡  
**Estimation**: 5-7 jours  
**Module**: Qualité (specifications.md §5)  
**Fichiers concernés**:
- `test/` (créer tests unitaires)
- `integration_test/` (créer tests intégration)
- `test/mocks/` (créer mocks)
- `.github/workflows/flutter_ci.yml` (CI/CD)

**Contexte (specifications.md §5):**
> "Tests unitaires et d'intégration obligatoires."  
> "Coverage minimum 70% avant mise en production."

**Description:**
Créer une suite de tests complète couvrant unitaires, widgets, intégration et E2E pour garantir la qualité avant production. Tests automatisés dans CI/CD.

**État actuel du code:**
- ❌ Pas de tests unitaires
- ❌ Pas de tests widgets  
- ❌ Pas de tests intégration
- ❌ Pas de CI/CD configuré
- ❌ Coverage 0%

**Comportement attendu:**

1. **Tests unitaires (Coverage >70%)**
   - Providers : MatchingProvider, AuthProvider, SubscriptionProvider
   - Services : ApiService, CacheService, FirebaseService
   - Validators : EmailValidator, PromptsValidator
   - Utils : DateUtils, StringUtils

2. **Tests widgets**
   - Pages critiques : DailySelectionPage, ChatPage, ProfilePage
   - Formulaires : PromptsForm, ProfileSetupForm
   - Widgets custom : ProfileCard, PromptWidget

3. **Tests intégration**
   - Flow onboarding complet (signup → questionnaire → prompts → sélection)
   - Flow matching (sélection → like → match → chat)
   - Flow chat (envoi message → réception → expiration)

4. **Tests E2E**
   - User journey complet
   - Tests platform-specific (iOS/Android)

5. **CI/CD**
   - GitHub Actions
   - Tests automatiques sur PR
   - Build checks
   - Coverage reports

**Code exemple tests (complet dans backup):**

**Critères d'acceptation:**
- [ ] Coverage globale >70%
- [ ] Tests providers critiques 100%
- [ ] Tests widgets pages majeures
- [ ] Tests intégration 3 flows
- [ ] Tests E2E user journey
- [ ] CI/CD configuré GitHub Actions
- [ ] Tests auto sur chaque PR
- [ ] Coverage report automatique
- [ ] Tests passent 100% localement
- [ ] Documentation tests README
- [ ] Mocks propres et réutilisables
- [ ] Tests rapides (<2min total)

---

## 📊 RÉSUMÉ DES ISSUES FRONTEND (COMPLET)

**Total**: 15 issues  
**Estimation totale**: 35-45 jours  
**Modules concernés**: Tous modules MVP + V2  

**Répartition par priorité**:
- 🔥 **Critiques** (Issues #1-5): 15-21 jours
- ⚡ **Importantes** (Issues #6, #10, #15): 11-15 jours
- 🔧 **Normales** (Issues #7-9, #11-14): 17-24 jours

**Routes backend impliquées**: 35+ endpoints  
**État actuel**: 78% complet, infrastructure en place  

**Ordre d'implémentation recommandé**:
1. **Phase 1 - MVP Critique** (Issues #1-5): Prompts, Quotas, Matches, Chat, Photos
2. **Phase 2 - MVP Important** (Issues #6, #10): Notifications, RGPD
3. **Phase 3 - Finitions** (Issues #7-9, #11-12): Pages secondaires, Feedback
4. **Phase 4 - Polish** (Issues #13-15): Accessibilité, UX, Tests

---

*Document complet prêt pour création d'issues GitHub individuelles*  
*Chaque issue peut être assignée à un développeur Flutter avec specs complètes*  
*Total 15 issues couvrant 100% des fonctionnalités manquantes*
