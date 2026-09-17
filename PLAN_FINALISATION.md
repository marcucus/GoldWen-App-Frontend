# GoldWen — Plan de finalisation (backend + mobile + web)

## Context

Audit complet des trois dépôts :

- `/Users/amarques/Documents/Dev/GoldWen-App-Backend` — NestJS 11 (`main-api`, ~46k LOC, 21 contrôleurs) + `matching-service` FastAPI
- `/Users/amarques/Documents/Dev/GoldWen-App-Frontend` — Flutter, 231 fichiers Dart, provider + go_router
- `/Users/amarques/Documents/Dev/GoldWen-app-web` — Next.js 14 Pages Router, site vitrine 6 langues

Les README des trois repos annoncent un MVP « ✅ implémenté ». La réalité vérifiée est différente : **6 failles permettent à n'importe qui de se connecter comme un autre utilisateur, de supprimer des comptes ou d'obtenir un abonnement premium gratuit**, plusieurs fonctionnalités (signalements, historique, temps réel du chat, feedback, export RGPD) appellent des routes qui n'existent pas ou avec un client HTTP mal configuré, la section Réglages contient quatre culs-de-sac, la CI backend est rouge (141 tests en échec), et l'app n'est pas publiable (signature debug, Firebase absent, icônes par défaut). Le site vitrine n'a aucune page légale réelle ni bandeau cookies alors qu'il charge Vercel Analytics.

**Décisions produit prises pour ce plan :**

- Périmètre : tout (sécurité, features, qualité, release, web).
- Back-office admin : **retiré de l'app Flutter**, reporté vers une app web séparée (hors périmètre immédiat, préparé côté backend).
- Rituel quotidien : **5 profils présentés à tous**, 1 choix en gratuit / 3 en GoldWen Plus. Taille de sélection découplée du quota de choix.

**Résultat visé :** une application publiable sur les stores, sans faille connue, sans écran mort, avec une CI verte et un site conforme au droit français.

---

## Phase 0 — Sécurité backend (bloquant absolu)

**Statut (2026-09-17) : ✅ Implémentée et vérifiée.** Les 10 correctifs ci-dessous sont en place dans le code (non commités — `git status` liste 42 fichiers modifiés/nouveaux dans `main-api` et `matching-service`). `npx tsc --noEmit` : aucune erreur dans le code touché. Suite de tests des modules concernés (`auth`, `admin`, `moderation`, `matching`, `chat`, `notifications`, `subscriptions`) : **285/290 tests passent** ; les 5 échecs restants sont dans `matching.scheduler.spec.ts`, un fichier à diff nul (jamais touché par ces correctifs) — pré-existant, hors périmètre Phase 0, à traiter en Phase 4.1 (cf. CI backend rouge). Vérifications manuelles faites au niveau code (routes, guards) : `POST /auth/social-login` supprimée, `GET /admin/*` protégé par `AdminGuard`, `POST /webhooks/revenuecat` exige la signature sur le raw body, `POST /subscriptions/purchase` vérifie l'achat via l'API REST RevenueCat, `POST /moderation/webhook/photo` exige le secret partagé. Les vérifications bout-en-bout avec serveur + Postgres + Redis réels (section « Vérification > Backend » plus bas) restent à faire par Adrien.

**Points à arbitrer avant déploiement :**
- `ConsentGuard` est maintenant global (`APP_GUARD`) : tout utilisateur existant sans ligne `UserConsent` sera bloqué sur toutes les routes authentifiées tant qu'il n'aura pas (re)donné son consentement. À valider avant mise en prod (migration de données ou fenêtre de grâce ?).
- Le login admin (`POST /admin/auth/login`) est un flux réellement nouveau (avant : pas de vérification de mot de passe). Tout outillage/scripts admin existants doivent être mis à jour pour utiliser la nouvelle réponse `{accessToken}` en `Authorization: Bearer`.
- Le JWT admin partage le même secret (`jwt.secret`) que les JWT utilisateurs, distingués par le claim `type: 'admin'` — acceptable mais à noter.

Chacun de ces points est exploitable aujourd'hui en production.

### ✅ 0.1 Usurpation d'identité via `POST /auth/social-login`
`main-api/src/modules/auth/auth.controller.ts:98` → `auth.service.ts:186-232`. Le body (`socialId`, `email`) est cru sur parole, l'utilisateur est retrouvé par email et un JWT est renvoyé. Un POST avec l'email de la victime suffit.
→ **Supprimer la route** `social-login` et son DTO. `POST /auth/google` et `POST /auth/apple` vérifient déjà les jetons ; ce sont les seuls chemins à conserver. Mettre à jour l'appelant Flutter (`api_service.dart`) si présent.

### ✅ 0.2 Routes admin sans contrôle de rôle
`main-api/src/modules/admin/admin.controller.ts:32-233` n'utilise que `JwtAuthGuard` : tout utilisateur authentifié peut lister, suspendre et **supprimer** des comptes, diffuser des notifications et traiter les signalements. Idem `moderation.controller.ts:59-92`.
→ Créer `AdminGuard` (ou réutiliser le `RolesGuard` existant s'il y en a un dans `common/guards/`), l'appliquer au niveau contrôleur sur `AdminController`, `MonitoringController` et les routes `admin/*` de `ModerationController`.

### ✅ 0.3 Mot de passe admin en dur + login sans jeton
`admin.service.ts:87-89` : `if (password === 'admin_password_123')`. La colonne `passwordHash` de `admin.entity.ts:21` n'est jamais utilisée. `admin.controller.ts:47` ne renvoie aucun token et lève un `Error` nu (→ 500).
→ Comparer avec `bcrypt.compare(password, admin.passwordHash)`, émettre un JWT avec un claim de rôle consommé par `AdminGuard`, lever `UnauthorizedException`. Ajouter une migration + un script de seed pour créer le premier admin.

### ✅ 0.4 Premium gratuit — trois chemins
- `subscriptions.controller.ts:131-138` : webhook RevenueCat **sans authentification ni signature**, accorde directement l'abonnement.
- `revenuecat.controller.ts:81` : la signature n'est vérifiée *que si l'en-tête est présent* → l'omettre suffit. De plus le HMAC est calculé sur `JSON.stringify(parsedBody)` au lieu du corps brut, donc les vraies signatures échouent.
- `revenuecat.service.ts:196-230` : `validatePurchase` active `goldwen_plus` à partir d'un `productId` fourni par le client, sans vérification de reçu.

→ Supprimer le webhook non signé de `SubscriptionsController` ; garder un seul point d'entrée dans `RevenueCatController`. Rendre la vérification obligatoire (`UnauthorizedException` si l'en-tête manque) et la calculer sur le **raw body** — activer `rawBody: true` dans `NestFactory.create` (`main.ts`) et lire `req.rawBody`. Faire de `validatePurchase` un appel à l'API REST RevenueCat (`GET /subscribers/{app_user_id}`) et n'accorder l'abonnement que selon la réponse.

### ✅ 0.5 Webhook de modération ouvert
`moderation.controller.ts:32-42` accepte n'importe quel `photoId` sans auth.
→ Guard par secret partagé (`MODERATION_WEBHOOK_SECRET`), même mécanisme que RevenueCat.

### ✅ 0.6 Déclencheurs internes exposés
- `notifications.controller.ts:237-258` : la garde « dev only » est `if (this.scheduledNotificationsService)` → toujours vraie. Envoi de masse accessible à tous.
- `matching.controller.ts:76-84` : génération manuelle de sélection quotidienne, non gardée, coûte un appel au service de matching par requête.

→ Passer les deux derrière `AdminGuard`, ou les conditionner à `NODE_ENV !== 'production'`.

### ✅ 0.7 Modération d'images inopérante (tout est auto-approuvé)
`moderation.service.ts:45-47` construit `./uploads/${photo.filename}` alors que `StorageService` stocke sous `photos/<timestamp>-<name>` ou une URL S3. `image-moderation.service.ts:122-129` intercepte l'échec de lecture et retourne `createSafeResult()` → **toutes les photos passent**.
→ Utiliser `moderateImageFromUrl` (déjà écrit, jamais appelé) avec `photo.url`. Faire échouer en « à réviser manuellement » plutôt qu'en « sûr » dans le `catch`.

### ✅ 0.8 `isApproved` écrit mais jamais lu
`moderation.service.ts:53` positionne le flag ; aucun consommateur (`grep isApproved` → aucune lecture). Les photos rejetées restent visibles.
→ Filtrer sur `isApproved` dans `ProfilesService` et dans la construction des profils de `MatchingService`.

### ✅ 0.9 Traversée de chemin dans le stockage local *(code non commité)*
`main-api/src/common/services/storage.service.ts` (modifié, non commité) : `deleteLocal` fait `path.join(process.cwd(), new URL(fileUrl).pathname)` puis `unlink` sans vérifier que le chemin résolu reste sous `uploads/`.
→ Résoudre puis vérifier `resolved.startsWith(path.resolve(uploadsRoot) + path.sep)`.
Par ailleurs `main.ts` sert `/uploads` en statique sans auth ni filtre d'approbation → à réserver au développement, ou passer par des URLs signées.

### ✅ 0.10 Durcissements complémentaires
- `ConsentGuard` (`auth/guards/consent.guard.ts`) existe et n'est enregistré nulle part, alors que `SkipConsentCheck` est déjà utilisé (`users.controller.ts:380,437`). L'enregistrer en `APP_GUARD` — le contrat RGPD documenté n'est pas appliqué aujourd'hui.
- WebSocket : `chat.gateway.ts:38` CORS `origin: … || true` (joker) ; `handleConnection:73-96` ne consulte pas la liste noire Redis ni `user.status` → un logout ne coupe pas les sockets.
- `auth.service.ts:352,391,398` utilise `KEYS refresh:*` sur chaque refresh et logout → commande bloquante O(N). Indexer les refresh tokens par utilisateur (`refresh:<userId>:<jti>`).
- Jetons de reset et de vérification email stockés en clair (`auth.service.ts:246-253`) → hacher.
- `ValidationPipe` est strict mais ces bodies n'ont pas de DTO : `matching.controller.ts:100`, `auth.controller.ts:128,172`, `subscriptions.controller.ts:162`, `gdpr.controller.ts:180`, `users.controller.ts:123`.
- `Error` nu → 500 avec fuite de message : `admin.controller.ts:44`, `auth.controller.ts:136,178,213`.
- Ajouter `main-api/.dockerignore` — `dockerfile` fait `COPY . .` et `main-api/.env` (4 Ko de vrais identifiants) est dans ce répertoire.
- Clés en dur à sortir du code : `matching-integration.service.ts:90-92`, `matching-service/main.py:69`, `google.strategy.ts:10,12` (`dummy-client-id`).

---

## Phase 1 — Bugs fonctionnels backend

### 1.1 Sélection quotidienne réduite à 1 profil
`matching.service.ts:159-160` : `selectionSize = Math.min(5, maxChoicesAllowed)` avec `getMaxChoicesPerDay` = 1 (gratuit) / 3 (Plus). Un utilisateur gratuit reçoit **un seul profil**. Le chemin de repli (`:204-206`) en renvoie 5 → comportement incohérent selon que le service Python répond.
→ `selectionSize = 5` constant (décision produit), `maxChoicesAllowed` reste 1/3 et ne pilote que le quota de choix. Supprimer `getSelectionSize()` (`:611-615`, mort). Vérifier que le frontend affiche bien les 5 cartes en grisant les choix au-delà du quota (`daily_matches_page.dart:391-417` gère déjà l'UI de quota).

### 1.2 Notifications programmées ne partent jamais
`scheduled-notifications.service.ts:52` compare `user.status = 'ACTIVE'` alors que l'enum vaut `'active'` → **zéro utilisateur** correspond. Même bug `:120` (`chat.status = 'ACTIVE'`) → les notifications de chat expirant ne partent jamais.
→ Utiliser les enums `UserStatus.ACTIVE` / `ChatStatus.ACTIVE` plutôt que des littéraux. Grep global sur `= 'ACTIVE'` pour débusquer les autres occurrences.

### 1.3 Double notification de midi
`matching.scheduler.ts:96-98` envoie déjà `sendDailySelectionNotification` par utilisateur ; `scheduled-notifications.service.ts:29` la renvoie à 12h Europe/Paris. Une fois 1.2 corrigé, les utilisateurs parisiens reçoivent deux push.
→ Garder le chemin par fuseau horaire du scheduler de matching, supprimer le cron de midi.

### 1.4 Endpoints manquants côté backend (appelés par le mobile)
À créer dans `main-api` :
- `POST /feedback` — module absent, documenté dans `API_ROUTES_DOCUMENTATION.md:1495`, appelé par `api_service.dart:976`. Entité + contrôleur + route admin de lecture.
- `GET /legal/terms-of-service` — documenté, absent (`legal` n'expose que `privacy-policy`).
- `GET /users/me/deletion-status`, `POST /users/me/cancel-deletion` — appelés par l'app (`api_service.dart:1102,1109`), n'existent que sous une autre forme (`GET /gdpr/delete-account/:requestId`).
- `GET /chat/:chatId` (détail de conversation) — appelé `api_service.dart:579`.
- `DELETE /profiles/me/media/:id`, `PUT /profiles/me/media/order` — appelés `api_service.dart:493,499`.
- `GET /users/me/email-history` — **à trancher** : soit implémenter, soit supprimer l'écran mobile (voir 2.4).

### 1.5 Doublons de surface d'API à unifier
Ces duplications vont dériver et produisent des bugs silencieux :
- `ConversationsController` n'a pas de service propre, il injecte `ChatService` (`conversations.controller.ts:31`) → supprimer le module, ne garder que `/chat`.
- Deux classes nommées `GdprService` injectées côte à côte dans `users.controller.ts:62-63`, plus trois préfixes RGPD (`/gdpr/*`, `/user/*`, `/users/me/export-data*`) → converger sur `/users/me/*` (ce que l'app appelle) et garder `/gdpr/*` en alias déprécié.
- Push tokens exposés sous `/users/me/push-tokens` **et** `/notifications/push-tokens`.
- Deux routes de questions de personnalité (`personality.controller.ts:24`, `profiles.controller.ts:99`).
- Deux webhooks RevenueCat (traité en 0.4).

### 1.6 Corrections diverses
- `chat.service.ts:301-315` : `markMessagesAsRead` marque aussi les messages de l'appelant → filtrer `senderId != userId`.
- `matching.scheduler.ts:140` : `successRate` divise par `users.length` au lieu de `usersAtNoon.length`.
- `revenuecat.service.ts:46-49` : `timingSafeEqual` lève sur des buffers de longueurs différentes → comparer les longueurs d'abord.
- `stats.controller.ts:187-195,260-270` + `stats.service.ts:494-497` : les exports CSV/PDF posent les en-têtes `text/csv` / `application/pdf` puis renvoient du JSON. Implémenter la vraie sérialisation ou retirer les routes.
- `users/gdpr.service.ts:63-71` : export PDF non implémenté.
- `gdpr/data-export.service.ts:105-116` : le fichier d'export est une data-URI base64 stockée en colonne de base — à basculer sur `StorageService` avec une URL signée à expiration.
- `subscriptions.service.ts:529-545` : `restoreSubscriptions` relit la base sans interroger le store → appeler RevenueCat.
- `reports.service.ts:320-321` : aucune notification admin à la création d'un signalement.
- `monitoring.service.ts:313-320` : `/admin/monitoring/*` renvoie des chiffres inventés (`averageResponseTime: 150`…) et `setupLogCapture()` (`:57-60`) est vide → brancher sur Prometheus (déjà en dépendance) ou retirer les routes.
- Module `analytics` : `AnalyticsService` et `AnalyticsMiddleware` ne sont référencés nulle part hors de leur dossier, le middleware n'est jamais appliqué dans `app.module.configure()` → brancher Mixpanel ou supprimer le module.
- `matching-service/main.py:613-642` : `GET /api/v1/matching/recommendations/{user_id}` renvoie une réponse factice vide.

### 1.7 Infrastructure
- **`BullModule` est configuré (`app.module.ts:130-141`) sans aucune queue ni processeur.** Soit brancher les envois de push/mail dessus, soit retirer la dépendance.
- **Aucune migration initiale pour les 23 entités** : seulement 4 migrations incrémentales, `synchronize: true` en dev, et les options TypeORM de Nest ne déclarent pas de chemin `migrations` alors que `migrationsRun: true` est posé hors dev → **un déploiement sur une base vierge ne crée aucune table**. Générer une migration initiale et déclarer `migrations` dans `app.module.ts:120`.
- **Aucun `validationSchema` sur `ConfigModule.forRoot`** (`app.module.ts:71-89`) : seul `JWT_SECRET` est requis, tout le reste tombe silencieusement sur des valeurs par défaut. Ajouter un schéma Joi.
- `MATCHING_SERVICE_API_KEY` est présent dans `.env.example`, `.env` et `docker-compose.yml`, mais `matchingServiceConfig` n'expose que `url` (`configuration.ts:128-133`, `config.interface.ts:80-82`) → la clé est toujours `undefined` et le client retombe sur la valeur en dur. **Si une vraie clé est posée côté Python, tous les appels de matching renvoient 401.**
- `fcm.service.ts:23` utilise l'API HTTP FCM *legacy* (`fcm.googleapis.com/fcm/send`), supprimée par Google → tout passer par `FirebaseService` (admin SDK, déjà implémenté) et supprimer `FcmService`.
- Variables jamais lues : `UPLOAD_DIR`, `STORAGE_PROVIDER`. Variables absentes des `.env.example` : `FIREBASE_*`, `MIXPANEL_*`, `SENDGRID_API_KEY`, `APP_URL` (nouvellement lue par le code non commité).
- `docker-compose.yml` racine ne définit pas de service `main-api` alors que `Dockerfile.api` existe ; il utilise des noms `DB_*` que l'app ne lit pas et `POSTGRES_PASSWORD: admin`.
- Supprimer de `src/` : `demo-ux-improvements.ts` (~45 `console.log`, compilé dans `dist/`), et à la racine `demo-gdpr-endpoints.js`, `demo-reports-api.js`, `demo-subscription-endpoints.js`, `unidirectional-match-demo.js`.
- `alerting.service.ts:192-195` : le canal e-mail d'alerte n'est qu'une ligne de log ; `matching.scheduler.ts:153,170` : alertes critiques en `TODO`, code commenté.

---

## Phase 2 — Mobile : fonctionnalités cassées

### 2.1 `MatchingServiceApi` sans `baseUrl` → 4 fonctionnalités mortes
`api_service.dart:1266-1275` : le `Dio` est construit sans `baseUrl` alors que `baseUrl` n'est qu'un getter (`:1261`). Tout appel à chemin relatif échoue faute de schéma/hôte. Cassés : `submitReport` (`:1465`), `getMyReports` (`:1490`), `getHistory` (`:1441`), `getMatchDetails` (`:1432`), `calculateCompatibilityV2` (`:1403`).
→ **Ces routes (`/reports`, `/matching/history`) sont sur l'API principale et attendent le JWT, pas `X-API-Key`** : les déplacer dans `ApiService`. Ne laisser dans `MatchingServiceApi` que les vrais appels au service Python, et lui donner son `baseUrl`. Voir aussi 2.8 — la clé du service de matching ne doit pas être compilée dans le binaire.

### 2.2 `ProfileDetailPage` affiche un faux profil
`lib/features/matching/pages/profile_detail_page.dart:22-35` : l'écran routé `/profile/:profileId` construit en dur `MatchProfile(name: 'Sophie', age: 29, …)` et ignore `profileId`. Les photos sont des dégradés (`:79`, `:257`).
→ Récupérer le profil via `MatchingProvider` / `GET /matching/matches/:id`, avec états chargement / erreur / photos réelles. C'est aussi ce qui débloque l'affichage du score de compatibilité (item F-P2-3 de l'`AUDIT_PLAN.md`).

### 2.3 Temps réel du chat inopérant
`lib/core/services/websocket_service.dart:58-60` ouvre un WebSocket brut (`IOWebSocketChannel`) vers `ws://host/chat?token=…`, alors que le backend est un serveur **Socket.IO avec namespace `/chat`** (`chat.gateway.ts:35-41`). Protocoles incompatibles → aucun message live, aucun indicateur de frappe, aucun accusé de lecture, aucun événement d'expiration.
→ Passer au paquet `socket_io_client`, namespace `/chat`, auth par handshake. Conserver le backoff exponentiel déjà correct (`:88-107`).

### 2.4 Chemins d'API divergents (404 systématiques)
| Appel Flutter | Réalité backend |
|---|---|
| `POST /users/me/data-export` (`:1057`) | `POST /users/me/export-data` |
| `GET /users/me/export-data` (`:1011`) | existe seulement en POST |
| `GET/PUT /users/me/privacy-settings` (`:1033,1050`) | inexistant (RGPD sous `/gdpr/*`) |
| `PUT /chat/:chatId/expire` (`:652`) | `PUT /chat/:chatId/extend` |
| `POST /subscriptions/verify-receipt` (`:690`) | inexistant |
| `POST /matching-service/*` (`:1360-1424`) | non exposé par l'API principale |
| `GET /users/me/email-history` (`:1222`) | inexistant |

→ Aligner chemin par chemin. Les routes vraiment manquantes côté backend sont traitées en 1.4. Pour `email-history` : soit l'implémenter, soit retirer l'écran `/email-history` et sa ligne dans Réglages.

### 2.5 Providers admin non enregistrés → crash
`main.dart:26-27` importe `AdminProvider` et `AdminAuthProvider`, `main.dart:60-88` ne les enregistre pas. Chaque écran admin fait `context.read<AdminProvider>()` (`admin_dashboard_page.dart:22`, `admin_users_page.dart:24`, `admin_reports_page.dart:25`, `admin_auth_guard.dart:8`) → `ProviderNotFoundException`.
→ **Décision : retirer entièrement l'admin du mobile.** Supprimer `lib/features/admin/`, les 5 routes `/admin/*` d'`app_router.dart`, les imports de `main.dart` et les méthodes admin d'`api_service.dart`. `admin_support_page.dart:494-548` tournait de toute façon sur `_generateMockTickets()`. Le back-office reviendra en Next.js séparé (voir Phase 6).

### 2.6 `Navigator.pushNamed` sous go_router → exceptions
`match_acceptance_dialog.dart:195` (post-match → chat, chemin critique), `notifications_page.dart:110,385,388,393,399` (dont `/discover`, route inexistante), `navigation_service.dart:15,23,31,39`.
→ Tout convertir en `context.push(...)` / `context.go(...)` avec des chemins déclarés dans `app_router.dart`.

### 2.7 Absence de rafraîchissement de jeton
`api_service.dart:36-40` : sur 401 l'intercepteur appelle `clearToken()`, sans rejouer la requête, sans appeler `POST /auth/refresh` (qui existe côté backend), et sans réinitialiser `AuthProvider` ni rediriger. Aucun refresh token n'est persisté (`auth_provider.dart` ne stocke que l'access token).
→ Stocker le refresh token, ajouter un intercepteur de rafraîchissement avec file d'attente des requêtes concurrentes, et déconnexion propre + redirection si le refresh échoue.

### 2.8 Configuration réseau en dur
`app_config.dart:32-63` : URL de dev Android figée sur `http://192.168.1.183:3000` ; `ios/Runner/Info.plist` contient une exception ATS pour `192.168.1.5` ; `main.ts:113-115` du backend affiche encore une troisième IP. `app_config.dart` compile aussi `matchingServiceApiKey` par défaut à `'matching-service-secret-key'` **dans le binaire**. `email_auth_page.dart:389` affiche à l'utilisateur final « …backend est démarré sur localhost:3000 ».
→ Tout passer en `--dart-define` avec des valeurs de production par défaut, retirer la clé du service de matching du client (l'app ne doit parler qu'à l'API principale), nettoyer les exceptions ATS, corriger le message d'erreur utilisateur.

---

## Phase 3 — Mobile : écrans inachevés

### 3.1 Réglages — les quatre culs-de-sac
Dans `lib/features/settings/pages/settings_page.dart` :

| Ligne | État actuel | À faire |
|---|---|---|
| `:661` Préférences | Dialogue « en cours de développement » | Écran de préférences de matching → `GET/PUT /preferences/me` (le backend est prêt et n'est jamais appelé) |
| `:821` Localisation | Dialogue « en cours de développement » | Écran de localisation ; `LocationService` + `geolocator` existent déjà |
| `:839` Sécurité | Dialogue « en cours de développement » | Changement de mot de passe : `AuthProvider.changePassword` (`:203`) et `ApiService.changePassword` **sont déjà écrits et jamais appelés** — il ne manque que l'UI |
| `:876` Contacter le support | SnackBar sans suite | Brancher sur `POST /feedback` (1.4) ou un `mailto:` |

Également dans cet écran :
- `:221-222` — statistiques **en dur** : `Matches '3'`, `Messages '2'`. À câbler sur `GET /users/me/stats`.
- `:172-187` — l'avatar n'affiche jamais la vraie photo (cercle doré + icône générique) même quand des photos existent.
- `:53-59` — la flèche retour appelle `Navigator.pop()` alors que l'écran vit dans l'`IndexedStack` de `MainNavigationPage` → **bouton inerte**. À supprimer.
- Toute la sous-navigation utilise `context.go(...)` au lieu de `push` → sort du shell d'onglets et casse le retour.
- `:634-636` « Mes photos » mène à `/profile-setup` (écran d'onboarding) alors que `photo_management_page.dart` (181 lignes, fonctionnel) existe et n'est atteignable par aucune route.
- `:784-798` — les heures de silence sont en lecture seule ici alors que la page Notifications a un sélecteur fonctionnel : UI dupliquée et incohérente.

### 3.2 `user_profile_page.dart` — second écran de réglages redondant
L'onglet « Profil » duplique un écran de réglages plus faible : même stub « Préférences » (`:653`), callbacks vides (`:414-417` notifications, `:685-688` contact), et surtout **`:633` déconnexion vers `/login`, route inexistante** → écran d'erreur go_router. Téléphone et e-mail de support divergent de ceux de `settings_page` (`support@goldwen.com` vs `support@goldwen.app`).
→ Fusionner avec `SettingsPage` ou réduire cet onglet à l'aperçu de profil, corriger la déconnexion.

### 3.3 Écrans terminés mais inaccessibles
Du travail déjà payé, hors du flux :
- `settings/pages/accessibility_settings_page.dart` (535 lignes, fonctionnel, **aucun point d'entrée**) → ajouter dans Réglages.
- `moderation/pages/moderation_history_page.dart` (452 lignes, câblé à `ModerationService`) → ajouter dans Réglages ou Profil.
- `profile/pages/photo_management_page.dart` (181 lignes) → cible de « Mes photos » (cf. 3.1).
- Routes déclarées sans aucun point d'entrée UI : `/who-liked-me`, `/history`, `/advanced-recommendations`, `/consent` (`app_router.dart:193-210,245-249`). `/who-liked-me` est une fonctionnalité **GoldWen Plus** invendable si elle est introuvable.

### 3.4 Consentement RGPD jamais demandé
`lib/core/widgets/gdpr_consent_guard.dart` existe et n'est utilisé nulle part → le consentement exigé par l'annexe A de la spec n'est jamais recueilli à l'inscription. À brancher dans le flux d'onboarding (en cohérence avec `ConsentGuard` côté backend, 0.10).

### 3.5 Contenus factices en production
- `home_page.dart:783-826` — « Conseil du jour » : une seule chaîne en dur.
- `home_page.dart:224-300` — la série « Votre rituel » est fabriquée côté client (`i < todayIdx && hasEngagedToday`), sans données serveur.
- `personality_questionnaire_page.dart:27` — questions de repli en dur.
- `matching_provider.dart:110-180` — `_createMockDailySelection` avec des photos Unsplash (à garder **strictement** sous `kDebugMode`, comme le fait déjà correctement `subscription_provider.dart:128`).
- `lib/demo/` (3 fichiers, `MockMatchingProvider`, `via.placeholder.com`) — à sortir du code de production.
- `report_page.dart:236` — `SnackBarAction(onPressed: () {})`.
- ~40 `print()` en production, dont `api_service.dart:186-187` (réponses au questionnaire de personnalité) et `user.dart:109-110` (JSON brut) → **fuite de données personnelles dans les logs de l'appareil**. Remplacer par un logger désactivé en release.

### 3.6 Reste de l'`AUDIT_PLAN.md` (18 mai 2026)
Déjà faits depuis : F-P1-1/2/3/4/5/6, F-P2-6. Encore ouverts : F-P1-7 (glisser-déposer des photos non testé), F-P1-8 (notifications locales sensibles au fuseau), F-P2-1 (suppression de message), F-P2-2 (indicateur de complétude du profil), F-P2-3 (détail du score — débloqué par 2.2), F-P2-4 (préférences de notification granulaires — cf. 3.1), F-P2-5 (shimmer de chargement).

### 3.7 Internationalisation
`flutter_localizations` et `lib/l10n/app_*.arb` sont en place mais utilisés dans **7 fichiers / 15 appels** : ~99 % de l'UI est en français codé en dur, alors que le site vitrine est traduit en 6 langues. À trancher : soit assumer le français seul pour le MVP (et retirer la plomberie `en`), soit planifier l'extraction des chaînes.

---

## Phase 4 — Tests et CI

### 4.1 Backend : CI rouge
`npx jest` → **20 suites en échec / 50 réussies, 141 tests en échec / 471 réussis**. La CI (`.github/workflows/ci.yml`) lance lint + `tsc --noEmit` + test : elle échoue aujourd'hui. Causes, toutes des mocks périmés après refactor :
- `StorageService` ajouté au constructeur de `ProfilesService`, absent des modules de test → 9 suites.
- `ConfigService` ajouté à `ChatGateway` → `chat/tests/chat.gateway-integration.spec.ts`.
- `SentryService` ajouté à `HttpExceptionFilter` → `common/filters/http-exception.filter.spec.ts`.
- `ConfigService` + `AlertingService` ajoutés à `BruteForceGuard` → `common/guards/brute-force.guard.spec.ts`.
- `UserConsentRepository` / double `GdprService` non fournis → `users/tests/*`.
- `preferences/tests/preferences.service.spec.ts:178` — **faute de frappe `jest.spyN(...)`**.
- `common/monitoring/monitoring.spec.ts:190` — **erreur de syntaxe**, seule erreur `tsc --noEmit` du dépôt.
- `matching/tests/matching.scheduler.spec.ts` — assertions calées sur l'ancien comportement « midi Paris » alors que le scheduler est désormais horaire par fuseau.

→ Réparer, puis ajouter des tests sur ce qui a été corrigé en Phase 0 (guard admin, signature webhook, suppression de `social-language`), et poser un seuil de couverture.

### 4.2 Mobile : pas de CI, tests cassés
Aucun `.github/` dans le repo Flutter. `test/settings_page_export_data_test.dart:25` appelle `NotificationProvider(prefs)` alors que la classe n'a pas de paramètre → **le fichier ne compile pas**. `test/widget_test.dart:7-12` attend « Bienvenue sur » alors que l'app démarre sur `/splash`. `test/navigation_test.dart:15-40` teste une barre de navigation qui n'existe plus (*Accueil/Découvrir/Messages/GoldWen+* vs *Du jour/Messages/Profil/Réglages*).
→ Réparer ou supprimer, ajouter un workflow `flutter analyze` + `flutter test`, et couvrir les zones réparées en Phase 2 (client API, navigation, détail de profil).

---

## Phase 5 — Préparation à la publication (mobile)

Aucun de ces points ne permet actuellement une soumission.

**Android**
- `android/app/build.gradle.kts:33-37` — build release **signé avec la clé debug**. Créer un keystore de release + `key.properties` (non versionné).
- **`google-services.json` absent** (seulement `.template`) et le plugin `com.google.gms.google-services` n'est pas appliqué → **FCM ne peut pas fonctionner**.
- `AndroidManifest.xml:16` — `android:label="goldwen_app"` (nom de paquet brut sous l'icône).
- `AndroidManifest.xml:19` — `usesCleartextTraffic="true"` sur **tous** les variants → à restreindre au debug.
- Aucun `intent-filter` App Links, aucun canal de notification déclaré, pas de `queries` pour Google Sign-In.
- Icônes de lanceur = icônes Flutter par défaut (442 à 1443 octets), splash = `LaunchTheme` par défaut.

**iOS**
- **`GoogleService-Info.plist` absent** → `Firebase.initializeApp()` échoue et `app_initialization_service.dart:19-27` retombe sur les notifications locales seules.
- Pas de `CFBundleURLTypes` → la redirection Google Sign-In échoue. Pas de `Runner.entitlements` ni `com.apple.developer.applesignin` → **Sign in with Apple non provisionné, ce qui est un motif de rejet** dès lors qu'une connexion sociale tierce est proposée.
- Identifiants de bundle incohérents : iOS `com.goldwenApp` (`project.pbxproj:504,695`), Android `com.goldwen.app`, `FirebaseConfig.iosBundleId = com.goldwen.app`.
- `Info.plist` : exceptions ATS de développement (`192.168.1.5`, `localhost`) à retirer ; `NSMicrophoneUsageDescription` manquant alors que `image_picker` vidéo et `audioplayers` sont utilisés ; orientations paysage autorisées alors que `main.dart:35-37` force le portrait.
- AppIcon et `LaunchImage*.png` = ressources Flutter par défaut (68 octets).
- `RunnerTests` encore en `com.example.*`.

**Clés tierces** — `firebase_config.dart:5-15` contient des clés API fabriquées et le fichier est importé par `main.dart:11` sans être utilisé ; le token Mixpanel vaut `YOUR_MIXPANEL_TOKEN_HERE` (`app_initialization_service.dart:54`) → analytics silencieusement désactivée ; la clé RevenueCat est vide par défaut (`revenue_cat_service.dart:9-20`) → **« Restaurer les achats » lève une exception** sauf build avec `--dart-define=REVENUECAT_API_KEY`.

**Métadonnées stores** — rien dans le dépôt : pas de fastlane, pas de fiche store, pas de `PrivacyInfo.xcprivacy` (**obligatoire à la soumission iOS**), pas de config `flutter_launcher_icons` / `flutter_native_splash`. Version `1.0.0+1`.

---

## Phase 6 — Site vitrine (`GoldWen-app-web`)

**Suivi d’exécution au 17 septembre 2026 : correctifs techniques réalisés, finalisation juridique et configuration de production encore ouvertes.**

- [x] 6.1 : avis et statistiques de lancement fictifs retirés ; personas explicitement fictifs, sans badge vérifié. Pages CGU de la vitrine, confidentialité et exercice des droits rédigées avec un périmètre explicite (pas un contrat mobile). Éditeur personne physique : Adrien Marques, sans société constituée. Contacts confirmés : marquesadrien.site@gmail.com (éditeur), goldwen.supp.app@gmail.com (support/données). Hébergeur confirmé par l’utilisateur : Vercel Inc., coordonnées et DPA vérifiés sur vercel.com.
- [x] 6.1 : consentement de mesure facultative, boutons accepter/refuser de même style, conservation six mois, retrait avec rechargement. SDK chargés dynamiquement après accord seulement, activation globale désactivée par défaut.
- [ ] 6.1 : compléter adresse de publication et téléphone, confirmer prestataires SMTP/Redis, rétention réelle des e-mails/logs, régions et garanties de transfert. Les champs non fournis sont signalés, aucune société/SIRET ni DPO inventé. La conformité juridique n’est donc pas déclarée complète. Textes de référence en français, titres et avertissement de périmètre dans les six langues ; traduction complète des textes à prévoir avant ouverture internationale. Les documents contractuels mobiles restent distincts.
- [x] 6.2 : canonical et hreflang sans `/fr`, URL nettoyées des query/hash, domaine configurable, métadonnées des six langues, suppression des listes de mots-clés. Sitemap/robots générés avant build depuis le domaine configuré (variables shell et fichiers .env), sans lastmod inventé.
- [x] 6.3 : logos et traductions 404/500, suppression CSS absent, ancien hook de redirection supprimé au profit de Next, hook A/B inutilisé retiré, configuration Vercel native. Formulaire : validation de types/tailles, anti-injection HTML/en-têtes, destinataire fixe, contrôle d’origine, honeypot, limite partagée Redis de 3 requêtes/IP hachée/10 min, expiration 11 min, TLS SMTP, erreurs sans données personnelles. En production le formulaire refuse les envois si le limiteur manque/échoue.
- [ ] 6.3 : renseigner et vérifier SMTP et Redis sur Vercel ; aucune livraison réelle d’e-mail ni recette avec Redis de production effectuée. Les tests utilisent un transport SMTP simulé et le limiteur local de test.
- [x] 6.4 : anciens Handlebars/CSS supprimés, scan Tailwind nettoyé, README Next.js réécrit, workflow CI ajouté. Rituel produit cohérent (5 profils, 1/3 choix, match mutuel, 24 h), disponibilité annoncée comme en préparation. Téléphone squelette remplacé par une présentation de marque/rituel ; aucune fausse capture créée. Titres stabilisés et reduced-motion ajouté.
- [ ] 6.4 : vraies captures mobiles absentes du dépôt, à intégrer après recette de l’application.
- [x] 6.5 : back-office planifié dans `GoldWen-app-web/docs/BACK_OFFICE_PLAN.md`, application séparée, hors exécution immédiate conformément à la décision produit.

**Vérification locale réelle :** `npm run lint`, `npm run typecheck`, `npm test` (**7/7**) et `npm run build` réussis, 54 pages générées. Tests de validation JSON, longueurs, injection d’en-têtes, échappement HTML, quotas, refus production sans Redis, canonical et handler SMTP simulé. Navigateur local : bandeau visible, refus retire le bandeau, aucun script analytics/insights après refus, aucune feuille `/css/styles.css`, canonical FR `https://goldwen.app`, `/es/contact` avec titre `Contacto | GoldWen` et canonical `https://goldwen.app/es/contact`. Recette du build final : mentions légales affichent Adrien Marques et les champs non fournis explicitement ; page inconnue `/en/nonexistent` affiche une 404 anglaise avec logo. CI ajoutée mais pas exécutée sur GitHub. Aucun déploiement ni modification du plan vivant externe Claude revendiqué.


### 6.1 Conformité juridique (bloque le lancement français)
- **Mentions légales vides** (`pages/mentions-legales.tsx:76`, `fr/legal.json:34` « Informations à venir ») : ni raison sociale, ni SIRET, ni capital, ni directeur de publication, ni hébergeur. **Obligatoire (LCEN art. 6-III).**
- **CGU** (`pages/conditions.tsx:67`) et **politique de confidentialité** (`pages/confidentialite.tsx:171`) réduites à des cartes « disponible prochainement ».
- **Aucun bandeau cookies / consentement** (zéro occurrence de `cookie|consent` dans `pages/`, `components/`, `lib/`) alors que `_app.tsx:15-16` charge Vercel Analytics et Speed Insights **inconditionnellement**.
- Aucune page de contact DPO ni de procédure d'exercice des droits.
- **Risque de pratique commerciale trompeuse** : trois témoignages nommés inventés (`fr/common.json:111-131` — Sophie/Thomas/Camille), « 10K+ utilisateurs », « 4.9★ Note App Store », « 95 % Satisfaction » (`pages/index.tsx:513,518,523`) — **pour une application non encore publiée**. À retirer ou requalifier explicitement jusqu'au lancement.

### 6.2 Bugs SEO
- **Canonical faux en français** : `components/Layout.tsx:112-115` génère `https://goldwen.app/fr/...` alors que Next ne préfixe pas la locale par défaut → chaque page FR se canonicalise vers une URL non servie. Même défaut dans les alternates de `public/sitemap.xml`.
- **Métadonnées SEO uniquement en FR et EN** : `lib/app-service.ts:145` fait `seedData[locale] || seoData.fr` et l'objet (`:52-137`) ne contient que `fr` et `en` → `/es`, `/de`, `/it`, `/pt` servent des `<title>` et descriptions **en français** sur du contenu traduit. Bourrage de mots-clés également (~60 par page).
- `public/sitemap.xml` : `lastmod` figé au `2025-01-01`.
- `NEXT_PUBLIC_SITE_URL` existe dans `.env.example:9` et **n'est lu nulle part** : `https://goldwen.app` est écrit en dur à 8 endroits de `components/Layout.tsx`.

### 6.3 Bugs fonctionnels
- **Logo cassé sur les pages d'erreur** : `pages/404.tsx:20` et `pages/500.tsx:15` pointent vers `/images/logo.png`, inexistant (`public/images/` contient `logo_base/dark/light/sans_fond.png`). La page 500 n'est en outre pas traduite.
- **Requête 404 à chaque chargement** : `pages/_app.tsx:19` injecte `<link href="/css/styles.css">`, fichier gitignoré et absent ; `vercel.json:8` ne lance jamais `build:css`. Le style fonctionne via `globals.css`, c'est donc un fetch mort à supprimer.
- `pattern-overlay-dark` (utilisé dans `conditions.tsx:54`, `confidentialite.tsx:54`, `mentions-legales.tsx:54`) n'est défini nulle part dans `globals.css` → sans effet.
- **`/api/contact` : injection HTML + relais de spam ouvert** — `pages/api/contact.ts:64-69` interpole `name`, `email`, `subject`, `message` bruts dans le corps HTML ; aucun rate limit, aucun captcha, aucun honeypot, et `replyTo` (`:57`) est contrôlé par l'attaquant.
- `lib/useBrowserLanguageDetection.ts:9-45` a `router` dans son tableau de dépendances et appelle `router.push` → risque de boucle de redirection avec la `localeDetection` native de Next.
- `lib/useABVariant.ts` n'est jamais importé, et ne fonctionnerait pas : l'accès dynamique `process.env[key]` (`:13`) n'est pas inliné par Next côté client → retourne toujours `'a'`.
- `vercel.json` utilise le tableau `builds` v2 hérité, ce qui désactive les optimisations zéro-config de Next (ISR, images).

### 6.4 Nettoyage
- `views/*.hbs` (6 fichiers, ~3 140 lignes) et `src/styles-old.css` (384 lignes) sont des restes de l'ancienne version NestJS ; `tailwind.config.js:6` scanne encore `./views/**/*.{hbs,html}`.
- `README.md` décrit un projet **NestJS/Handlebars** avec des fichiers et des scripts npm qui n'existent plus.
- Aucun test, aucune CI ; `package.json` n'a pas de script `test` alors que le README en annonce un.
- La maquette de téléphone de la page d'accueil (`pages/index.tsx:138-189`) est un squelette gris, pas de vraies captures d'écran.

### 6.5 Back-office admin (suite de la décision 2.5)
Le back-office est au périmètre MVP (`specifications.md:100-106`) et n'existe **nulle part** une fois l'admin retiré du mobile. À planifier comme application Next.js séparée (gestion des utilisateurs, file de modération, support), consommant les routes `/admin/*` sécurisées en Phase 0. Non inclus dans l'exécution immédiate — mais les Phases 0.2 et 0.3 sont précisément ce qui le rendra possible.

---

## Ordre d'exécution recommandé

0. **Copier ce plan dans les trois dépôts** (première action, avant tout changement de code) :
   - `/Users/amarques/Documents/Dev/GoldWen-App-Backend/PLAN_FINALISATION.md`
   - `/Users/amarques/Documents/Dev/GoldWen-App-Frontend/PLAN_FINALISATION.md`
   - `/Users/amarques/Documents/Dev/GoldWen-app-web/PLAN_FINALISATION.md`

   Chaque copie contient le plan complet (les phases sont interdépendantes : la Phase 2 du mobile dépend des routes créées en Phase 1 du backend). Cocher les éléments au fur et à mesure dans la copie du dépôt concerné.

1. **Phase 0** — sécurité backend. À faire en premier et à déployer seul : rien d'autre ne doit partir en production avant.
2. **Phase 4.1** — réparer la CI backend, pour que les phases suivantes soient validées par les tests.
3. **Phase 1** — bugs fonctionnels + endpoints manquants backend (préalable à la Phase 2).
4. **Phase 2** — fonctionnalités mobiles cassées (dépend des routes créées en 1.4).
5. **Phase 3** — écrans inachevés, Réglages en tête.
6. **Phase 4.2** — tests mobiles + CI.
7. **Phase 5** — préparation à la publication.
8. **Phase 6** — site vitrine ; 6.1 (juridique) peut être menée en parallèle dès le début, c'est un chemin critique indépendant.

---

## Vérification

**Backend**
```bash
cd /Users/amarques/Documents/Dev/GoldWen-App-Backend/main-api
npm run lint && npx tsc --noEmit && npm test        # doit être vert (141 échecs aujourd'hui)
npm run test:e2e
```
Contrôles manuels de la Phase 0, à faire avec un compte utilisateur ordinaire :
- `POST /auth/social-login` → 404 (route supprimée).
- `GET /admin/dashboard` avec un JWT non-admin → 403.
- `POST /subscriptions/webhook/revenuecat` → 404 ; `POST /webhooks/revenuecat` sans en-tête de signature → 401.
- `POST /subscriptions/purchase` avec un faux `productId` → refus.
- `POST /moderation/webhook/photo` sans secret → 401.
- Envoyer une photo manifestement inappropriée → statut « rejetée », photo absente du profil et de la sélection quotidienne.
- Générer une sélection quotidienne sur un compte gratuit → **5 profils**, quota de choix à 1 ; sur un compte Plus → 5 profils, quota 3.
- Déployer sur une base vierge → les 23 tables sont créées par les migrations.

**Mobile**
```bash
cd /Users/amarques/Documents/Dev/GoldWen-App-Frontend
flutter analyze && flutter test
flutter run --dart-define=API_BASE_URL=... --dart-define=REVENUECAT_API_KEY=...
```
Parcours de bout en bout : inscription (avec consentement RGPD) → questionnaire → profil → sélection de midi → ouvrir un profil (**vraies données, pas « Sophie »**) → choisir → match → chat (**message reçu en temps réel sur un second appareil**) → expiration 24 h. Puis Réglages : chacune des lignes Préférences, Localisation, Sécurité, Support ouvre un écran fonctionnel ; les statistiques d'en-tête reflètent le compte ; le signalement d'un utilisateur aboutit ; l'export de données renvoie un fichier ; aucune route `/admin/*` n'est atteignable.

**Web**
```bash
cd /Users/amarques/Documents/Dev/GoldWen-app-web
npm run build && npm start
```
Vérifier : les trois pages légales ont un contenu réel ; le bandeau cookies s'affiche avant le chargement des analytics et le refus les bloque ; `view-source` d'une page `/es` montre un `<title>` espagnol ; le canonical FR est `https://goldwen.app/...` sans `/fr` ; `/404` affiche le logo ; aucune requête vers `/css/styles.css` dans l'onglet réseau ; `/api/contact` échappe le HTML et limite le débit.
