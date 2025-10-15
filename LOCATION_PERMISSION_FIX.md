# Fix de la demande de permission de localisation

## Problème identifié

L'application rencontrait plusieurs problèmes avec la gestion des permissions de localisation sur iOS :

1. ❌ **Permission demandée trop tôt** : La permission était demandée au démarrage de l'app, avant que l'utilisateur ne comprenne pourquoi elle est nécessaire
2. ❌ **Détection incorrecte de "refus permanent"** : L'app considérait parfois à tort que la permission avait été définitivement refusée
3. ❌ **Conflit entre deux systèmes de permissions** : Utilisation simultanée de `permission_handler` et `geolocator` causant des incohérences
4. ❌ **Info.plist iOS contenant des clés dépréciées** : Présence de clés obsolètes pouvant créer de la confusion

## Solution implémentée

### 1. Utilisation exclusive de Geolocator

L'app utilise maintenant **uniquement** le package `geolocator` pour gérer les permissions de localisation, éliminant les conflits avec `permission_handler`.

### 2. Permission demandée au bon moment

La permission de localisation est maintenant demandée **uniquement** dans `LocationSetupPage` pendant le flux d'onboarding, quand l'utilisateur comprend le contexte et la raison de cette demande.

### 3. Info.plist iOS nettoyé

Suppression des clés dépréciées et conservation uniquement de `NSLocationWhenInUseUsageDescription`.

## Modifications apportées

### Fichier 1: `ios/Runner/Info.plist`

**Avant :**
```xml
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>...</string>
<key>NSLocationAlwaysUsageDescription</key>  <!-- DÉPRÉCIÉ -->
<string>...</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>...</string>
```

**Après :**
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>GoldWen utilise votre localisation pour vous proposer des profils compatibles dans votre région et améliorer votre expérience de matching.</string>
```

### Fichier 2: `lib/core/services/location_service.dart`

**Changements :**
1. Suppression de l'import `permission_handler`
2. Remplacement de `Permission.location` par `Geolocator.checkPermission()` et `Geolocator.requestPermission()`
3. Utilisation des états `LocationPermission` au lieu de `PermissionStatus`
4. Meilleure gestion des états : `denied`, `deniedForever`, `whileInUse`, `always`

**Code clé :**
```dart
// Check current permission status
LocationPermission permission = await Geolocator.checkPermission();

// If permission is denied, request it
if (permission == LocationPermission.denied) {
  permission = await Geolocator.requestPermission();
}

// Check if granted
if (permission == LocationPermission.whileInUse || 
    permission == LocationPermission.always) {
  // Permission granted
}
```

### Fichier 3: `lib/features/onboarding/pages/location_setup_page.dart`

**Changements :**
1. Suppression de l'import `permission_handler`
2. Utilisation exclusive de `geolocator` pour vérifier et demander les permissions
3. Meilleure détection de l'état "deniedForever" pour éviter les faux positifs
4. Vérification préalable de l'activation des services de localisation

**Flux amélioré :**
```dart
1. Vérifier si les services de localisation sont activés
2. Vérifier l'état actuel de la permission
3. Si "deniedForever", afficher le bouton paramètres
4. Sinon, demander la permission
5. Traiter le résultat correctement
```

### Fichier 4: `lib/core/services/app_initialization_service.dart`

**Changement majeur :**

**Avant :**
```dart
// Request location permissions at app startup
try {
  final hasLocationPermission = await LocationService.requestLocationAccess();
  ...
} catch (e) {
  ...
}
```

**Après :**
```dart
// Note: Location permission is NOT requested here
// It will be requested during onboarding in LocationSetupPage
// This prevents iOS from silently denying permission when requested too early
debugPrint('Location permission will be requested during onboarding');
```

## Comportement après le fix

### Au premier démarrage de l'application

1. ✅ **Demande de notifications** - Pour recevoir les notifications de l'app
2. ⏭️ **PAS de demande de localisation** - Sera demandée plus tard pendant l'onboarding
3. ✅ **Accès réseau** (Android uniquement)

### Pendant l'onboarding (LocationSetupPage)

1. L'utilisateur arrive sur la page de configuration de localisation
2. Il voit une explication claire de pourquoi la localisation est nécessaire
3. Il clique sur "Activer la localisation"
4. La permission système est demandée avec le contexte approprié
5. Le résultat est traité correctement :
   - ✅ **Accordé** : Position détectée et enregistrée
   - ⚠️ **Refusé** : Message d'erreur, possibilité de réessayer
   - 🔒 **Refusé définitivement** : Bouton pour ouvrir les paramètres de l'app

## Vérifications des configurations

### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```
✅ Permissions déclarées correctement

### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>GoldWen utilise votre localisation pour vous proposer des profils compatibles dans votre région et améliorer votre expérience de matching.</string>
```
✅ Description unique et claire en français

## Tests à effectuer

### Test 1 : Installation fraîche sur iOS
1. Désinstaller complètement l'application
2. Réinstaller et lancer l'application
3. ✅ Vérifier que la demande de localisation N'apparaît PAS au démarrage
4. ✅ Procéder à l'onboarding jusqu'à LocationSetupPage
5. ✅ Cliquer sur "Activer la localisation"
6. ✅ Vérifier que la popup système de permission apparaît
7. ✅ Tester les différentes réponses (Autoriser, Ne pas autoriser)

### Test 2 : Refus puis réactivation
1. Refuser la permission lors de la première demande
2. ✅ Vérifier que le message d'erreur s'affiche
3. ✅ Cliquer à nouveau sur "Activer la localisation"
4. ✅ Vérifier qu'on peut redemander la permission

### Test 3 : Refus définitif (iOS)
1. Sur iOS, refuser la permission deux fois de suite
2. ✅ Vérifier que le bouton "Ouvrir les paramètres" apparaît
3. ✅ Cliquer sur "Ouvrir les paramètres"
4. ✅ Vérifier que les paramètres de l'app s'ouvrent avec l'option de localisation visible
5. ✅ Activer la localisation dans les paramètres
6. ✅ Revenir à l'app et vérifier que la permission est maintenant accordée

### Test 4 : Services de localisation désactivés
1. Désactiver les services de localisation dans les paramètres iOS/Android
2. ✅ Lancer l'app et aller à LocationSetupPage
3. ✅ Cliquer sur "Activer la localisation"
4. ✅ Vérifier que le message approprié s'affiche

## Impact sur le flux utilisateur

### Avant le fix
1. Démarrage app → ❌ Demande localisation (trop tôt, contexte manquant)
2. Inscription/Connexion
3. Onboarding → LocationSetupPage
4. ⚠️ Permission peut être déjà refusée ou mal gérée

### Après le fix
1. Démarrage app → Demande notifications uniquement
2. Inscription/Connexion
3. Onboarding → LocationSetupPage
4. ✅ Explication claire de pourquoi la localisation est nécessaire
5. ✅ Demande de permission avec contexte approprié
6. ✅ Gestion correcte de tous les états de permission

## Avantages de cette approche

1. **Meilleur taux d'acceptation** : L'utilisateur comprend pourquoi la permission est nécessaire
2. **Pas de faux positifs "deniedForever"** : La permission n'est pas demandée trop tôt
3. **Code plus simple** : Un seul système de gestion des permissions (geolocator)
4. **Conforme aux guidelines iOS** : Permission demandée au moment approprié avec contexte
5. **Meilleure UX** : Messages clairs et options de récupération si refus

## Notes techniques

- La demande de permission est encapsulée dans un try-catch pour éviter les crashs
- Si la permission est refusée, l'app explique clairement comment la réactiver
- Le service LocationService ne s'initialise que si la permission est accordée
- Les logs de débogage permettent de suivre le statut de la permission
- Sur iOS, `Geolocator.openAppSettings()` ouvre directement les paramètres de l'app
