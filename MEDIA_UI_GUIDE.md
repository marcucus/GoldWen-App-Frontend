# Audio/Video Media Upload - UI/UX Guide

## User Flow

### 1. Profile Setup - Media Upload Page

**Location**: Between "Photos" and "Prompts" pages in profile setup flow

**Header Section**:
- Title: "Médias Audio/Vidéo (Optionnel)"
- Subtitle: "Ajoutez des fichiers audio ou vidéo pour enrichir votre profil"
- Counter: "Audio: 0/2 | Vidéo: 0/1"

**Upload Section**:

When empty (no media uploaded):
```
┌─────────────────────────────────────────┐
│  ╔═════════════════════════════════╗    │
│  ║         [Perm Media Icon]       ║    │
│  ║                                 ║    │
│  ║     Aucun média ajouté          ║    │
│  ║                                 ║    │
│  ║  Utilisez le bouton + pour      ║    │
│  ║  ajouter audio ou vidéo         ║    │
│  ╚═════════════════════════════════╝    │
└─────────────────────────────────────────┘
```

**Add Button** (Top right):
- Icon: "+" circle outline in gold color
- When clicked, shows popup menu with:
  - 🎵 Ajouter Audio
  - 🎥 Ajouter Vidéo
  - (Disabled options are grayed out when limit reached)

When media files are added, they appear as cards:
```
┌─────────────────────────────────────────┐
│  ╔═════════════════════════════════╗    │
│  ║ 🔵 Audio 1                      ║    │
│  ║    2:00                         ║    │
│  ║              [▶️] [🗑️]          ║    │
│  ╚═════════════════════════════════╝    │
│                                         │
│  ╔═════════════════════════════════╗    │
│  ║ 🟣 Vidéo 1                      ║    │
│  ║    3:45                         ║    │
│  ║              [▶️] [🗑️]          ║    │
│  ╚═════════════════════════════════╝    │
└─────────────────────────────────────────┘
```

**Continue Button**:
- Always enabled (media is optional)
- Full width at bottom
- Text: "Continuer"

---

## 2. File Upload Process

### Step 1: File Selection
User clicks on "+ Ajouter Audio" or "+ Ajouter Vidéo"
- Opens native file picker
- Shows only allowed file types
- User selects a file

### Step 2: Validation
**If file is too large (>50MB):**
```
┌─────────────────────────────────────────┐
│  ⚠️  Le fichier est trop volumineux.   │
│      Taille maximale: 50MB       [✕]   │
└─────────────────────────────────────────┘
```

**If invalid format:**
```
┌─────────────────────────────────────────┐
│  ⚠️  Format de fichier non supporté.   │
│  Formats acceptés: mp3, wav, m4a... [✕]│
└─────────────────────────────────────────┘
```

### Step 3: Upload Progress
```
┌─────────────────────────────────────────┐
│  [████████████████░░░░░░░] 75%         │
└─────────────────────────────────────────┘
```

### Step 4: Success
```
┌─────────────────────────────────────────┐
│  ✓ Audio ajouté avec succès             │
└─────────────────────────────────────────┘
```

---

## 3. Media Player UI

### Audio Player
```
┌─────────────────────────────────────────┐
│                                         │
│            🎵 [Large Icon]              │
│                                         │
│  ●─────────────○────────────── 2:15    │
│  1:30                                   │
│                                         │
│              [⏸️/▶️]                    │
│          (Play/Pause)                   │
│                                         │
└─────────────────────────────────────────┘
```

Components:
- Large audio icon (64px) in gold color
- Progress slider with:
  - Current position (left)
  - Total duration (right)
  - Draggable thumb
- Large play/pause button (48px) centered
- Gradient background (gold to cream)

### Video Player
```
┌─────────────────────────────────────────┐
│                                         │
│     [Video Content/Thumbnail]           │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │  ●────────○────────── 1:45 / 3:30 │  │
│  │              [⏸️]                  │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

Components:
- Video display with aspect ratio preserved
- Controls overlay at bottom with semi-transparent background
- Progress slider
- Play/pause button
- Time display (current / total)

---

## 4. Profile View (Others Viewing)

### Profile Detail Page

After photos gallery section, if user has media files:

```
┌─────────────────────────────────────────┐
│  Médias                                 │
│  ────────                               │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │     🎵 Audio Player UI            │  │
│  │  ●───○────────── 1:30 / 2:00      │  │
│  │          [▶️]                      │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │   [Video Thumbnail/Player]        │  │
│  │  ●───○────────── 0:45 / 3:30      │  │
│  │          [▶️]                      │  │
│  └───────────────────────────────────┘  │
│                                         │
└─────────────────────────────────────────┘
```

---

## 5. Delete Confirmation Dialog

```
┌─────────────────────────────────────────┐
│  Confirmer la suppression               │
│  ─────────────────────────                │
│                                         │
│  Voulez-vous vraiment supprimer         │
│  ce média ?                             │
│                                         │
│         [Annuler]    [Supprimer]        │
│                         (Red)           │
└─────────────────────────────────────────┘
```

---

## 6. Colors & Icons

### Icons
- Audio: `Icons.audiotrack` (Blue: #2196F3)
- Video: `Icons.videocam` (Purple: #9C27B0)
- Play: `Icons.play_circle_filled` / `Icons.play_arrow`
- Pause: `Icons.pause_circle_filled` / `Icons.pause`
- Delete: `Icons.delete_outline` (Red from theme)
- Add: `Icons.add_circle_outline` (Gold from theme)
- Media: `Icons.perm_media`

### Color Scheme
- Primary Gold: #D4AF37 (from AppColors.primaryGold)
- Accent Cream: #FFF8DC (from AppColors.accentCream)
- Error: Red from theme
- Success: Green (#4CAF50)
- Audio Accent: Blue (#2196F3)
- Video Accent: Purple (#9C27B0)

### Spacing
- AppSpacing.xs: 4px
- AppSpacing.sm: 8px
- AppSpacing.md: 16px
- AppSpacing.lg: 24px
- AppSpacing.xl: 32px
- AppSpacing.xxl: 48px

### Border Radius
- AppBorderRadius.small: 4px
- AppBorderRadius.medium: 8px
- AppBorderRadius.large: 16px

---

## 7. Responsive Design

### Mobile (< 600px width)
- Single column layout
- Full width buttons
- Media players expand to container width
- Touch-optimized controls (min 48x48dp)

### Tablet (600px - 1024px width)
- 2 column grid for media files
- Larger media players
- Increased padding

### Desktop (> 1024px width)
- Maximum content width: 800px
- Centered layout
- Side-by-side audio/video display

---

## 8. Accessibility

### Screen Readers
- All icons have semantic labels
- Media durations announced
- Upload status announced
- Error messages announced

### Keyboard Navigation
- Tab order: Add button → Media cards → Controls
- Enter/Space to play/pause
- Arrow keys to seek (when focused on slider)
- Delete key to remove (with confirmation)

### High Contrast Mode
- Border visibility increased
- Icon contrast maintained
- Focus indicators visible

### Touch Targets
- All interactive elements minimum 48x48dp
- Adequate spacing between controls
- Large touch areas for sliders

---

## 9. Error States

### Network Error
```
┌─────────────────────────────────────────┐
│  ❌ Erreur de chargement                │
│     Impossible de charger le média.     │
│     Vérifiez votre connexion.           │
└─────────────────────────────────────────┘
```

### Upload Failed
```
┌─────────────────────────────────────────┐
│  ⚠️ Erreur lors de l'ajout du fichier: │
│     [Error details]               [✕]   │
└─────────────────────────────────────────┘
```

### Playback Error
```
┌─────────────────────────────────────────┐
│            ❌ [Icon]                     │
│                                         │
│     Erreur de lecture:                  │
│     [Error message]                     │
│                                         │
└─────────────────────────────────────────┘
```

---

## 10. Animation & Transitions

### Upload Progress
- Linear progress bar animation
- Smooth 0-100% transition
- Duration based on upload speed

### Media Card Appearance
- Fade in + slide up animation
- Duration: 300ms
- Easing: ease-out

### Player Controls
- Fade in/out on hover (desktop)
- Always visible on mobile
- Smooth opacity transitions

### Delete Animation
- Card fade out
- Slide up remaining items
- Duration: 250ms
