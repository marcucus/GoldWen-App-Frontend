# Photo Validation UI - Visual Mockup Description

## Before Implementation

```
┌─────────────────────────────────────────────┐
│         Ajoutez vos photos                  │
│   Ajoutez au moins 3 photos pour continuer │
│                                             │
│  ┌──────┐  ┌──────┐  ┌──────┐             │
│  │Photo1│  │Photo2│  │ [+] │             │
│  └──────┘  └──────┘  └──────┘             │
│  ┌──────┐  ┌──────┐  ┌──────┐             │
│  │ [+] │  │ [+] │  │ [+] │             │
│  └──────┘  └──────┘  └──────┘             │
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │  Continuer (2/6)  [DISABLED/GRAY]  │   │
│  └─────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

## After Implementation - LESS THAN 3 PHOTOS

```
┌─────────────────────────────────────────────┐
│         Ajoutez vos photos                  │
│   Ajoutez au moins 3 photos pour continuer │
│                                             │
│  ┌──────┐  ┌──────┐  ┌──────┐             │
│  │Photo1│  │Photo2│  │ [+] │             │
│  └──────┘  └──────┘  └──────┘             │
│  ┌──────┐  ┌──────┐  ┌──────┐             │
│  │ [+] │  │ [+] │  │ [+] │             │
│  └──────┘  └──────┘  └──────┘             │
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │  ⓘ 2/3 photos minimum ajoutées     │   │
│  │     [AMBER WARNING COLOR]           │   │
│  └─────────────────────────────────────┘   │
│  ┌─────────────────────────────────────┐   │
│  │ Continuer (2/3 minimum) [GRAY BG]  │   │
│  └─────────────────────────────────────┘   │
└─────────────────────────────────────────────┘

When button is clicked:
┌──────────────────────────────────────┐
│  ⚠️  Photos manquantes              │
│                                      │
│  Vous devez ajouter au moins 3      │
│  photos pour continuer.             │
│                                      │
│  Les photos permettent aux autres   │
│  utilisateurs de mieux vous         │
│  connaître et augmentent vos        │
│  chances de match.                  │
│                                      │
│          [ J'ai compris ]           │
└──────────────────────────────────────┘
```

## After Implementation - 3 OR MORE PHOTOS

```
┌─────────────────────────────────────────────┐
│         Ajoutez vos photos                  │
│   Ajoutez au moins 3 photos pour continuer │
│                                             │
│  ┌──────┐  ┌──────┐  ┌──────┐             │
│  │Photo1│  │Photo2│  │Photo3│             │
│  └──────┘  └──────┘  └──────┘             │
│  ┌──────┐  ┌──────┐  ┌──────┐             │
│  │Photo4│  │ [+] │  │ [+] │             │
│  └──────┘  └──────┘  └──────┘             │
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │  ✓ 4/3 photos minimum ajoutées     │   │
│  │     [GREEN SUCCESS COLOR]           │   │
│  └─────────────────────────────────────┘   │
│  ┌─────────────────────────────────────┐   │
│  │  Continuer (4/6)  [GOLD ENABLED]   │   │
│  └─────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

## Color Legend

- **Amber/Warning** (#FFC107): Used when requirement not met
  - Info icon (ⓘ)
  - Text color
  
- **Green/Success** (#4CAF50): Used when requirement is met
  - Check circle icon (✓)
  - Text color

- **Gray/Disabled** (#9E9E9E): Used for disabled button background
  
- **Gold/Primary** (#D4AF37): Used for enabled button background

## Icons Used

- **Warning state**: `Icons.info_outline` (ⓘ)
- **Success state**: `Icons.check_circle` (✓)
- **Alert dialog**: `Icons.warning_amber_rounded` (⚠️)

## Interaction Flow

1. **User lands on photo page with 0 photos**
   - Indicator: "0/3 photos minimum ajoutées" (amber)
   - Button: Grayed out "Continuer (0/3 minimum)"
   - Action: Shows alert dialog

2. **User adds 1st photo**
   - Indicator updates: "1/3 photos minimum ajoutées" (amber)
   - Button: Still grayed "Continuer (1/3 minimum)"
   - Action: Shows alert dialog

3. **User adds 2nd photo**
   - Indicator updates: "2/3 photos minimum ajoutées" (amber)
   - Button: Still grayed "Continuer (2/3 minimum)"
   - Action: Shows alert dialog

4. **User adds 3rd photo** ✨
   - Indicator changes: "3/3 photos minimum ajoutées" (green with check)
   - Button: Enabled "Continuer (3/6)" (gold)
   - Action: Proceeds to next page

5. **User adds more photos (4, 5, 6)**
   - Indicator updates: "4/3 photos minimum ajoutées" (green)
   - Button: "Continuer (4/6)" (gold)
   - Action: Proceeds to next page

## Accessibility Notes

- Clear visual feedback through color AND icons
- Text explains the requirement ("minimum" keyword)
- Alert provides additional context
- Button state changes are both visual and functional
- Meets WCAG color contrast requirements (verified in AppColors)
