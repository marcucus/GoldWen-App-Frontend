# 🛡️ Validation des Mots Interdits - Documentation

## 📋 Vue d'ensemble

Cette documentation décrit le système de validation des mots interdits implémenté dans l'application GoldWen pour protéger les utilisateurs contre les contenus inappropriés, le spam et les tentatives de phishing.

## 🎯 Objectifs

1. **Sécurité** : Empêcher l'utilisation de langage offensant ou inapproprié
2. **Protection** : Bloquer le partage d'informations de contact (email, téléphone, URLs)
3. **Qualité** : Prévenir le spam et les patterns de texte inappropriés
4. **Expérience utilisateur** : Maintenir un environnement respectueux et professionnel

## 🏗️ Architecture

### Composants principaux

#### 1. `TextValidator` (lib/core/utils/text_validator.dart)

Classe utilitaire centrale contenant toutes les fonctions de validation.

**Méthodes principales :**

```dart
// Validation complète avec tous les checks
static String? validateText(String? text, {
  bool checkForbiddenWords = true,
  bool checkContactInfo = true,
  bool checkSpamPatterns = true,
})

// Validation des mots interdits uniquement
static String? validateForbiddenWords(String? text)

// Validation des informations de contact
static String? validateContactInfo(String? text)

// Validation des patterns de spam
static String? validateSpamPatterns(String? text)

// Nettoyage du texte
static String cleanText(String text)
```

#### 2. `EnhancedTextField` (lib/shared/widgets/enhanced_input.dart)

Widget de saisie texte amélioré avec validation intégrée.

**Nouveaux paramètres :**

```dart
final bool validateForbiddenWords;  // Par défaut: true
final bool validateContactInfo;     // Par défaut: false
final bool validateSpamPatterns;    // Par défaut: false
```

## 📝 Liste des Mots Interdits

### Catégories

1. **Contenu explicite** : Langage vulgaire et offensant
2. **Discours de haine** : Termes discriminatoires
3. **Scam/Spam** : Mots-clés liés aux arnaques (crypto, bitcoin, forex, etc.)
4. **Contact info patterns** : Plateformes sociales (Instagram, Snapchat, etc.)
5. **Profanité française** : Équivalents français du contenu inapproprié

### Extensibilité

La liste des mots interdits peut être facilement étendue en modifiant le tableau `_forbiddenWords` dans `TextValidator`.

```dart
static final List<String> _forbiddenWords = [
  // Ajouter de nouveaux mots ici
  'nouveau_mot_interdit',
];
```

## 🔍 Méthodes de Détection

### 1. Normalisation du texte

Le texte est normalisé avant validation pour détecter les variations :

- **Accents** : `é → e`, `à → a`
- **Leetspeak** : `0 → o`, `3 → e`, `@ → a`, `$ → s`
- **Casse** : Tout converti en minuscules
- **Espaces** : Normalisés et trimés

### 2. Patterns détectés

#### Emails
```regex
\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b
```

#### Numéros de téléphone
```regex
\b(\+?\d{1,3}[-.\s]?)?\(?\d{2,4}\)?[-.\s]?\d{2,4}[-.\s]?\d{2,4}[-.\s]?\d{0,4}\b
```

#### URLs
```regex
https?://|www\.|\.com|\.fr|\.net|\.org
```

#### Répétitions excessives
```regex
(.)\1{4,}
```

## 📍 Points d'Intégration

### Champs texte validés

1. **Profil utilisateur**
   - ✅ Pseudo
   - ✅ Bio
   - ✅ Réponses aux prompts
   - ✅ Informations professionnelles (métier, entreprise, formation)

2. **Communication**
   - ✅ Messages de chat
   - ✅ Feedback
   - ✅ Signalements (reports)

3. **Onboarding**
   - ✅ Informations additionnelles
   - ✅ Gestion des prompts

### Configuration par champ

Chaque champ peut activer/désactiver les validations selon le contexte :

```dart
// Exemple: Bio - toutes les validations
EnhancedTextField(
  controller: _bioController,
  validateForbiddenWords: true,   // ✓ Mots interdits
  validateContactInfo: true,      // ✓ Infos de contact
  validateSpamPatterns: true,     // ✓ Patterns spam
)

// Exemple: Pseudo - uniquement mots interdits
EnhancedTextField(
  controller: _nameController,
  validateForbiddenWords: true,   // ✓ Mots interdits
  validateContactInfo: false,     // ✗ Infos de contact
  validateSpamPatterns: false,    // ✗ Patterns spam
)
```

## 🧪 Tests

### Tests unitaires

Fichier: `test/text_validator_test.dart`

**Couverture :**
- ✅ Détection des mots interdits (anglais/français)
- ✅ Insensibilité à la casse
- ✅ Détection du leetspeak
- ✅ Détection des emails
- ✅ Détection des numéros de téléphone
- ✅ Détection des URLs
- ✅ Détection du spam (répétitions, CAPS)
- ✅ Validation complète
- ✅ Gestion des flags de validation
- ✅ Normalisation du texte

**Exécution :**
```bash
flutter test test/text_validator_test.dart
```

## 💬 Messages d'Erreur

### Français (utilisateurs)

| Validation | Message |
|------------|---------|
| Mots interdits | "Ce texte contient des mots interdits. Merci de rester respectueux." |
| Email/Téléphone | "Le partage d'informations de contact n'est pas autorisé." |
| URLs | "Le partage de liens n'est pas autorisé." |
| Répétitions | "Merci d'éviter les répétitions excessives." |
| CAPS | "Merci de ne pas écrire tout en majuscules." |

### Affichage

Les messages sont affichés :
- **Dans les formulaires** : Via le système de validation de `TextFormField`
- **Dans le chat** : Via une `SnackBar` flottante rouge
- **Inline** : Directement sous le champ de saisie

## 🔐 Sécurité

### Principes

1. **Validation côté client ET serveur**
   - Frontend : Feedback immédiat à l'utilisateur
   - Backend : Validation finale et authoritative

2. **Defense in depth**
   - Normalisation du texte (anti-contournement)
   - Détection de patterns multiples
   - Validation en cascade

3. **Privacy by design**
   - Pas de transmission de données sensibles
   - Messages d'erreur génériques (pas de détails sur le mot détecté)

### Limitations

⚠️ **Important** : Cette validation est un premier niveau de défense. Elle doit être complétée par :

1. **Validation backend** : Indispensable pour la sécurité réelle
2. **Modération humaine** : Pour les cas complexes
3. **Machine Learning** : Pour une détection avancée (phase V2)
4. **Rate limiting** : Pour prévenir les abus

## 🚀 Utilisation

### Cas d'usage typique

```dart
// 1. Importer le validateur
import '../../../core/utils/text_validator.dart';

// 2a. Utiliser avec EnhancedTextField (recommandé)
EnhancedTextField(
  controller: _controller,
  validateForbiddenWords: true,
  validateContactInfo: true,
  validateSpamPatterns: true,
)

// 2b. Utiliser manuellement dans un validator
validator: (value) {
  // Vos validations custom
  if (value == null || value.isEmpty) {
    return 'Ce champ est requis';
  }
  
  // Validation des mots interdits
  return TextValidator.validateText(value);
}

// 2c. Utiliser avant un appel API
void _sendMessage() {
  final text = _controller.text;
  final error = TextValidator.validateText(text);
  
  if (error != null) {
    _showError(error);
    return;
  }
  
  // Envoyer le message...
}
```

## 📊 Métriques et Monitoring

### Recommandations futures

1. **Analytics** : Tracker les tentatives de contenu inapproprié
2. **Reporting** : Dashboard admin des violations
3. **A/B Testing** : Optimiser les messages d'erreur
4. **ML Training** : Utiliser les données pour améliorer la détection

## 🔄 Maintenance

### Mise à jour de la liste de mots

1. Éditer `lib/core/utils/text_validator.dart`
2. Ajouter le mot dans `_forbiddenWords`
3. Ajouter un test dans `test/text_validator_test.dart`
4. Exécuter les tests
5. Commit et déploiement

### Ajout d'une nouvelle validation

```dart
// 1. Créer une nouvelle méthode dans TextValidator
static String? validateNewPattern(String? text) {
  if (text == null || text.trim().isEmpty) return null;
  
  // Votre logique de validation
  if (/* condition */) {
    return 'Message d\'erreur';
  }
  
  return null;
}

// 2. Intégrer dans validateText
static String? validateText(String? text, {
  bool checkForbiddenWords = true,
  bool checkContactInfo = true,
  bool checkSpamPatterns = true,
  bool checkNewPattern = false,  // Nouveau paramètre
}) {
  // ...
  if (checkNewPattern) {
    error = validateNewPattern(text);
    if (error != null) return error;
  }
  // ...
}
```

## 📚 Références

### Standards suivis

- **SOLID** : Single Responsibility, Open/Closed principles
- **Clean Code** : Noms explicites, fonctions courtes
- **Security First** : Validation stricte par défaut

### Ressources

- [OWASP Input Validation Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Input_Validation_Cheat_Sheet.html)
- [Flutter Form Validation Best Practices](https://docs.flutter.dev/cookbook/forms/validation)
- [Dart RegExp Documentation](https://api.dart.dev/stable/dart-core/RegExp-class.html)

## ⚠️ Notes importantes

1. **Performance** : Les validations regex sont optimisées mais peuvent impacter sur textes très longs (>10000 caractères)
2. **Faux positifs** : Certains mots légitimes peuvent être bloqués (ex: "Scunthorpe problem")
3. **Multilinguisme** : Actuellement français/anglais uniquement
4. **Évolutivité** : La liste doit être maintenue régulièrement

## 🎯 Checklist d'Implémentation

- [x] Créer le validateur de texte
- [x] Ajouter la liste de mots interdits
- [x] Intégrer dans EnhancedTextField
- [x] Valider les champs de profil
- [x] Valider les messages de chat
- [x] Valider les formulaires de feedback
- [x] Valider les signalements
- [x] Créer les tests unitaires
- [x] Documenter le système
- [ ] ⚠️ **Backend** : Implémenter la validation côté serveur
- [ ] **ML** : Ajouter la détection par machine learning (V2)
- [ ] **Admin** : Dashboard de modération (V2)

## 📧 Support

Pour toute question ou suggestion d'amélioration, contacter l'équipe de développement.

---

**Version** : 1.0  
**Dernière mise à jour** : 2025-10-15  
**Auteur** : GoldWen Development Team
