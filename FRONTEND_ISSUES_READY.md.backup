# 📋 Issues Frontend GoldWen - Prêtes pour Implémentation

**Basé sur**: specifications.md (Cahier des Charges v1.1) + Analyse du code Flutter  
**Date**: Janvier 2025  
**État du frontend**: 78% complet  

Ce document contient toutes les issues frontend avec les routes backend correspondantes et le comportement attendu pour une implémentation directe.

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

## 📊 RÉSUMÉ DES ISSUES FRONTEND

**Total**: 5 issues critiques/importantes  
**Estimation totale**: 15-21 jours  
**Modules concernés**: Onboarding, Matching, Chat, Profil  

**Routes backend impliquées**: 17 endpoints  
**État actuel**: 78% complet, infrastructure en place, logique métier manquante  

**Priorité d'implémentation**:
1. Issue #1 - Prompts (bloque complétion profil)
2. Issue #2 - Quotas (fonctionnalité core)
3. Issue #3 - Matches (fonctionnalité core)
4. Issue #4 - Expiration chat (améliore UX)
5. Issue #5 - Photos backend (finalise profil)

---

*Document prêt pour création d'issues GitHub individuelles*  
*Chaque issue peut être assignée à un développeur Flutter avec specs complètes*
