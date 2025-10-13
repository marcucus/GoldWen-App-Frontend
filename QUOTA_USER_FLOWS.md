# Flux Utilisateurs - Système de Quotas de Sélection Quotidienne

## 📱 Diagrammes de Flux Complets

### Flux 1: Utilisateur Gratuit - Première Visite du Jour

```
┌─────────────────────────────────────────────────────────────┐
│ UTILISATEUR GRATUIT - PREMIÈRE VISITE                       │
└─────────────────────────────────────────────────────────────┘

Ouverture de l'App
        │
        ▼
┌─────────────────────────┐
│ App détecte le resume   │◄────── didChangeAppLifecycleState
│ via WidgetsBinding      │        détecte AppLifecycleState.resumed
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│ refreshSelectionIfNeeded│
│ vérifie si expired      │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│ loadDailySelection()    │───► GET /api/v1/matching/daily-selection
│ + _loadSubscriptionUsage│───► GET /api/v1/subscriptions/usage
└────────────┬────────────┘
             │
             ▼
╔═════════════════════════╗
║  Page de Sélection      ║
║                         ║
║  ┌─────────────────┐   ║
║  │ Sélection du jour│   ║
║  └─────────────────┘   ║
║                         ║
║  ┌─────────────────┐   ║
║  │ 3 profils       │   ║◄── Affichage des profils
║  │ disponibles     │   ║    non sélectionnés
║  └─────────────────┘   ║
║                         ║
║  ┌─────────────────┐   ║
║  │ Choix restants  │   ║
║  │     1/1         │   ║◄── Indicateur de quota
║  │ GoldWen Plus:   │   ║    (gratuit = 1 seul choix)
║  │ 3 choix/jour    │   ║
║  └─────────────────┘   ║
║                         ║
║  ┌─────────────────┐   ║
║  │ [Profil 1]      │   ║
║  │ Emma, 25 ans    │   ║
║  │ [Passer][Choisir│   ║◄── Boutons actifs
║  └─────────────────┘   ║
║                         ║
║  ┌─────────────────┐   ║
║  │ [Profil 2]      │   ║
║  │ Sophie, 28 ans  │   ║
║  │ [Passer][Choisir│   ║
║  └─────────────────┘   ║
║                         ║
║  ┌─────────────────┐   ║
║  │ 🌟 Passez à     │   ║◄── Bannière upgrade
║  │ GoldWen Plus    │   ║    (non-intrusive)
║  └─────────────────┘   ║
╚═════════════════════════╝
             │
             │ Utilisateur clique "Choisir" sur Emma
             ▼
┌─────────────────────────┐
│ _showChoiceConfirmation │
│                         │
│ ╔═══════════════════╗  │
│ ║ Confirmer choix   ║  │
│ ║                   ║  │
│ ║ Voulez-vous       ║  │
│ ║ vraiment choisir  ║  │
│ ║ Emma ?            ║  │
│ ║                   ║  │
│ ║ ⓘ Ce sera votre   ║  │◄── Avertissement
│ ║   dernier choix   ║      (dernier choix gratuit)
│ ║   aujourd'hui.    ║  │
│ ║                   ║  │
│ ║ [Annuler][Confirm]║  │
│ ╚═══════════════════╝  │
└────────────┬────────────┘
             │ Clique "Confirmer"
             ▼
┌─────────────────────────┐
│ selectProfile()         │
│                         │───► POST /api/v1/matching/choose/:profileId
│ choice: 'like'          │     { choice: "like" }
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│ Backend répond          │◄──── { isMatch: false,
│ _updateDailySelection   │       choicesRemaining: 0 }
│ choicesRemaining = 0    │
└────────────┬────────────┘
             │
             ▼
╔═════════════════════════╗
║  SnackBar verte         ║
║  ────────────────────   ║
║  ✨ Votre choix est     ║◄── Message de confirmation
║  fait ! Revenez demain  ║
║  pour de nouveaux       ║
║  profils.               ║
╚═════════════════════════╝
             │
             ▼
╔═════════════════════════╗
║  État: Selection        ║
║  Complete               ║
║                         ║
║    ┌───────────┐       ║
║    │     ✓     │       ║◄── Icône de validation
║    └───────────┘       ║
║                         ║
║  Sélection terminée !   ║
║                         ║
║  Votre choix est fait.  ║
║  Revenez demain pour    ║
║  de nouveaux profils.   ║
║                         ║
║  🕐 Prochaine sélection :║◄── Timer de reset
║     demain à 12:00      ║
║                         ║
║  ┌─────────────────┐   ║
║  │ Découvrir       │   ║◄── Call-to-action
║  │ GoldWen Plus    │   ║    vers subscription
║  └─────────────────┘   ║
╚═════════════════════════╝
```

### Flux 2: Utilisateur Gratuit - Quota Déjà Atteint

```
┌─────────────────────────────────────────────────────────────┐
│ UTILISATEUR GRATUIT - QUOTA ATTEINT                         │
└─────────────────────────────────────────────────────────────┘

Ouverture de l'App
        │
        ▼
┌─────────────────────────┐
│ loadDailySelection()    │───► Charge métadonnées:
│                         │     choicesRemaining: 0
│                         │     choicesMade: 1
│                         │     maxChoices: 1
└────────────┬────────────┘     refreshTime: "2025-01-16T12:00:00Z"
             │
             ▼
┌─────────────────────────┐
│ isSelectionComplete     │───► return true
│ = choicesMade >= max    │     (1 >= 1)
└────────────┬────────────┘
             │
             ▼
╔═════════════════════════╗
║  État: Selection        ║
║  Complete affiché       ║
║                         ║
║    ┌───────────┐       ║
║    │     ✓     │       ║
║    └───────────┘       ║
║                         ║
║  Sélection terminée !   ║
║                         ║
║  Vous avez fait vos     ║
║  choix pour aujourd'hui.║
║  Revenez demain pour    ║
║  de nouveaux profils.   ║
║                         ║
║  ┌─────────────────┐   ║
║  │ 🕐 Prochaine    │   ║◄── Timer calculé en temps réel
║  │    sélection :  │   ║    via _formatResetTime()
║  │    dans 4h15    │   ║
║  └─────────────────┘   ║
║                         ║
║  ┌─────────────────┐   ║
║  │ 🌟 Découvrir    │   ║
║  │ GoldWen Plus    │   ║
║  │ → Subscription  │   ║
║  └─────────────────┘   ║
╚═════════════════════════╝
             │
             │ Si l'utilisateur tente de choisir
             ▼
┌─────────────────────────┐
│ canSelectMore = false   │
│ Boutons désactivés      │
└─────────────────────────┘
```

### Flux 3: Utilisateur Premium - Multiple Sélections

```
┌─────────────────────────────────────────────────────────────┐
│ UTILISATEUR PREMIUM (GoldWen Plus) - MULTIPLE CHOIX         │
└─────────────────────────────────────────────────────────────┘

Ouverture de l'App
        │
        ▼
┌─────────────────────────┐
│ loadDailySelection()    │───► Charge métadonnées:
│ + loadSubscriptionUsage │     choicesRemaining: 3
│                         │     maxChoices: 3
└────────────┬────────────┘     hasActiveSubscription: true
             │
             ▼
╔═════════════════════════╗
║  Page de Sélection      ║
║  (Premium User)         ║
║                         ║
║  ┌─────────────────┐   ║
║  │ 🌟 GoldWen Plus │   ║◄── Badge subscription
║  │    actif        │   ║    (si proche expiration,
║  └─────────────────┘   ║     affiche countdown)
║                         ║
║  ┌─────────────────┐   ║
║  │ 3 profils       │   ║
║  │ disponibles     │   ║
║  └─────────────────┘   ║
║                         ║
║  ┌─────────────────┐   ║
║  │ Choix restants  │   ║
║  │  [PLUS]  3/3    │   ║◄── Badge "PLUS" doré
║  └─────────────────┘   ║    + Compteur 3/3
║                         ║
║  [Profils...]           ║
║                         ║
║  (Pas de bannière       ║◄── Pas de bannière upgrade
║   upgrade)              ║    pour utilisateurs premium
╚═════════════════════════╝
             │
             │ PREMIER CHOIX
             ▼
┌─────────────────────────┐
│ Choisit Emma            │───► POST /matching/choose/:id
│                         │     choicesRemaining: 2
└────────────┬────────────┘
             │
             ▼
╔═════════════════════════╗
║  SnackBar verte         ║
║  ────────────────────   ║
║  💖 Vous avez choisi    ║
║  Emma ! Il vous reste   ║
║  2 choix.               ║◄── Message avec choix restants
╚═════════════════════════╝
             │
             ▼
╔═════════════════════════╗
║  Page mise à jour       ║
║                         ║
║  ┌─────────────────┐   ║
║  │ Choix restants  │   ║
║  │  [PLUS]  2/3    │   ║◄── Compteur mis à jour
║  └─────────────────┘   ║
║                         ║
║  [2 profils restants]   ║◄── Emma n'apparaît plus
╚═════════════════════════╝
             │
             │ DEUXIÈME CHOIX
             ▼
┌─────────────────────────┐
│ Choisit Sophie          │───► POST /matching/choose/:id
│                         │     choicesRemaining: 1
└────────────┬────────────┘
             │
             ▼
╔═════════════════════════╗
║  SnackBar verte         ║
║  ────────────────────   ║
║  💖 Vous avez choisi    ║
║  Sophie ! Il vous reste ║
║  1 choix.               ║
╚═════════════════════════╝
             │
             ▼
╔═════════════════════════╗
║  ┌─────────────────┐   ║
║  │ Choix restants  │   ║
║  │  [PLUS]  1/3    │   ║◄── Compteur: 1/3
║  └─────────────────┘   ║
║                         ║
║  [1 profil restant]     ║◄── Seul Clara visible
╚═════════════════════════╝
             │
             │ TROISIÈME CHOIX
             ▼
┌─────────────────────────┐
│ Choisit Clara           │───► POST /matching/choose/:id
│                         │     choicesRemaining: 0
└────────────┬────────────┘
             │
             ▼
╔═════════════════════════╗
║  SnackBar verte         ║
║  ────────────────────   ║
║  ✨ Votre choix est     ║◄── Message final
║  fait ! Revenez demain  ║    (quota épuisé)
║  pour de nouveaux       ║
║  profils.               ║
╚═════════════════════════╝
             │
             ▼
╔═════════════════════════╗
║  État: Selection        ║
║  Complete (Premium)     ║
║                         ║
║    ┌───────────┐       ║
║    │     ✓     │       ║
║    └───────────┘       ║
║                         ║
║  Sélection terminée !   ║
║                         ║
║  Vous avez fait vos     ║
║  3 choix pour           ║
║  aujourd'hui.           ║
║                         ║
║  🕐 Prochaine sélection :║◄── Timer de reset
║     dans 8h45           ║
║                         ║
║  (Pas de bouton         ║◄── Pas d'upgrade prompt
║   upgrade pour premium) ║    pour utilisateurs premium
╚═════════════════════════╝
```

### Flux 4: Tentative de Sélection avec Quota Épuisé

```
┌─────────────────────────────────────────────────────────────┐
│ TENTATIVE DE SÉLECTION - QUOTA ÉPUISÉ                       │
└─────────────────────────────────────────────────────────────┘

Utilisateur clique "Choisir"
        │
        ▼
┌─────────────────────────┐
│ _selectProfile()        │
│ vérifie canSelectMore   │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│ canSelectMore = false   │
│ (remainingSelections=0) │
└────────────┬────────────┘
             │
       ┌─────┴─────┐
       │           │
   Gratuit     Premium
       │           │
       ▼           ▼
╔═════════════╗  ╔═════════════╗
║ GRATUIT     ║  ║ PREMIUM     ║
║             ║  ║             ║
║ showDialog: ║  ║ SnackBar:   ║
║ Subscription║  ║ "Limite     ║
║ LimitReached║  ║ quotidienne ║
║ Dialog      ║  ║ atteinte.   ║
╚═════════════╝  ║ Nouvelle    ║
       │         ║ sélection   ║
       │         ║ dans 4h15." ║
       ▼         ╚═════════════╝
╔══════════════════════╗
║ Limite atteinte      ║
║                      ║
║ Vous avez utilisé    ║
║ 1/1 sélections       ║
║ aujourd'hui.         ║
║                      ║
║ 🕐 Nouvelle          ║
║    sélection dans    ║◄── Timer formaté
║    4h15              ║
║                      ║
║ ┌──────────────────┐║
║ │ 🌟 Avec GoldWen  │║
║ │    Plus:         │║
║ │                  │║
║ │ • 3 sélections   │║
║ │   par jour       │║
║ │ • Chat illimité  │║◄── Liste des avantages
║ │ • Voir qui vous  │║
║ │   a sélectionné  │║
║ │ • Profil         │║
║ │   prioritaire    │║
║ └──────────────────┘║
║                      ║
║ [Plus tard]          ║
║ [Passer à Plus]      ║◄── Actions
╚══════════════════════╝
       │
       │ Si clique "Passer à Plus"
       ▼
┌─────────────────────┐
│ context.go(         │
│  '/subscription'    │───► Navigation vers
│ )                   │     page d'abonnement
└─────────────────────┘
```

### Flux 5: Reset Automatique (Nouveau Jour)

```
┌─────────────────────────────────────────────────────────────┐
│ RESET AUTOMATIQUE - NOUVEAU JOUR                            │
└─────────────────────────────────────────────────────────────┘

Minuit / Midi (Backend)
        │
        ▼
┌─────────────────────────┐
│ Backend Reset           │
│ - choicesRemaining      │◄── Backend réinitialise
│   réinitialisé          │    automatiquement
│ - choicesMade = 0       │    (Cron job backend)
│ - Nouvelle sélection    │
│   générée               │
└─────────────────────────┘
        
        ⏰ Attente...
        
Utilisateur ouvre l'app
        │
        ▼
┌─────────────────────────┐
│ didChangeAppLifecycle   │
│ State.resumed           │◄── Observer détecte
└────────────┬────────────┘    le retour à l'app
             │
             ▼
┌─────────────────────────┐
│ refreshSelectionIfNeeded│
│                         │
│ Vérifie:                │
│ - dailySelection?.      │
│   isExpired             │◄── Vérifie si selection
│ = DateTime.now()        │    a expiré
│   .isAfter(expiresAt)   │
└────────────┬────────────┘
             │
             ▼ isExpired = true
┌─────────────────────────┐
│ loadDailySelection()    │───► GET /api/v1/matching/
│                         │     daily-selection
│ Charge nouvelle         │
│ sélection du jour       │◄── Nouvelle sélection
└────────────┬────────────┘    avec quotas réinitialisés
             │
             ▼
╔═════════════════════════╗
║  Page de Sélection      ║
║  (Nouvelle Journée)     ║
║                         ║
║  ┌─────────────────┐   ║
║  │ Choix restants  │   ║
║  │     1/1 (ou     │   ║◄── Quotas réinitialisés
║  │     3/3 Premium)│   ║
║  └─────────────────┘   ║
║                         ║
║  [Nouveaux profils]     ║◄── Nouvelle sélection
║                         ║    de profils
╚═════════════════════════╝
```

## 🎨 Composants UI Détaillés

### Widget: _buildSelectionInfo()

```
┌─────────────────────────────────────────┐
│ Container                               │
│ (Background: white.withOpacity(0.2))    │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │ Row (SpaceBetween)                │ │
│  │                                   │ │
│  │  Column (Left)                    │ │
│  │  ┌──────────────┐                │ │
│  │  │ "Choix       │                │ │
│  │  │  restants"   │                │ │◄── Label principal
│  │  └──────────────┘                │ │
│  │  ┌──────────────┐                │ │
│  │  │ "GoldWen     │ (si gratuit)   │ │
│  │  │  Plus: 3/j"  │                │ │◄── Suggestion upgrade
│  │  └──────────────┘                │ │
│  │                                   │ │
│  │  Row (Right)                      │ │
│  │  ┌────────┐ ┌──────────┐        │ │
│  │  │ [PLUS] │ │  2/3     │        │ │◄── Badge + Compteur
│  │  └────────┘ └──────────┘        │ │    (couleur selon quota)
│  └───────────────────────────────────┘ │
│                                         │
│  Si quota = 0:                          │
│  ┌───────────────────────────────────┐ │
│  │ Row (Timer)                       │ │
│  │  🕐 Reset: dans 4h15              │ │◄── Timer de reset
│  └───────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

### Widget: SubscriptionLimitReachedDialog

```
╔═══════════════════════════════════════╗
║ AlertDialog                           ║
║                                       ║
║  Title Row:                           ║
║  ┌──────┐                            ║
║  │ 🌟   │ "Limite atteinte"         ║◄── Icône + Titre
║  └──────┘                            ║
║                                       ║
║  Content:                             ║
║  ┌─────────────────────────────────┐║
║  │ "Vous avez utilisé X/Y          │║◄── Message quota
║  │  sélections aujourd'hui."       │║
║  └─────────────────────────────────┘║
║                                       ║
║  ┌─────────────────────────────────┐║
║  │ 🕐 "Nouvelle sélection dans     │║◄── Timer formaté
║  │     4h15"                        │║
║  └─────────────────────────────────┘║
║                                       ║
║  Container (GoldWen Plus Features):   ║
║  ┌─────────────────────────────────┐║
║  │ 🌟 Avec GoldWen Plus:           │║
║  │                                  │║
║  │ • 3 sélections par jour         │║
║  │ • Chat illimité avec matches    │║◄── Liste avantages
║  │ • Voir qui vous a sélectionné   │║    avec gradient gold
║  │ • Profil prioritaire            │║
║  └─────────────────────────────────┘║
║                                       ║
║  Actions:                             ║
║  [Plus tard] [Passer à Plus]         ║◄── Boutons d'action
╚═══════════════════════════════════════╝
```

### Widget: SubscriptionPromoBanner

```
┌───────────────────────────────────────────┐
│ Card (Gradient gold background)          │
│                                           │
│  InkWell (tapable → /subscription)       │
│  ┌─────────────────────────────────────┐│
│  │ Row                                 ││
│  │                                     ││
│  │  ┌────────┐                        ││
│  │  │   🌟   │  (Icon in colored box) ││◄── Icône star dorée
│  │  └────────┘                        ││
│  │                                     ││
│  │  Column (Expanded)                  ││
│  │  ┌───────────────────────┐         ││
│  │  │ "Passez à GoldWen     │         ││◄── Message principal
│  │  │  Plus pour 3 choix/   │         ││
│  │  │  jour"                │         ││
│  │  └───────────────────────┘         ││
│  │  ┌───────────────────────┐         ││
│  │  │ "Plus de matches,     │ (opt)   ││◄── Sous-message
│  │  │  plus de possibilités"│         ││    (si !compact)
│  │  └───────────────────────┘         ││
│  │                                     ││
│  │  →  (Arrow icon)                   ││◄── Flèche navigation
│  └─────────────────────────────────────┘│
└───────────────────────────────────────────┘
```

## 🔄 États du Système

### État 1: Initial (Quotas Disponibles)
- `canSelectMore = true`
- `remainingSelections > 0`
- Boutons "Choisir" actifs
- Compteur affiché avec couleur primaire
- Bannière upgrade (si gratuit, en bas de page)

### État 2: Après Premier Choix (Premium)
- `remainingSelections` décrémenté
- Profil sélectionné retiré de la liste
- SnackBar de confirmation
- Compteur mis à jour
- Autres profils toujours disponibles

### État 3: Quota Épuisé
- `canSelectMore = false`
- `remainingSelections = 0`
- `isSelectionComplete = true`
- Boutons "Choisir" désactivés (grisés)
- Timer de reset affiché
- État "Selection Complete" affiché
- Bannière upgrade prominente (si gratuit)

### État 4: Après Reset (Nouveau Jour)
- Retour à État 1
- Nouveaux profils chargés
- Quotas réinitialisés
- `_selectedProfileIds` vidé

## 📊 Décisions de Design

### Couleurs
- **Quota disponible**: Theme.primaryColor (actif, vert)
- **Quota épuisé**: Colors.grey[400] (désactivé)
- **Badge Premium**: Colors.amber (gold)
- **Timer**: Colors.grey[600] (neutre)
- **Success**: Colors.green (confirmation)
- **Warning**: Colors.orange (limite atteinte)

### Typographie
- **Compteur**: bodyMedium, fontWeight.bold
- **Label**: bodyMedium, fontWeight.w500
- **Timer**: bodySmall, color: grey[600]
- **Message success**: Theme default

### Espacement
- **Compact mode**: AppSpacing.sm, AppSpacing.xs
- **Normal mode**: AppSpacing.md
- **Padding counters**: 12x4 (horizontal x vertical)
- **Border radius**: AppBorderRadius.medium (12-16px)

## 🧩 Intégration Backend

### Synchronisation des États

```
Frontend State           Backend State
─────────────────       ─────────────────
choicesRemaining   ←───  dailyChoices.remaining
choicesMade        ←───  dailyChoices.used
maxChoices         ←───  dailyChoices.limit
refreshTime        ←───  dailyChoices.resetTime
canSelectMore      ←───  dailyChoices.remaining > 0
```

### Gestion de la Cohérence

1. **Load**: Backend est source de vérité
2. **Update**: Frontend optimiste + confirmation backend
3. **Conflict**: Backend prévaut (re-fetch si nécessaire)
4. **Offline**: État local en cache, sync au retour

## ✨ Conclusion

Ces flux détaillés montrent que:
- ✅ Tous les parcours utilisateurs sont couverts
- ✅ L'UI est cohérente et informative
- ✅ Les transitions d'état sont fluides
- ✅ Les messages sont clairs et contextuels
- ✅ L'upgrade est suggéré de manière non-intrusive
- ✅ Le système est robuste aux cas limites

**Le système de quotas est complet et production-ready.**
