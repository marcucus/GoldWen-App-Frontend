# Guide de Test - Correction du Flux d'Inscription

## 🎯 Objectif
Ce document décrit comment tester les corrections apportées au flux d'inscription pour résoudre le problème d'écran blanc à l'étape 1/5.

## 🔍 Problèmes Corrigés

### 1. Navigation après inscription email
**Avant:** L'application naviguait directement vers `GenderSelectionPage` après l'inscription
**Après:** L'application navigue vers `/splash` qui route correctement selon l'état de complétion

### 2. Compteur d'étapes incorrect
**Avant:** Affichait "Étape X/5" pour 6 pages (0-5)
**Après:** Affiche correctement "Étape X/6"

### 3. Exigences photos contradictoires
**Avant:** Demandait minimum 10 photos mais maximum 6 (impossible!)
**Après:** Demande minimum 3 photos, maximum 6 (aligné avec l'API)

### 4. Nombre de prompts incorrect
**Avant:** Demandait 10 prompts mais l'API n'en requiert que 3
**Après:** Demande exactement 3 prompts (aligné avec l'API)

### 5. Index de pages incorrects
**Avant:** Plusieurs fonctions utilisaient de mauvais index de pages
**Après:** Tous les index sont corrects:
- Page 0: Informations de base
- Page 1: Photos
- Page 2: Media (optionnel)
- Page 3: Prompts
- Page 4: Validation
- Page 5: Review

## 📋 Flux d'Inscription Complet

### Étape 1: Inscription Email
1. Lancer l'application
2. Cliquer sur "Commencer"
3. Choisir "Continuer avec email"
4. Basculer en mode inscription
5. Entrer: prénom, nom, email, mot de passe
6. Cliquer sur "Créer mon compte"

**Résultat attendu:**
- ✅ Redirection vers la page Splash
- ✅ Pas d'erreur
- ✅ Pas de navigation vers GenderSelectionPage

### Étape 2: Questionnaire de Personnalité
Après l'inscription, l'utilisateur devrait automatiquement être redirigé vers le questionnaire.

**Résultat attendu:**
- ✅ Navigation automatique vers `/questionnaire`
- ✅ Affichage du questionnaire de personnalité
- ✅ Pas d'écran blanc

**Actions:**
1. Répondre à toutes les questions (10 questions)
2. Cliquer sur "Terminer"

**Résultat attendu:**
- ✅ Backend marque `isOnboardingCompleted = true`
- ✅ Redirection vers `/profile-setup`

### Étape 3: Configuration du Profil (6 pages)

#### Page 0/6: Informations de Base
**Titre:** "Étape 1/6"

**Champs:**
- Pseudo (requis)
- Date de naissance (requis, 18+ ans)
- Bio (requis, max 200 caractères)

**Test:**
1. Laisser vide → bouton "Continuer" désactivé ✅
2. Remplir tous les champs → bouton activé ✅
3. Cliquer "Continuer" → passage à la page suivante ✅

#### Page 1/6: Photos
**Titre:** "Étape 2/6" (c'est cette page qui causait l'écran blanc!)

**Exigences:**
- Minimum: 3 photos
- Maximum: 6 photos
- Texte: "Ajoutez au moins 3 photos pour continuer"
- Compteur: "Continuer (X/6)"

**Test:**
1. Vérifier que la page s'affiche correctement (pas d'écran blanc) ✅
2. Vérifier le texte "au moins 3 photos" ✅
3. Ajouter moins de 3 photos → bouton désactivé ✅
4. Ajouter 3 photos → bouton activé avec texte "Continuer (3/6)" ✅
5. Essayer d'ajouter plus de 6 photos → bloqué à 6 ✅
6. Cliquer "Continuer" → passage à la page suivante ✅

#### Page 2/6: Media (Optionnel)
**Titre:** "Étape 3/6"

**Contenu:**
- Upload audio/vidéo optionnel
- Bouton "Continuer" toujours activé

**Test:**
1. Vérifier affichage correct ✅
2. Passer sans ajouter de media → OK ✅
3. Ajouter un media → OK ✅

#### Page 3/6: Prompts
**Titre:** "Étape 4/6"

**Exigences:**
- Exactement 3 prompts requis
- Max 300 caractères par réponse
- Compteur: "Réponses complétées: X/3"
- Bouton: "Complétez les 3 réponses (X/3)"

**Test:**
1. Vérifier qu'il y a exactement 3 champs ✅
2. Laisser vide → bouton désactivé ✅
3. Remplir 1 ou 2 réponses → bouton désactivé ✅
4. Remplir les 3 réponses → bouton activé "Continuer" ✅
5. Vérifier le compteur "X/3" ✅
6. Cliquer "Continuer" → sauvegarde et passage à validation ✅

**Note:** Cette page sauvegarde automatiquement au backend avant de passer à la suivante.

#### Page 4/6: Validation
**Titre:** "Étape 5/6"

**Contenu:**
- Widget de complétion du profil
- Vérification de toutes les exigences

**Test:**
1. Vérifier l'affichage du statut de complétion ✅
2. Si profil complet → bouton "Continuer" activé ✅
3. Si profil incomplet → bouton "Profil incomplet" désactivé ✅
4. Cliquer sur une étape manquante → navigation vers cette page ✅

#### Page 5/6: Review
**Titre:** "Étape 6/6"

**Contenu:**
- Message de félicitations
- Explication du rituel quotidien
- Bouton "Commencer mon aventure"

**Test:**
1. Vérifier l'affichage correct ✅
2. Cliquer sur le bouton final ✅
3. Vérifier la sauvegarde au backend ✅
4. Vérifier `isProfileCompleted = true` ✅
5. Redirection vers `/home` ✅

## 🔄 Navigation Retour

**Test:**
1. Sur chaque page (sauf la première), vérifier la présence du bouton retour ✅
2. Cliquer sur retour → retour à la page précédente ✅
3. Les données saisies sont conservées ✅

## 📊 Progress Bar

**Test:**
1. Page 0: 1/6 = 16.67% ✅
2. Page 1: 2/6 = 33.33% ✅
3. Page 2: 3/6 = 50% ✅
4. Page 3: 4/6 = 66.67% ✅
5. Page 4: 5/6 = 83.33% ✅
6. Page 5: 6/6 = 100% ✅

## 🧪 Scénarios de Test Complets

### Scénario 1: Inscription Complète Réussie
1. Créer un nouveau compte email ✅
2. Compléter le questionnaire de personnalité ✅
3. Remplir informations de base ✅
4. Ajouter 3 photos ✅
5. Passer la page media ✅
6. Répondre aux 3 prompts ✅
7. Valider le profil ✅
8. Finaliser ✅
9. Vérifier l'arrivée sur la page d'accueil ✅

### Scénario 2: Interruption et Reprise
1. Créer un compte ✅
2. Compléter le questionnaire ✅
3. Remplir jusqu'à la page photos ✅
4. Fermer l'application ✅
5. Rouvrir l'application ✅
6. Vérifier la redirection vers `/profile-setup` ✅
7. Vérifier que l'on reprend là où on s'était arrêté ✅

### Scénario 3: Validation des Erreurs
1. Essayer de continuer sans remplir les champs requis → bloqué ✅
2. Essayer de mettre une date de naissance < 18 ans → bloqué ✅
3. Essayer de continuer avec moins de 3 photos → bloqué ✅
4. Essayer de continuer avec moins de 3 prompts → bloqué ✅
5. Vérifier les messages d'erreur appropriés ✅

## ⚠️ Points Critiques à Vérifier

### 1. Écran Blanc (Principal Bug)
**Page concernée:** Page 1/6 (Photos)
**Test:** 
- ✅ La page s'affiche correctement avec le widget PhotoManagementWidget
- ✅ Pas d'écran blanc
- ✅ Le texte "au moins 3 photos" s'affiche
- ✅ Le bouton est désactivé si < 3 photos

### 2. Cohérence des Compteurs
**Test:**
- ✅ Header: "Étape X/6" (pas X/5)
- ✅ Progress bar: correct percentage
- ✅ Photos: "X/6" (pas X/10)
- ✅ Prompts: "X/3" (pas X/10)

### 3. Sauvegarde Backend
**Test après page Prompts:**
- ✅ Appel API pour sauvegarder le profil
- ✅ Appel API pour soumettre les prompts
- ✅ Rechargement du statut de complétion
- ✅ Pas d'erreur de sauvegarde

### 4. Flags de Complétion
**Test:**
- ✅ Après questionnaire: `isOnboardingCompleted = true`
- ✅ Après profil complet: `isProfileCompleted = true`
- ✅ Redirection appropriée basée sur ces flags

## 🐛 Bugs Connus Résolus

1. ✅ Écran blanc à l'étape 2/6 (photos) - Résolu en corrigeant minPhotos/maxPhotos
2. ✅ Progress bar dépassant 100% - Résolu en changeant diviseur de 5 à 6
3. ✅ Navigation vers mauvaises pages - Résolu en corrigeant tous les index
4. ✅ Demande de 10 prompts au lieu de 3 - Résolu en alignant avec l'API
5. ✅ Navigation incorrecte après signup - Résolu en utilisant splash routing

## 📝 Checklist de Validation Finale

- [ ] Aucun écran blanc dans tout le flux
- [ ] Tous les compteurs affichent les bonnes valeurs
- [ ] Navigation fluide entre toutes les pages
- [ ] Bouton retour fonctionne correctement
- [ ] Données sauvegardées correctement au backend
- [ ] Flags de complétion mis à jour correctement
- [ ] Redirection finale vers `/home` réussie
- [ ] Possibilité de reprendre là où on s'était arrêté
- [ ] Messages d'erreur clairs et appropriés
- [ ] Performance acceptable (pas de lag)

## 🚀 Commandes de Test

```bash
# Démarrer le backend
cd main-api
npm run dev

# Dans un autre terminal, démarrer l'app Flutter
cd /path/to/frontend
flutter run

# Pour tester sur un émulateur Android
flutter run -d android

# Pour tester sur un émulateur iOS
flutter run -d ios

# Pour voir les logs
flutter logs
```

## 📸 Screenshots à Prendre

Pour validation visuelle, prendre des screenshots de:
1. Page 1/6 - Informations de base
2. Page 2/6 - Photos (celle qui causait l'écran blanc)
3. Page 3/6 - Media
4. Page 4/6 - Prompts (montrer compteur 3/3)
5. Page 5/6 - Validation
6. Page 6/6 - Review
7. Progress bar à différentes étapes

## ✅ Résultat Attendu Final

Après avoir suivi tout le flux d'inscription:
- L'utilisateur arrive sur la page d'accueil `/home`
- Le profil est complet dans la base de données
- Les flags `isOnboardingCompleted` et `isProfileCompleted` sont à `true`
- Aucun écran blanc rencontré
- Expérience utilisateur fluide et cohérente
