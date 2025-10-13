# 📱 TÂCHES FRONTEND - GoldWen App

**Date de création**: 13 octobre 2025  
**Basé sur**: specifications.md v1.1 + Analyse complète du code (FRONTEND_FEATURES_ANALYSIS.md)  
**État actuel**: 78% de complétude (infrastructure technique)  
**Temps estimé total**: 33-47 jours de développement

---

## 📊 RÉSUMÉ EXÉCUTIF

Le frontend GoldWen présente une architecture solide avec 78% de l'infrastructure en place. Les tâches restantes concernent principalement :
- **Logique métier core** (40% complète)
- **Fonctionnalités utilisateur** (60% complètes)
- **Intégrations backend** (60% complètes)

**Code existant analysé**: 109 fichiers .dart, 15 modules, 10 providers, 12 services, 37 pages

---

## 🎯 PRIORITÉS DE DÉVELOPPEMENT

### 🔥 PRIORITÉ 1 - FONCTIONNALITÉS CRITIQUES (MVP BLOQUANTES)
**Temps estimé**: 15-20 jours

### ⚡ PRIORITÉ 2 - FONCTIONNALITÉS IMPORTANTES
**Temps estimé**: 10-15 jours

### 🔧 PRIORITÉ 3 - AMÉLIORATIONS ET OPTIMISATIONS
**Temps estimé**: 8-12 jours

---

# 🔥 PRIORITÉ 1 - CRITIQUES (MVP BLOQUANTES)

## MODULE 1 : GESTION DES PHOTOS DE PROFIL

### Tâche #1.1 : Finaliser l'intégration backend des photos
**Estimation**: 2-3 jours  
**Priorité**: 🔥 Critique  
**État actuel**: ✅ UI complète (drag & drop implémenté), ⚠️ Backend à finaliser

**Fichiers concernés**:
- `lib/features/profile/pages/photo_management_page.dart` (existant)
- `lib/features/profile/widgets/photo_management_widget.dart` (existant)
- `lib/features/profile/providers/profile_provider.dart` (existant)

**Fonctionnalités à compléter**:
- [ ] Finaliser l'upload multipart/form-data vers le backend
- [ ] Implémenter la compression d'images côté client avant upload
- [ ] Gérer les états de chargement (loading, success, error)
- [ ] Synchroniser l'ordre des photos après drag & drop
- [ ] Définir une photo principale (première position = principale)
- [ ] Gérer la suppression avec confirmation

**Routes backend attendues**:

```http
POST /api/v1/profiles/me/photos
Content-Type: multipart/form-data
Body: photos (1-6 fichiers)
Response: {
  "success": boolean,
  "photos": [{
    "id": string,
    "url": string,
    "order": number,
    "isPrimary": boolean
  }]
}
```

```http
PUT /api/v1/profiles/me/photos/:photoId/order
Body: { "newOrder": number }
Response: { "success": boolean }
```

```http
PUT /api/v1/profiles/me/photos/:photoId/primary
Response: { "success": boolean }
```

```http
DELETE /api/v1/profiles/me/photos/:photoId
Response: { "success": boolean }
```

**Critères d'acceptation**:
- ✅ L'utilisateur peut uploader 1 à 6 photos
- ✅ Les photos sont compressées automatiquement (max 1MB chacune)
- ✅ Le drag & drop réorganise les photos et synchronise avec le backend
- ✅ La première photo est automatiquement définie comme principale
- ✅ Les états de chargement sont affichés pendant l'upload
- ✅ Messages d'erreur clairs en cas d'échec

---

### Tâche #1.2 : Validation minimum 3 photos obligatoires
**Estimation**: 1 jour  
**Priorité**: 🔥 Critique  
**État actuel**: ⚠️ Logique partielle présente

**Fichiers concernés**:
- `lib/features/profile/providers/profile_provider.dart`
- `lib/features/profile/pages/profile_setup_page.dart`

**Fonctionnalités à implémenter**:
- [ ] Bloquer la progression si moins de 3 photos
- [ ] Afficher un indicateur "X/3 photos minimum"
- [ ] Message d'alerte si tentative de continuer sans 3 photos
- [ ] Intégrer avec la vérification de complétude du profil

**Routes backend attendues**:

```http
GET /api/v1/profiles/completion
Response: {
  "isComplete": boolean,
  "completionPercentage": number,
  "requirements": {
    "minimumPhotos": {
      "required": 3,
      "current": number,
      "satisfied": boolean
    },
    "minimumPrompts": {
      "required": 3,
      "current": number,
      "satisfied": boolean
    },
    "personalityQuestionnaire": {
      "required": true,
      "completed": boolean,
      "satisfied": boolean
    }
  }
}
```

**Critères d'acceptation**:
- ✅ Le bouton "Continuer" est désactivé si moins de 3 photos
- ✅ Un indicateur visuel montre "X/3 photos ajoutées"
- ✅ Un message clair explique pourquoi on ne peut pas continuer
- ✅ La vérification backend est appelée avant de rendre le profil visible

---

## MODULE 2 : SYSTÈME DE PROMPTS TEXTUELS

### Tâche #2.1 : Créer l'interface de sélection des prompts
**Estimation**: 3-4 jours  
**Priorité**: 🔥 Critique  
**État actuel**: 🚨 À créer (structure de base présente dans profile_setup_page)

**Fichiers à créer**:
- `lib/features/profile/widgets/prompt_selection_widget.dart`
- `lib/features/profile/pages/prompts_management_page.dart`

**Fichiers à modifier**:
- `lib/features/profile/pages/profile_setup_page.dart`
- `lib/features/profile/providers/profile_provider.dart`

**Fonctionnalités à implémenter**:
- [ ] Charger la liste des prompts disponibles depuis le backend
- [ ] Interface de sélection avec recherche/filtrage
- [ ] Interface de réponse aux prompts (TextField avec compteur de caractères)
- [ ] Validation : 3 prompts obligatoires avec réponses complètes
- [ ] Sauvegarde des réponses vers le backend
- [ ] Possibilité de modifier les prompts choisis

**Routes backend attendues**:

```http
GET /api/v1/profiles/prompts
Response: {
  "prompts": [{
    "id": string,
    "question": string,
    "category": "personality|interests|lifestyle|values",
    "isActive": boolean
  }]
}
```

```http
POST /api/v1/profiles/me/prompt-answers
Body: {
  "answers": [{
    "promptId": string,
    "answer": string (max 150 caractères)
  }]
}
Response: { "success": boolean }
```

```http
GET /api/v1/profiles/me
Response: {
  "profile": {
    "promptAnswers": [{
      "id": string,
      "promptId": string,
      "prompt": {
        "question": string,
        "category": string
      },
      "answer": string
    }]
  }
}
```

```http
PUT /api/v1/profiles/me/prompt-answers
Body: {
  "answers": [{
    "id": string,
    "promptId": string,
    "answer": string
  }]
}
Response: { "success": boolean }
```

**Critères d'acceptation**:
- ✅ L'utilisateur voit une liste de prompts disponibles
- ✅ Il peut choisir 3 prompts minimum
- ✅ Il peut répondre à chaque prompt (max 150 caractères)
- ✅ Un compteur de caractères est visible
- ✅ Les 3 réponses sont obligatoires pour continuer
- ✅ Les prompts sont affichés sur le profil utilisateur
- ✅ L'utilisateur peut modifier ses prompts depuis les paramètres

---

## MODULE 3 : SÉLECTION QUOTIDIENNE ET QUOTAS

### Tâche #3.1 : Implémenter la logique de quotas de sélection quotidienne
**Estimation**: 3-4 jours  
**Priorité**: 🔥 Critique  
**État actuel**: ⚠️ Structure présente, logique incomplète

**Fichiers concernés**:
- `lib/features/matching/pages/daily_matches_page.dart`
- `lib/features/matching/providers/matching_provider.dart`
- `lib/features/subscription/providers/subscription_provider.dart`

**Fonctionnalités à implémenter**:
- [ ] Charger l'usage quotidien depuis le backend
- [ ] Afficher "X/1 choix disponible" (gratuit) ou "X/3 choix disponibles" (premium)
- [ ] Bloquer la sélection si quota atteint
- [ ] Afficher une bannière "Upgrade pour choisir 3 profils" si utilisateur gratuit
- [ ] Masquer les profils non sélectionnés après avoir fait son/ses choix
- [ ] Message de confirmation : "Votre choix est fait. Revenez demain à midi !"
- [ ] Gestion du reset quotidien (affichage du timer)

**Routes backend attendues**:

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
```

```http
POST /api/v1/matching/choose/:targetUserId
Body: {
  "choice": "like|pass"
}
Response: {
  "success": boolean,
  "remainingChoices": number,
  "message": string,
  "isMatch": boolean
}
```

```http
GET /api/v1/matching/daily-selection
Response: {
  "selection": [{
    "id": string,
    "user": { /* profil complet */ },
    "compatibilityScore": number,
    "isChosen": boolean
  }],
  "selectionDate": "ISO date string",
  "nextSelectionTime": "ISO date string"
}
```

```http
GET /api/v1/subscriptions/features
Response: {
  "tier": "free|premium",
  "features": {
    "dailyChoices": number,
    "canSeeWhoLikedMe": boolean,
    "canSendUnlimitedLikes": boolean
  }
}
```

**Critères d'acceptation**:
- ✅ Utilisateur gratuit : 1 choix par jour maximum
- ✅ Utilisateur premium : 3 choix par jour maximum
- ✅ L'indicateur "X/Y choix" est visible en haut de page
- ✅ Une bannière upgrade s'affiche quand quota gratuit atteint
- ✅ Les profils non choisis disparaissent après sélection
- ✅ Message de confirmation clair après chaque choix
- ✅ Timer visible indiquant "Prochaine sélection dans Xh Ymin"

---

### Tâche #3.2 : Implémenter le refresh quotidien de la sélection
**Estimation**: 1-2 jours  
**Priorité**: 🔥 Critique  
**État actuel**: 🚨 À implémenter

**Fichiers concernés**:
- `lib/features/matching/providers/matching_provider.dart`
- `lib/features/matching/pages/daily_matches_page.dart`

**Fonctionnalités à implémenter**:
- [ ] Vérifier si une nouvelle sélection est disponible au lancement de l'app
- [ ] Afficher un badge "Nouvelle sélection disponible !" si applicable
- [ ] Charger automatiquement la nouvelle sélection à midi (local time)
- [ ] Afficher un timer compte à rebours jusqu'à la prochaine sélection
- [ ] Empêcher les doubles sélections du même profil

**Routes backend attendues**:

```http
GET /api/v1/matching/daily-selection/status
Response: {
  "hasNewSelection": boolean,
  "lastSelectionDate": "ISO date string",
  "nextSelectionTime": "ISO date string",
  "hoursUntilNext": number
}
```

```http
GET /api/v1/matching/user-choices
Response: {
  "choices": [{
    "userId": string,
    "choiceType": "like|pass",
    "date": "ISO date string"
  }],
  "todayChoicesCount": number
}
```

**Critères d'acceptation**:
- ✅ La sélection se rafraîchit automatiquement à midi (heure locale)
- ✅ Un badge indique quand une nouvelle sélection est disponible
- ✅ Un timer montre le temps restant jusqu'à la prochaine sélection
- ✅ Les profils déjà choisis ne réapparaissent pas
- ✅ L'utilisateur voit un message s'il n'y a pas de nouvelle sélection

---

## MODULE 4 : SYSTÈME DE MATCH

### Tâche #4.1 : Implémenter la logique de match mutuel
**Estimation**: 3-4 jours  
**Priorité**: 🔥 Critique  
**État actuel**: ⚠️ Structure présente, logique incomplète

**Fichiers concernés**:
- `lib/features/matching/pages/matches_page.dart`
- `lib/features/matching/providers/matching_provider.dart`
- `lib/features/chat/providers/chat_provider.dart`

**Fonctionnalités à implémenter**:
- [ ] Détecter quand un match mutuel se produit (A choisit B ET B choisit A)
- [ ] Afficher une notification locale de match
- [ ] Créer automatiquement une conversation accessible
- [ ] Page "Mes matches" affichant tous les matches obtenus
- [ ] Distinction visuelle entre "sélections" et "matches"
- [ ] Badge sur l'onglet Matches indiquant les nouveaux matches

**Routes backend attendues**:

```http
GET /api/v1/matching/matches
Response: {
  "matches": [{
    "id": string,
    "matchedUser": { /* profil complet */ },
    "matchDate": "ISO date string",
    "compatibilityScore": number,
    "hasUnreadMessages": boolean,
    "chatId": string
  }]
}
```

```http
GET /api/v1/matching/matches/:matchId
Response: {
  "match": {
    "id": string,
    "users": [{ /* profils */ }],
    "matchDate": "ISO date string",
    "chatId": string,
    "expiresAt": "ISO date string"
  }
}
```

```http
POST /api/v1/chat/accept/:matchId
Response: {
  "success": boolean,
  "chatId": string,
  "expiresAt": "ISO date string (24h depuis maintenant)"
}
```

```http
GET /api/v1/matching/pending-matches
Response: {
  "pending": [{
    "id": string,
    "user": { /* profil */ },
    "waitingSince": "ISO date string"
  }]
}
```

**Critères d'acceptation**:
- ✅ Un match se produit seulement si A et B se choisissent mutuellement
- ✅ Une notification "Nouveau match !" apparaît immédiatement
- ✅ La page "Matches" affiche tous les matches actifs
- ✅ Chaque match montre le profil, score de compatibilité et date
- ✅ Un badge indique le nombre de nouveaux matches
- ✅ Cliquer sur un match ouvre directement le chat

---

### Tâche #4.2 : Créer la page de notification de match
**Estimation**: 1-2 jours  
**Priorité**: 🔥 Critique  
**État actuel**: 🚨 À créer

**Fichiers à créer**:
- `lib/features/matching/pages/match_notification_page.dart`
- `lib/features/matching/widgets/match_celebration_widget.dart`

**Fonctionnalités à implémenter**:
- [ ] Animation de célébration lors d'un nouveau match
- [ ] Affichage "Félicitations ! Vous avez un match avec [Prénom] !"
- [ ] Bouton "Envoyer un message" (ouvre le chat)
- [ ] Bouton "Voir le profil" (affiche profil complet)
- [ ] Affichage du timer 24h visible

**Routes backend attendues**:
- Utilise les routes existantes des matches (ci-dessus)

**Critères d'acceptation**:
- ✅ Animation fluide et élégante à l'affichage
- ✅ Message de félicitation personnalisé
- ✅ Timer 24h clairement visible
- ✅ Boutons d'action clairs et accessibles
- ✅ Possibilité de fermer et revenir plus tard

---

## MODULE 5 : VALIDATION PROFIL COMPLET

### Tâche #5.1 : Implémenter la validation stricte du profil
**Estimation**: 2 jours  
**Priorité**: 🔥 Critique  
**État actuel**: ⚠️ Structure de base présente

**Fichiers concernés**:
- `lib/features/profile/providers/profile_provider.dart`
- `lib/features/profile/widgets/profile_completion_widget.dart`
- `lib/features/onboarding/pages/profile_setup_page.dart`

**Fonctionnalités à implémenter**:
- [ ] Vérification backend du statut de complétude
- [ ] Blocage de la visibilité du profil si incomplet
- [ ] Barre de progression détaillée (photos, prompts, questionnaire)
- [ ] Messages de guidage pour chaque étape manquante
- [ ] Redirection automatique vers la première étape incomplète

**Routes backend attendues**:

```http
GET /api/v1/profiles/completion
Response: {
  "isComplete": boolean,
  "completionPercentage": number,
  "requirements": {
    "minimumPhotos": {
      "required": 3,
      "current": number,
      "satisfied": boolean
    },
    "minimumPrompts": {
      "required": 3,
      "current": number,
      "satisfied": boolean
    },
    "personalityQuestionnaire": {
      "required": true,
      "completed": boolean,
      "satisfied": boolean
    }
  },
  "missingSteps": [string],
  "nextStep": string
}
```

```http
PUT /api/v1/profiles/me/status
Body: {
  "isVisible": boolean
}
Response: { "success": boolean }
```

**Critères d'acceptation**:
- ✅ Le profil n'est pas visible tant qu'incomplet (3 photos + 3 prompts + questionnaire)
- ✅ Une barre de progression montre "X% complété"
- ✅ Messages clairs indiquent les étapes manquantes
- ✅ Redirection automatique vers l'étape incomplète
- ✅ Une fois complet, le profil devient automatiquement visible

---

# ⚡ PRIORITÉ 2 - IMPORTANTES

## MODULE 6 : NOTIFICATIONS PUSH

### Tâche #6.1 : Implémenter les notifications push quotidiennes
**Estimation**: 3-4 jours  
**Priorité**: ⚡ Importante  
**État actuel**: ✅ Firebase configuré, ⚠️ Logique à compléter

**Fichiers concernés**:
- `lib/core/services/firebase_messaging_service.dart` (existant)
- `lib/features/notifications/providers/notification_provider.dart` (existant)

**Fonctionnalités à implémenter**:
- [ ] Enregistrement du token FCM au backend
- [ ] Gestion des permissions de notification
- [ ] Notification quotidienne à midi : "Votre sélection GoldWen du jour est arrivée !"
- [ ] Notification de match : "Félicitations ! Nouveau match avec [Prénom]"
- [ ] Notification de message : "[Prénom] vous a envoyé un message"
- [ ] Badge sur l'icône de l'app (nombre de matches/messages)
- [ ] Gestion du tap sur notification (deep linking)

**Routes backend attendues**:

```http
POST /api/v1/users/me/push-tokens
Body: {
  "token": string,
  "platform": "ios|android"
}
Response: { "success": boolean }
```

```http
DELETE /api/v1/users/me/push-tokens/:tokenId
Response: { "success": boolean }
```

```http
POST /api/v1/notifications/trigger-daily-selection
(Cron Job backend - pas d'appel direct frontend)
```

```http
PUT /api/v1/notifications/settings
Body: {
  "dailySelection": boolean,
  "newMatches": boolean,
  "newMessages": boolean,
  "chatExpiringSoon": boolean
}
Response: { "success": boolean }
```

```http
GET /api/v1/notifications/settings
Response: {
  "settings": {
    "dailySelection": boolean,
    "newMatches": boolean,
    "newMessages": boolean,
    "chatExpiringSoon": boolean
  }
}
```

**Critères d'acceptation**:
- ✅ L'app demande la permission de notifications au bon moment
- ✅ Notification quotidienne reçue à midi (heure locale)
- ✅ Notification immédiate lors d'un nouveau match
- ✅ Badge visible sur l'icône de l'app
- ✅ Tap sur notification navigue vers le bon écran
- ✅ Paramètres pour activer/désactiver chaque type de notification

---

## MODULE 7 : CHAT AVEC EXPIRATION 24H

### Tâche #7.1 : Implémenter l'expiration automatique des chats
**Estimation**: 2-3 jours  
**Priorité**: ⚡ Importante  
**État actuel**: ✅ Timer UI implémenté, ⚠️ Logique d'expiration à compléter

**Fichiers concernés**:
- `lib/features/chat/pages/chat_page.dart`
- `lib/features/chat/providers/chat_provider.dart`

**Fonctionnalités à implémenter**:
- [ ] Vérifier le statut d'expiration à chaque chargement du chat
- [ ] Bloquer l'envoi de messages si chat expiré
- [ ] Afficher "Cette conversation a expiré" si 24h dépassées
- [ ] Notification 2h avant expiration : "Votre chat avec [Prénom] expire dans 2h"
- [ ] Archiver automatiquement les chats expirés
- [ ] Page "Chats archivés" (lecture seule)

**Routes backend attendues**:

```http
GET /api/v1/chat/:chatId
Response: {
  "chat": {
    "id": string,
    "matchId": string,
    "participants": [{ /* users */ }],
    "createdAt": "ISO date string",
    "expiresAt": "ISO date string",
    "isExpired": boolean,
    "status": "active|expired|archived"
  }
}
```

```http
POST /api/v1/chat/:chatId/messages
Body: {
  "content": string,
  "type": "text|emoji|system"
}
Response: {
  "message": { /* message complet */ }
}
Error 403: { "error": "Chat expired" }
```

```http
PUT /api/v1/chat/:chatId/expire
(Cron Job backend - appelé automatiquement après 24h)
```

```http
GET /api/v1/chat/archived
Response: {
  "archivedChats": [{
    "id": string,
    "participants": [{ /* users */ }],
    "lastMessage": { /* message */ },
    "expiredAt": "ISO date string"
  }]
}
```

**Critères d'acceptation**:
- ✅ Le timer 24h est visible en permanence dans le chat
- ✅ Impossible d'envoyer des messages après expiration
- ✅ Message système clair : "Cette conversation a expiré"
- ✅ Notification 2h avant expiration
- ✅ Les chats expirés sont automatiquement archivés
- ✅ Possibilité de consulter les chats archivés (lecture seule)

---

## MODULE 8 : PAGE DE MATCHES

### Tâche #8.1 : Créer la page complète des matches
**Estimation**: 2-3 jours  
**Priorité**: ⚡ Importante  
**État actuel**: ✅ Structure de base présente

**Fichiers concernés**:
- `lib/features/matching/pages/matches_page.dart`
- `lib/features/matching/widgets/match_card_widget.dart`

**Fonctionnalités à implémenter**:
- [ ] Liste de tous les matches actifs
- [ ] Affichage du score de compatibilité
- [ ] Indication du temps restant pour chaque chat (24h)
- [ ] Badge "Non lu" si nouveaux messages
- [ ] Filtres : "Actifs", "Expire bientôt", "Archivés"
- [ ] Swipe pour archiver manuellement un match
- [ ] État vide élégant si aucun match

**Routes backend attendues**:
- Utilise `GET /api/v1/matching/matches` (voir Tâche #4.1)

**Critères d'acceptation**:
- ✅ Tous les matches sont affichés avec photo et prénom
- ✅ Score de compatibilité visible (ex: "87% compatibles")
- ✅ Timer visible montrant le temps restant
- ✅ Badge sur les chats non lus
- ✅ Filtres fonctionnels
- ✅ Message élégant si aucun match

---

## MODULE 9 : CONFORMITÉ RGPD (Fonctionnalités de base)

### Tâche #9.1 : Implémenter le consentement explicite
**Estimation**: 1-2 jours  
**Priorité**: ⚡ Importante (Légalement obligatoire)  
**État actuel**: 🚨 À implémenter

**Fichiers à créer**:
- `lib/features/legal/pages/consent_page.dart`
- `lib/features/legal/widgets/consent_modal.dart`

**Fonctionnalités à implémenter**:
- [ ] Modal de consentement à la première inscription
- [ ] Checkboxes pour différents types de consentement
- [ ] Liens vers politique de confidentialité et CGU
- [ ] Enregistrement du consentement au backend
- [ ] Impossibilité de continuer sans consentement

**Routes backend attendues**:

```http
POST /api/v1/users/consent
Body: {
  "dataProcessing": boolean,
  "marketing": boolean,
  "analytics": boolean,
  "timestamp": "ISO date string"
}
Response: { "success": boolean }
```

```http
GET /api/v1/legal/privacy-policy
Query: ?version=latest&format=json
Response: {
  "version": string,
  "content": string,
  "lastUpdated": "ISO date string"
}
```

**Critères d'acceptation**:
- ✅ Modal de consentement s'affiche à la première inscription
- ✅ Tous les consentements obligatoires doivent être acceptés
- ✅ Liens cliquables vers politique de confidentialité et CGU
- ✅ Impossibilité de continuer sans accepter
- ✅ Consentement enregistré avec timestamp

---

### Tâche #9.2 : Créer la page de suppression de compte
**Estimation**: 1-2 jours  
**Priorité**: ⚡ Importante (Droit à l'oubli)  
**État actuel**: 🚨 À implémenter

**Fichiers à créer**:
- `lib/features/settings/pages/delete_account_page.dart`

**Fichiers à modifier**:
- `lib/features/settings/pages/settings_page.dart`

**Fonctionnalités à implémenter**:
- [ ] Bouton "Supprimer mon compte" dans les paramètres
- [ ] Page d'avertissement avec conséquences de la suppression
- [ ] Confirmation par mot de passe ou biométrie
- [ ] Double confirmation ("Êtes-vous sûr ?")
- [ ] Appel backend pour suppression complète
- [ ] Déconnexion et redirection vers page d'accueil

**Routes backend attendues**:

```http
DELETE /api/v1/users/me
Body: {
  "password": string,
  "confirmationText": "DELETE"
}
Response: { 
  "success": boolean,
  "message": "Account deleted successfully"
}
```

**Critères d'acceptation**:
- ✅ Bouton accessible depuis les paramètres
- ✅ Page d'avertissement listant les conséquences
- ✅ Confirmation par mot de passe
- ✅ Double confirmation requise
- ✅ Suppression complète des données (backend)
- ✅ Déconnexion automatique et redirection

---

### Tâche #9.3 : Implémenter l'export de données utilisateur
**Estimation**: 1-2 jours  
**Priorité**: ⚡ Importante (RGPD obligatoire)  
**État actuel**: 🚨 À implémenter

**Fichiers à créer**:
- `lib/features/settings/pages/export_data_page.dart`

**Fonctionnalités à implémenter**:
- [ ] Bouton "Télécharger mes données" dans les paramètres
- [ ] Demande de génération au backend
- [ ] Affichage du statut de génération (en cours, prêt)
- [ ] Téléchargement du fichier JSON/PDF
- [ ] Notification quand l'export est prêt

**Routes backend attendues**:

```http
POST /api/v1/users/me/export-data
Response: {
  "exportId": string,
  "status": "processing",
  "estimatedTime": number (en secondes)
}
```

```http
GET /api/v1/users/me/export-data/:exportId
Response: {
  "status": "processing|ready|failed",
  "downloadUrl": string (si ready),
  "expiresAt": "ISO date string"
}
```

**Critères d'acceptation**:
- ✅ Bouton accessible depuis les paramètres
- ✅ L'utilisateur peut demander un export
- ✅ Indicateur de progression visible
- ✅ Notification quand l'export est prêt
- ✅ Téléchargement direct du fichier
- ✅ Export contient toutes les données personnelles

---

## MODULE 10 : AMÉLIORATIONS UX CRITIQUES

### Tâche #10.1 : Implémenter les états de chargement cohérents
**Estimation**: 2 jours  
**Priorité**: ⚡ Importante  
**État actuel**: ⚠️ Partiellement implémenté

**Fichiers concernés**:
- Tous les fichiers de pages et widgets

**Fonctionnalités à implémenter**:
- [ ] Skeleton loaders pour toutes les listes
- [ ] Shimmer effect pendant le chargement
- [ ] Spinners cohérents (couleur or, taille appropriée)
- [ ] États de chargement pour les images
- [ ] Feedback visuel sur les boutons d'action

**Critères d'acceptation**:
- ✅ Tous les écrans affichent un skeleton pendant le chargement
- ✅ Les images ont un placeholder élégant
- ✅ Les boutons montrent un spinner pendant l'action
- ✅ Cohérence visuelle dans toute l'application
- ✅ Transitions fluides entre états

---

### Tâche #10.2 : Améliorer la gestion d'erreurs
**Estimation**: 2-3 jours  
**Priorité**: ⚡ Importante  
**État actuel**: ⚠️ Basique

**Fichiers concernés**:
- `lib/core/utils/error_handler.dart` (à créer)
- Tous les providers

**Fonctionnalités à implémenter**:
- [ ] Messages d'erreur informatifs et non techniques
- [ ] Actions de récupération (Réessayer, Annuler, Support)
- [ ] Gestion des erreurs réseau (offline, timeout)
- [ ] Logging des erreurs pour debugging
- [ ] Snackbars/dialogs cohérents pour les erreurs

**Critères d'acceptation**:
- ✅ Messages d'erreur clairs et compréhensibles
- ✅ Bouton "Réessayer" fonctionnel
- ✅ Gestion du mode hors-ligne gracieuse
- ✅ Logging des erreurs (console + backend si critique)
- ✅ Design cohérent pour tous les messages d'erreur

---

# 🔧 PRIORITÉ 3 - AMÉLIORATIONS ET OPTIMISATIONS

## MODULE 11 : PAGES ADDITIONNELLES

### Tâche #11.1 : Créer la page de signalement
**Estimation**: 1-2 jours  
**Priorité**: 🔧 Normale  
**État actuel**: ⚠️ Provider présent, page à créer

**Fichiers à créer**:
- `lib/features/reports/pages/report_page.dart`
- `lib/features/reports/widgets/report_form_widget.dart`

**Fonctionnalités à implémenter**:
- [ ] Formulaire de signalement (profil ou message)
- [ ] Catégories : Contenu inapproprié, Harcèlement, Spam, Autre
- [ ] Champ de description (optionnel)
- [ ] Envoi du signalement au backend
- [ ] Confirmation de soumission

**Routes backend attendues**:

```http
POST /api/v1/reports
Body: {
  "targetType": "user|message",
  "targetId": string,
  "reason": "inappropriate_content|harassment|spam|fake_profile|other",
  "description": string (optionnel)
}
Response: { 
  "success": boolean,
  "reportId": string 
}
```

**Critères d'acceptation**:
- ✅ Accessible depuis le profil ou le chat
- ✅ Catégories claires et complètes
- ✅ Envoi au backend fonctionnel
- ✅ Message de confirmation après soumission
- ✅ Utilisateur ne peut pas signaler plusieurs fois le même contenu

---

### Tâche #11.2 : Créer l'historique des sélections
**Estimation**: 1-2 jours  
**Priorité**: 🔧 Normale  
**État actuel**: ✅ Page présente, logique à compléter

**Fichiers concernés**:
- `lib/features/matching/pages/history_page.dart`

**Fonctionnalités à implémenter**:
- [ ] Liste des sélections quotidiennes passées
- [ ] Affichage des profils vus avec choix (Like/Pass)
- [ ] Filtre par date
- [ ] Indication des matches obtenus

**Routes backend attendues**:

```http
GET /api/v1/matching/history
Query: ?startDate=ISO&endDate=ISO&page=1&limit=20
Response: {
  "history": [{
    "date": "ISO date string",
    "profiles": [{
      "userId": string,
      "user": { /* profil */ },
      "choice": "like|pass",
      "wasMatch": boolean
    }]
  }],
  "pagination": { /* info */ }
}
```

**Critères d'acceptation**:
- ✅ Historique complet des sélections passées
- ✅ Indication claire Like/Pass pour chaque profil
- ✅ Badge "Match" si match obtenu
- ✅ Filtrage par date fonctionnel
- ✅ Pagination efficace

---

### Tâche #11.3 : Créer la page "Qui m'a sélectionné" (Premium)
**Estimation**: 2 jours  
**Priorité**: 🔧 Normale  
**État actuel**: ✅ Page présente, logique à compléter

**Fichiers concernés**:
- `lib/features/matching/pages/who_liked_me_page.dart`
- `lib/features/subscription/providers/subscription_provider.dart`

**Fonctionnalités à implémenter**:
- [ ] Vérification du statut premium
- [ ] Affichage flouté si utilisateur gratuit
- [ ] Bannière upgrade si gratuit
- [ ] Liste des utilisateurs ayant sélectionné l'utilisateur
- [ ] Bouton "Voir le profil" pour chaque utilisateur

**Routes backend attendues**:

```http
GET /api/v1/matching/who-liked-me
Requires: Premium subscription
Response: {
  "likedBy": [{
    "userId": string,
    "user": { /* profil */ },
    "likedDate": "ISO date string"
  }]
}
Error 403: { "error": "Premium subscription required" }
```

**Critères d'acceptation**:
- ✅ Accessible uniquement aux utilisateurs premium
- ✅ Profils floutés avec bannière upgrade si gratuit
- ✅ Liste complète des utilisateurs ayant sélectionné
- ✅ Navigation vers profil fonctionnelle
- ✅ Badge indiquant le nombre de nouveaux "likes"

---

## MODULE 12 : SYSTÈME DE FEEDBACK

### Tâche #12.1 : Compléter le système de feedback utilisateur
**Estimation**: 1 jour  
**Priorité**: 🔧 Normale  
**État actuel**: ✅ Provider présent, UI à améliorer

**Fichiers concernés**:
- `lib/features/feedback/pages/feedback_page.dart`
- `lib/features/feedback/providers/feedback_provider.dart`

**Fonctionnalités à implémenter**:
- [ ] Sélection de catégorie (Bug, Feature, Général)
- [ ] Rating optionnel avec étoiles (1-5)
- [ ] Collecte automatique de métadonnées (version, device, OS)
- [ ] Dialog de confirmation après envoi
- [ ] Validation du formulaire

**Routes backend attendues**:

```http
POST /api/v1/feedback
Body: {
  "type": "bug|feature|general",
  "subject": string (max 100 caractères),
  "message": string (max 500 caractères),
  "rating": number (1-5, optionnel),
  "metadata": {
    "appVersion": string,
    "platform": "ios|android",
    "osVersion": string,
    "deviceModel": string
  }
}
Response: { 
  "success": boolean,
  "feedbackId": string 
}
```

**Critères d'acceptation**:
- ✅ Sélection de catégorie intuitive
- ✅ Rating optionnel avec étoiles
- ✅ Métadonnées collectées automatiquement
- ✅ Validation avant envoi
- ✅ Confirmation après soumission

---

## MODULE 13 : OPTIMISATIONS PERFORMANCES

### Tâche #13.1 : Implémenter le lazy loading des images
**Estimation**: 1-2 jours  
**Priorité**: 🔧 Normale  
**État actuel**: ⚠️ Basique

**Fichiers concernés**:
- Tous les widgets affichant des images

**Fonctionnalités à implémenter**:
- [ ] Lazy loading avec package `cached_network_image`
- [ ] Placeholders élégants
- [ ] Cache intelligent des images
- [ ] Compression automatique
- [ ] Gestion de la mémoire

**Critères d'acceptation**:
- ✅ Images chargées progressivement
- ✅ Placeholders cohérents
- ✅ Cache efficace (pas de rechargements inutiles)
- ✅ Consommation mémoire optimisée
- ✅ Performances fluides même avec beaucoup d'images

---

### Tâche #13.2 : Implémenter le mode hors-ligne basique
**Estimation**: 2 jours  
**Priorité**: 🔧 Normale  
**État actuel**: 🚨 Non implémenté

**Fichiers à créer**:
- `lib/core/services/offline_service.dart`
- `lib/core/widgets/offline_banner_widget.dart`

**Fonctionnalités à implémenter**:
- [ ] Détection de la connexion réseau
- [ ] Bannière "Mode hors-ligne" visible
- [ ] Cache local des données consultées
- [ ] Synchronisation à la reconnexion
- [ ] Messages explicatifs pour actions impossibles hors-ligne

**Critères d'acceptation**:
- ✅ Détection immédiate de la perte de connexion
- ✅ Bannière claire indiquant le mode hors-ligne
- ✅ Données en cache accessibles en lecture seule
- ✅ Synchronisation automatique à la reconnexion
- ✅ Messages explicatifs pour actions bloquées

---

## MODULE 14 : ACCESSIBILITÉ

### Tâche #14.1 : Améliorer le support des lecteurs d'écran
**Estimation**: 2 jours  
**Priorité**: 🔧 Normale  
**État actuel**: ⚠️ Partiel

**Fichiers concernés**:
- Tous les widgets et pages

**Fonctionnalités à implémenter**:
- [ ] Semantic labels appropriés pour tous les widgets interactifs
- [ ] Ordre de navigation logique
- [ ] Descriptions alternatives pour les images
- [ ] Hints pour les actions

**Critères d'acceptation**:
- ✅ Tous les boutons ont des labels sémantiques
- ✅ Navigation au clavier/VoiceOver fonctionnelle
- ✅ Images décoratives marquées comme telles
- ✅ Formulaires accessibles avec hints clairs

---

### Tâche #14.2 : Paramètres d'accessibilité
**Estimation**: 1-2 jours  
**Priorité**: 🔧 Normale  
**État actuel**: 🚨 Non implémenté

**Fichiers à créer**:
- `lib/features/settings/pages/accessibility_settings_page.dart`

**Fonctionnalités à implémenter**:
- [ ] Support des tailles de police système
- [ ] Mode contraste élevé
- [ ] Réduction des animations
- [ ] Sauvegarde des préférences

**Routes backend attendues**:

```http
GET /api/v1/users/me/accessibility-settings
Response: {
  "fontSize": "small|medium|large",
  "highContrast": boolean,
  "reduceAnimations": boolean
}
```

```http
PUT /api/v1/users/me/accessibility-settings
Body: {
  "fontSize": "small|medium|large",
  "highContrast": boolean,
  "reduceAnimations": boolean
}
Response: { "success": boolean }
```

**Critères d'acceptation**:
- ✅ Respect des préférences système
- ✅ Options de personnalisation disponibles
- ✅ Préférences sauvegardées et synchronisées
- ✅ Application immédiate des changements

---

# 📊 RÉSUMÉ DES ROUTES BACKEND REQUISES

## Routes existantes à utiliser (31)

### Authentification (3)
- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/social-login`

### Profils (6)
- `GET /api/v1/profiles/me`
- `PUT /api/v1/profiles/me`
- `POST /api/v1/profiles/me/photos`
- `DELETE /api/v1/profiles/me/photos/:photoId`
- `GET /api/v1/profiles/prompts`
- `POST /api/v1/profiles/me/prompt-answers`

### Matching (5)
- `GET /api/v1/matching/daily-selection`
- `POST /api/v1/matching/choose/:targetUserId`
- `GET /api/v1/matching/matches`
- `GET /api/v1/matching/matches/:matchId`

### Chat (4)
- `GET /api/v1/chat`
- `GET /api/v1/chat/:chatId`
- `POST /api/v1/chat/:chatId/messages`
- `GET /api/v1/chat/archived`

### Abonnements (3)
- `GET /api/v1/subscriptions/usage`
- `GET /api/v1/subscriptions/features`
- `GET /api/v1/subscriptions/tier`

### Notifications (3)
- `POST /api/v1/users/me/push-tokens`
- `DELETE /api/v1/users/me/push-tokens/:tokenId`
- `GET /api/v1/notifications/settings`

### Utilisateurs (3)
- `GET /api/v1/users/me`
- `PUT /api/v1/users/me`
- `DELETE /api/v1/users/me`

### Autres (4)
- `GET /api/v1/health`
- `GET /api/v1/legal/privacy-policy`
- `GET /api/v1/legal/terms-of-service`
- `POST /api/v1/feedback`

---

## Nouvelles routes à créer (15)

### Profils (3)
- `PUT /api/v1/profiles/me/photos/:photoId/order` - Réorganiser photos
- `PUT /api/v1/profiles/me/photos/:photoId/primary` - Définir photo principale
- `PUT /api/v1/profiles/me/prompt-answers` - Modifier prompts

### Matching (4)
- `GET /api/v1/matching/daily-selection/status` - Statut nouvelle sélection
- `GET /api/v1/matching/user-choices` - Historique choix quotidiens
- `GET /api/v1/matching/pending-matches` - Matches en attente
- `GET /api/v1/matching/history` - Historique sélections
- `GET /api/v1/matching/who-liked-me` - Qui m'a sélectionné (premium)

### Chat (2)
- `POST /api/v1/chat/accept/:matchId` - Accepter match pour créer chat
- `PUT /api/v1/chat/:chatId/expire` - Expiration manuelle/automatique

### RGPD (3)
- `POST /api/v1/users/consent` - Enregistrer consentement
- `POST /api/v1/users/me/export-data` - Demander export données
- `GET /api/v1/users/me/export-data/:exportId` - Télécharger export

### Autres (3)
- `POST /api/v1/reports` - Signaler contenu
- `PUT /api/v1/notifications/settings` - Paramètres notifications
- `GET /api/v1/users/me/accessibility-settings` - Paramètres accessibilité
- `PUT /api/v1/users/me/accessibility-settings` - Sauvegarder paramètres accessibilité

---

## Routes à modifier/enrichir (8)

### Profils
- `GET /api/v1/profiles/completion` - Ajouter détails requirements et nextStep

### Matching
- `GET /api/v1/matching/daily-selection` - Ajouter filtrage selon choix effectués
- `POST /api/v1/matching/choose/:targetUserId` - Enrichir réponse avec remainingChoices

### Chat
- `POST /api/v1/chat/:chatId/messages` - Ajouter vérification expiration

### Abonnements
- `GET /api/v1/subscriptions/usage` - Ajouter resetTime pour quotas

### Notifications
- `POST /api/v1/notifications/trigger-daily-selection` - Cron job automatique (backend)

### Profils
- `PUT /api/v1/profiles/me/status` - Gérer visibilité profil

### Utilisateurs
- `GET /api/v1/users/me` - Inclure promptAnswers dans réponse

---

# 📈 ESTIMATION TEMPORELLE TOTALE

| Priorité | Modules | Tâches | Temps estimé |
|----------|---------|--------|--------------|
| 🔥 Priorité 1 | 5 | 10 | 15-20 jours |
| ⚡ Priorité 2 | 5 | 10 | 10-15 jours |
| 🔧 Priorité 3 | 4 | 8 | 8-12 jours |
| **TOTAL** | **14** | **28** | **33-47 jours** |

---

# 🎯 CONCLUSION

Le frontend GoldWen App est à **78% de complétude**. L'architecture est solide, le design est en place, mais il reste principalement :

1. **La logique métier core** (gestion photos, prompts, quotas de sélection)
2. **Les fonctionnalités utilisateur critiques** (match mutuel, expiration chat, notifications)
3. **La conformité RGPD** (consentement, export données, suppression compte)
4. **Les optimisations UX** (états de chargement, gestion erreurs, accessibilité)

**Recommandation** : Se concentrer sur la **Priorité 1** (15-20 jours) pour obtenir un MVP fonctionnel, puis compléter progressivement les Priorités 2 et 3 selon les retours utilisateurs.

---

**Document généré le 13 octobre 2025**  
**Basé sur l'analyse complète du code et du cahier des charges specifications.md**
