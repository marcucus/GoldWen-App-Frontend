# Documentation RGPD - Conformité Complète

## Vue d'ensemble

Cette documentation décrit l'implémentation complète des fonctionnalités RGPD (Règlement Général sur la Protection des Données) dans l'application GoldWen, conformément aux articles 17 et 20 du RGPD.

## Fonctionnalités Implémentées

### 1. Export de Données (Article 20 RGPD - Portabilité des Données)

#### Description
Permet aux utilisateurs d'exporter toutes leurs données personnelles dans un format structuré, couramment utilisé et lisible par machine (JSON).

#### Interface Utilisateur
- **Page dédiée**: `/data-export` (`DataExportPage`)
- **Accès**: Depuis les paramètres de confidentialité
- **Composants**:
  - Bannière d'information RGPD
  - Liste des données incluses dans l'export
  - Statut de la demande d'export
  - Bouton de téléchargement (quand prêt)

#### Flux Utilisateur
1. L'utilisateur demande un export via le bouton "Demander un export"
2. Une requête est créée avec un `requestId` unique
3. Le statut passe à "processing" avec temps estimé (24h)
4. L'utilisateur reçoit un email quand l'export est prêt
5. Le téléchargement est disponible pendant 7 jours
6. L'utilisateur peut télécharger et partager le fichier JSON

#### Données Exportées
- Informations de profil (nom, email, etc.)
- Photos et média uploadés
- Réponses au questionnaire de personnalité
- Historique de conversations
- Matches et préférences
- Paramètres et consentements
- Historique d'activité

#### Endpoints API
```dart
// Demander un export
POST /api/v1/users/me/data-export
Response: { requestId, status: 'processing', estimatedTime: '24 heures' }

// Vérifier le statut
GET /api/v1/users/me/data-export/:requestId
Response: { requestId, status, downloadUrl?, expiresAt? }

// Télécharger l'export
GET /api/v1/users/me/data-export/:requestId/download
Response: JSON file (bytes)
```

#### Modèle de Données
```dart
class DataExportRequest {
  final String requestId;
  final String status; // 'processing', 'ready', 'expired', 'failed'
  final DateTime requestedAt;
  final DateTime? expiresAt;
  final String? downloadUrl;
  final String? estimatedTime;
  
  // Helpers
  bool get isReady;
  bool get isProcessing;
  bool get isFailed;
  bool get isExpired;
}
```

### 2. Suppression de Compte avec Délai de Grâce (Article 17 RGPD - Droit à l'Effacement)

#### Description
Permet aux utilisateurs de supprimer définitivement leur compte avec option de délai de grâce de 30 jours.

#### Interface Utilisateur
- **Page dédiée**: `/account-deletion` (`AccountDeletionPage`)
- **Accès**: Depuis les paramètres de confidentialité
- **Composants**:
  - Bannière d'avertissement
  - Liste des données qui seront supprimées
  - Champ de confirmation par mot de passe
  - Champ de raison (optionnel)
  - Choix: suppression immédiate ou avec délai de grâce
  - Vue de statut si suppression programmée
  - Bouton d'annulation (si applicable)

#### Flux Utilisateur

##### Suppression avec Délai de Grâce (30 jours)
1. L'utilisateur accède à la page de suppression
2. Entre son mot de passe pour confirmation
3. Peut indiquer une raison (optionnel)
4. Choisit la suppression avec délai de grâce (par défaut)
5. Confirme l'action
6. Le compte est marqué comme "scheduled_deletion"
7. Un compte à rebours de 30 jours démarre
8. L'utilisateur peut annuler à tout moment pendant ces 30 jours
9. Après 30 jours, le compte est automatiquement supprimé

##### Suppression Immédiate
1. L'utilisateur coche "Supprimer immédiatement"
2. Confirme avec mot de passe
3. Double confirmation requise
4. Le compte et toutes les données sont supprimés immédiatement
5. Redirection vers la page de bienvenue
6. Déconnexion automatique

#### Données Supprimées
- Profil et toutes les photos
- Réponses au questionnaire de personnalité
- Tous les matches et conversations
- Historique d'activité
- Préférences et paramètres
- Abonnement (si actif, annulé)

#### Endpoints API
```dart
// Demander la suppression
DELETE /api/v1/users/me
Body: {
  password: string,
  reason?: string,
  immediateDelete: boolean
}
Response: {
  status: 'scheduled_deletion' | 'deleted',
  deletionDate?: DateTime,
  message: string
}

// Annuler la suppression
POST /api/v1/users/me/cancel-deletion
Response: { success: true, message: string }

// Vérifier le statut de suppression
GET /api/v1/users/me/deletion-status
Response: {
  status: 'active' | 'scheduled_deletion' | 'deleted',
  deletionDate?: DateTime,
  canCancel: boolean
}
```

#### Modèle de Données
```dart
class AccountDeletionStatus {
  final String status; // 'active', 'scheduled_deletion', 'deleted'
  final DateTime? deletionDate;
  final String? message;
  final bool canCancel;
  
  // Helpers
  bool get isScheduledForDeletion;
  bool get isActive;
  bool get isDeleted;
  int? get daysUntilDeletion;
}
```

### 3. Gestion des Consentements (Existant - Amélioré)

#### Description
Le système de consentement existant a été conservé et est conforme RGPD.

#### Fonctionnalités
- Consentement obligatoire pour le traitement des données
- Consentements optionnels pour marketing et analytics
- Renouvellement suggéré après 10 mois
- Validation expire après 1 an
- Modal de consentement réutilisable

## Architecture Technique

### Services

#### GdprService
Service principal pour la gestion RGPD.

```dart
class GdprService extends ChangeNotifier {
  // État
  DataExportRequest? currentExportRequest;
  AccountDeletionStatus? accountDeletionStatus;
  GdprConsent? currentConsent;
  PrivacySettings? currentPrivacySettings;
  
  // Export de données
  Future<bool> requestDataExport();
  Future<bool> getExportStatus(String requestId);
  Future<Uint8List?> downloadDataExport(String requestId);
  
  // Suppression de compte
  Future<bool> deleteAccountWithGdprCompliance({
    required String password,
    String? reason,
    bool immediateDelete = false,
  });
  Future<bool> cancelAccountDeletion();
  Future<bool> getAccountDeletionStatus();
  
  // Consentement (existant)
  Future<bool> submitConsent({...});
  bool isConsentStillValid();
  bool needsConsentRenewal();
}
```

#### ApiService
Endpoints API pour les opérations RGPD.

```dart
class ApiService {
  // Export
  static Future<Map<String, dynamic>> requestDataExport();
  static Future<Map<String, dynamic>> getDataExportStatus(String requestId);
  static Future<dynamic> downloadDataExport(String requestId);
  
  // Suppression
  static Future<Map<String, dynamic>> deleteAccountWithGdpr({
    required String password,
    String? reason,
    bool immediateDelete = false,
  });
  static Future<Map<String, dynamic>> cancelAccountDeletion();
  static Future<Map<String, dynamic>> getAccountDeletionStatus();
}
```

### Routes

```dart
// Routes ajoutées
GoRoute(path: '/data-export', builder: () => DataExportPage())
GoRoute(path: '/account-deletion', builder: () => AccountDeletionPage())

// Routes existantes modifiées
GoRoute(path: '/privacy-settings', builder: () => PrivacySettingsPage())
  // Liens vers les nouvelles pages au lieu de dialogs
```

### Modèles de Données

#### Nouveaux Modèles
- `DataExportRequest`: Gestion des demandes d'export
- `AccountDeletionStatus`: Suivi du statut de suppression

#### Modèles Existants (Inchangés)
- `GdprConsent`: Consentements utilisateur
- `PrivacySettings`: Paramètres de confidentialité
- `PrivacyPolicy`: Politique de confidentialité

## Tests

### Tests Unitaires

#### rgpd_models_test.dart
- Tests pour `DataExportRequest`
  - Création depuis JSON
  - Détection de statuts (ready, processing, failed, expired)
  - Sérialisation
- Tests pour `AccountDeletionStatus`
  - Création depuis JSON
  - Calcul des jours restants
  - Détection de statuts
- Tests pour modèles existants (backward compatibility)

#### rgpd_service_enhanced_test.dart
- Gestion des requêtes d'export
- Suivi du statut de suppression
- Calculs de période de grâce
- Expiration des exports
- Conformité RGPD (Art. 17, 20)

### Tests Widgets

#### account_deletion_page_test.dart
- Affichage du formulaire de suppression
- Option de délai de grâce
- Vue de suppression programmée
- Bouton d'annulation
- Validation du mot de passe
- Couleurs et icônes appropriées

#### data_export_page_test.dart
- Affichage de la bannière RGPD
- Liste des données incluses
- Statuts d'export (processing, ready, failed, expired)
- Bouton de téléchargement
- Bouton d'actualisation
- Informations de temps de traitement

## Dépendances Ajoutées

```yaml
dependencies:
  path_provider: ^2.1.1  # Pour la gestion des fichiers
  share_plus: ^10.1.4     # Pour le partage de fichiers
```

## Conformité RGPD

### Article 17 - Droit à l'Effacement ("Droit à l'Oubli")
✅ **Implémenté**
- Suppression complète des données personnelles
- Délai de grâce de 30 jours (bonne pratique)
- Suppression immédiate disponible
- Confirmation par mot de passe
- Possibilité d'annuler pendant le délai de grâce

### Article 20 - Droit à la Portabilité des Données
✅ **Implémenté**
- Export dans un format structuré (JSON)
- Format lisible par machine
- Toutes les données personnelles incluses
- Processus de demande simple
- Email de notification
- Téléchargement sécurisé

### Autres Articles Concernés

#### Article 13 & 14 - Information
✅ Bannières d'information claires sur les droits RGPD

#### Article 7 - Consentement
✅ Système de consentement existant et conforme

#### Article 15 - Droit d'Accès
✅ Via l'export de données

#### Article 16 - Droit de Rectification
✅ Via les paramètres de profil (existant)

## Guide d'Utilisation

### Pour les Utilisateurs

#### Exporter ses Données
1. Aller dans **Profil & Paramètres**
2. Sélectionner **Paramètres de confidentialité**
3. Cliquer sur **Exporter mes données**
4. Cliquer sur **Demander un export**
5. Attendre l'email de confirmation (max 24h)
6. Télécharger le fichier JSON
7. Le lien expire après 7 jours

#### Supprimer son Compte
1. Aller dans **Profil & Paramètres**
2. Sélectionner **Paramètres de confidentialité**
3. Cliquer sur **Supprimer mon compte**
4. Choisir entre:
   - **Délai de grâce de 30 jours** (recommandé)
   - **Suppression immédiate** (irréversible)
5. Entrer son mot de passe
6. Confirmer la suppression

#### Annuler une Suppression Programmée
1. Aller dans **Paramètres de confidentialité**
2. Cliquer sur **Supprimer mon compte**
3. Voir le compte à rebours
4. Cliquer sur **Annuler la suppression**

### Pour les Développeurs

#### Ajouter une Nouvelle Donnée à l'Export
1. Mettre à jour l'endpoint backend `/api/v1/users/me/data-export`
2. Ajouter la donnée dans la liste UI (`DataExportPage`)
3. Mettre à jour la documentation

#### Tester les Fonctionnalités RGPD
```bash
# Exécuter tous les tests RGPD
flutter test test/rgpd_models_test.dart
flutter test test/rgpd_service_enhanced_test.dart
flutter test test/account_deletion_page_test.dart
flutter test test/data_export_page_test.dart

# Exécuter tous les tests
flutter test
```

## Bonnes Pratiques

### Sécurité
- ✅ Confirmation par mot de passe pour suppression
- ✅ Double confirmation pour suppression immédiate
- ✅ Liens de téléchargement avec expiration
- ✅ Authentification requise pour toutes les opérations

### UX/UI
- ✅ Messages clairs et rassurants
- ✅ Avertissements visibles pour actions destructives
- ✅ Compte à rebours visuel pour délai de grâce
- ✅ Possibilité d'annuler les actions critiques
- ✅ Design accessible et responsive

### Performance
- ✅ Export asynchrone pour ne pas bloquer l'utilisateur
- ✅ Notification email au lieu d'attente active
- ✅ Gestion d'état optimisée avec Provider

## Maintenance et Support

### Logs et Monitoring
Les opérations RGPD critiques doivent être loggées:
- Demandes d'export
- Suppressions de compte
- Annulations de suppression
- Téléchargements d'exports

### Support Utilisateur
En cas de problème:
1. Vérifier les logs backend
2. Vérifier le statut de la requête
3. Relancer l'export si échec
4. Contacter le support technique si nécessaire

## Évolutions Futures

### Améliorations Possibles
- [ ] Historique des consentements
- [ ] Formats d'export additionnels (PDF, CSV)
- [ ] Export partiel (sélection de données)
- [ ] Notification push pour export prêt
- [ ] Interface d'administration pour gestion RGPD

### Conformité Continue
- Revoir annuellement la conformité RGPD
- Mettre à jour en cas de changements législatifs
- Audits réguliers de sécurité
- Formation continue de l'équipe

## Ressources

### Documentation RGPD
- [RGPD Article 17](https://gdpr-info.eu/art-17-gdpr/) - Droit à l'effacement
- [RGPD Article 20](https://gdpr-info.eu/art-20-gdpr/) - Portabilité des données
- [CNIL - Guide du développeur](https://www.cnil.fr/fr/guide-du-developpeur)

### Code Source
- `/lib/features/legal/pages/data_export_page.dart`
- `/lib/features/legal/pages/account_deletion_page.dart`
- `/lib/core/services/gdpr_service.dart`
- `/lib/core/models/gdpr_consent.dart`

### Tests
- `/test/rgpd_models_test.dart`
- `/test/rgpd_service_enhanced_test.dart`
- `/test/account_deletion_page_test.dart`
- `/test/data_export_page_test.dart`

## Contact

Pour toute question concernant l'implémentation RGPD:
- Email: legal@goldwen.com
- Documentation: Ce fichier
- Issues: GitHub Issues du projet
