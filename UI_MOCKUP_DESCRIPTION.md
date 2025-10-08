# Advanced Recommendations Screen - UI Mockup Description

## Screen Layout

### Header (AppBar)
```
┌─────────────────────────────────────────┐
│ ← Recommandations Avancées              │
│                                         │
│ [Gold background with white text]       │
└─────────────────────────────────────────┘
```

### Main Content (Scrollable)

#### 1. Recommendation Card

```
┌─────────────────────────────────────────┐
│                                         │
│  Score de compatibilité      [87.5%]   │
│                              ┌────────┐ │
│                              │  87.5% │ │
│                              │  Gold  │ │
│                              │Gradient│ │
│                              └────────┘ │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ Détails du score                 │  │
│  │                                   │  │
│  │ 🧠 Personnalité                   │  │
│  │    ████████████░░░░░░░░  51.0    │  │
│  │                                   │  │
│  │ ❤️  Préférences                   │  │
│  │    ██████████░░░░░░░░░░  34.0    │  │
│  │                                   │  │
│  │ ─────────────────────────────     │  │
│  │                                   │  │
│  │ Bonus                             │  │
│  │                                   │  │
│  │ ⚡ Activité        [↑ +8.0]      │  │
│  │ 💬 Taux de réponse [↑ +7.0]      │  │
│  │ 💕 Réciprocité     [↑ +15.0]     │  │
│  │                                   │  │
│  │ ─────────────────────────────     │  │
│  │                                   │  │
│  │ Score de base      85.0           │  │
│  │ Total bonus        30.0           │  │
│  │                                   │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ─────────────────────────────────      │
│                                         │
│  Raisons du match                       │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ 🧠 PERSONNALITÉ          [+15%]  │  │
│  │                                   │  │
│  │ Vous partagez des traits de       │  │
│  │ personnalité similaires           │  │
│  │                                   │  │
│  │ [Blue background with icon]       │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ 🎯 INTÉRÊTS              [+12%]  │  │
│  │                                   │  │
│  │ Intérêts communs en musique       │  │
│  │ et voyage                         │  │
│  │                                   │  │
│  │ [Gold background with icon]       │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ 💜 VALEURS               [+18%]  │  │
│  │                                   │  │
│  │ Valeurs et objectifs de vie       │  │
│  │ alignés                           │  │
│  │                                   │  │
│  │ [Purple background with icon]     │  │
│  └───────────────────────────────────┘  │
│                                         │
└─────────────────────────────────────────┘
```

## Color Coding

### Score Display
- **Final Score Badge**: Gold gradient (D4AF37 → B8941F)
  - White text
  - Large, bold percentage
  - Rounded corners

### Base Scores
- **Personality**: Blue (#2196F3)
  - Brain icon
  - Blue progress bar
  
- **Preferences**: Gold (#D4AF37)
  - Heart icon
  - Gold progress bar

### Bonuses/Malus
- **Positive Bonuses**: Green (#4CAF50)
  - Green badge with up arrow
  - White text with +X.X format
  
- **Negative Malus**: Red (#E57373)
  - Red badge with down arrow
  - White text with -X.X format

### Match Reasons Categories
- **Personality**: Blue (#2196F3) - Brain icon
- **Interests**: Gold (#D4AF37) - Target icon
- **Values**: Purple (#9C27B0) - Heart icon
- **Lifestyle**: Green (#4CAF50) - City icon
- **Communication**: Orange (#FF5722) - Chat bubble icon
- **Activity**: Orange (#FF9800) - Lightning icon
- **Reciprocity**: Pink (#E91E63) - Sync icon

## Interaction States

### Loading State
```
┌─────────────────────────────────────────┐
│                                         │
│              ⟳ Loading...               │
│                                         │
│     Calcul des compatibilités          │
│     avancées...                        │
│                                         │
│     [Animated spinner]                  │
│                                         │
└─────────────────────────────────────────┘
```

### Error State
```
┌─────────────────────────────────────────┐
│                                         │
│              ⚠️ Error                   │
│                                         │
│     Erreur de chargement               │
│                                         │
│     [Error message text]               │
│                                         │
│     ┌──────────────┐                   │
│     │  Réessayer   │                   │
│     └──────────────┘                   │
│                                         │
└─────────────────────────────────────────┘
```

### Empty State
```
┌─────────────────────────────────────────┐
│                                         │
│              🔍                         │
│                                         │
│     Aucune recommandation              │
│                                         │
│     Aucune recommandation avancée      │
│     n'est disponible pour le moment.   │
│                                         │
└─────────────────────────────────────────┘
```

## Responsive Behavior

### Mobile (< 600px)
- Single column layout
- Full width cards
- Stack progress bars vertically
- Touch-optimized spacing

### Tablet (600-1200px)
- Single column layout
- Max width 800px centered
- Larger text sizes
- More padding

### Desktop (> 1200px)
- Single column layout
- Max width 1000px centered
- Comfortable reading width
- Hover effects on interactive elements

## Accessibility Features

### Screen Reader Support
- Semantic labels for all elements
- Proper heading hierarchy
- Descriptive button labels
- ARIA attributes where needed

### High Contrast Mode
- Increased border thickness
- Solid colors instead of gradients
- Enhanced text contrast
- Clear visual separators

### Reduced Motion
- Disable animations
- Instant transitions
- No spinning loaders
- Static progress bars

## Animation Details

### Page Entry
1. Fade in effect (300ms)
2. Slide up cards (staggered 100ms each)
3. Progress bars animate on appear

### Pull to Refresh
1. Pull down gesture
2. Spinner appears
3. Content refreshes
4. Smooth return to top

### Score Updates
1. Number counts up (500ms)
2. Progress bars fill (300ms)
3. Badges pop in (200ms delay)

## Spacing & Typography

### Spacing
- Card margin: 16px
- Card padding: 16px
- Section spacing: 24px
- Item spacing: 12px
- Small spacing: 8px

### Typography
- **Headline**: 24px, Bold
- **Title**: 18px, Semi-Bold
- **Body**: 16px, Regular
- **Small**: 14px, Regular
- **Caption**: 12px, Regular

### Font Weights
- **Bold**: 700
- **Semi-Bold**: 600
- **Medium**: 500
- **Regular**: 400

## Interactive Elements

### Buttons
- Elevated with shadow
- Gold background
- White text
- Rounded corners (8px)
- Ripple effect on tap

### Cards
- White background
- Subtle shadow
- Rounded corners (16px)
- Elevation 2

### Progress Bars
- Height: 6px
- Rounded ends
- Smooth fill animation
- Background: Light grey

## Edge Cases

### No Bonuses
- Shows 0.0 with up arrow
- Neutral color (grey)

### All Negative
- Shows with down arrows
- Red indicators
- Warning message

### Very High Scores (>95)
- Special celebration badge
- Enhanced gold color
- Congratulatory message

### Very Low Scores (<50)
- Muted colors
- Helpful suggestions
- Encouraging message

## Example Flow

1. User taps "View Advanced Score" on profile
2. Loading animation appears
3. API call fetches V2 compatibility
4. Cards animate in with scores
5. User scrolls to see all details
6. User can pull to refresh
7. User taps back to return

## Technical Notes

- All measurements in logical pixels (dp)
- Colors follow Material Design
- Icons from Material Icons
- Animations follow Material Motion
- Responsive breakpoints standard
- Touch targets minimum 48x48dp
