# Daily Quota System - Visual Flow Diagram

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        DAILY QUOTA SYSTEM                        │
└─────────────────────────────────────────────────────────────────┘

┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│   Backend    │◄────────┤   Provider   │◄────────┤  UI Layer    │
│   API        │         │   Logic      │         │  (Widgets)   │
└──────────────┘         └──────────────┘         └──────────────┘
      │                        │                        │
      ▼                        ▼                        ▼
GET /subscriptions     MatchingProvider        DailyMatchesPage
    /usage            - maxSelections           - Counter widget
                      - remainingSelections     - Profile cards
GET /matching/        - canSelectMore          - Dialogs
    daily-selection   - isSelectionComplete    - Banners
                      - refreshSelectionIfNeeded
POST /matching/
     choose/:id
```

## Data Flow

```
APP LAUNCH
    │
    ├─► Load Subscription Usage (/subscriptions/usage)
    │   └─► dailyChoices: { used, limit, resetTime }
    │
    ├─► Load Daily Selection (/matching/daily-selection)
    │   └─► metadata: { choicesRemaining, choicesMade, maxChoices }
    │
    └─► Display UI
        ├─► Free User: "1/1 choix restants"
        └─► Premium: "3/3 choix restants" + PLUS badge


USER SELECTS PROFILE
    │
    ├─► Check: canSelectMore?
    │   ├─► NO → Show limit dialog
    │   └─► YES → Proceed
    │
    ├─► Call API: POST /matching/choose/:id
    │   └─► Response: { choicesRemaining, isMatch }
    │
    └─► Update UI
        ├─► Decrement counter
        ├─► If quota = 0: Hide profiles
        └─► If free user: Show upgrade prompt


QUOTA EXHAUSTED
    │
    ├─► Show "Sélection terminée !"
    ├─► Display reset time: "Prochaine sélection : demain à 12:00"
    ├─► If free user: Show upgrade options
    └─► Disable "Choisir" buttons


APP RESUME (after quota reset)
    │
    ├─► Lifecycle event: didChangeAppLifecycleState(resumed)
    │
    ├─► Check: shouldShowNewProfiles()?
    │   └─► Compare now vs dailySelection.expiresAt
    │
    └─► If expired:
        ├─► Call refreshSelectionIfNeeded()
        └─► Reload daily selection automatically
```

## UI Components Map

```
DailyMatchesPage
│
├─── Header (GlassCard)
│    └─── "Sélection du jour" + ❤️ icon
│
├─── Selection Info Widget
│    ├─── "Choix restants: X/Y"
│    ├─── PLUS badge (if premium)
│    ├─── Upgrade hint (if free)
│    └─── Reset time (if quota = 0)
│         └─── "Reset: dans 4h15"
│
├─── Profile Cards (List)
│    ├─── Profile Image
│    ├─── Profile Info (name, age, bio)
│    └─── Action Buttons
│         ├─── "Passer" (always enabled)
│         └─── "Choisir" (disabled if quota = 0)
│
├─── Upgrade Banner (if free & quota > 0)
│    └─── "Passez à GoldWen Plus pour 3 choix/jour"
│
└─── Selection Complete State (if quota = 0)
     ├─── ✓ icon
     ├─── "Sélection terminée !"
     ├─── Message with reset time
     │    └─── "Prochaine sélection : demain à 12:00"
     └─── Upgrade button (if free)
          └─── "Découvrir GoldWen Plus"
```

## Dialog Flows

```
CHOICE CONFIRMATION DIALOG
┌─────────────────────────────────────────┐
│  ❤️  Confirmer votre choix              │
├─────────────────────────────────────────┤
│ Voulez-vous choisir Emma ?             │
│                                         │
│ ┌─────────────────────────────────┐   │
│ │ Il vous restera 2 choix après   │   │
│ │ cette sélection                 │   │
│ └─────────────────────────────────┘   │
│                                         │
│ [Annuler]           [Confirmer]        │
└─────────────────────────────────────────┘


LIMIT REACHED DIALOG (Free User)
┌─────────────────────────────────────────┐
│  ⭐ Limite atteinte                     │
├─────────────────────────────────────────┤
│ Vous avez utilisé 1/1 sélections        │
│ aujourd'hui.                            │
│                                         │
│ 🕐 Nouvelle sélection dans 4h15        │
│                                         │
│ ┌─────────────────────────────────┐   │
│ │ ⭐ Avec GoldWen Plus:           │   │
│ │                                 │   │
│ │ • 3 sélections par jour         │   │
│ │ • Chat illimité                 │   │
│ │ • Voir qui vous a sélectionné   │   │
│ │ • Profil prioritaire            │   │
│ └─────────────────────────────────┘   │
│                                         │
│ [Plus tard]         [Passer à Plus]    │
└─────────────────────────────────────────┘
```

## Reset Time Display Logic

```
_formatResetTime(DateTime resetTime)
    │
    ├─── Calculate difference from now
    │
    ├─── If < 1 hour
    │    └─► Return "45min"
    │
    ├─── If < 24 hours (same day)
    │    └─► Return "4h15"
    │
    └─── If next day
         └─► Return "demain à 12:00"

DISPLAY LOCATIONS:
1. Selection info widget (when quota = 0)
2. Selection complete message
3. Limit reached dialog
4. Error snackbar messages
```

## State Management

```
MatchingProvider State
├─── _dailySelection: DailySelection?
│    ├─── profiles: List<Profile>
│    ├─── choicesRemaining: int
│    ├─── choicesMade: int
│    ├─── maxChoices: int
│    └─── refreshTime: DateTime?
│
├─── _subscriptionUsage: SubscriptionUsage?
│    ├─── dailyChoicesUsed: int
│    ├─── dailyChoicesLimit: int
│    └─── resetDate: DateTime
│
├─── _selectedProfileIds: List<String>
│
└─── Computed Properties
     ├─── maxSelections → from dailySelection or subscription
     ├─── remainingSelections → from dailySelection
     ├─── canSelectMore → remainingSelections > 0
     └─── isSelectionComplete → choicesMade >= maxChoices
```

## User Experience Timeline

```
TIME: 10:00 - User Opens App (Free Tier)
    │
    └─► Shows: "1/1 choix restants"
    └─► 3 profiles displayed


TIME: 10:15 - User Selects Profile
    │
    ├─► Confirmation dialog appears
    ├─► User confirms
    └─► Profile selected


TIME: 10:16 - After Selection
    │
    ├─► Shows: "Sélection terminée !"
    ├─► Shows: "Prochaine sélection : demain à 12:00"
    ├─► Shows: Upgrade banner
    └─► All remaining profiles hidden


TIME: 10:20 - User Closes App
    │
    └─► App backgrounded


TIME: 12:00 - Backend Resets Quota
    │
    └─► Backend: choicesRemaining = 1, choicesMade = 0


TIME: 14:00 - User Opens App Again
    │
    ├─► App detects: AppLifecycleState.resumed
    ├─► Checks: isSelectionExpired? → YES
    ├─► Calls: refreshSelectionIfNeeded()
    ├─► Reloads: daily selection with new profiles
    └─► Shows: "1/1 choix restants" (reset!)
```

## Error Scenarios

```
SCENARIO 1: Network Failure
    │
    ├─► API call fails
    ├─► Error: "Vérifiez votre connexion internet"
    └─► Retry button displayed


SCENARIO 2: Quota Exceeded (Backend)
    │
    ├─► API returns 403: QUOTA_EXCEEDED
    ├─► Show limit dialog
    └─► Display reset time


SCENARIO 3: Profile Already Selected
    │
    ├─► Check: profileId in selectedProfileIds?
    ├─► Error: "Profil déjà sélectionné"
    └─► Snackbar message


SCENARIO 4: Missing Backend Data
    │
    ├─► metadata: null or incomplete
    ├─► Fallback: Use subscription data
    └─► Default: 1 choice for free users
```

## Testing Coverage

```
UNIT TESTS
├─── daily_selection_quota_test.dart
│    ├─── Model parsing (metadata wrapper)
│    ├─── Model parsing (direct fields)
│    ├─── Quota calculations
│    └─── Edge cases (missing data)
│
└─── daily_quota_ui_test.dart
     ├─── Reset time formatting
     ├─── Premium vs free logic
     ├─── Selection completion
     └─── Time display variations


INTEGRATION TESTS
└─── subscription_integration_test.dart
     ├─── Banner display
     ├─── Limit dialog
     └─── Status indicators


WIDGET TESTS
└─── daily_matches_page_test.dart
     ├─── Counter display
     ├─── Profile cards
     ├─── Button states
     └─── Dialog behavior
```

---

**Legend:**
- ├── Direct dependency
- └── Result/outcome
- │   Flow continuation
- ◄── Data flow direction
- ▼   Vertical flow
