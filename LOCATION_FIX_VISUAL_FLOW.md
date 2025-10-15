# Diagramme de flux - Fix de localisation

## Flux AVANT le fix

```
┌─────────────────────────────────────────────────┐
│          Démarrage de l'application             │
└─────────────────────┬───────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────┐
│    app_initialization_service.initialize()      │
│                                                  │
│  1. ✅ Demande permission notifications          │
│  2. ❌ Demande permission localisation           │
│     (trop tôt, contexte manquant)                │
└─────────────────────┬───────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────┐
│         Problème potentiel sur iOS              │
│                                                  │
│  • Permission refusée car contexte manquant     │
│  • iOS peut marquer comme "deniedForever"       │
│    même si user a juste fermé la popup          │
│  • Conflit permission_handler vs geolocator     │
└─────────────────────┬───────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────┐
│           Onboarding → LocationSetupPage        │
│                                                  │
│  ⚠️ Permission déjà considérée comme refusée    │
│  🔒 Message "refus permanent" affiché à tort    │
│  ❌ Pas d'option de localisation dans Settings   │
└─────────────────────────────────────────────────┘
```

## Flux APRÈS le fix

```
┌─────────────────────────────────────────────────┐
│          Démarrage de l'application             │
└─────────────────────┬───────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────┐
│    app_initialization_service.initialize()      │
│                                                  │
│  1. ✅ Demande permission notifications          │
│  2. ⏭️ SKIP permission localisation              │
│     (sera demandée dans LocationSetupPage)      │
└─────────────────────┬───────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────┐
│        Inscription/Connexion + Onboarding       │
└─────────────────────┬───────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────┐
│              LocationSetupPage                   │
│                                                  │
│  📍 Explication claire du besoin de localisation│
│  🔘 Bouton "Activer la localisation"            │
└─────────────────────┬───────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────┐
│        User clique "Activer la localisation"    │
└─────────────────────┬───────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────┐
│     1. Vérifier si services de localisation     │
│        sont activés sur l'appareil              │
└─────────────────────┬───────────────────────────┘
                      │
              ┌───────┴────────┐
              │                │
              ▼                ▼
        ❌ Désactivés      ✅ Activés
              │                │
              │                ▼
              │   ┌────────────────────────────┐
              │   │ 2. Vérifier permission     │
              │   │    avec Geolocator         │
              │   └────────┬───────────────────┘
              │            │
              │    ┌───────┴────────┬──────────────┐
              │    │                │              │
              │    ▼                ▼              ▼
              │  denied      deniedForever    whileInUse
              │    │                │              │
              │    ▼                ▼              ▼
              │  Request         Settings      Success!
              │  Permission       Button          │
              │    │                              │
              │    ▼                              │
              │  Popup                            │
              │  système                          │
              │    │                              │
              │    ▼                              │
              │  ┌─────────────┐                 │
              │  │ User décide │                 │
              │  └──┬──────┬───┘                 │
              │     │      │                     │
              │     ▼      ▼                     │
              │  Accepter Refuser                │
              │     │      │                     │
              └─────┴──────┴─────────────────────┘
                    │
                    ▼
        ┌───────────────────────────────┐
        │    Gestion du résultat        │
        │                               │
        │  ✅ Accordé:                  │
        │     • Obtenir position        │
        │     • Afficher confirmation   │
        │     • Activer bouton Continuer│
        │                               │
        │  ⚠️ Refusé:                   │
        │     • Message d'erreur        │
        │     • Possibilité de réessayer│
        │                               │
        │  🔒 Refusé définitivement:    │
        │     • Afficher message clair  │
        │     • Bouton "Ouvrir Settings"│
        │     • Guide utilisateur       │
        └───────────────────────────────┘
```

## CODE CHANGE

### Fichier: `lib/core/services/app_initialization_service.dart`

```dart
// AVANT
static Future<void> initialize() async {
  ...
  await localNotificationService.initialize();
  await localNotificationService.requestPermissions();
  debugPrint('Local notifications initialized successfully');
  
  // Request location permissions at app startup  <-- PROBLÈME!
  try {
    final hasLocationPermission = await LocationService.requestLocationAccess();
    if (hasLocationPermission) {
      debugPrint('Location permission granted');
    } else {
      debugPrint('Location permission denied or not available');
    }
  } catch (e) {
    debugPrint('Error requesting location permission: $e');
  }
  
  // Try to initialize Firebase messaging if available
  if (_firebaseAvailable) {
    ...
  }
}

// APRÈS
static Future<void> initialize() async {
  ...
  await localNotificationService.initialize();
  await localNotificationService.requestPermissions();
  debugPrint('Local notifications initialized successfully');
  
  // Note: Location permission is NOT requested here  <-- FIX!
  // It will be requested during onboarding in LocationSetupPage
  // This prevents iOS from silently denying permission when requested too early
  debugPrint('Location permission will be requested during onboarding');
  
  // Try to initialize Firebase messaging if available
  if (_firebaseAvailable) {
    ...
  }
}
```

### Fichier: `lib/core/services/location_service.dart`

```dart
// AVANT (avec permission_handler)
import 'package:permission_handler/permission_handler.dart';
...
PermissionStatus permission = await Permission.location.status;
if (permission != PermissionStatus.granted) {
  permission = await Permission.location.request();
}
_hasPermission = permission == PermissionStatus.granted;

// APRÈS (avec geolocator uniquement)
import 'package:geolocator/geolocator.dart';
...
LocationPermission permission = await Geolocator.checkPermission();
if (permission == LocationPermission.denied) {
  permission = await Geolocator.requestPermission();
}
_hasPermission = permission == LocationPermission.whileInUse || 
                 permission == LocationPermission.always;
```

### Fichier: `lib/features/onboarding/pages/location_setup_page.dart`

```dart
// AVANT
import 'package:permission_handler/permission_handler.dart';
...
final status = await Permission.location.request();
if (status.isGranted) { ... }
else if (status.isPermanentlyDenied) { ... }

// APRÈS
import 'package:geolocator/geolocator.dart';
...
// Vérifier d'abord si services activés
bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

// Puis vérifier la permission
LocationPermission permission = await Geolocator.checkPermission();
if (permission == LocationPermission.deniedForever) {
  // Afficher bouton Settings
}
if (permission == LocationPermission.denied) {
  permission = await Geolocator.requestPermission();
}
if (permission == LocationPermission.whileInUse || 
    permission == LocationPermission.always) {
  // Success!
}
```

### Fichier: `ios/Runner/Info.plist`

```xml
<!-- AVANT -->
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>...</string>
<key>NSLocationAlwaysUsageDescription</key> <!-- DÉPRÉCIÉ -->
<string>...</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>...</string>

<!-- APRÈS -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>GoldWen utilise votre localisation pour vous proposer des profils compatibles dans votre région et améliorer votre expérience de matching.</string>
```

## EXPÉRIENCE UTILISATEUR

### Ce que l'utilisateur voit maintenant:

1. **Lancement de l'app**
2. **Pop-up**: "GoldWen souhaite vous envoyer des notifications"
   - Autoriser / Ne pas autoriser
3. **Inscription/Connexion**
4. **Onboarding** (étapes diverses)
5. **LocationSetupPage** avec explication claire
6. **Clic sur "Activer la localisation"**
7. **Pop-up**: "GoldWen souhaite accéder à votre position"
   - Autoriser une fois / Autoriser pendant l'utilisation / Ne pas autoriser

### Avantages:
- ✅ Permission demandée au bon moment (avec contexte)
- ✅ Meilleur taux d'acceptation (utilisateur comprend pourquoi)
- ✅ Pas de conflit entre systèmes de permissions
- ✅ Détection correcte de "deniedForever"
- ✅ Option claire pour récupérer si refusé
- ✅ Conforme aux guidelines iOS/Android
