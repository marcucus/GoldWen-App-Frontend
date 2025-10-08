# GoldWen Plus Subscription - UI States & User Flows

## UI States Documentation

This document describes all UI states and user flows for the GoldWen Plus subscription feature.

## Subscription Page States

### 1. Loading State
**Trigger**: Page first loads, plans being fetched
**UI Elements**:
- Animated gold gradient background
- Header with "GoldWen Plus" title
- Loading spinner (CircularProgressIndicator)
- Text: "Chargement des plans..."
**User Actions**: None - automatic transition

### 2. Error State
**Trigger**: Failed to load plans from API/RevenueCat
**UI Elements**:
- Error icon (Icons.error_outline)
- Title: "Erreur lors du chargement"
- Error message (from provider.error)
- "Réessayer" button
**User Actions**:
- Tap "Réessayer" → Retry loading plans
- Tap back button → Return to previous page

### 3. Normal State (Plans Available)
**Trigger**: Plans successfully loaded
**UI Elements**:

**Header Section**:
- Back button (top-left)
- "GoldWen Plus" title
- "Débloquez votre potentiel" subtitle
- Animated gradient background

**Features Section**:
- Title: "Fonctionnalités Premium"
- Feature cards (4 items):
  - 3 sélections par jour (❤️)
  - Chat illimité (💬)
  - Voir qui vous a sélectionné (👁️)
  - Profil prioritaire (⭐)

**Pricing Section**:
- Title: "Choisissez votre plan"
- Plan cards (dynamically loaded):
  - Plan duration and name
  - "POPULAIRE" badge (if applicable)
  - Monthly price breakdown
  - Savings text (for multi-month plans)
  - Total price
  - Selection indicator (radio button)

**Subscribe Button**:
- Text: "S'abonner maintenant"
- Premium white button with gold text
- Animated slide-in appearance

**Legal Links**:
- Terms of Service
- Privacy Policy
- Cancellation policy text

**User Actions**:
- Select a plan → Highlights selected plan
- Tap "S'abonner maintenant" → Initiates purchase
- Tap back → Return to previous page
- Tap legal links → Navigate to legal pages

### 4. Processing State
**Trigger**: User taps "S'abonner maintenant"
**UI Elements**:
- Subscribe button changes to "Traitement..."
- Loading indicator on button
- Button becomes disabled
- Plans remain visible but not selectable
**User Actions**: 
- Wait for RevenueCat payment sheet
- Cannot interact with page during processing

### 5. RevenueCat Payment Sheet
**Trigger**: Purchase initiated successfully
**UI Elements**:
- Native iOS App Store or Android Play Store payment sheet
- Managed entirely by RevenueCat SDK
- Shows selected plan details and price
**User Actions**:
- Complete purchase → Success state
- Cancel purchase → Returns to normal state (no error)
- Face/Touch ID or password authentication

### 6. Success State (Dialog)
**Trigger**: Purchase completed and verified
**UI Elements**:
- Full-screen modal dialog
- Premium gradient background
- White circle with gold checkmark icon
- Title: "Félicitations !"
- Message: "Vous êtes maintenant membre GoldWen Plus\nVous pouvez désormais choisir jusqu'à 3 profils par jour !"
- "Commencer" button (white with gold text)
**User Actions**:
- Tap "Commencer" → Navigate to home page
- Cannot dismiss by tapping outside

### 7. Error State (Dialog)
**Trigger**: Purchase failed (network error, verification failure)
**UI Elements**:
- Alert dialog
- Error icon
- Title: "Erreur d'abonnement"
- Error message describing the issue
- "OK" button
**User Actions**:
- Tap "OK" → Dismiss dialog, return to normal state
- Can retry purchase

## Widget States

### SubscriptionPromoBanner

**Compact Variant**:
- Small banner with gold accent
- Icon: Star
- Message: "Passez à GoldWen Plus pour 3 choix/jour"
- Arrow indicator
- Used in: Daily matches page

**Full Variant**:
- Larger banner with more details
- Icon: Star
- Primary message
- Subtitle: "Plus de matches, plus de possibilités !"
- Arrow indicator
- Used in: Settings, other promotional areas

**User Actions**:
- Tap anywhere on banner → Navigate to /subscription page

### SubscriptionLimitReachedDialog

**Displayed When**: Free user reaches 1/1 daily selections

**UI Elements**:
- Alert dialog
- Gold star icon in header
- Title: "Limite atteinte"
- Message: "Vous avez utilisé 1/1 sélections aujourd'hui."
- Premium features box with gold border:
  - "Avec GoldWen Plus:"
  - • 3 sélections par jour au lieu d'1
  - • Chat illimité avec vos matches
  - • Voir qui vous a sélectionné
  - • Profil prioritaire
- Two buttons:
  - "Plus tard" (text button)
  - "Passer à Plus" (elevated button, gold)

**User Actions**:
- Tap "Plus tard" → Dismiss dialog
- Tap "Passer à Plus" → Navigate to /subscription page

### SubscriptionStatusIndicator

**Premium User (Active)**:
- Gold gradient border
- Star icon (gold)
- Text: "GoldWen Plus actif"
- Compact or full variant

**Premium User (Expiring Soon ≤7 days)**:
- Orange gradient border
- Warning icon (orange)
- Text: "Plus expire dans X jour(s)"
- Compact or full variant

**Free User**:
- Widget not displayed (returns empty container)

## User Journey Flows

### Flow 1: Free User Discovers Premium

```
Daily Matches Page (Free User)
    ↓
Sees SubscriptionPromoBanner
    ↓
Taps Banner
    ↓
Subscription Page Opens
    ↓
Views Features & Plans
    ↓
Selects Quarterly Plan
    ↓
Taps "S'abonner maintenant"
    ↓
RevenueCat Payment Sheet
    ↓
Completes Payment
    ↓
Success Dialog
    ↓
Taps "Commencer"
    ↓
Returns to Home (Now Premium)
```

### Flow 2: Free User Hits Selection Limit

```
Daily Matches Page
    ↓
Selects First Profile (1/1)
    ↓
Tries to Select Second Profile
    ↓
SubscriptionLimitReachedDialog Appears
    ↓
User Reviews Premium Benefits
    ↓
Taps "Passer à Plus"
    ↓
Subscription Page Opens
    ↓
(Continues as Flow 1)
```

### Flow 3: User Cancels Purchase

```
Subscription Page
    ↓
Selects Plan
    ↓
Taps "S'abonner maintenant"
    ↓
RevenueCat Payment Sheet Opens
    ↓
User Taps "Cancel" or Dismisses
    ↓
Returns to Subscription Page
    ↓
(No error shown, can try again)
```

### Flow 4: Purchase Error Occurs

```
Subscription Page
    ↓
Selects Plan
    ↓
Taps "S'abonner maintenant"
    ↓
Network Error / Verification Failure
    ↓
Error Dialog Appears
    ↓
User Reads Error Message
    ↓
Taps "OK"
    ↓
Returns to Subscription Page
    ↓
Can Tap "Réessayer" or Try Different Plan
```

### Flow 5: Premium User Views Status

```
Settings Page
    ↓
Scrolls to Subscription Section
    ↓
Sees SubscriptionStatusIndicator
    ↓
Views "Gérer mon abonnement" Option
    ↓
Taps to View Details
    ↓
Management Dialog Opens
    ↓
Options: Cancel / View Details / Change Plan
```

### Flow 6: User Restores Purchase

```
Settings Page (New Device or Reinstalled App)
    ↓
Subscription Section Shows "Upgrade"
    ↓
User Taps "Restaurer mes achats"
    ↓
RevenueCat Checks Purchase History
    ↓
Success: Subscription Restored
    ↓
Status Updated to Premium
    ↓
SubscriptionStatusIndicator Appears
```

## Responsive Design Notes

### Mobile Portrait
- Single column layout
- Full-width cards
- Stacked plan cards
- Comfortable touch targets (min 48x48)

### Mobile Landscape
- Similar to portrait
- Slightly reduced vertical spacing
- Scrollable content

### Tablet
- Centered content with max-width
- Larger spacing
- Enhanced animations

## Accessibility Features

### Visual
- High contrast text on gradient backgrounds
- Clear visual hierarchy
- Color is not the only indicator (icons + text)
- Large, readable fonts

### Interaction
- All interactive elements have >48dp touch targets
- Clear focus states
- Semantic labels for screen readers

### Content
- Simple, clear language
- Price information prominently displayed
- Error messages are specific and actionable

## Animation Timeline

**Page Load**:
- 0ms: Background gradient animation starts
- 200ms: Header fades in
- 400ms: Features section slides in
- 600ms: Pricing section appears
- 900ms: Subscribe button slides in
- 1000ms: Legal links fade in

**Plan Selection**:
- Instant highlight change
- Smooth border color transition (200ms)
- Radio button fill animation (150ms)

**Purchase Process**:
- Button text change (instant)
- Loading indicator fade in (100ms)

## Color Scheme

### Primary Colors
- Gold: `#D4AF37` (AppColors.primaryGold)
- Gold Dark: `#B8941F` (AppColors.primaryGoldDark)
- Gold Light: `#E6D08A` (AppColors.primaryGoldLight)

### Status Colors
- Success: Green for savings text
- Warning: Orange for expiring subscription
- Error: Red for error states

### Background
- Dynamic gradient: Gold tones
- Semi-transparent cards: White with opacity
- Borders: White with varying opacity

## Typography Hierarchy

1. **Page Title**: headlineSmall, bold, white
2. **Section Titles**: headlineSmall, bold, white
3. **Plan Names**: titleLarge, bold, white
4. **Prices**: headlineSmall, bold, white
5. **Body Text**: bodyMedium, white (0.8-0.9 opacity)
6. **Small Text**: bodySmall, white (0.6-0.8 opacity)
7. **Badges**: bodySmall, 10px, bold, gold on white

## Best Practices Applied

1. **Progressive Disclosure**: Show features before pricing
2. **Social Proof**: "POPULAIRE" badge on recommended plan
3. **Urgency**: Savings text creates value perception
4. **Clarity**: Clear pricing with no hidden fees
5. **Trust**: Legal links easily accessible
6. **Friction Reduction**: Single tap to purchase
7. **Confirmation**: Success dialog provides positive reinforcement
8. **Error Recovery**: Clear error messages with retry options
9. **Accessibility**: High contrast, large targets, clear labels
10. **Performance**: Smooth animations, lazy loading

## Testing Checklist

- [ ] All states display correctly
- [ ] Animations are smooth (60fps)
- [ ] Touch targets are >48dp
- [ ] Text is readable on all backgrounds
- [ ] Error states show helpful messages
- [ ] Success flow completes properly
- [ ] Cancellation doesn't show errors
- [ ] Back navigation works from all states
- [ ] Legal links navigate correctly
- [ ] Loading states show appropriate indicators
- [ ] Plans load from RevenueCat correctly
- [ ] Subscription status updates after purchase
- [ ] Banner appears correctly for free users
- [ ] Limit dialog shows at correct time
- [ ] Status indicator reflects actual state
