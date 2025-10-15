# Guide de Test Manuel - Fix iOS Camera Crash

## 🎯 Objectif
Valider que le crash de l'appareil photo sur iOS a été corrigé et que la gestion des permissions fonctionne correctement.

## ⚠️ Prérequis

### Matériel Requis
- ✅ Un iPhone physique (iOS 12.0 ou supérieur)
- ✅ Câble Lightning/USB-C pour connexion
- ✅ Mac avec Xcode installé

**IMPORTANT**: Le test doit être effectué sur un appareil physique car le simulateur iOS n'a pas de caméra fonctionnelle.

### Préparation
1. Ouvrez le projet dans Xcode:
   ```bash
   cd ios
   open Runner.xcworkspace
   ```

2. Sélectionnez votre iPhone comme device cible

3. Configurez le provisioning profile et signing

4. Build et installez l'app sur votre iPhone

## 📋 Scénarios de Test

### Test 1: Première Utilisation - Permissions Accordées ✅

**Objectif**: Vérifier que les permissions sont demandées correctement

**Étapes**:
1. Désinstallez complètement l'app si elle est déjà installée
2. Installez l'app fraîchement depuis Xcode
3. Naviguez vers "Gestion des Photos" (Photo Management)
4. Appuyez sur le bouton "+" pour ajouter une photo
5. Sélectionnez "Appareil photo"

**Résultat Attendu**:
- ✅ Une alerte système iOS s'affiche avec le message:
  > "GoldWen a besoin d'accéder à votre appareil photo pour prendre des photos de profil et personnaliser votre expérience."
- ✅ Deux boutons: "Ne pas autoriser" et "Autoriser"
- ✅ Le texte est en français et clair

**Actions**:
- Appuyez sur "Autoriser"
- L'appareil photo s'ouvre normalement
- Prenez une photo
- La photo est compressée et uploadée avec succès
- Un message de succès apparaît: "Photo ajoutée avec succès"

**Statut**: ⬜ À tester

---

### Test 2: Permission Caméra Refusée ❌

**Objectif**: Vérifier la gestion gracieuse du refus de permission

**Étapes**:
1. Désinstallez complètement l'app
2. Réinstallez l'app
3. Naviguez vers "Gestion des Photos"
4. Appuyez sur "+" puis "Appareil photo"
5. Appuyez sur "Ne pas autoriser"

**Résultat Attendu**:
- ✅ L'app ne crash PAS
- ✅ Un Snackbar rouge apparaît avec le message:
  > "Permission d'accès à l'appareil photo refusée. Veuillez autoriser l'accès dans les réglages de votre appareil."
- ✅ Le message reste affiché pendant 5 secondes
- ✅ L'indicateur de chargement disparaît
- ✅ L'utilisateur peut réessayer

**Statut**: ⬜ À tester

---

### Test 3: Permission Galerie - Première Utilisation ✅

**Objectif**: Vérifier les permissions pour la galerie photo

**Étapes**:
1. Sur une installation fraîche (ou après avoir désinstallé)
2. Naviguez vers "Gestion des Photos"
3. Appuyez sur "+" puis "Galerie"

**Résultat Attendu**:
- ✅ Une alerte système iOS s'affiche avec le message:
  > "GoldWen a besoin d'accéder à vos photos pour que vous puissiez sélectionner des photos de profil."
- ✅ Options: "Sélectionner des photos...", "Autoriser l'accès à toutes les photos", "Ne pas autoriser"

**Actions**:
- Choisissez "Autoriser l'accès à toutes les photos"
- La galerie s'ouvre normalement
- Sélectionnez une photo
- La photo est traitée correctement

**Statut**: ⬜ À tester

---

### Test 4: Permission Galerie Refusée ❌

**Objectif**: Vérifier la gestion du refus d'accès à la galerie

**Étapes**:
1. Sur une installation fraîche
2. Naviguez vers "Gestion des Photos"
3. Appuyez sur "+" puis "Galerie"
4. Appuyez sur "Ne pas autoriser"

**Résultat Attendu**:
- ✅ L'app ne crash PAS
- ✅ Un Snackbar rouge apparaît avec le message:
  > "Permission d'accès à la galerie photo refusée. Veuillez autoriser l'accès dans les réglages de votre appareil."
- ✅ L'indicateur de chargement disparaît

**Statut**: ⬜ À tester

---

### Test 5: Réactivation des Permissions ✅

**Objectif**: Vérifier que l'utilisateur peut réactiver les permissions

**Étapes**:
1. Après avoir refusé les permissions (Test 2 ou 4)
2. Allez dans Réglages iPhone > GoldWen
3. Activez "Appareil photo" et/ou "Photos"
4. Retournez dans l'app
5. Réessayez d'ajouter une photo

**Résultat Attendu**:
- ✅ L'appareil photo/galerie s'ouvre normalement
- ✅ Pas besoin de redemander la permission
- ✅ La fonctionnalité marche comme prévu

**Statut**: ⬜ À tester

---

### Test 6: Caméra Restreinte (Parental Controls) 🔒

**Objectif**: Vérifier le comportement avec restrictions parentales

**Prérequis**: 
- Activez les restrictions sur l'iPhone: Réglages > Temps d'écran > Restrictions relatives au contenu et à la confidentialité > Appareil photo (Désactivé)

**Étapes**:
1. Avec les restrictions actives
2. Naviguez vers "Gestion des Photos"
3. Appuyez sur "+" puis "Appareil photo"

**Résultat Attendu**:
- ✅ L'app ne crash PAS
- ✅ Un message d'erreur approprié s'affiche:
  > "L'accès à l'appareil photo est restreint sur cet appareil."

**Statut**: ⬜ À tester

---

### Test 7: Flux Normal Complet ✅

**Objectif**: Vérifier que le flux normal fonctionne de bout en bout

**Étapes**:
1. Avec les permissions accordées
2. Naviguez vers "Gestion des Photos"
3. Ajoutez 3 photos via caméra
4. Ajoutez 2 photos via galerie
5. Réorganisez les photos par drag & drop
6. Définissez une photo comme principale
7. Supprimez une photo

**Résultat Attendu**:
- ✅ Toutes les opérations fonctionnent sans crash
- ✅ Les photos sont compressées correctement (max 1MB)
- ✅ Les photos sont uploadées au backend
- ✅ L'UI se met à jour correctement
- ✅ Les messages de succès s'affichent

**Statut**: ⬜ À tester

---

## 🔍 Points de Vérification Critiques

### Permissions (Info.plist)
Vérifiez que ces clés existent dans `ios/Runner/Info.plist`:
- ✅ `NSCameraUsageDescription` 
- ✅ `NSPhotoLibraryUsageDescription`
- ✅ `NSPhotoLibraryAddUsageDescription`

### Comportement Sans Crash
- ✅ L'app ne crash JAMAIS, même si les permissions sont refusées
- ✅ Des messages d'erreur clairs s'affichent en français
- ✅ L'utilisateur sait comment résoudre le problème

### Messages d'Erreur
Vérifiez que les messages sont:
- ✅ En français
- ✅ Clairs et actionables
- ✅ Affichés pendant 5 secondes (durée suffisante pour lire)
- ✅ Avec un fond rouge (AppColors.error)

## 📸 Captures d'Écran à Fournir

Pour chaque test réussi, capturez:
1. L'alerte de permission système iOS
2. Le message d'erreur en cas de refus
3. Le flux normal de prise de photo
4. Les réglages iOS montrant les permissions

## ✅ Checklist de Validation Finale

- [ ] Aucun crash détecté dans tous les scénarios
- [ ] Toutes les permissions fonctionnent correctement
- [ ] Les messages d'erreur sont clairs et en français
- [ ] Le flux normal de photo fonctionne parfaitement
- [ ] Les logs Xcode ne montrent aucune erreur
- [ ] La compression des photos fonctionne (images < 1MB)
- [ ] L'upload vers le backend réussit

## 🐛 Rapport de Bugs (Si Applicable)

Si vous rencontrez des problèmes pendant les tests:

**Bug #1**: _À remplir si nécessaire_
- **Scénario**: 
- **Étapes pour reproduire**: 
- **Comportement observé**: 
- **Comportement attendu**: 
- **Logs**: 

## 📊 Résultat du Test

**Date du test**: ___________  
**Testeur**: ___________  
**Device**: iPhone _____ (iOS _____)  
**Version de l'app**: ___________

**Résultat Global**: 
- [ ] ✅ Tous les tests passent
- [ ] ⚠️ Quelques problèmes mineurs
- [ ] ❌ Problèmes critiques détectés

**Notes additionnelles**:
_____________________________________
_____________________________________
_____________________________________

## 🚀 Prochaines Étapes

Une fois tous les tests validés:
1. ✅ Marquer la PR comme "Ready for Review"
2. ✅ Partager les captures d'écran dans la PR
3. ✅ Demander une code review
4. ✅ Merger après approbation
5. ✅ Déployer en production

## 📚 Ressources

- [Documentation Info.plist - Apple](https://developer.apple.com/documentation/bundleresources/information_property_list)
- [Image Picker Plugin](https://pub.dev/packages/image_picker)
- [Guide de Test iOS](https://developer.apple.com/documentation/xcode/running-your-app-in-simulator-or-on-a-device)
