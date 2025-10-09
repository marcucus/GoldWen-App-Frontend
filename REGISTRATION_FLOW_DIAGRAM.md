# Diagramme de Flux d'Inscription - GoldWen

## Flux Visuel Complet

```
┌─────────────────────────────────────────────────────────────────────┐
│                         NOUVEAU UTILISATEUR                          │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
                        ┌───────────────────────┐
                        │    Welcome Page       │
                        │  "Commencer"          │
                        └───────────────────────┘
                                    │
                                    ▼
                        ┌───────────────────────┐
                        │    Auth Page          │
                        │  Choix méthode auth   │
                        └───────────────────────┘
                                    │
                                    ▼
                        ┌───────────────────────┐
                        │  Email Auth Page      │
                        │  - Prénom             │
                        │  - Nom                │
                        │  - Email              │
                        │  - Mot de passe       │
                        └───────────────────────┘
                                    │
                                    ▼
                        ┌───────────────────────┐
                        │   Splash Page         │◄────┐
                        │   (Auto-routing)      │     │
                        └───────────────────────┘     │
                                    │                 │
                    ┌───────────────┴───────────────┐ │
                    │                               │ │
        isOnboardingCompleted?                      │ │
                    │                               │ │
        ┌───────────┴───────────┐                   │ │
        │                       │                   │ │
       NON                     OUI                  │ │
        │                       │                   │ │
        ▼                       ▼                   │ │
┌───────────────┐   ┌───────────────────────┐      │ │
│ Personality   │   │ isProfileCompleted?   │      │ │
│ Questionnaire │   └───────────────────────┘      │ │
│               │           │          │            │ │
│ 10 Questions  │          NON        OUI           │ │
│               │           │          │            │ │
└───────────────┘           ▼          ▼            │ │
        │           ┌─────────────┐ ┌─────────┐    │ │
        │           │   Profile   │ │  Home   │    │ │
        │           │   Setup     │ │  Page   │    │ │
        │           └─────────────┘ └─────────┘    │ │
        │                   │                      │ │
        │                   │                      │ │
        └───────────────────┘                      │ │
                    │                              │ │
                    ▼                              │ │
        ┌───────────────────────┐                  │ │
        │  Set Flag:            │                  │ │
        │  isOnboardingCompleted│                  │ │
        │  = true               │                  │ │
        └───────────────────────┘                  │ │
                    │                              │ │
                    └──────────────────────────────┘ │
                                                     │
                                                     │
┌────────────────────────────────────────────────────┘
│
│   Profile Setup - 6 Pages
│
├─► PAGE 1/6: Informations de Base
│   ├─ Pseudo (requis)
│   ├─ Date de naissance (requis, 18+)
│   └─ Bio (requis, max 200 car.)
│
├─► PAGE 2/6: Photos ◄─── FIX ÉCRAN BLANC ICI
│   ├─ Minimum: 3 photos (CORRIGÉ: était 10)
│   ├─ Maximum: 6 photos
│   └─ Bouton: "Continuer (X/6)"
│
├─► PAGE 3/6: Media (Optionnel)
│   ├─ Audio (max 2 fichiers)
│   ├─ Vidéo (max 1 fichier)
│   └─ Bouton: "Continuer" (toujours actif)
│
├─► PAGE 4/6: Prompts
│   ├─ 3 réponses requises (CORRIGÉ: était 10)
│   ├─ Max 300 caractères/réponse
│   └─ Auto-save au backend
│
├─► PAGE 5/6: Validation
│   ├─ Vérification complétude
│   ├─ Affichage statut
│   └─ Navigation vers étapes manquantes
│
└─► PAGE 6/6: Review (CORRIGÉ: était inaccessible)
    ├─ Message félicitations
    ├─ Explication rituel quotidien
    └─ Bouton: "Commencer mon aventure"
        │
        ▼
    ┌───────────────────────┐
    │  Set Flag:            │
    │  isProfileCompleted   │
    │  = true               │
    └───────────────────────┘
        │
        └──► Retour Splash ──────────────────────────┘
                                                      │
                                                      ▼
                                            ┌─────────────────┐
                                            │   Home Page     │
                                            │  (App Principale)│
                                            └─────────────────┘
```

## Détails de Navigation

### Splash Page - Logique de Routing

```
┌─────────────────────────────────────────────────┐
│            SPLASH PAGE ROUTING                  │
└─────────────────────────────────────────────────┘
                    │
          ┌─────────┴─────────┐
          │                   │
    Authenticated?           NON
          │                   │
         OUI                  ▼
          │              /welcome
          │
          ▼
    ┌─────────────────────────────┐
    │ isOnboardingCompleted == true│
    │           AND                │
    │ isProfileCompleted == true   │
    └─────────────────────────────┘
          │           │
         OUI         NON
          │           │
          ▼           ▼
        /home   ┌─────────────────────────┐
                │ isOnboardingCompleted?  │
                └─────────────────────────┘
                      │           │
                     OUI         NON
                      │           │
                      ▼           ▼
              /profile-setup  /questionnaire
```

### Profile Setup - Navigation Interne

```
┌─────────────────────────────────────────────────┐
│        PROFILE SETUP - INTERNAL PAGES           │
└─────────────────────────────────────────────────┘

Page 0 (Basic Info)
  │ _isBasicInfoValid()? → Pseudo + Date + Bio remplis
  ▼ YES
Page 1 (Photos) ◄── ÉCRAN BLANC RÉSOLU ICI
  │ photos.length >= 3?
  ▼ YES
Page 2 (Media)
  │ Toujours actif (optionnel)
  ▼
Page 3 (Prompts)
  │ _arePromptsValid()? → 3 réponses complètes
  │ + Auto-save to backend
  ▼ YES
Page 4 (Validation)
  │ profileCompletion.isCompleted?
  ▼ YES
Page 5 (Review)
  │ Click "Commencer mon aventure"
  │ + Save all to backend
  │ + Validate & Activate profile
  ▼
Home Page
```

## Progress Bar Visuelle

```
Page 0/6 - Basic Info:     ■□□□□□ 16.67%
Page 1/6 - Photos:         ■■□□□□ 33.33%  ◄── ÉCRAN BLANC ICI (RÉSOLU)
Page 2/6 - Media:          ■■■□□□ 50.00%
Page 3/6 - Prompts:        ■■■■□□ 66.67%
Page 4/6 - Validation:     ■■■■■□ 83.33%
Page 5/6 - Review:         ■■■■■■ 100.00%
```

## Flags de Complétion

```
┌─────────────────────────────────────────────────────────┐
│                    COMPLETION FLAGS                      │
└─────────────────────────────────────────────────────────┘

User {
  isOnboardingCompleted: boolean  ◄── Questionnaire terminé
  isProfileCompleted: boolean     ◄── Profile Setup terminé
}

ÉTAT 1: Nouvel utilisateur
  isOnboardingCompleted: false
  isProfileCompleted: false
  → Redirection: /questionnaire

ÉTAT 2: Questionnaire terminé
  isOnboardingCompleted: true
  isProfileCompleted: false
  → Redirection: /profile-setup

ÉTAT 3: Tout terminé
  isOnboardingCompleted: true
  isProfileCompleted: true
  → Redirection: /home
```

## Points de Sauvegarde Backend

```
┌─────────────────────────────────────────────────────────┐
│              BACKEND SAVE POINTS                         │
└─────────────────────────────────────────────────────────┘

1. Après Page 0 (Basic Info):
   profileProvider.setBasicInfo(...)
   [Sauvegarde locale seulement]

2. Après Page 3 (Prompts):
   └─► profileProvider.saveProfile()          ◄── API Call
   └─► profileProvider.submitPromptAnswers()  ◄── API Call
   └─► profileProvider.loadProfileCompletion() ◄── API Call
   [Sauvegarde backend complète]

3. Après Page 5 (Review):
   └─► profileProvider.saveProfile()              ◄── API Call
   └─► profileProvider.submitPromptAnswers()      ◄── API Call
   └─► profileProvider.validateAndActivateProfile() ◄── API Call
   └─► authProvider.refreshUser()                 ◄── API Call
   [Activation finale du profil]
```

## Erreurs Corrigées

```
┌─────────────────────────────────────────────────────────┐
│                   BUGS RÉSOLUS                           │
└─────────────────────────────────────────────────────────┘

❌ AVANT:
   Étape affichée: "1/5" "2/5" "3/5" "4/5" "5/5" "6/5" ◄── 120%!
   
✅ APRÈS:
   Étape affichée: "1/6" "2/6" "3/6" "4/6" "5/6" "6/6" ✓

────────────────────────────────────────────────────────────

❌ AVANT:
   Photos: minimum 10, maximum 6 ◄── IMPOSSIBLE!
   
✅ APRÈS:
   Photos: minimum 3, maximum 6 ✓

────────────────────────────────────────────────────────────

❌ AVANT:
   Prompts: 10 réponses requises
   API: 3 réponses requises ◄── INCOHÉRENCE!
   
✅ APRÈS:
   Prompts: 3 réponses requises ✓
   API: 3 réponses requises ✓

────────────────────────────────────────────────────────────

❌ AVANT:
   _currentPage < 4 ◄── Bloque à page 4, page 5 inaccessible!
   
✅ APRÈS:
   _currentPage < 5 ✓ Permet d'aller jusqu'à page 5

────────────────────────────────────────────────────────────

❌ AVANT:
   Page 2: Prompts ◄── Index incorrect après ajout Media
   
✅ APRÈS:
   Page 2: Media
   Page 3: Prompts ✓
```

## Structure des Pages

```
PageView (6 pages total)
├─► [0] _buildBasicInfoPage()
│   └─► Controllers: _nameController, _birthDate, _bioController
│
├─► [1] _buildPhotosPage() ◄── FIX ÉCRAN BLANC
│   └─► Widget: PhotoManagementWidget(min: 3, max: 6)
│
├─► [2] _buildMediaPage()
│   └─► Widget: MediaManagementWidget (optionnel)
│
├─► [3] _buildPromptsPage()
│   └─► Controllers: _promptControllers[0..2] (3 prompts)
│
├─► [4] _buildValidationPage()
│   └─► Widget: ProfileCompletionWidget
│
└─► [5] _buildReviewPage()
    └─► Finalisation + navigation vers /home
```

## Légende

```
┌────┐
│    │  Page/Étape
└────┘

  ▼     Flux descendant

  →     Navigation/Transition

  ◄──   Point d'attention/Fix

  ✓     Corrigé/Valide
  
  ❌    Erreur/Bug
  
  ✅    Résolu
```
