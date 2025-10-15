# Fix de la demande de permission de localisation

## Problème identifié

Au premier démarrage de l'application, les permissions suivantes étaient demandées :
- ✅ Notifications (demandées correctement)
- ✅ Accès aux appareils du réseau (Android)
- ❌ Localisation (PAS demandée automatiquement)

La permission de localisation n'était demandée que lorsque l'utilisateur atteignait manuellement la page `LocationSetupPage` dans le flux d'onboarding, ce qui n'était pas optimal.

## Solution implémentée

La demande de permission de localisation a été ajoutée au service d'initialisation de l'application (`app_initialization_service.dart`), au même niveau que la demande de permission de notifications.

### Modifications apportées

**Fichier modifié :** `lib/core/services/app_initialization_service.dart`

1. **Import ajouté :**
   ```dart
   import 'location_service.dart';
   ```

2. **Code ajouté dans la méthode `initialize()` :**
   ```dart
   // Request location permissions at app startup
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
   ```

## Comportement attendu après le fix

Au premier démarrage de l'application, l'utilisateur verra les demandes de permission suivantes :

1. **Permission de notifications** - Pour recevoir les notifications de l'app
2. **Permission de localisation** - Pour proposer des profils à proximité
3. **Accès réseau** (Android uniquement) - Pour découvrir les appareils sur le réseau local

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

<key>NSLocationAlwaysUsageDescription</key>
<string>Nous avons besoin de votre localisation pour vous proposer des profils à proximité.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>GoldWen utilise votre localisation pour vous proposer des profils compatibles dans votre région et améliorer votre expérience de matching.</string>
```
✅ Descriptions des permissions configurées en français

## Tests à effectuer

Pour vérifier que le fix fonctionne correctement :

### Test 1 : Installation fraîche sur Android
1. Désinstaller complètement l'application
2. Réinstaller et lancer l'application
3. Vérifier que la demande de permission de localisation apparaît au démarrage
4. Observer l'ordre des demandes : notifications → localisation

### Test 2 : Installation fraîche sur iOS
1. Désinstaller complètement l'application
2. Réinstaller et lancer l'application
3. Vérifier que la demande de permission de localisation apparaît au démarrage
4. Observer l'ordre des demandes : notifications → localisation

### Test 3 : Logs de débogage
Vérifier dans les logs que les messages suivants apparaissent :
```
Local notifications initialized successfully
Location permission granted (ou denied)
```

## Impact sur le flux utilisateur

### Avant le fix
1. Démarrage app → Demande notifs
2. Inscription/Connexion
3. Onboarding → Arrivée sur LocationSetupPage
4. **Clic manuel requis** → Demande localisation

### Après le fix
1. Démarrage app → Demande notifs
2. **Demande localisation automatique**
3. Inscription/Connexion
4. Onboarding → LocationSetupPage (permission déjà accordée ou refusée)

## Notes techniques

- La demande de permission est encapsulée dans un try-catch pour éviter les crashs
- Si la permission est refusée, l'app continue de fonctionner normalement
- Le service LocationService gère déjà les cas de refus de permission
- Les logs de débogage permettent de suivre le statut de la permission
