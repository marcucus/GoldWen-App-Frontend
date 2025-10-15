# Bio Field Validation Flow

## Visual Representation of Validation Points

```
┌─────────────────────────────────────────────────────────────────┐
│                     Profile Setup - Step 1/6                     │
│                         (Basic Info Page)                        │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Pseudo Field                                             │  │
│  │  [Votre pseudo________________________]                   │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Date de naissance                                        │  │
│  │  [📅 Select Birth Date_________________]                  │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Bio                                    ← Label visible    │  │
│  │  ┌─────────────────────────────────────────────────────┐  │  │
│  │  │ Décrivez-vous en quelques mots...                   │  │  │
│  │  │                                                      │  │  │
│  │  │ [User types bio text here]                          │  │  │
│  │  │                                                      │  │  │
│  │  │                                                      │  │  │
│  │  │                                                      │  │  │
│  │  │                                                      │  │  │
│  │  └─────────────────────────────────────────────────────┘  │  │
│  │                                          XXX/600 ← Counter │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                   │
│                    ┌────────────┐                                │
│                    │ Continuer  │ ← Button State Logic          │
│                    └────────────┘                                │
└─────────────────────────────────────────────────────────────────┘
```

## Validation Logic Flow

```
User types in Bio field
        │
        ▼
┌───────────────────────┐
│ Real-time Counter     │
│ Updates: XXX/600      │
└───────────────────────┘
        │
        ▼
┌───────────────────────────────────────────────┐
│ _isBasicInfoValid() checks:                   │
│                                                │
│ ✓ Pseudo not empty                            │
│ ✓ Birth date selected                         │
│ ✓ Bio not empty                               │
│ ✓ Bio length <= 600  ← NEW CHECK              │
└───────────────────────────────────────────────┘
        │
        ├─── IF bio.length <= 600 ───┐
        │                             │
        │                             ▼
        │                    ┌────────────────┐
        │                    │ Button ENABLED │
        │                    └────────────────┘
        │
        └─── IF bio.length > 600 ────┐
                                      │
                                      ▼
                             ┌────────────────┐
                             │ Button DISABLED│
                             └────────────────┘
```

## User Attempts to Click "Continuer"

```
User clicks "Continuer"
        │
        ▼
┌───────────────────────────────────────────────┐
│ _nextPage() executes                          │
│                                                │
│ IF _currentPage == 0 (Basic Info):            │
│   ┌─────────────────────────────────────────┐│
│   │ Check: bio.length > 600?                ││
│   └─────────────────────────────────────────┘│
└───────────────────────────────────────────────┘
        │
        ├─── YES (> 600) ───────┐
        │                       │
        │                       ▼
        │              ┌──────────────────────────┐
        │              │ Show Red Alert:          │
        │              │ "La bio dépasse la       │
        │              │ limite de 600            │
        │              │ caractères (XXX/600)"    │
        │              │                          │
        │              │ STOP - Don't proceed     │
        │              └──────────────────────────┘
        │
        └─── NO (<= 600) ──────┐
                               │
                               ▼
                      ┌────────────────────┐
                      │ Save basic info to │
                      │ ProfileProvider    │
                      │                    │
                      │ Proceed to Photos  │
                      │ page (Step 2/6)    │
                      └────────────────────┘
```

## Final Profile Submission

```
User completes all steps and clicks finish
        │
        ▼
┌───────────────────────────────────────────────┐
│ _finishSetup() executes                       │
│                                                │
│ Validation checks in order:                   │
│   1. Pseudo not empty                         │
│   2. Birth date selected                      │
│   3. Bio not empty                            │
│   4. Bio length <= 600  ← NEW CHECK           │
│   5. Valid prompt IDs                         │
│   6. 3 prompts answered                       │
│   7. Each prompt <= 150 chars                 │
└───────────────────────────────────────────────┘
        │
        ├─── ANY CHECK FAILS ───────┐
        │                           │
        │                           ▼
        │                  ┌──────────────────────┐
        │                  │ Show specific alert  │
        │                  │ for failed check     │
        │                  │                      │
        │                  │ STOP - Don't submit  │
        │                  └──────────────────────┘
        │
        └─── ALL CHECKS PASS ──────┐
                                   │
                                   ▼
                          ┌─────────────────────┐
                          │ Submit profile data │
                          │ to backend API      │
                          │                     │
                          │ Complete setup ✓    │
                          └─────────────────────┘
```

## Character Counting Logic

```
┌──────────────────────────────────────────────────────────┐
│  Bio text: "Hello world\nNew line with spaces   end"     │
│                                                           │
│  Counted characters:                                     │
│  - Letters: H,e,l,l,o,w,o,r,l,d,N,e,w,l,i,n,e,w,i,t,h    │
│  - Spaces: ' ' (multiple spaces all counted)             │
│  - Newlines: \n (counted as 1 character)                 │
│  - Special chars: Any UTF-8 character                    │
│                                                           │
│  Flutter's maxLength counts ALL characters               │
│  including whitespace and control characters             │
└──────────────────────────────────────────────────────────┘
```

## Validation Points Summary

```
┌─────────────────────────────────────────────────────────────┐
│                    Validation Point                 Layer   │
├─────────────────────────────────────────────────────────────┤
│ 1. TextField maxLength                            UI Layer  │
│    - Hard limit at 600 chars                                │
│    - User can't type beyond 600                             │
│    - Counter shows XXX/600                                  │
├─────────────────────────────────────────────────────────────┤
│ 2. _isBasicInfoValid()                       Button State  │
│    - Disables "Continuer" button                           │
│    - Prevents navigation if > 600                          │
│    - Real-time validation on text change                   │
├─────────────────────────────────────────────────────────────┤
│ 3. _nextPage()                            Navigation Guard  │
│    - Double-checks before page transition                  │
│    - Shows alert if somehow > 600                          │
│    - Defensive programming layer                           │
├─────────────────────────────────────────────────────────────┤
│ 4. _finishSetup()                         Final Submission  │
│    - Last check before backend submission                  │
│    - Shows alert if > 600                                  │
│    - Prevents invalid data from reaching API               │
└─────────────────────────────────────────────────────────────┘
```

## Alert Message Example

```
┌──────────────────────────────────────────────────────┐
│  ⚠️  La bio dépasse la limite de 600 caractères      │
│      (650/600)                                       │
└──────────────────────────────────────────────────────┘
     ↑                                        ↑
     Alert text                    Current count/limit
```

## User Experience Flow

```
Empty Bio → User starts typing → Counter appears (1/600)
                    ↓
         User continues typing → Counter updates (500/600)
                    ↓
         User reaches 600 chars → Counter shows (600/600)
                    ↓
                    ├─ User tries to type more → BLOCKED by maxLength
                    │
                    └─ User clicks "Continuer" → ✓ Proceeds to next page


Overfilled Bio → User has 650 chars somehow
                    ↓
         Button appears disabled (grayed out)
                    ↓
         User must delete chars to get to ≤600
                    ↓
         Button becomes enabled at 600 or less
                    ↓
         User clicks "Continuer" → ✓ Proceeds to next page
```

## Code Integration Points

```
profile_setup_page.dart
│
├── Line 342: maxLength: 600
│   └── Controls TextField max input
│
├── Line 949: _bioController.text.length <= 600
│   └── Button enable/disable logic
│
├── Line 1021: if (_bioController.text.length > 600)
│   └── Navigation validation
│
└── Line 1161: if (_bioController.text.length > 600)
    └── Final submission validation
```
