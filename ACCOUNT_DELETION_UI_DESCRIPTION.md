# Account Deletion Feature - UI/UX Description

## Visual Flow Description

### 1. Settings Page - Entry Point

**Location:** Help & Legal Section (bottom of settings)

**Button Appearance:**
```
┌─────────────────────────────────────────────────────────┐
│  [🗑️]  Supprimer mon compte                            │
│        Suppression définitive de votre compte       [>] │
└─────────────────────────────────────────────────────────┘
```

**Visual Properties:**
- Icon: 🗑️ (delete_forever) - Red color
- Title: "Supprimer mon compte" - Red text
- Subtitle: "Suppression définitive de votre compte" - Light red text
- Background: White card with subtle shadow
- Border: Thin red border (isDestructive: true)
- Hover: Slight red tint
- Position: Last item in Help & Legal section

**Context:**
The button appears after:
- "Envoyer un feedback"
- "Mes signalements"
- "Aide et support"
- "Paramètres de confidentialité"
- "Confidentialité"
- "Conditions"

And before:
- Logout section

---

### 2. Account Deletion Page - Warning Screen

**Header:**
```
┌─────────────────────────────────────────────────────────┐
│ [←] Suppression de compte                               │
└─────────────────────────────────────────────────────────┘
```

**Main Content:**

#### Warning Banner (Top)
```
╔═══════════════════════════════════════════════════════╗
║  ⚠️                                                    ║
║  Attention                                             ║
║  La suppression de votre compte est une action         ║
║  définitive. Toutes vos données seront supprimées.     ║
╚═══════════════════════════════════════════════════════╝
```
- Background: Light red (#FFEBEE)
- Border: Red (#F44336)
- Icon: ⚠️ Warning amber (32px)
- Text: Black with bold title

#### Data Deletion List
```
Ce qui sera supprimé
─────────────────────

┌─────────────────────────────────────────────────────────┐
│ ✕ Votre profil et toutes vos photos                    │
│ ✕ Vos réponses au questionnaire de personnalité        │
│ ✕ Tous vos matches et conversations                    │
│ ✕ Votre historique d'activité                          │
│ ✕ Vos préférences et paramètres                        │
│ ✕ Votre abonnement (si actif)                          │
└─────────────────────────────────────────────────────────┘
```
- Background: Light grey (#F5F5F5)
- Icons: Red ✕ marks
- Text: Dark grey

#### Password Confirmation
```
Confirmation
────────────

┌─────────────────────────────────────────────────────────┐
│ 🔒 Mot de passe                                         │
│ ●●●●●●●●●                                         [👁️] │
└─────────────────────────────────────────────────────────┘
```
- Input field with lock icon
- Password obscured by default
- Eye icon to toggle visibility

#### Optional Reason
```
┌─────────────────────────────────────────────────────────┐
│ 💬 Raison (optionnel)                                   │
│ Pourquoi souhaitez-vous supprimer votre compte ?       │
│                                                         │
│                                                         │
└─────────────────────────────────────────────────────────┘
```
- Multi-line text field
- Comment icon
- Placeholder text in grey

#### Grace Period Option
```
┌─────────────────────────────────────────────────────────┐
│ ☐ Supprimer immédiatement                              │
│                                                         │
│   Délai de grâce de 30 jours : vous pourrez annuler   │
│   la suppression pendant cette période.                │
└─────────────────────────────────────────────────────────┘
```
- Checkbox (unchecked by default)
- Text changes based on checkbox state
- Background: Light grey

#### Action Buttons
```
┌─────────────────────────────────────────────────────────┐
│            [🗑️ Supprimer mon compte]                   │
│                   (RED BUTTON)                          │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                  [ Annuler ]                            │
│                (OUTLINED BUTTON)                        │
└─────────────────────────────────────────────────────────┘
```

---

### 3. Confirmation Dialog - Double Check

**Dialog Appearance:**
```
╔═══════════════════════════════════════════════════════╗
║ Dernière confirmation                                  ║
║                                                        ║
║ Votre compte sera supprimé immédiatement et            ║
║ définitivement. Cette action est irréversible.         ║
║                                                        ║
║ (ou)                                                   ║
║                                                        ║
║ Votre compte sera programmé pour suppression dans      ║
║ 30 jours. Vous pourrez annuler cette action pendant    ║
║ cette période.                                         ║
║                                                        ║
║                    [ Annuler ]  [Confirmer]            ║
╚═══════════════════════════════════════════════════════╝
```
- Modal dialog overlay
- Message changes based on immediate/grace period choice
- "Confirmer" button in red
- "Annuler" button in default color

---

### 4. Processing State

**During API Call:**
```
┌─────────────────────────────────────────────────────────┐
│            [⏳ Suppression...]                          │
│              (LOADING SPINNER)                          │
└─────────────────────────────────────────────────────────┘
```
- Delete button shows loading spinner
- Button disabled during processing
- Text changes to "Suppression..."

---

### 5. Success State (Immediate Deletion)

**Immediate Redirect:**
- User is logged out automatically
- Navigation to welcome page (`/welcome`)
- No intermediate screen

---

### 6. Success State (Grace Period)

**Snackbar Message:**
```
┌─────────────────────────────────────────────────────────┐
│ ✓ Suppression programmée. Vous avez 30 jours pour      │
│   annuler.                                              │
└─────────────────────────────────────────────────────────┘
```
- Green snackbar at bottom
- Auto-dismisses after 5 seconds
- Page refreshes to show countdown view

**Countdown View:**
```
╔═══════════════════════════════════════════════════════╗
║                      ⚠️                                ║
║                                                        ║
║           Suppression programmée                       ║
║                                                        ║
║      Votre compte sera supprimé dans                   ║
║                                                        ║
║                  30 jours                              ║
║                                                        ║
╚═══════════════════════════════════════════════════════╝

Date de suppression
───────────────────
📅  14/11/2025

Ce qui sera supprimé
───────────────────
[Same list as before]

┌─────────────────────────────────────────────────────────┐
│          [❌ Annuler la suppression]                    │
│              (GREEN BUTTON)                             │
└─────────────────────────────────────────────────────────┘
```

---

### 7. Error States

**Password Incorrect:**
```
┌─────────────────────────────────────────────────────────┐
│ ❌ Erreur lors de la suppression                        │
│    Mot de passe incorrect                              │
└─────────────────────────────────────────────────────────┘
```
- Red snackbar at bottom
- Error message from backend

**Network Error:**
```
┌─────────────────────────────────────────────────────────┐
│ ❌ Erreur de connexion                                  │
│    Veuillez réessayer                                   │
└─────────────────────────────────────────────────────────┘
```

---

## Color Scheme

### Destructive Actions
- Primary: `#F44336` (Red - AppColors.errorRed)
- Background: `#FFEBEE` (Light Red)
- Text: White on red buttons, red on white backgrounds

### Success Actions
- Primary: `#4CAF50` (Green - AppColors.successGreen)
- Used for: Cancel deletion, success messages

### Warning Elements
- Primary: `#FF9800` (Orange - AppColors.warningOrange)
- Icon: `⚠️` Warning amber

### Neutral Elements
- Background: `#FFFFFF` (White - AppColors.backgroundWhite)
- Secondary BG: `#F5F5F5` (Grey - AppColors.backgroundGrey)
- Text Primary: Dark grey
- Text Secondary: Light grey

---

## Accessibility

### Visual Indicators
- Clear color coding (red for danger)
- Icons reinforce meaning (🗑️ for delete, ⚠️ for warning)
- High contrast text
- Multiple confirmation steps

### Text Clarity
- Plain language (no jargon)
- Clear consequences listed
- Explicit action labels
- Undo option visible (grace period)

### User Safety
1. Password required (prevents accidental deletion)
2. Double confirmation (prevents impulsive decisions)
3. Warning banner (sets expectations)
4. Consequences list (informed decision)
5. Grace period option (allows reversal)
6. Countdown display (shows time remaining)

---

## Responsive Design

### Mobile (Portrait)
- Full width buttons
- Stacked layout
- Scroll for content
- Bottom sheet for dialogs

### Tablet (Landscape)
- Centered content (max-width: 600px)
- Side margins for readability
- Modal dialogs

### Desktop
- Centered card layout
- Comfortable reading width
- Hover states on buttons

---

## Animation & Transitions

### Page Transitions
- Slide from right (entering)
- Fade out (exiting after deletion)

### Button States
- Hover: Subtle color change
- Press: Slight scale down
- Loading: Spinner animation

### Dialog
- Fade in with backdrop
- Scale animation
- Center of screen

### Snackbar
- Slide up from bottom
- Auto-dismiss animation

---

## Typography

### Headers
- Font: Bold, 24px
- Color: Dark grey or Red (for warnings)
- Line height: 1.2

### Body Text
- Font: Regular, 16px
- Color: Dark grey
- Line height: 1.5

### Buttons
- Font: Medium, 16px
- Color: White (filled) or Red (text)
- Uppercase: No (French convention)

---

This UI follows Material Design principles and maintains consistency with the rest of the GoldWen app theme.
