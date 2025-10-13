# Guide de Test Manuel - Refresh Quotidien de la Sélection

## Vue d'ensemble
Ce guide décrit comment tester manuellement les fonctionnalités de refresh quotidien de la sélection implémentées dans GoldWen App.

## Pré-requis
- Application GoldWen installée sur un appareil ou émulateur
- Compte utilisateur actif
- Backend API accessible (peut utiliser des données mock en développement)

## Tests à effectuer

### 1. Test du Badge "Nouvelle sélection disponible !"

#### Objectif
Vérifier que le badge apparaît quand une nouvelle sélection est disponible.

#### Étapes
1. Ouvrir l'application à un moment où une nouvelle sélection devrait être disponible (après midi si la dernière consultation était avant midi)
2. Naviguer vers la page "Sélection du jour"
3. Observer le header de la page

#### Résultats attendus
- ✅ Un badge vert avec le texte "Nouvelle sélection disponible !" devrait être visible
- ✅ Le badge doit contenir une icône "NEW"
- ✅ Le badge doit avoir un effet d'ombre et un dégradé vert

#### Capture d'écran attendue
```
┌────────────────────────────────────────┐
│  Sélection du jour            ❤️       │
│  Découvrez vos matchs parfaits         │
│  ┌──────────────────────────────────┐  │
│  │ 🆕 Nouvelle sélection disponible!│  │
│  └──────────────────────────────────┘  │
└────────────────────────────────────────┘
```

### 2. Test du Timer Compte à Rebours

#### Objectif
Vérifier que le compte à rebours s'affiche et se met à jour correctement.

#### Étapes
1. Ouvrir l'application quand aucune nouvelle sélection n'est disponible
2. Naviguer vers la page "Sélection du jour"
3. Observer le timer pendant au moins 1 minute

#### Résultats attendus
- ✅ Un timer avec le format "Prochaine sélection dans Xh Xmin" devrait être visible
- ✅ Le timer doit se mettre à jour toutes les secondes
- ✅ Le timer doit afficher une icône d'horloge
- ✅ Le format doit s'adapter selon le temps restant:
  - Plus de 1 jour: "1j 8h"
  - Plus d'1 heure: "5h 30min"
  - Moins d'1 heure: "45min"
  - Moins d'1 minute: "30s"

#### Capture d'écran attendue
```
┌────────────────────────────────────────┐
│  Sélection du jour            ❤️       │
│  Découvrez vos matchs parfaits         │
│  ┌──────────────────────────────────┐  │
│  │ ⏱️ Prochaine sélection dans 5h 30min│
│  └──────────────────────────────────┘  │
└────────────────────────────────────────┘
```

### 3. Test du Refresh Automatique à Midi

#### Objectif
Vérifier que la sélection se rafraîchit automatiquement à midi.

#### Configuration
Pour tester cette fonctionnalité sans attendre midi:
1. Modifier temporairement le code pour utiliser un délai plus court (ex: 2 minutes)
2. OU attendre l'heure de midi réelle

#### Étapes
1. Ouvrir l'application quelques minutes avant midi
2. Rester sur la page "Sélection du jour"
3. Observer l'application à midi

#### Résultats attendus
- ✅ À midi précisément, l'application devrait:
  - Afficher le badge "Nouvelle sélection disponible !"
  - Charger automatiquement la nouvelle sélection (appel API)
  - Mettre à jour la liste des profils
  - Réinitialiser le compteur de sélections disponibles

### 4. Test de Reprise de l'Application

#### Objectif
Vérifier que l'application vérifie les nouvelles sélections quand elle reprend.

#### Étapes
1. Ouvrir l'application avec une sélection valide
2. Mettre l'application en arrière-plan (home button)
3. Attendre que le temps de refresh soit passé (ou simuler avec un changement d'heure système)
4. Rouvrir l'application

#### Résultats attendus
- ✅ L'application doit vérifier automatiquement si une nouvelle sélection est disponible
- ✅ Si disponible, le badge doit apparaître et la sélection doit se charger
- ✅ Les timers doivent redémarrer correctement

### 5. Test de Prévention des Doubles Sélections

#### Objectif
Vérifier qu'un profil ne peut pas être sélectionné deux fois.

#### Étapes
1. Naviguer vers la page "Sélection du jour"
2. Choisir un profil
3. Essayer de sélectionner le même profil à nouveau (si encore visible)

#### Résultats attendus
- ✅ Le profil sélectionné doit être marqué comme sélectionné
- ✅ Une tentative de re-sélection doit afficher un message d'erreur
- ✅ Le profil ne doit pas réapparaître dans les sélections futures

### 6. Test d'Accessibilité

#### Objectif
Vérifier que les fonctionnalités respectent les paramètres d'accessibilité.

#### Étapes avec "Réduire les animations"
1. Activer "Réduire les animations" dans les paramètres du système
2. Ouvrir l'application
3. Naviguer vers la page "Sélection du jour"

#### Résultats attendus
- ✅ Le badge et le timer doivent être visibles
- ✅ Les animations doivent être désactivées ou minimales
- ✅ Les transitions doivent être instantanées

#### Étapes avec "Contraste élevé"
1. Activer "Contraste élevé" dans les paramètres du système
2. Ouvrir l'application
3. Naviguer vers la page "Sélection du jour"

#### Résultats attendus
- ✅ Le badge doit avoir des couleurs à contraste élevé
- ✅ Le texte doit être facilement lisible
- ✅ Les dégradés peuvent être remplacés par des couleurs unies

### 7. Test des États Vides et d'Erreur

#### Test État Vide
**Étapes:**
1. S'assurer qu'aucun profil n'est disponible
2. Naviguer vers la page "Sélection du jour"

**Résultats attendus:**
- ✅ Un message indiquant qu'aucun profil n'est disponible
- ✅ Le timer doit toujours être visible

#### Test État d'Erreur
**Étapes:**
1. Désactiver la connexion internet
2. Ouvrir l'application
3. Naviguer vers la page "Sélection du jour"

**Résultats attendus:**
- ✅ Un message d'erreur clair
- ✅ Option de réessayer
- ✅ Les données mock peuvent être affichées en mode développement

### 8. Test de Sélection Complète

#### Objectif
Vérifier le comportement quand l'utilisateur a atteint sa limite quotidienne.

#### Étapes
1. Utiliser toutes les sélections disponibles (1 pour free, 3 pour premium)
2. Observer l'écran

#### Résultats attendus
- ✅ Message "Votre choix est fait. Revenez demain pour votre nouvelle sélection !"
- ✅ Les profils non sélectionnés ne doivent plus être visibles
- ✅ Le timer doit indiquer quand la prochaine sélection sera disponible
- ✅ Pour les utilisateurs gratuits, une bannière de promotion GoldWen Plus

### 9. Test de Performance des Timers

#### Objectif
Vérifier que les timers n'impactent pas les performances.

#### Étapes
1. Ouvrir la page "Sélection du jour"
2. Laisser l'application ouverte pendant 5-10 minutes
3. Observer l'utilisation de la batterie et de la mémoire

#### Résultats attendus
- ✅ Pas de fuite de mémoire
- ✅ Utilisation CPU minimale
- ✅ Les timers doivent s'arrêter quand l'app est en arrière-plan

### 10. Test des Cas Limites

#### Test à Minuit
**Étapes:**
1. Ouvrir l'application juste avant minuit
2. Observer le comportement à minuit

**Résultats attendus:**
- ✅ Le calcul du prochain midi doit être correct
- ✅ Pas de crash ou de comportement inattendu

#### Test Changement d'Heure (DST)
**Étapes:**
1. Tester l'application pendant un changement d'heure d'été/hiver

**Résultats attendus:**
- ✅ Le timer doit s'ajuster correctement
- ✅ Le refresh à midi doit se faire à la bonne heure

## Exécution des Tests Automatisés

### Tests Unitaires
```bash
# Dans le répertoire du projet
flutter test test/daily_selection_refresh_test.dart

# Résultats attendus:
# ✓ All tests should pass (environ 15-20 tests)
# ✓ Coverage des fonctions principales
```

### Tests de Widgets
```bash
# Dans le répertoire du projet
flutter test test/daily_selection_refresh_ui_test.dart

# Résultats attendus:
# ✓ All tests should pass (environ 20-25 tests)
# ✓ Vérification de l'affichage du badge
# ✓ Vérification du timer
# ✓ Tests d'accessibilité
```

### Tests d'Intégration Complets
```bash
# Tous les tests
flutter test

# Avec coverage
flutter test --coverage
```

## Critères de Validation

### Critères Fonctionnels
- [ ] Le badge "Nouvelle sélection disponible !" apparaît au bon moment
- [ ] Le timer de compte à rebours est précis et se met à jour
- [ ] Le refresh automatique se déclenche à midi
- [ ] Aucun profil ne peut être sélectionné deux fois
- [ ] L'application reprend correctement après mise en arrière-plan

### Critères d'Accessibilité
- [ ] Fonctionne avec "Réduire les animations"
- [ ] Fonctionne avec "Contraste élevé"
- [ ] Labels sémantiques appropriés pour les lecteurs d'écran
- [ ] Taille de texte respecte les préférences système

### Critères de Performance
- [ ] Pas de fuite de mémoire
- [ ] Utilisation CPU < 5% en idle
- [ ] Les timers s'arrêtent en arrière-plan
- [ ] Temps de chargement < 2 secondes

### Critères de Robustesse
- [ ] Gestion correcte des erreurs réseau
- [ ] Gestion des cas limites (minuit, DST)
- [ ] Récupération après crash/restart
- [ ] Comportement prévisible dans tous les états

## Problèmes Connus et Solutions

### Le badge n'apparaît pas
**Causes possibles:**
- Le backend ne retourne pas le champ `refreshTime`
- L'heure système n'est pas correcte
- Les timers ne se sont pas lancés

**Solutions:**
- Vérifier les logs de l'application
- Vérifier la réponse API dans les dev tools
- Redémarrer l'application

### Le timer ne se met pas à jour
**Causes possibles:**
- L'application est en mode réduit d'animations
- Le timer s'est arrêté à cause d'une erreur

**Solutions:**
- Vérifier les paramètres d'accessibilité
- Relancer l'application
- Vérifier les logs

### Le refresh automatique ne se déclenche pas
**Causes possibles:**
- Les timers ont été arrêtés
- L'application est en arrière-plan depuis trop longtemps
- Problème de connexion réseau

**Solutions:**
- Ramener l'application au premier plan
- Tirer pour rafraîchir manuellement
- Vérifier la connexion internet

## Logs de Debug

Pour activer les logs de debug:
```dart
// Dans matching_provider.dart
debugPrint('hasNewSelectionAvailable: ${hasNewSelectionAvailable()}');
debugPrint('Time until next refresh: ${getTimeUntilNextRefresh()}');
debugPrint('Countdown: ${getNextRefreshCountdown()}');
```

## Conclusion

Ces tests couvrent tous les aspects de la fonctionnalité de refresh quotidien. Une validation complète nécessite:
1. ✅ Tests automatisés passent tous
2. ✅ Tests manuels validés sur iOS et Android
3. ✅ Tests d'accessibilité validés
4. ✅ Tests de performance satisfaisants
5. ✅ Validation par les utilisateurs bêta

## Références
- Issue GitHub: #[numéro]
- Spécifications: `specifications.md` Module 2
- Documentation Backend: `TACHES_BACKEND.md` Module 2
