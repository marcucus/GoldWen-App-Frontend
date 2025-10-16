# Solution: Fix API Validation Error Parsing

## Problème

L'application rencontrait une erreur lors de la sauvegarde du profil avec des données de géolocalisation invalides :

```
flutter: API Response Body: {"success":false,"message":"Validation failed","code":"VALIDATION_ERROR","errors":["latitude must be a number conforming to the specified constraints","longitude must be a number conforming to the specified constraints"],...}
flutter: Error in saveProfile: ApiException: Failed to parse response: type 'List<dynamic>' is not a subtype of type 'Map<String, dynamic>?' (Status: 400)
```

## Cause racine

Le backend retourne les erreurs de validation sous forme de **Liste de chaînes** :
```json
"errors": [
  "latitude must be a number conforming to the specified constraints",
  "longitude must be a number conforming to the specified constraints"
]
```

Mais le code frontend attendait un **Map** :
```dart
final Map<String, dynamic>? errors;
errors = decoded['errors']; // ❌ Type mismatch!
```

## Solution implémentée

### 1. Modification de la classe ApiException

**Avant :**
```dart
class ApiException implements Exception {
  final Map<String, dynamic>? errors;
  // ...
}
```

**Après :**
```dart
class ApiException implements Exception {
  final dynamic errors; // ✅ Accepte List ou Map
  // ...
}
```

### 2. Ajout de méthodes d'aide pour formater les erreurs

```dart
/// Obtenir les messages d'erreur sous forme de liste
List<String> get errorMessages {
  if (errors == null) return [];
  
  // Gère le format Liste
  if (errors is List) {
    return (errors as List).map((e) => e.toString()).toList();
  } 
  
  // Gère le format Map
  else if (errors is Map<String, dynamic>) {
    final result = <String>[];
    (errors as Map<String, dynamic>).forEach((key, value) {
      if (value is List) {
        result.addAll((value as List).map((e) => '$key: $e'));
      } else {
        result.add('$key: $value');
      }
    });
    return result;
  }
  
  return [errors.toString()];
}

/// Obtenir un message d'erreur unique formaté
String get errorMessage {
  final messages = errorMessages;
  if (messages.isEmpty) return message;
  return messages.join(', ');
}
```

### 3. Mise à jour des gestionnaires de réponse

**Dans ApiService._handleResponse :**
```dart
dynamic errors; // Au lieu de Map<String, dynamic>?
errors = decoded['errors']; // ✅ Fonctionne avec List ou Map
```

**Dans MatchingServiceApi._handleResponse :**
```dart
dynamic errors;
errors = decoded['errors'];

throw ApiException(
  statusCode: response.statusCode,
  message: message,
  code: code,
  errors: errors, // ✅ Inclut les erreurs
  rateLimitInfo: rateLimitInfo,
);
```

### 4. Amélioration de l'affichage des erreurs

**Dans profile_setup_page.dart :**
```dart
catch (e) {
  String errorMessage = 'Erreur lors de la sauvegarde';
  
  if (e is ApiException) {
    // Utilise les messages formatés
    if (e.errorMessages.isNotEmpty) {
      errorMessage = e.errorMessages.join('\n');
    } else {
      errorMessage = e.message;
    }
  } else {
    errorMessage = e.toString();
  }
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(errorMessage),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 10),
    ),
  );
}
```

## Formats d'erreur supportés

La solution gère maintenant les deux formats d'erreur du backend :

### Format Liste (erreurs de validation simples)
```json
{
  "errors": [
    "latitude must be a number",
    "longitude must be a number"
  ]
}
```

**Affichage :**
```
latitude must be a number
longitude must be a number
```

### Format Map (erreurs de validation par champ)
```json
{
  "errors": {
    "email": ["Email is required", "Email must be valid"],
    "password": ["Password is too short"]
  }
}
```

**Affichage :**
```
email: Email is required
email: Email must be valid
password: Password is too short
```

## Tests ajoutés

```dart
test('should handle validation errors as List', () {
  final exception = ApiException(
    statusCode: 400,
    message: 'Validation failed',
    code: 'VALIDATION_ERROR',
    errors: [
      'latitude must be a number conforming to the specified constraints',
      'longitude must be a number conforming to the specified constraints'
    ],
  );

  expect(exception.errorMessages.length, equals(2));
  expect(exception.errorMessages[0], contains('latitude'));
  expect(exception.errorMessages[1], contains('longitude'));
});

test('should handle validation errors as Map', () {
  final exception = ApiException(
    statusCode: 400,
    message: 'Validation failed',
    code: 'VALIDATION_ERROR',
    errors: {
      'email': ['Email is required', 'Email must be valid'],
      'password': ['Password is too short'],
    },
  );

  expect(exception.errorMessages.length, equals(3));
});

test('should handle null errors gracefully', () {
  final exception = ApiException(
    statusCode: 500,
    message: 'Internal server error',
  );

  expect(exception.errorMessages, isEmpty);
  expect(exception.errorMessage, equals('Internal server error'));
});
```

## Résultat

### Avant le correctif ❌
```
Error in saveProfile: ApiException: Failed to parse response: 
type 'List<dynamic>' is not a subtype of type 'Map<String, dynamic>?' (Status: 400)
```

### Après le correctif ✅
```
latitude must be a number conforming to the specified constraints
longitude must be a number conforming to the specified constraints
```

## Fichiers modifiés

1. **lib/core/services/api_service.dart**
   - Classe `ApiException` : champ `errors` de `Map?` à `dynamic`
   - Ajout des méthodes `errorMessages` et `errorMessage`
   - Mise à jour de `_handleResponse` dans `ApiService`
   - Mise à jour de `_handleResponse` dans `MatchingServiceApi`
   - Mise à jour de `_handleMatchingResponse`

2. **lib/features/profile/pages/profile_setup_page.dart**
   - Amélioration de l'affichage des erreurs de validation

3. **test/api_service_test.dart**
   - Ajout de tests pour les erreurs au format List
   - Ajout de tests pour les erreurs au format Map
   - Ajout de tests pour les erreurs null

## Vérification de la correction

Pour vérifier que la correction fonctionne :

1. **Lancer les tests unitaires :**
   ```bash
   flutter test test/api_service_test.dart
   ```

2. **Test manuel :**
   - Essayer de sauvegarder un profil sans données de localisation
   - L'application devrait maintenant afficher clairement les erreurs de validation
   - L'application ne devrait plus planter avec une erreur de type

3. **Résultats attendus :**
   - ✅ Pas d'erreur de casting de type
   - ✅ Messages d'erreur clairs pour l'utilisateur
   - ✅ L'utilisateur peut voir quels champs doivent être corrigés

## Notes importantes

Cette correction résout l'erreur de parsing des réponses API, mais l'erreur de validation sous-jacente (latitude/longitude doivent être des nombres) suggère que :

1. Les données de localisation ne sont pas correctement collectées
2. La détection de localisation pourrait avoir échoué
3. Les valeurs de localisation pourraient être invalides

Ces problèmes séparés doivent être adressés par :
1. S'assurer que la localisation est correctement capturée avant la sauvegarde du profil
2. Ajouter une validation côté client pour les valeurs latitude/longitude
3. Fournir un retour UI clair lorsque la localisation est requise mais manquante
