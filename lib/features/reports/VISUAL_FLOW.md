# Report Feature - Visual Flow

## 1. User Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    User Views Profile/Message                │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
                    ┌───────────────┐
                    │ Clicks Report │
                    │    Button     │
                    └───────┬───────┘
                            │
        ┌───────────────────┴───────────────────┐
        │                                       │
        ▼                                       ▼
┌──────────────────┐                   ┌──────────────────┐
│  ReportDialog    │                   │   ReportPage     │
│  (Quick Modal)   │                   │  (Full Screen)   │
└────────┬─────────┘                   └────────┬─────────┘
         │                                      │
         └──────────────────┬───────────────────┘
                            │
                            ▼
                ┌───────────────────────┐
                │ Check Local Storage   │
                │  (SharedPreferences)  │
                └───────────┬───────────┘
                            │
                ┌───────────┴───────────┐
                │                       │
        Already Reported           Not Reported
                │                       │
                ▼                       ▼
        ┌──────────────┐        ┌──────────────┐
        │ Show Message │        │ Show Form    │
        │ "Already     │        │ - Categories │
        │  Reported"   │        │ - Description│
        └──────────────┘        └──────┬───────┘
                                       │
                                       ▼
                               ┌───────────────┐
                               │ User Submits  │
                               └───────┬───────┘
                                       │
                                       ▼
                            ┌──────────────────┐
                            │ ReportProvider   │
                            │  .submitReport() │
                            └─────────┬────────┘
                                      │
                                      ▼
                            ┌──────────────────┐
                            │ POST /reports    │
                            │   (Backend)      │
                            └─────────┬────────┘
                                      │
                ┌─────────────────────┼─────────────────────┐
                │                     │                     │
          Success (200)         Duplicate (409)      Error (4xx/5xx)
                │                     │                     │
                ▼                     ▼                     ▼
        ┌──────────────┐      ┌──────────────┐    ┌──────────────┐
        │ Save to      │      │ Save to      │    │ Show Error   │
        │ SharedPrefs  │      │ SharedPrefs  │    │  SnackBar    │
        └──────┬───────┘      └──────┬───────┘    └──────────────┘
               │                     │
               └─────────┬───────────┘
                         │
                         ▼
                ┌────────────────┐
                │ Show Success   │
                │    Dialog      │
                └────────┬───────┘
                         │
                         ▼
                ┌────────────────┐
                │  Navigate Back │
                └────────────────┘
```

## 2. Component Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Application                           │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                  MultiProvider                        │   │
│  │    ┌──────────────────────────────────────────┐      │   │
│  │    │        ReportProvider                     │      │   │
│  │    │  - submitReport()                         │      │   │
│  │    │  - loadMyReports()                        │      │   │
│  │    │  - State: reports, loading, error         │      │   │
│  │    └──────────────────┬────────────────────────┘      │   │
│  └───────────────────────┼──────────────────────────────┘   │
└────────────────────────┼────────────────────────────────────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
        ▼                ▼                ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ ReportPage   │  │ ReportDialog │  │UserReportsPage│
│              │  │              │  │              │
│ - Full page  │  │ - Modal      │  │ - History    │
│ - Duplicate  │  │ - Quick      │  │ - Status     │
│   check      │  │   report     │  │   tracking   │
└──────┬───────┘  └──────┬───────┘  └──────────────┘
       │                 │
       └────────┬────────┘
                │
                ▼
    ┌───────────────────┐
    │ ReportFormWidget  │
    │                   │
    │ - Category select │
    │ - Description     │
    │ - Validation      │
    │ - Submit callback │
    └─────────┬─────────┘
              │
              ▼
    ┌───────────────────┐
    │  API Service      │
    │  - submitReport() │
    │  - getMyReports() │
    └───────────────────┘
```

## 3. Data Storage

```
┌─────────────────────────────────────────────────────────────┐
│                   SharedPreferences (Local)                  │
│                                                               │
│  Keys:                                                        │
│    report_user_{userId}      → true/false                    │
│    report_message_{messageId} → true/false                   │
│                                                               │
│  Purpose:                                                     │
│    - Quick duplicate check                                   │
│    - Offline prevention                                      │
│    - Reduce API calls                                        │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    Backend Database                          │
│                                                               │
│  Reports Table:                                               │
│    - id (UUID)                                               │
│    - reporterId (UUID)                                       │
│    - targetUserId (UUID)                                     │
│    - type (enum)                                             │
│    - reason (text)                                           │
│    - messageId (UUID, optional)                              │
│    - chatId (UUID, optional)                                 │
│    - status (pending/reviewed/resolved/dismissed)            │
│    - createdAt (timestamp)                                   │
│    - updatedAt (timestamp)                                   │
│                                                               │
│  Constraints:                                                 │
│    - UNIQUE(reporterId, targetUserId) for profiles           │
│    - UNIQUE(reporterId, messageId) for messages              │
│    - Rate limit: 5 reports/day per user                      │
└─────────────────────────────────────────────────────────────┘
```

## 4. State Management

```
┌─────────────────────────────────────────────────────────────┐
│                        ReportProvider                         │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                    State                              │   │
│  │  - List<Report> _myReports                           │   │
│  │  - bool _isLoading                                   │   │
│  │  - String? _error                                    │   │
│  │  - bool _hasMoreReports                              │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                   Methods                             │   │
│  │  submitReport(...)                                   │   │
│  │    1. Set loading = true                             │   │
│  │    2. Call API                                       │   │
│  │    3. Update state                                   │   │
│  │    4. Notify listeners                               │   │
│  │                                                       │   │
│  │  loadMyReports(...)                                  │   │
│  │    1. Set loading = true                             │   │
│  │    2. Call API                                       │   │
│  │    3. Parse response                                 │   │
│  │    4. Update reports list                            │   │
│  │    5. Notify listeners                               │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## 5. Error Handling Flow

```
                    ┌──────────────┐
                    │ Submit Report│
                    └──────┬───────┘
                           │
                ┌──────────┴─────────┐
                │                    │
         Try Block            Catch Block
                │                    │
                ▼                    ▼
        ┌──────────────┐     ┌──────────────┐
        │ API Success  │     │  Exception   │
        │   (200)      │     │   Thrown     │
        └──────┬───────┘     └──────┬───────┘
               │                    │
               │             ┌──────┴───────────────┐
               │             │                      │
               │      Contains "already"    Contains "429"
               │      or "duplicate"               │
               │             │                      │
               │             ▼                      ▼
               │     ┌──────────────┐      ┌──────────────┐
               │     │ Mark as      │      │ Show Rate    │
               │     │ Reported     │      │ Limit Error  │
               │     │ Show Dialog  │      └──────────────┘
               │     └──────────────┘              │
               │             │                     │
               └─────────────┴─────────────────────┘
                             │
                             ▼
                    ┌────────────────┐
                    │ Reset Loading  │
                    └────────────────┘
```

## 6. Category Selection UI

```
┌─────────────────────────────────────────────────────────────┐
│                    Report Form Widget                        │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ ⚠️  Contenu inapproprié                            ✓  │ │ <- Selected
│  │     Photos ou texte inapproprié, offensant            │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ 🚫  Harcèlement                                        │ │
│  │     Messages insistants, comportement harcelant       │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ 📢  Spam                                               │ │
│  │     Messages publicitaires, liens suspects            │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ ❓  Autre                                              │ │
│  │     Autre problème non listé ci-dessus                │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Description (optionnel)                                │ │
│  │                                                         │ │
│  │ ┌─────────────────────────────────────────────────────┐│ │
│  │ │                                                     ││ │
│  │ │ Décrivez le problème...                           ││ │
│  │ │                                                     ││ │
│  │ └─────────────────────────────────────────────────────┘│ │
│  │ 0/500                                                  │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ ℹ️  Votre signalement sera examiné par notre équipe    │ │
│  │     de modération. Vous ne pouvez signaler le même    │ │
│  │     contenu qu'une seule fois.                        │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │            🚨 Envoyer le signalement                   │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```
