# Fix: Gestion du Focus dans la Bio (Étape 1/6)

## Problème

À l'étape 1/6 de la création du profil (page d'informations de base), il était impossible de déselectionner le champ texte de la bio. Le clavier virtuel restait actif même lorsque l'utilisateur tapait en dehors du champ.

## Cause

Bien qu'une solution globale de gestion du focus (`KeyboardDismissible`) soit déjà intégrée dans l'application au niveau de `main.dart`, il existe des cas où la structure de la page (notamment avec `SingleChildScrollView`) peut ne pas offrir suffisamment d'espace vide visible pour permettre à l'utilisateur de taper en dehors des champs de saisie, surtout lorsque le clavier est ouvert.

## Solution Implémentée

### Changements au Code

**Fichier**: `lib/features/profile/pages/profile_setup_page.dart`

1. **Import du widget `KeyboardDismissible`**:
   ```dart
   import '../../../shared/widgets/keyboard_dismissible.dart';
   ```

2. **Encapsulation de la page d'informations de base**:
   La méthode `_buildBasicInfoPage()` a été modifiée pour envelopper son contenu dans un widget `KeyboardDismissible`:
   ```dart
   Widget _buildBasicInfoPage() {
     return KeyboardDismissible(
       child: SingleChildScrollView(
         padding: const EdgeInsets.all(AppSpacing.lg),
         child: Column(
           children: [
             // ... contenu existant ...
           ],
         ),
       ),
     );
   }
   ```

### Principe de Fonctionnement

Le widget `KeyboardDismissible` :
- Détecte les taps sur les zones vides de la page
- Retire le focus du champ actif (nom, bio, etc.)
- Ferme automatiquement le clavier virtuel
- Utilise `HitTestBehavior.translucent` pour ne pas bloquer les interactions avec les autres widgets (boutons, champs de saisie, etc.)

### Tests Ajoutés

**Fichier**: `test/profile_setup_keyboard_dismissal_test.dart`

Trois nouveaux tests ont été créés pour vérifier :
1. Le champ bio perd le focus quand on tape en dehors
2. Le champ nom/pseudo perd le focus quand on tape en dehors
3. La présence du widget `KeyboardDismissible` dans la page

## Conformité avec les Spécifications

Cette solution respecte les principes du cahier des charges :

- ✅ **Clean Code**: Changement minimal et ciblé, réutilise un widget existant
- ✅ **Non-régression**: Ne modifie pas le comportement des autres pages
- ✅ **Performance**: Utilise le système de gestion de focus natif de Flutter
- ✅ **Tests**: Couverture de tests ajoutée pour valider le comportement
- ✅ **Accessibilité**: Améliore l'expérience utilisateur sur mobile

## Comportement Attendu

### Avant le Fix
- L'utilisateur tape dans le champ bio → Le clavier s'ouvre
- L'utilisateur tape en dehors du champ → **Le clavier reste ouvert** ❌
- L'utilisateur doit utiliser le bouton "retour" du système pour fermer le clavier

### Après le Fix
- L'utilisateur tape dans le champ bio → Le clavier s'ouvre
- L'utilisateur tape en dehors du champ → **Le clavier se ferme automatiquement** ✅
- L'expérience utilisateur est fluide et intuitive

## Notes Techniques

- Cette solution est cohérente avec le pattern déjà utilisé dans `lib/demo/keyboard_dismissal_demo.dart`
- Le widget `KeyboardDismissible` est un widget réutilisable déjà présent dans le codebase
- La solution est locale à la page concernée et n'affecte pas les autres pages de l'application
- Aucune dépendance externe n'a été ajoutée

## Pages Concernées

- ✅ Page 1/6 : Informations de base (nom, date de naissance, bio)

Les autres pages du flux de création de profil (photos, médias, prompts, validation, révision) bénéficient déjà de la solution globale ou n'ont pas ce problème spécifique.
