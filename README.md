# GoldWen App Frontend

Une application de rencontres premium qui privilégie la qualité des connexions plutôt que la quantité.

## À propos

GoldWen est une application de "slow dating" conçue pour réduire la fatigue liée aux applications de rencontre traditionnelles. Notre approche unique propose :

- **Sélection quotidienne limitée** : 3-5 profils soigneusement sélectionnés par jour
- **Design "Calm Technology"** : Interface épurée et apaisante
- **Matching authentique** : Basé sur la compatibilité des personnalités
- **Chat éphémère** : Conversations de 24h pour encourager des échanges authentiques
- **Modèle freemium** : Version gratuite avec option GoldWen Plus

## Fonctionnalités principales

### MVP (Version 1.0)
- ✅ Authentification OAuth (Google/Apple)
- ✅ Questionnaire de personnalité (10 questions)
- ✅ Création de profil complète
- ✅ Rituel quotidien de matching
- ✅ Système de sélection (1 gratuit, 3 avec abonnement)
- ✅ Chat avec expiration 24h
- ✅ Abonnement GoldWen Plus
- ✅ Interface "Calm Technology"

### Technologies utilisées

- **Framework** : Flutter 3.24+
- **Langage** : Dart
- **State Management** : Provider
- **Navigation** : GoRouter
- **Design** : Material Design 3 avec thème personnalisé
- **Authentification** : Firebase Auth
- **Typographie** : Google Fonts (Playfair Display + Lato)

## Architecture

```
lib/
├── core/                   # Configuration de base
│   ├── theme/             # Thème et couleurs
│   ├── routes/            # Configuration de navigation
│   └── constants/         # Constantes de l'app
├── features/              # Fonctionnalités principales
│   ├── auth/              # Authentification
│   ├── onboarding/        # Parcours d'inscription
│   ├── profile/           # Gestion des profils
│   ├── matching/          # Système de matching
│   ├── chat/              # Messagerie
│   └── subscription/      # Abonnements
└── shared/                # Composants partagés
    ├── widgets/           # Widgets réutilisables
    ├── models/            # Modèles de données
    └── services/          # Services partagés
```

## Design System

### Palette de couleurs
- **Primaire** : Or mat élégant (#D4AF37)
- **Secondaire** : Tons crème et beige (#F5F5DC, #FAF0E6)
- **Texte** : Gris foncé (#2C2C2C) et secondaire (#6B6B6B)
- **Arrière-plan** : Blanc cassé (#FFFFF8)

### Typographie
- **Titres** : Playfair Display (Serif élégante)
- **Corps de texte** : Lato (Sans-Serif lisible)

### Principes UX
- **Minimalisme** : Interfaces épurées sans éléments superflus
- **Espace et respiration** : Utilisation généreuse des espaces blancs
- **Interactions prévisibles** : Feedback clair et rassurant
- **Notifications limitées** : Une seule notification par jour

## Installation et développement

### Prérequis
- Flutter SDK 3.24 ou supérieur
- Dart SDK 3.1 ou supérieur
- Android Studio / VS Code
- Git

### Installation
```bash
# Cloner le repository
git clone https://github.com/marcucus/GoldWen-App-Frontend.git
cd GoldWen-App-Frontend

# Installer les dépendances
flutter pub get

# Lancer l'application
flutter run
```

### Configuration pour développement avec émulateur Android

Si vous utilisez un émulateur Android et que votre backend est lancé sur localhost, l'application détecte automatiquement la plateforme et utilise l'adresse IP appropriée :

- **Android Emulator** : `10.0.2.2` (pour accéder à la machine hôte)
- **iOS Simulator** : `localhost` (accès direct à la machine hôte)
- **Appareil physique** : Utiliser l'adresse IP de votre machine sur le réseau local

Le fichier `lib/core/config/app_config.dart` gère automatiquement cette configuration selon la plateforme détectée.

### Backend requis

Pour que l'application fonctionne, assurez-vous que votre backend soit lancé sur :
- **API principale** : Port 3000 (`http://localhost:3000/api/v1`)
- **Service de matching** : Port 8000 (`http://localhost:8000/api/v1`)
- **WebSocket** : Port 3000 (`ws://localhost:3000/chat`)

### Commandes utiles
```bash
# Analyse du code
flutter analyze

# Tests
flutter test

# Build pour production
flutter build apk --release
flutter build ios --release
```

## Spécifications techniques

Voir le fichier `specifications.md` pour le cahier des charges complet incluant :
- Architecture des microservices
- Spécifications fonctionnelles détaillées
- Exigences non-fonctionnelles
- Conformité RGPD
- Estimations budgétaires

## Contribution

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/nouvelle-fonctionnalite`)
3. Commit les changements (`git commit -m 'Ajout nouvelle fonctionnalité'`)
4. Push vers la branche (`git push origin feature/nouvelle-fonctionnalite`)
5. Ouvrir une Pull Request

## Licence

Ce projet est sous licence propriétaire. Tous droits réservés.

## Contact

Pour toute question ou suggestion concernant le développement :
- Repository : https://github.com/marcucus/GoldWen-App-Frontend
- Issues : https://github.com/marcucus/GoldWen-App-Frontend/issues

---

*"Conçue pour être désinstallée"* - GoldWen