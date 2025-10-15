# Visual Guide: Fix de la Gestion du Focus (Étape 1/6)

## Problème Initial

```
┌─────────────────────────────────────┐
│  Étape 1/6 - Profil                 │
├─────────────────────────────────────┤
│                                     │
│  Parlez-nous de vous                │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ Pseudo: [Jean]              │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ Date: 01/01/1990            │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ Bio: Je suis passionné...   │◄──── Champ focus
│  │ [cursor]                    │   │
│  │                             │   │
│  │                             │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │      Continuer              │   │
│  └─────────────────────────────┘   │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │      [Clavier virtuel]          │ │ ◄── Clavier OUVERT
│ │      RESTE ACTIF ❌             │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
        ↓ Tap en dehors
        ↓ (zone vide)
        ↓ RIEN NE SE PASSE ❌
```

**Comportement problématique:**
- L'utilisateur ne peut pas fermer le clavier en tapant en dehors
- Le champ bio reste focus
- Il faut utiliser le bouton "retour" système

---

## Solution Implémentée

### Architecture

```
┌─────────────────────────────────────────────────┐
│  MaterialApp (main.dart)                        │
│  └─ KeyboardDismissible (GLOBAL)               │
│     └─ Router                                   │
│        └─ ProfileSetupPage                     │
│           └─ PageView                           │
│              └─ _buildBasicInfoPage()           │
│                 └─ KeyboardDismissible (LOCAL) │ ◄── AJOUTÉ!
│                    └─ SingleChildScrollView     │
│                       └─ Column                 │
│                          ├─ Text fields         │
│                          └─ Button              │
└─────────────────────────────────────────────────┘
```

### Code Changement

**Avant:**
```dart
Widget _buildBasicInfoPage() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Column(
      children: [
        // ... champs de formulaire ...
      ],
    ),
  );
}
```

**Après:**
```dart
Widget _buildBasicInfoPage() {
  return KeyboardDismissible(           // ◄── Wrapper ajouté
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          // ... champs de formulaire ...
        ],
      ),
    ),
  );
}
```

---

## Nouveau Comportement

```
┌─────────────────────────────────────┐
│  Étape 1/6 - Profil                 │
├─────────────────────────────────────┤
│                                     │
│  Parlez-nous de vous   ◄──────────────┐
│                                     │  │
│  ┌─────────────────────────────┐   │  │ Zone tappable
│  │ Pseudo: [Jean]              │   │  │ (dismiss keyboard)
│  └─────────────────────────────┘   │  │
│                                     │  │
│  ┌─────────────────────────────┐   │  │
│  │ Date: 01/01/1990            │   │  │
│  └─────────────────────────────┘   │  │
│                                     │  │
│  ┌─────────────────────────────┐   │  │
│  │ Bio: Je suis passionné...   │   │  │
│  │                             │   │  │
│  │                             │   │  │
│  └─────────────────────────────┘   │  │
│                                     │  │
│  ┌─────────────────────────────┐   │  │
│  │      Continuer              │   │  │
│  └─────────────────────────────┘   │  │
│                                     │  │
│  [Zone vide]    ◄─────────────────────┘
│                                     │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │      [Clavier virtuel]          │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
        ↓ Tap sur titre, zone vide, etc.
        ↓
        ↓
┌─────────────────────────────────────┐
│  Étape 1/6 - Profil                 │
├─────────────────────────────────────┤
│                                     │
│  Parlez-nous de vous                │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ Pseudo: [Jean]              │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ Date: 01/01/1990            │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ Bio: Je suis passionné...   │   │ ◄── Plus de focus
│  │                             │   │
│  │                             │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │      Continuer              │   │
│  └─────────────────────────────┘   │
│                                     │
│  [Zone vide]                        │
│                                     │
│  Clavier FERMÉ ✅                   │
│                                     │
└─────────────────────────────────────┘
```

**Nouveau comportement:**
- L'utilisateur peut fermer le clavier en tapant n'importe où en dehors ✅
- Le champ perd le focus automatiquement ✅
- Expérience utilisateur fluide et intuitive ✅

---

## Mécanisme du Widget KeyboardDismissible

```dart
class KeyboardDismissible extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Détecte le tap
        final currentFocus = FocusScope.of(context);
        
        // Si un champ est focus
        if (!currentFocus.hasPrimaryFocus && 
            currentFocus.focusedChild != null) {
          
          // Retire le focus → ferme le clavier
          currentFocus.unfocus();
        }
      },
      // Permet aux widgets enfants de recevoir les taps en premier
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}
```

**Fonctionnement:**
1. Détecte tous les taps sur la zone
2. Vérifie si un champ texte a le focus
3. Si oui, retire le focus (ferme le clavier)
4. Les widgets enfants (boutons, champs) reçoivent leurs taps normalement

---

## Impact

### Fichiers Modifiés
- ✅ `lib/features/profile/pages/profile_setup_page.dart` (1 import + 1 wrapper)
- ✅ `test/profile_setup_keyboard_dismissal_test.dart` (nouveau, 3 tests)
- ✅ `FIX_KEYBOARD_FOCUS_BIO.md` (documentation)

### Pages Affectées
- ✅ Page 1/6: Informations de base (FIXÉE)
- ⚪ Page 2/6: Photos (pas de champs texte)
- ⚪ Page 3/6: Médias (pas de champs texte)
- ⚪ Page 4/6: Prompts (a des champs, mais non mentionné dans l'issue)
- ⚪ Page 5/6: Validation (pas de champs texte)
- ⚪ Page 6/6: Révision (pas de champs texte)

### Régression
- ✅ Aucune: solution non-invasive
- ✅ Compatible avec le KeyboardDismissible global
- ✅ Ne modifie pas le comportement des autres widgets

---

## Tests

```dart
testWidgets('Bio field should lose focus when tapping outside', ...) {
  // 1. Tap sur le champ bio
  await tester.tap(bioField);
  
  // 2. Vérifier que le champ a le focus
  expect(FocusScope.of(context).hasFocus, isTrue);
  
  // 3. Tap en dehors (sur le titre)
  await tester.tap(find.text('Parlez-nous de vous'));
  
  // 4. Le focus est retiré ✅
}
```

**Couverture:**
- ✅ Test bio field focus/unfocus
- ✅ Test name field focus/unfocus
- ✅ Test présence du widget KeyboardDismissible
