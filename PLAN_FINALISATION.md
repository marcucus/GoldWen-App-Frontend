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

**Points à arbitrer avant déploiement — décisions prises le 19 septembre 2026 (Adrien) :**
- [x] `ConsentGuard` (`APP_GUARD`) : **décision — blocage immédiat**, pas de fenêtre de grâce ni de migration de données. Tout compte existant sans ligne `UserConsent` reste bloqué sur les routes authentifiées tant qu'il n'a pas (re)donné son consentement. C'est déjà le comportement codé aujourd'hui : aucun changement de code nécessaire, seule la décision produit était en attente.
- [x] Outillage admin externe utilisant l'ancien flux `POST /admin/auth/login` : **vérifié, aucun script/outil trouvé** dans les trois dépôts (scripts, seeds, collections Postman/Insomnia) qui référence cette route ou l'ancien mot de passe en dur `admin_password_123`. Rien à migrer.
- [x] Secret JWT admin partagé avec celui des utilisateurs (claim `type: 'admin'`) : **décision — séparer les secrets** (défense en profondeur). Fait : nouvelle variable `JWT_ADMIN_SECRET` (obligatoire, `configuration.ts` échoue au démarrage si absente comme pour `JWT_SECRET`), utilisée dans les 5 endroits qui fournissent `AdminGuard` avec leur propre `JwtModule.registerAsync` (`admin.module.ts`, `common/monitoring/monitoring.module.ts`, `subscriptions.module.ts`, `notifications.module.ts`, `moderation.module.ts` — vérifié qu'aucun de ces modules n'utilise `JwtService` pour autre chose que `AdminGuard`, donc aucune régression sur les JWT utilisateurs). .env.example documenté, .env local complété avec un secret généré. `tsc --noEmit` propre sur les fichiers touchés ; 20 suites / 195 tests (admin, auth, monitoring, subscriptions, notifications, moderation, entities) verts.

Chacun de ces points est exploitable aujourd'hui en production tant que le dernier n'est pas traité.

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
- [ ] 6.1 : compléter adresse de publication et téléphone, confirmer prestataires SMTP/Redis, application effective de la rétention des e-mails/logs chez les prestataires, régions et garanties de transfert. Les champs non fournis sont signalés, aucune société/SIRET ni DPO inventé. La conformité juridique n’est donc pas déclarée complète. Textes de référence en français, titres et avertissement de périmètre dans les six langues ; traduction complète des textes à prévoir avant ouverture internationale. Les documents contractuels mobiles restent distincts.
- [x] 6.2 : canonical et hreflang sans `/fr`, URL nettoyées des query/hash, domaine configurable, métadonnées des six langues, suppression des listes de mots-clés. Sitemap/robots générés avant build depuis le domaine configuré (variables shell et fichiers .env), sans lastmod inventé.
- [x] 6.3 : logos et traductions 404/500, suppression CSS absent, ancien hook de redirection supprimé au profit de Next, hook A/B inutilisé retiré, configuration Vercel native. Formulaire : validation de types/tailles, anti-injection HTML/en-têtes, destinataire fixe, contrôle d’origine, honeypot, limite partagée Redis de 3 requêtes/IP hachée/10 min, expiration 11 min, TLS SMTP, erreurs sans données personnelles. En production le formulaire refuse les envois si le limiteur manque/échoue.
- [ ] 6.3 : renseigner et vérifier SMTP et Redis sur Vercel ; aucune livraison réelle d’e-mail ni recette avec Redis de production effectuée. Les tests utilisent un transport SMTP simulé et le limiteur local de test.
- [x] 6.4 : anciens Handlebars/CSS supprimés, scan Tailwind nettoyé, README Next.js réécrit, workflow CI ajouté. Rituel produit cohérent (5 profils, 1/3 choix, match mutuel, 24 h), disponibilité annoncée comme en préparation. Téléphone squelette remplacé par une présentation de marque/rituel ; aucune fausse capture créée. Titres stabilisés et reduced-motion ajouté.
- [ ] 6.4 : vraies captures mobiles **reportées par Adrien** jusqu’à ce que le mobile soit plus avancé ; aucune capture fictive à produire.
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

## Rétention site et application — complément du 17 septembre 2026

- [x] Durées validées appliquées au backend : inactivité 12 mois avec avertissement 30 jours, messages 24 h + effacement sous 24 h, choix 90 jours, notifications 30 jours, exports 7 jours, support/signalements 12 mois après clôture, logs 180 jours.
- [x] Suppression physique des photos/exports, reprise des effacements en échec, présence authentifiée, recontrôle d’activité sous verrou ; preuves de messages signalés préservées et réservées à la modération. Journal minimal d’effacement 30 jours ; exceptions comptables limitées aux transactions nécessaires.
- [x] Texte de rétention de la vitrine mis à jour ; les captures réelles sont différées à la demande d’Adrien. Politique mobile par défaut 1.1.0 et script de publication préparés.
- [x] Vérification locale : backend TypeScript/ESLint/build ; 71 suites, 640 tests. Vitrine lint/typecheck/build (54 pages), 7 tests.
- [ ] Activation en production : migration PostgreSQL testée en staging puis déployée, publication de la politique existante, transport d’avertissement testé, purge de la boîte support/logs des prestataires, rotation des sauvegardes 30 jours et protocole de restauration avec rejeu des effacements. Aucun déploiement ni modification du plan externe Claude effectué.

Détail et mise en service : `GoldWen-App-Backend/docs/DATA_RETENTION_POLICY.md` (chemin depuis le workspace parent).


## Environnement de recette locale — 18 septembre 2026

- [x] PostgreSQL et Redis Docker démarrés, conteneurs healthy.
- [x] API NestJS démarrée : `GET http://localhost:3000/api/v1/health` retourne 200, base et cache healthy.
- [x] Blocages runtime AdminGuard corrigés : dépendances JWT/repository dans MonitoringModule et exports nécessaires aux contrôleurs consommateurs d’AdminModule. ESLint ciblé réussi ; monitoring et AdminGuard : 2 suites, 17 tests réussis.
- [x] Matching démarré sur `127.0.0.1:8000`, connexion PostgreSQL/Redis confirmée ; `/health` healthy. Dépendances installées sous Python 3.13 dans `/private/tmp/goldwen-matching-py313`. Relance : `cd GoldWen-App-Backend/matching-service && /private/tmp/goldwen-matching-py313/bin/python run_local.py` depuis le workspace parent. Virtualenv temporaire à recréer si nettoyé.
- [x] Flutter debug compilé et lancé sur iPhone 17 Pro iOS 26.3, UUID `59D4C9E1-16A8-407D-BD6B-AED40D331A64`. Écran « Bienvenue sur GoldWen » vérifié via UI, API configurée à `http://localhost:3000/api/v1`. Relance dans le dépôt mobile : `flutter run -d 59D4C9E1-16A8-407D-BD6B-AED40D331A64`. Notifications refusées sur ce simulateur ; livraison push non validée. Podfile.lock complété automatiquement par CocoaPods.
- [ ] Recette fonctionnelle complète avec comptes fictifs : onboarding, sélection, match, chat et expiration. Aucun parcours complet ni achats/OAuth/push réels revendiqués. Aucun déploiement ni modification du plan externe.


## Recette visuelle exhaustive — 18–19 septembre 2026 (audit local étendu ; suites externes en L15)

Priorité utilisateur : parcourir visuellement l’application et inscrire tous les bugs, améliorations et manquements pour correction ultérieure. Aucun nouveau correctif pendant cette recette. Support : iPhone 17 Pro iOS 26.3, build debug, API/DB/cache/matching locaux ; compte fictif @goldwen.invalid. Les constats source et les constats observés doivent rester distincts.

### Constats observés

| ID | Priorité | Écran / reproduction | Constat et impact | Travail ultérieur | Statut |
|---|---|---|---|---|---|
| V01 | P1 | Accueil → textes légaux | Initialement texte sans liens : impossible de consulter les textes avant connexion. | Conserver les liens et routes publiques, couvrir navigation avant et pendant onboarding. | Correction appliquée avant consigne de différer ; liens et retour vérifiés sur simulateur. |
| V02 | P2 | Accueil, capture iPhone | Texte doré sur crème (slogan et liens) peu contrasté ; dernier paragraphe très proche du bouton principal. | Mesurer contraste et revoir espacement, tester grande taille de texte. | À corriger ; faible lisibilité observée, contraste chiffré non mesuré. |
| V03 | P1 | Accueil → Conditions / Confidentialité | Date « dernière mise à jour » générée chaque jour, et version confidentialité 1.0 malgré politique 1.1.0 prévue. | Afficher version/date du document publié et aligner mobile/backend/site. | À corriger, affichage observé et DateTime.now confirmé dans le code. |
| V04 | P1 | Politique confidentialité → Contact | « GoldWen SAS, 123 Rue de la Tech, 75001 Paris » et adresses @goldwen.com : identité/adresse fictives, incohérentes avec contexte et support @goldwen.app. | Remplacer uniquement par données fournies/confirmées, aligner coordonnées sur textes validés. | À corriger, observé. |
| V05 | P1 | Politique confidentialité → Sécurité | Promesses 2FA, audits réguliers, formation personnel et chiffrement sensibles au repos non établies par recette. | Vérifier les garanties réellement mises en place et supprimer/reformuler les promesses non prouvées. | Manquement à vérifier, texte observé ; aucune conformité complète déclarée. |
| V06 | P1 | Politique confidentialité sans connexion | « Consentement requis », « Renouvellement » et bouton renouveler affichés avant toute connexion ; route consent protégée par auth/onboarding. | Différencier consultation publique et gestion consentement authentifiée ; vérifier parcours. | À corriger, affichage observé, redirection à tester. |
| V07 | P1 | Politique confidentialité → Conservation | Rétention très générale, ne détaille pas messages 24 h + purge, choix 90 j, exports 7 j et suppression compte sous 30 j. | Réutiliser politique validée 1.1.0, éviter textes mobiles divergents. | À corriger, observé. |

### Constats source à reproduire visuellement

| ID | Priorité | Localisation | Constat | Statut |
|---|---|---|---|---|
| V08 | P1 | Réglages → Déconnexion | context.go('/') alors qu’aucune route '/' n’existe. | Correction '/welcome' appliquée avant consigne de différer ; reproduction après connexion à faire. |
| V09 | P1 | Auth e-mail | Column avec Spacer sans défilement : risque overflow clavier/inscription/petit écran. | À reproduire visuellement, aucune correction appliquée. |
| V10 | P1 | Réglages → Support | Téléphone +33 1 23 45 67 89 et « chat disponible » dans dialogue support. | À vérifier visuellement puis retirer coordonnées/fonctions fictives. |

Vérification technique complémentaire (ne remplace pas recette visuelle) : flutter analyze sans erreur ; suite Flutter 697 tests réussis. Périmètre parcouru : accueil, conditions et politique confidentialité ; tous les autres écrans restent à parcourir. Deux corrections préalables conservées et explicitement distinguées.


### Suite recette — authentification

- V11 **P1 observé** : page choix connexion, overflow Flutter **71 px** en bas sur iPhone 17 Pro, bouton Apple/encart sécurité chevauchés. Prévoir défilement et espacement adaptatif ; aucune correction pendant recette.
- V12 **P1 observé** (confirme V09) : inscription overflow **15 px** sans clavier, **316 px** clavier ouvert sur Prénom. Champs suivants et action inaccessibles ; connexion overflow **132 px** après saisie mot de passe. Prévoir scroll/gestion clavier et tests petits écrans/grand texte.
- V13 **P1 observé** : compte neuf créé via API locale, tentative connexion e-mail → message anglais « Account is not active », aucune explication/récupération. Source : register crée pending, login refuse non-active. Prévoir parcours cohérent pour compte en onboarding/vérification, message français et action utile ; ne pas retirer les contrôles de suspension/suppression. Pour continuer l’audit, seul le compte fictif @goldwen.invalid est préparé active en base locale, ce qui ne valide pas le parcours inscription réel.
- V14 **P2 observé** : boutons visibilité du mot de passe et retours exposés sans libellé à l’accessibilité. Prévoir tooltips/libellés masqué/visible et Retour.
- V15 **P1 manquement observé** : formulaire connexion sans lien « mot de passe oublié ». Prévoir récupération accessible et confirmation neutre ; backend à vérifier.
- V16 **P1 à vérifier** : inscription sans étape visible d’âge/acceptation explicite des conditions avant bouton créer compte. Ne pas considérer consentement RGPD à l’entrée home comme preuve d’acceptation contractuelle ou contrôle majorité.


### Suite recette — onboarding Genre / Préférences / Localisation

- V17 **P1 observé** : Genre et Préférences affichent seulement Homme/Femme entièrement ; Non-binaire partiellement sous bouton Continuer, Autre hors viewport sur iPhone 17 Pro. Défilements AX puis coordonnées ne changent pas l’écran. Prévoir liste défilante avec espace réservé au bouton et vérifier choix de toutes les options.
- V18 **P2 observé** : Genre/Préférences exposent les choix comme textes, sans rôle sélectionnable ni état sélectionné dans arbre accessibilité ; activation Continuer visible après choix. Prévoir Semantics de bouton/radio/checkbox et annonce de sélection.
- V19 **P1 observé** : Localisation, Continuer fixé en bas recouvre bouton Activer la localisation ; bloc « Pourquoi » présent en AX mais absent de capture initiale. Prévoir disposition défilante et actions non superposées, grand texte/petit écran.
- V20 **P1 observé / décision produit à confirmer** : localisation obligatoire, aucune ville manuelle ni parcours sans GPS proposé. Refus système empêche toute progression. Prévoir alternative manuelle si autorisée par produit ; distinguer permission OS et besoin de zone de matching.
- V21 **P2 observé** : après premier refus système, écran annonce « définitivement refusée » avec deux messages redondants et bouton Ouvrir paramètres. Vérifier mapping denied/deniedForever et formulation utile ; la classification iOS réelle reste à confirmer.
- V22 **P2 observé** : après fermeture demande système, statut système blanc sur fond clair momentanément peu lisible ; confirmer stabilité des couleurs status bar sur transitions/modalités.

État courant : compte fictif connecté, genre Femme et préférence Homme sauvegardés via UI. Autorisation localisation refusée sur simulateur pour tester cas négatif ; prochain écran bloqué, aucune position personnelle fournie. La suite nécessite autoriser une position fictive du simulateur ou préparer une autre fixture ; aucune correction appliquée depuis la consigne de différer. Inscription via UI explicitement reportée par l’utilisateur.


### Suite recette — critères / informations / profil / photos

- V23 **P2 observé** : position fictive affichée « Position détectée: Position détectée (37.7858, -122.4064) » ; libellé doublé et coordonnées techniques à la place d’une zone compréhensible. Prévoir ville/zone et minimiser précision affichée.
- V24 **P1 observé** : étape critères affiche tranche âge mais distance/conseil hors écran ; essai drag ne révèle pas les contrôles. À confirmer par gestuelle utilisateur puis revoir scroll/hauteur et espace bouton. Le bouton Continuer permet toutefois progression.
- V25 **P1 observé** : Informations complémentaires, saisir taille **999 cm** puis Continuer mène à Profil sans erreur. Prévoir validation client/serveur et message français ; persistance réelle de 999 non vérifiée.
- V26 **P2 observé** : Informations complémentaires, taille et nombreuses passions/langues initialement hors écran ; focus AX taille la rend visible, mais scroll tactile automatisé non confirmé. Prévoir vérification manuelle complète, états limite 8 passions/5 langues.
- V27 **P2 observé** : création profil affiche « Étape 1/6 » après plusieurs étapes onboarding sans progression globale ; clarifier découpage/progression et reprise.
- V28 **P1 observé** : Photos, images démonstration galerie ajoutées et compteur incrémenté, message succès, mais vignettes blanches. Prévoir prévisualisation locale fiable, états chargement/erreur et vérification stockage/données URL.
- V29 **P2 observé** : Photos, bouton Continuer actif avant minimum, entraîne dialogue bloquant. Minimum 3 effectivement contrôlé côté écran. Prévoir désactivation explicite ou retour inline évitant modal répétée.
- V30 **P2 observé** : Photos, première capture affiche 4 cases puis autres sous bord écran ; Continuer hors viewport dans capture mais accessible via AX. Prévoir scroll et action toujours accessible, comparer avec gestuelle réelle.

Points vérifiés positivement : préférences genre sauvegardées via UI, date naissance via sélecteur natif, compteur bio correct (175/600), Continuer activé seulement après informations de base, galerie native disponible et minimum 3 photos contrôlé. Localisation fictive autorisée avec accord utilisateur ; aucune localisation personnelle utilisée. Recette des étapes suivantes toujours en cours.


### Suite recette — médias et réponses aux prompts

- V31 **P1 périmètre observé** : étape 3/6 propose médias audio/vidéo et plateformes musique alors qu’audio/vidéo exclus MVP dans specifications.md. Arbitrer report/suppression du flux MVP plutôt que déclarer ces fonctions terminées ; upload et lecture non testés.
- V32 **P2 observé** : catégories prompts brutes anglaises (aspiration, dreams, experience, humor, lifestyle, motivation, values) dans UI française. Traduire libellés d’affichage sans changer identifiants API ; choix exposés comme textes sans état sélectionné accessible.
- V33 **P2 observé** : réponses prompts présentent double navigation Retour et titres, progression globale 4/6 masquée selon défilement ; clarifier hiérarchie.
- V34 **P1 observé** : sauvegarde après réponses affiche **DioException HTTP 400** brute anglaise, lien MDN et indications développeur dans grand SnackBar rouge couvrant la majorité de l’écran. Prévoir mapping erreurs validation vers champs avec message français court et récupération, aucune trace technique utilisateur.
- V35 **P1 lié à V25, cause à confirmer** : valeur test 999 cm acceptée plusieurs étapes avant potentielle validation tardive lors saveProfile ; retour possible par 3 étapes profil puis retour Informations complémentaires. Revoir validation au point de saisie et préservation/reprise des données. Minimum backend height à vérifier ; aucune cause affirmée sans réponse serveur détaillée.

Points positifs : trois prompts sélectionnés, réponses complétées 3/3, compteurs caractères cohérents, saisies conservées en naviguant Retour. Recette toujours en cours ; écran questionnaire, consentement et onglets non encore atteints. Aucun correctif nouveau appliqué.


### Second format — iPhone 16e iOS 26.1

- V11 confirmé sur second format : overflow options authentification **103 pixels** (Flutter RenderFlex auth_page.dart:44). Priorité P1 maintenue.
- V36 **incident à qualifier** : retour SpringBoard/perte connexion Flutter après saisie/collage ; aucune preuve de crash natif. Relancer avec session debugger et distinguer intervention utilisateur / outil / défaut app avant classification.
- Environnement : iPhone 17 Pro arrêté pendant recette, iPhone 16e actif. Nouveau build installé sous com.goldwen.app ; ancienne app distincte com.goldwenApp (« Goldwen App ») également présente, laissée intacte. Une reprise sur autre appareil ne vérifie pas persistance locale sur le premier.
- V25/V35 précision source : DTO serveur height **100–250 cm**. L’UI laisse entrer 999 cm et progresse ; validation 400 tardive à la sauvegarde observée, réponse détaillée de validation non encore relevée.


### Suite recette — validation profil, 18 septembre 2026

- V37 **P1 observé** : après sauvegarde de 3 réponses, validation affiche Prompts **0/3** avec coche verte. Vérifier contrat API et compteurs ; les trois réponses étaient reconnues à l’étape précédente.
- V38 **P1 observé, cause à confirmer** : validation affiche Photos **6/6** après 3 sélections sur ce simulateur. Même compte utilisé auparavant sur autre simulateur : distinguer accumulation serveur/reprise et duplication d’upload ; aucun doublon prouvé.
- V39 **P1 bloquant observé** : parcours Genre → Localisation → Critères → Informations complémentaires → Profil ne propose pas questionnaire. Validation annonce 0/10 ; « Compléter le profil » affiche seulement un message invitant à contacter le support, sans accès au questionnaire. Source additional_info_page navigue directement ProfileSetupPage ; handleMissingStepTap case personality affiche uniquement SnackBar. Prévoir parcours cohérent et lien direct.
- V40 **P2 observé** : étape manquante anglaise « Complete personality questionnaire » dans UI française. Traduire les codes de validation côté affichage.
- V41 **P1 observé** : validation laisse bouton principal sous bord inférieur sur iPhone 16e ; accessible AX mais capture tronquée. Vérifier défilement et espace bas, sans conclure impossibilité de gestuelle manuelle.

La seconde sauvegarde réussit sans taille 999 : cause exacte du premier HTTP 400 non confirmée. Questionnaire et écrans suivants non encore validés visuellement ; aucune correction de code appliquée.


### Suite recette — questionnaire et reprise

- V42 **P1 observé** : questionnaire choix multiples, capture iPhone 16e affiche options jusqu’au bord bas mais Suivant/Terminer sous viewport ; actions accessibles AX. Échelles numériques tiennent à l’écran. Vérifier défilement tactile et conserver commandes accessibles.
- V43 **P2 observé** : réponses questionnaire et nombres sont exposés comme textes, sans rôle de sélection/état sélectionné. Même défaut que V18/V32.
- V44 **P2 observé** : formulation « qualité over quantité » dans question 5 française ; corriger texte serveur.
- V45 **P1 reprise observée** : après questionnaire réussi, retour Genre puis autres écrans déjà parcourus sans choix préremplis. Profil affiche pseudo/date/bio vides bien que API confirme profil complet (100%, 3 prompts, 6 photos). Prévoir reprise des données existantes et sortie directe vers application quand complète.

Compte fictif local préparé avec onboardingStep personality pour accéder au questionnaire autrement inaccessible ; ce contournement de fixture ne valide pas le parcours normal. Les dix réponses ont ensuite été saisies et soumises depuis l’app. API confirme questionnaire complété et isOnboardingCompleted/isProfileCompleted vrais. V37 précisé : serveur annonce bien minimumPrompts.current=3 ; compteur UI 0/3 incorrect. Six photos côté serveur confirmées, origine accumulation à vérifier.


### Suite recette — onglets accessibles

- V46 **P2 observé** : consentement RGPD modal iPhone 16e montre seulement obligatoire et début marketing, analyses et lien confidentialité hors vue initiale. Vérifier défilement et accès à tous les détails. Continuation avec seul obligatoire réussie, autres options restées désactivées.
- V47 **P2 observé** : visite guidée propose de compléter le profil déjà complet, annonce « match accepté » plutôt que choix mutuel. Adapter état et formulation produit.
- V48 **P1 observé** : accueil à 18h23 indique « Revenez à midi, sélection sera prête à midi » avec 0 profils, sans distinguer attente lendemain et manque de profils. Fixture sans sélection : vérifier état serveur et afficher vide explicite.
- V49 **P1 observé** : barre flottante recouvre les éléments bas accueil et profil (Mes photos). Réserver espace sous contenu et vérifier scroll réel.
- V50 **P1 produit observé** : archives vides promettent conversations expirées consultables en lecture seule, contraire au cahier des charges qui les rend inaccessibles après 24h. Arbitrer politique et conservation ; accès à une archive réelle non testé.
- V51 **P1 observé** : onglet Profil affiche questionnaire 0/10 et prompts 0/3 avec coches vertes et 100% complet. Serveur indique questionnaire complété, 3 réponses. Défaut compteur V37 étendu.
- V52 **P1 observé** : Mes réponses du Profil ouvre questionnaire vierge sans réponse sélectionnée, au lieu de consulter réponses existantes ou prompts. Corriger cible et reprise selon intention produit.
- V53 **P1 observé** : GoldWen Plus affiche erreur anglaise « Failed to load current subscription », Réessayer ne récupère pas l’offre. Cause API/configuration à diagnostiquer plus tard ; aucune tentative achat.
- V54 **P1 observé** : Réglages affiche Mes prompts « Non complété » bien que serveur confirme 3 réponses et profil complet.
- V55 **P1 contenu observé** : Réglages vend « 3 sélections par jour au lieu d’1 », « Chat illimité », « Profil prioritaire ». Contradiction avec 5 profils pour tous, quota choix 1/3 et chat 24h. Vérifier droits réellement prévus et aligner contenu.
- V28 confirmé : Gestion des Photos montre 6 cases blanches, sans prévisualisations, comme onboarding ; avatars Profil/Réglages également vides.

Préférences post-onboarding : critères 18–35, distance 25km et Hommes correctement chargés ; choix exposés comme boutons sélectionnés, action Enregistrer visible. Aucun changement requis appliqué. Messages/archives états vides et retour testés ; messages temps réel et profils candidats nécessitent fixtures supplémentaires. Inscription UI reste reportée conformément à la demande.


### Suite recette — réglages secondaires et données

- V56 **P1 observé** : Gérer mes prompts annonce « Aucun prompt configuré », édition repart à 0/3 malgré minimumPrompts.current=3 confirmé serveur. Vérifier chargement/mapping des réponses, sans écraser les réponses existantes.
- V57 **P1 observé** : Notifications Push présenté activé alors que permission iOS refusée ; aucune alerte visible pour activer via réglages système. Distinguer préférences app et autorisation OS.
- V58 **P2 observé** : formulaire feedback expose cinq étoiles comme éléments sans valeur/label accessible, flèche retour sans libellé. Aucune soumission réalisée.
- V59 **P1 observé** : Localisation initialement « Non définie » après position déjà transmise au serveur ; Actualiser restaure coordonnées et message succès. Charger position persistée et afficher zone lisible, lié V23.
- V60 **P1 confirmé** : Historique sélections affiche Internal server error, réessai même résultat ; logs API GET matching/history HTTP500, TypeError selection.selectionDate.toISOString is not a function, matching.service.ts:879. Normaliser date PostgreSQL et localiser erreur UI ; correctif différé.
- V61 **P2 observé** : modération état vide affirme « Tout votre contenu est conforme » ; absence d’action ne prouve pas validation des photos. Afficher état neutre et statut modération réel.
- V10 confirmé visuellement : support annonce chat disponible et téléphone +33 1 23 45 67 89 ; Contacter ouvre feedback. Remplacer promesses/canaux fictifs par destination opérationnelle.
- V62 **P2 observé** : suppression affiche « définitive » en tête mais délai de grâce 30 jours par défaut plus bas. Clarifier état immédiat/différé et possibilité d’annulation.
- V63 **P1 contenu à vérifier** : suppression promet supprimer abonnement actif ; vérifier gestion effective des abonnements stores et expliquer l’annulation nécessaire selon comportement réel, sans laisser croire à une résiliation automatique non prouvée.

Points positifs : accès Sécurité/Accessibilité fonctionnel (inspection, sans changer mot de passe ni réglages), paramètres privacy retrouvent marketing/analyses désactivés après consentement minimal. Mes signalements état vide et filtres disponibles. Export demandé depuis UI pour seul compte fictif .invalid : confirmation puis « en cours de préparation », Actualiser disponible. Téléchargement final et email non validés. Suppression inspectée uniquement, aucune suppression effectuée. Scroll automatisé sans effet sur Accessibilité ; vérifier gestuelle manuelle avant conclure blocage.


### Suite recette — centre notifications

- V64 **P1 observé** : centre Notifications, Non lues et Toutes affichent « Failed to load notifications » ; états vides inaccessibles. Diagnostiquer réponse API et proposer erreur française utile.
- V65 **P1 périmètre observé** : bouton insecte visible ouvre Test Notifications, écran intégralement anglais avec envoi/scheduling/annulation et état FCM. Réserver diagnostic au debug et vérifier absence release ; présence en debug seule ne prouve pas fuite release.
- V66 **P2 observé** : diagnostic affiche coches vertes et « Permission requested and available » alors que notifications iOS refusées et FCM token absent. Brancher statuts réels.
- V67 **P2 observé** : deux interfaces Notifications différentes (modal Réglages, onglet du centre) ne présentent pas mêmes options, notamment email présent seulement dans centre. Unifier état et commandes.

Diagnostic inspecté uniquement : aucune notification envoyée ni programmation créée. Rapport conservé dans plans des trois dépôts ; corrections différées.


### Suite recette — données présentes mais écrans bloqués

Fixtures locales : cinq profils audit-pair-1 à audit-pair-5 @goldwen.invalid, issus uniquement du profil de recette et de ses photos démonstration, créés pour tester affichage. Sélection du seul compte recette préparée avec cinq candidats ; une conversation active 24h avec AlexRecette préparée. Aucun compte existant hors recette modifié. Ces fixtures ne prouvent ni inscription UI ni algorithme ni match mutuel.

- V68 **P1 bloquant confirmé** : API matching/daily-selection HTTP200 renvoie 5 éléments mais accueil reste 0 profils / Revenez à midi. DailySelection.fromJson appelle Profile.fromJson sur User contenant profile imbriqué ; userId absent au niveau attendu et décimaux coordonnées à normaliser. Aligner contrat DTO/client, afficher erreur de chargement au lieu faux état vide.
- V69 **P1 bloquant confirmé** : API chats renvoie une conversation active mais ChatProvider la rejette : Null n’est pas List<dynamic>, Conversation.fromJson attend participantIds absent. Affiche Aucune conversation. Aligner DTO conversation, rendre visible erreur de mapping ; chat inaccessible depuis liste tant que corrigé.
- V70 **P0 sécurité confirmé pendant recette** : réponse conversation contient objets utilisateurs avec passwordHash et emailVerificationToken, copiés dans logs Flutter par debugPrint de réponse/données rejetées. Supprimer données d’authentification des DTO publics/réponses et logs, vérifier sérialisation récursive autres endpoints, ajouter test d’absence de champs sensibles. Valeurs volontairement absentes du plan. Nouveau constat sur réponse réelle locale, aucune protection corrigée n’a été désactivée pendant recette.
- V71 **P1 produit confirmé source, UI non accessible** : matching.service.chooseProfile crée immédiatement MatchStatus.MATCHED pour choix unilatéral (commentaire unidirectional system), contraire au match mutuel requis. Vérifier comportement avec deux comptes lors correctif et bloquer chat tant que choix réciproque absent.
- V72 **P1 observé** : Messages état vide, Découvrir des profils activé via AX puis coordonnées laisse onglet Messages inchangé. Prévoir navigation vers onglet Du jour et vérifier.

Écrans détail candidat / choix / acceptation match / chat non validés visuellement à cause V68/V69 ; aucune correction appliquée afin de respecter audit puis tâches ultérieures.


### Suite recette — restauration et suivi export

- V73 **P1 observé / contexte configuration confirmé** : Restaurer achats affiche « Aucun achat trouvé », alors que logs annoncent RevenueCat API key non configurée. Distinguer absence d’achat et service indisponible ; ne pas annoncer résultat de vérification non effectuée. Aucun achat ni paiement réalisé.
- V74 **P1 reprise observée** : après sortie et relance, Export revient à « Demander un export » sans retrouver demande en préparation ni historique. Charger dernière demande/état serveur ; récupération du fichier final reste à tester.
- Statistiques Réglages actualisées à 1 match après fixture : elles ne sont pas figées dans cette version. Accès Confidentialité depuis compte connecté et retour vers Réglages fonctionnent ; défauts de contenu V03–V07 confirmés sur second format.

### Backlog exploitable issu de la recette visuelle — corrections ultérieures

Statut : **audit des accès disponibles réalisé ; écrans dépendants du matching/chat bloqués**. Ne pas marquer la recette exhaustive terminée : détail candidat, choix, match mutuel, chat, archivage réel, achats stores et inscription UI restent non validés. Les éléments « observé », « source » et « à confirmer » ci-dessus distinguent faits et hypothèses. Aucune nouvelle correction de code depuis la consigne de différer.

| Tâche | Références | Priorité | Résultat attendu / validation |
|---|---|---|---|
| [x] AV-01 — Nettoyer DTO utilisateurs et logs imbriqués | V70 | P0 | Aucune réponse/log mobile ne contient hash mot de passe, jeton vérification/reset, secret. Test récursif des réponses sélection/chat/match/profil. |
| [ ] AV-02 — Réparer contrats sélection et conversation | V68, V69, V48, V80, V81, V82, V85, V98 | P1 | 5 candidats fixture visibles, conversation active accessible, matches chargés, profil candidat chargé par id, envoi de message confirmé ou erreur « non envoyé » visible, minuteur 24 h affiché, erreur distinguée d’état vide ; recette UI sur données serveur. |
| [ ] AV-03 — Restaurer match mutuel et droits Plus | V71, V31, V50, V55, V88, V89 | P1 | Aucun chat avant choix réciproque ; 5 profils pour tous, quotas choix 1/3 ; contenu abonnement/archives conforme aux décisions produit. |
| [ ] AV-04 — Corriger ordre onboarding et reprise | V13, V25, V35, V39, V45, V52, V96, V97 | P1 | Questionnaire atteignable sans modification DB ; champs repris ; taille 100–250 validée au point de saisie ; comptes pending expliqués. Inscription UI à tester après, conformément demande. |
| [ ] AV-05 — Corriger données photos/prompts/complétion | V28, V37, V38, V51, V54, V56, V94 | P1 | Photos visibles, accumulation/doublons expliqués, 3/3 prompts et 10/10 questionnaire affichés ; édition charge existant sans perte. |
| [ ] AV-06 — Corriger mises en page et navigation | V11, V12, V17, V19, V24, V26, V30, V41, V42, V49, V72, V79, V86, V87, V91, V93, V95 | P1 | Toutes options/actions accessibles sur iPhone 16e/17 Pro, clavier et grand texte ; pas d’overflow ; commandes onglets opérationnelles. Confirmer gestuelles réelles pour observations scroll. |
| [ ] AV-07 — Réparer erreurs API et retours UI | V34, V53, V60, V64, V73, V85, V90 | P1 | Historique date PostgreSQL gérée, notifications/offres chargées ; erreurs françaises utiles, jamais exception brute ; retry réellement récupérable. |
| [ ] AV-08 — Finaliser confidentialité/export/suppression | V03–V07, V46, V62, V63, V74, V92 | P1 | Contenus réels/versionnés, dernière demande export retrouvée et fichier disponible ; suppression immédiate/différée expliquée, gestion abonnement exacte. Faire valider contenu juridique avec informations société réelles. |
| [ ] AV-09 — Unifier notifications et localisation | V20–V23, V57, V59, V65–V67 | P1/P2 | Permission OS et préférence distinctes, données persistées chargées, diagnostic réservé debug, options cohérentes, canaux/rythme alignés produit. |
| [ ] AV-10 — Accessibilité et texte final | V02, V14, V18, V32, V33, V40, V43, V44, V47, V58, V61, V10, V83 | P2 | Rôles/états/libellés accessibles, étoiles lisibles VoiceOver, texte français, contraste mesuré, support opérationnel, états vides neutres. |
| [ ] AV-11 — Qualifier incident et terminer recette bloquée | V36, V68, V69 | P1 | Crash éventuel prouvé ou écarté ; après correctifs, parcourir détails/choix/match/chat, messages second appareil, expiration, archivage, contenu modéré, paiements sandbox et grands textes. |
| [ ] AV-12 — Signaler et bloquer depuis le chat | V100 | P1 (bloquant stores) | Signaler et bloquer accessibles depuis la conversation et le profil ; blocage effectif côté API (plus de sélection, plus de message) ; testé sur deux comptes. |
| [ ] AV-13 — Retirer pages legacy/hors MVP et routes doublons | V84, V88, V90, V94, V95, V98, V99, V109 | P2 | DailyMatchesPage, ReportPage, AdvancedRecommendations, /user-profile retirés ou redirigés ; « Qui m'a choisi » arbitré ; mocks de dev déplacés dans les tests ; toute page ouverte seule a un retour (`canPop()` sinon `/home`). |

Couverture réelle :
- Accueil avant connexion, options auth, connexion email : inspectés ; inscription UI reportée.
- Genre, préférences, localisation (refus puis position fictive autorisée), critères, informations complémentaires : parcourus ; champs limites complémentaires et défilement restent partiels.
- Profil étapes base/photos/médias/prompts/validation : parcourues ; médias seulement inspectés, uploads audio/vidéo exclus MVP ; dernière étape profil non atteinte par parcours normal.
- Questionnaire : 10 questions chargées, réponses sélectionnées et soumises via UI ; accès initial obtenu par préparation de fixture, pas preuve du flux normal.
- Consentement RGPD : continuation obligatoire seule testée ; marketing/analyses restent désactivés.
- Visite guidée : trois étapes et fermeture testées.
- Du jour, Messages, Profil, Réglages : accessibles ; faux états vides sélection/chat reproduits malgré données.
- Gestion Photos, Mes réponses, édition prompts, préférences post-onboarding : inspectés ; édition non sauvegardée.
- Abonnement : erreur bloquante ; restauration inspectée, aucune transaction.
- Notifications : Non lues/Toutes en erreur, Paramètres et sélecteur heure inspectés sans modification ; diagnostic inspecté sans envoi.
- Localisation post-onboarding : actualisation position fictive réussie.
- Sécurité, Accessibilité : inspectées ; aucun changement d’identifiant ni réglage effectué ; grand texte restant à tester.
- Feedback et contact support : inspectés, aucun message envoyé.
- Historique sélections : HTTP500 confirmé ; signalements/modération : états vides inspectés.
- Privacy settings : préférences optionnelles correctement reprises ; Export demande acceptée puis reprise manquante ; Suppression inspectée et annulée.
- Conditions/Confidentialité : consultées ; contenu à corriger ; aucune nouvelle acceptation de CGU.
- Détail candidat, choix, match, chat, archives avec données : toujours bloqués par les contrats DTO (V68/V69/V80/V81/V85). Pages sans entrée parcourues le 18/09 via le lanceur (L01–L12, constats V79–V100) : profil candidat, chat, matches, qui m'a choisi, recommandations, consentement séparé, profil et réglages séparés, archives, questionnaire et création profil hors onboarding, ancienne sélection, signalement. L13 est désormais couvert par fixture mémoire ; restent les validations externes listées en L15 et les parcours serveur après correction des DTO.
- Déconnexion réelle, changement mot de passe, suppression définitive, achats, réception email/export complet : non exécutés dans cette passe.

Plans locaux des trois dépôts mis à jour. Plan externe Claude non modifié.


### Reprise de recette exhaustive — suite demandée par utilisateur

L’audit n’est pas terminé. Ancienne conclusion « accès disponibles réalisé » ne couvre pas toutes les pages, dialogues et variantes. L’utilisateur demande explicitement de poursuivre toute la couverture. Corrections toujours différées.

- V75 **P2 observé** : confirmation suppression photo ne montre ni vignette ni numéro de photo, uniquement « cette photo ». Associé à V28 (toutes blanches), impossible de vérifier visuellement la cible. Ajouter identification de la cible ; dialogue annulé, rien supprimé.
- V76 **P2 observé** : très grand texte, titre Accessibilité coupe « accessibilité » en « accessibili / té ». Prévoir titre/layout permettant lecture sans coupure arbitraire ; contrôles de taille restent accessibles via AX.
- V77 **P2 observé** : très grand texte, pseudo CamilleRecette se coupe en milieu de mot dans carte Profil, email sur plusieurs lignes ; barre flottante masque davantage complétion/bas. Vérifier comportement noms longs et grandes tailles.
- V78 **P1 observé** : contraste élevé ajoute mention « Conforme WCAG AAA » dans switch ; marqueur rouge overflow visible dans bloc contraste sur iPhone 16e. Logs Flutter confirment RenderFlex overflow. Revoir hauteur/texte et vérifier conformité réelle avant promesse AAA.

Points vérifiés : bouton photo principale fonctionne et affiche Principal + succès ; pas de suppression. Sécurité champs vides affiche Champ requis sur ancien et nouveau mot de passe ; aucun mot de passe saisi/changé. Très grand texte testé sur Accessibilité/Accueil/Profil/Réglages, puis taille Normale restaurée. Contraste élevé testé puis désactivé comme à l’origine.

Accès temporaire demandé : un lanceur de routes debug permettrait de couvrir pages existantes sans corriger contrats API ni contourner auth/guards. **Auto-review a rejeté sa création** parce qu’il modifierait le code malgré consigne initiale audit sans modifications. Aucun fichier audit_entrypoint.dart créé (absence vérifiée). Accord explicite utilisateur demandé via question en cours ; ne pas créer le lanceur tant que cet accord n’est pas reçu. Aucun contournement de cette décision effectué.

Pages sans accès direct à couvrir après autorisation : ProfileDetailPage, ChatPage, MatchesPage, WhoLikedMePage, AdvancedRecommendationsPage, ConsentPage (distincte modal RGPD), variantes UserProfilePage et SettingsPage hors onglets. Pages source sans instanciation hors exemples : DailyMatchesPage et ReportPage ; déterminer retrait legacy ou point d’entrée MVP. ExportDataDialog (settings/pages/export_data_page.dart) à distinguer écran DataExportPage actuel.


### Lanceur de recette autorisé — reprise

L’utilisateur a répondu « fait le alors » à la demande d’autorisation du lanceur temporaire. Création autorisée de lib/audit_entrypoint.dart, entrypoint debug séparé de main.dart, refuse exécution hors kDebugMode. Aucune modification des écrans/API ni de leurs guards. Routes ouvertes via AppRouter ; pages source sans route proposées uniquement si AuthProvider confirme authentification, onboarding et profil complets. flutter analyze ciblé : aucun problème. Lanceur destiné à recette, jamais point d’entrée release. Tests ouverts par ce menu à distinguer du parcours normal toujours défectueux.

Précision inventaire : settings/pages/export_data_page.dart est une simple réexportation de DataExportPage, pas un dialogue distinct ; l’ancienne mention ExportDataDialog à vérifier est levée par lecture du fichier.


### Reprise session Claude (Cowork) — 18 septembre 2026, lanceur de recette

Point de reprise : lanceur `lib/audit_entrypoint.dart` créé ; aucune page du lanceur encore parcourue. Consigne maintenue : aucun correctif pendant la recette, constats uniquement. Numérotation suivante : V79.

Checklist de couverture (cocher au fil de l'eau ; reprendre à la première case vide) :
- [x] L01 Lancement de l'app via le lanceur (bouton « Recette » visible)
- [x] L02 Candidat Alex — profil (ProfileDetailPage)
- [x] L03 Chat fictif actif (ChatPage)
- [x] L04 Matches
- [x] L05 Qui m'a choisi
- [x] L06 Recommandations sans paramètres / fixture Alex
- [x] L07 Consentement séparé (/consent)
- [x] L08 Profil séparé (/user-profile)
- [x] L09 Réglages séparés (/settings)
- [x] L10 Archives
- [x] L11 Création profil (/profile-setup) et Questionnaire hors onboarding
- [x] L12 Ancienne sélection (DailyMatchesPage) et Signalement (ReportPage)
- [x] L13 Fixture visuelle mémoire → accueil avec candidat, puis Messages avec conversation

Journal de la reprise (constats au fil de l'eau) :
- L01 OK : iPhone simulateur actif, bouton « Recette » visible, compte CamilleRecette connecté (22:28). Le menu de l'app en cours d'exécution diffère du fichier source (libellés « Candidat Alex — utilisateur », « Recommandations avancées », pas d'entrée « Injecter fixture » en tête) : le build lancé n'est pas la dernière version de `audit_entrypoint.dart`. Relancer `flutter run -t lib/audit_entrypoint.dart` pour avoir la fixture mémoire.
- V79 **P2 observé** : accueil, sous la barre flottante, une ligne de texte citation (« …dites sur… » marque plus qu'un compliment ») dépasse et reste visible sous la barre de navigation. Même famille que V49 (espace bas non réservé).
- V80 **P1 observé** : lien direct profil candidat (`/profile/<id>` AlexRecette) → écran vide « Ce profil n'est plus disponible. » avec seule flèche retour. Cause source : ProfileDetailPage ne cherche que dans les listes du provider (sélection/matches/qui m'a choisi), toutes vides à cause de V68 ; aucun appel API par id. Le message confond « non chargé / erreur » et « profil retiré ». Prévoir chargement par id ou erreur distincte + action « Retour à la sélection ».
- L02 parcouru via lanceur : voir V80 (profil introuvable). Rendu complet de ProfileDetailPage non validé tant que V68 non corrigé ou fixture mémoire non disponible dans le build.
- Environnement : simulateur iPhone 16e iOS 26.1 actif (pas 17 Pro). Saisie clavier : seules les frappes touche par touche atteignent le simulateur, la saisie de texte groupée est perdue ; les messages de test sont donc courts (« Test »).
- V81 **P1 observé** : chat fictif actif (`/chat/333885df…`), envoi « Test » → champ vidé, aucun message affiché, aucune erreur visible. Source : ChatProvider.sendMessage ajoute un message temporaire puis le retire silencieusement en cas d'exception ; `_error` n'est jamais affiché par ChatPage. Cause de l'échec (HTTP ou parsing ChatMessage.fromJson) à relever dans les logs API/Flutter. Prévoir état « non envoyé / réessayer » sur la bulle, et vérifier persistance côté serveur.
- V82 **P1 observé** : en-tête du chat affiche « Chat » + avatar vide, sans prénom, ni compte à rebours 24 h, ni statut, alors que la conversation est active. Conséquence de V69 (conversation absente du provider → otherParticipant/expiresAt nuls). Le minuteur 24 h, élément central du produit, n'est donc jamais visible sur ce parcours.
- V83 **P1 observé** : état vide du chat affiche en dur « Commencez une conversation avec Sophie » (chat_page.dart:878) quel que soit l'interlocuteur (ici AlexRecette). Remplacer par le prénom réel ou une formulation neutre.
- V84 **P2 source** : `MatchingProvider._createMockDailySelection` injecte des profils fictifs (Sophie, photos Unsplash) en mode développement si l'API est injoignable. Limité à isDevelopment, mais masque les pannes réseau en recette ; préférer un état d'erreur explicite et garder les mocks dans les tests.
- Limite lanceur : le bouton « Recette » recouvre le bouton info (i) en haut à droite du chat ; route ouverte par `go()` donc pas de flèche retour. Artefacts du lanceur, pas des défauts de l'app.
- V85 **P1 observé** : Mes Matches (onglets Actifs, Expire bientôt, Archivés) → « Oups ! Failed to load matches » en anglais ; Réessayer reproduit l'erreur. Le compte a pourtant 1 match fixture (statistiques Réglages). Source : message = fallback de `_handleError`, donc exception hors ApiException, très probablement `Match.fromJson` sur la réponse `/matching/matches` (même famille que V68/V69). Relever la réponse réelle ; message français ; aligner DTO.
- V86 **P2 observé** : chips de filtre tronqués « Expire bi… » et « Archi… » sur iPhone 16e ; le chip sélectionné s'élargit et pousse le dernier hors marge. Prévoir libellés courts ou défilement horizontal.
- V87 **P2 observé** : flèche retour de Mes Matches sans effet quand la page est ouverte sans pile (`context.pop()` sans route précédente). Constaté via lanceur, mais même situation sur lien direct/notification : prévoir repli `go('/home')` si `canPop()` est faux. Même remarque probable pour les autres pages en `context.pop()`.
- V88 **P1 produit observé** : « Qui m'a sélectionné » (compte gratuit) → écran paywall en thème sombre noir/or, en rupture avec la charte crème « Calm Technology » du reste de l'app. Fonction absente du cahier des charges MVP (Plus = jusqu'à 3 choix/jour uniquement). Arbitrer : retirer du MVP ou l'inscrire au cahier des charges, et aligner le thème.
- V89 **P1 contenu observé** : ce paywall promet « Chat illimité avec vos matches » et « Profil mis en avant », contraires au chat 24 h et non prévus par la spec (même défaut que V55, second emplacement). « Passer à GoldWen Plus » ouvre bien l'abonnement, qui retombe sur V53 (« Failed to load current subscription », sous-titre anglais sous un titre français). Le retour vers le paywall fonctionne.
- V90 **P2 observé** : Recommandations avancées → « Erreur de chargement / Paramètres invalides », sans flèche retour ; en-tête doré plein, troisième style d'en-tête différent. Page atteignable uniquement par route/exemples (`examples/advanced_recommendations_usage_example.dart`), aucune entrée dans l'app. Variante avec paramètres fixture absente du build en cours, non testée. Décider : retrait du MVP (recommandé, hors spec) ou point d'entrée réel + retour.
- V91 **P1 observé** : Consentement RGPD séparé (`/consent`) affiche la modale de consentement enchâssée dans une page : carte étroite, mots coupés au milieu (« Traiteme / nt », « Obligato / ire »), double titre (« Consentement RGPD » + « Protection de vos données »).
- V92 **P1 observé** : sur cette page, les consentements déjà donnés ne sont pas repris : case obligatoire décochée alors que le compte a consenti à l'entrée ; message rouge « Le consentement… est requis » affiché avant toute action. Charger l'état serveur, ne montrer l'erreur qu'après tentative.
- V93 **P1 observé** : croix (X) de cette page → écran blanc, app inutilisable jusqu'à redémarrage. Source : `gdpr_consent_modal.dart:95` fait `Navigator.of(context).pop()`, prévu pour une modale, ici appelé comme page → dépile la route racine. Dans le lanceur la route racine est l'hôte de recette (amplifie l'effet) ; dans l'app normale le même pop sur la dernière route go_router est à vérifier. Utiliser `context.pop()`/`canPop()` ou masquer X en mode page.
- Point technique recette : le défilement par glisser (drag) fonctionne dans le simulateur ; la molette ne fait rien. Les observations « scroll sans effet » de V17, V24, V26, V30, V41, V42 sont à revérifier par glisser.
- État : app bloquée sur écran blanc (22:36) après V93 ; redémarrage (hot restart) nécessaire. Reprendre à L07 terminé → L08.
- Reprise bloquée : l'écran du Mac semble verrouillé (fenêtre de connexion au premier plan, captures impossibles). Le Terminal n'est accessible à Claude qu'en mode clic, donc pas de `flutter run` possible de son côté. Prochaine étape : Mac déverrouillé + app relancée (`flutter run -t lib/audit_entrypoint.dart`, ou icône GoldWen sur le simulateur), puis reprendre à L08.
- Relance 23:07 : app fermée depuis le sélecteur d'apps du simulateur et rouverte depuis son icône (même build, menu lanceur ancien, sans fixture mémoire). Pilotage en arrière-plan de la seule fenêtre Simulator.
- V94 **P2 observé** : Profil séparé (`/user-profile`, écran « Mon Profil » avec X) duplique l'onglet Profil avec un autre en-tête (carte dorée, avatar vide, e-mail technique affiché en entier et coupé en milieu de mot). Reprend les défauts V28/V37/V51 (Photos 6/6, Prompts 0/3 et Questionnaire 0/10 cochés verts, « 100 % »). Confirme l'item 3.2 : supprimer la route ou la rediriger vers l'onglet Profil. La croix renvoie correctement à l'accueil.
- V95 **P2 observé** : Réglages séparés (`/settings`, « Profil & Paramètres ») = même contenu que l'onglet Réglages mais sans barre d'onglets ni retour : cul-de-sac si atteint par lien direct/notification. Avatar vide (V28), « Mes prompts — Non complété » (V54) reproduits. Deux entrées quasi homonymes « …confidentialité » (paramètres RGPD) et « Confidentialité » (politique) côte à côte : renommer pour lever l'ambiguïté (« Mes données et consentements » / « Politique de confidentialité »).
- Déconnexion (V08) volontairement non exécutée : reconnexion du compte de recette impossible sans son mot de passe ; à tester en fin de recette ou avec le mot de passe fourni.
- L10 Archives (`/archived-chats`) : état vide « Aucun chat archivé… consultables en lecture seule » — confirme V50 (contraire à la spec). Pas de retour quand ouverte seule (même famille V87/V95). Archive réelle toujours non testée (aucune conversation expirée en données).
- V96 **P1 observé** : Questionnaire (`/questionnaire`) sur compte ayant déjà répondu → question 1/10 vierge, aucune réponse existante, aucun bouton quitter/retour. Risque d'écrasement des réponses en rejouant. Confirme V52 hors onglet Profil ; soit route inaccessible une fois complété, soit mode consultation/édition préremplie. Non soumis.
- V97 **P1 observé** : Création profil (`/profile-setup`) sur profil complet → « Étape 1/6 » avec pseudo, date et bio vides (profil serveur : CamilleRecette, bio renseignée) et aucune sortie. Confirme V45 hors onboarding. Rediriger un profil complet vers l'app, ou préremplir. Rien saisi.
- V98 **P2 observé** : Ancienne sélection (DailyMatchesPage, sans route) → badge vert « Nouvelle sélection disponible ! » affiché en même temps que « Oups ! Failed to load daily selection » (anglais). Page legacy à retirer. Information utile : cette page, contrairement à l'accueil, révèle l'erreur de chargement de la sélection → confirme que l'accueil masque l'échec de V68 derrière un faux « Revenez à midi ».
- V99 **P2 observé** : Signalement (ReportPage, sans route, utilisée seulement dans `examples/`) : motif « Contenu inapproprié » présélectionné par défaut ; grand bloc bleu vide sans texte au-dessus du bouton « Envoyer » (couleur hors charte, probablement un encart d'info au contenu manquant) ; bouton d'envoi rouge. Rien envoyé. Page legacy doublon de `ReportDialog` : retirer ou unifier.
- V100 **P1 manquement source + observé** : le signalement n'est accessible que depuis ProfileDetailPage (ReportDialog), elle-même inaccessible (V80). Le chat n'offre ni signaler ni bloquer (menu info = « À propos de cette conversation »), et aucune fonction « bloquer » n'existe dans le code mobile. Pour une app de rencontre, signaler/bloquer depuis la conversation est attendu par les stores (règle Apple 1.2 sur contenus générés par les utilisateurs) : prévoir avant publication (Phase 5).
- L13 **historique — blocage levé le 19/09** : le build installé ne contenait pas l'entrée « Injecter fixture visuelle mémoire » (fichier source plus récent que le build). Nécessite `flutter run -t lib/audit_entrypoint.dart` par l'utilisateur (Claude n'a accès au Terminal qu'en clic). Entrées Conditions, Confidentialité, Notifications, Abonnement, Export du lanceur non rejouées : déjà couvertes (V03–V07, V64, V53, V74).
- À revérifier par glisser (le défilement fonctionne) : V17, V19, V24, V26, V30, V41, V42. Écrans d'onboarding (`/gender-selection` etc.) absents du lanceur : ajouter ces routes au lanceur ou revérifier lors d'une prochaine inscription.

Bilan historique reprise 18/09 (23:10) : L01–L12 parcourus, L13 alors bloqué, désormais couvert le 19/09. Nouveaux constats V79–V100 (aucun correctif appliqué). Priorités qui en ressortent : V100 (signaler/bloquer absent du chat, bloquant stores), V81/V82/V85 (chat et matches inutilisables, même famille de contrats DTO que V68/V69), V93 (écran blanc via croix du consentement), V88/V89 (paywall hors spec et promesses fausses). Prochaine reprise : relancer le build lanceur à jour → L13, puis revérification par glisser.


### Reprise recette — 19 septembre 2026, fixture mémoire et variantes

Le lanceur debug autorisé a été relancé sur iPhone 16e avec l'API, PostgreSQL, Redis et le service de matching locaux. Le compte fictif local a été reconnecté via un raccourci debug du lanceur après expiration du jeton. Les données ci-dessous sont injectées uniquement dans les providers en mémoire ; elles valident le rendu des écrans, pas les contrats API ni la logique de matching. Aucun bug produit n'a été corrigé.

- [x] L13 Fixture visuelle mémoire : candidat sur Accueil, conversation dans Messages, détail candidat, compte à rebours et archive expirée inspectés.
- [x] L14 Reprise des étapes onboarding Genre, Genres recherchés, Localisation, Critères et Informations via le lanceur ; captures initiales et accès AX aux éléments bas inspectés.
- [ ] L15 Variantes encore dépendantes d'un environnement externe : achats StoreKit/RevenueCat sandbox, réception push réelle, second appareil temps réel, export final reçu/téléchargé, suppression définitive. À exécuter pendant les phases fonctionnelles concernées, pas en simulant un succès.

Nouveaux constats :

- V101 **P2 observé** : Accueil avec un candidat réel en mémoire affiche « 1 personnes choisies pour vous ». Gérer le singulier (« 1 personne »). La carte candidat et le bloc Conversation active apparaissent correctement quand les providers contiennent des objets valides ; cela confirme que V68/V69 sont des contrats DTO/parsing et non une absence de composants UI.
- V102 **validation positive / limite fixture** : ProfileDetailPage rend correctement nom, âge, bio, score global 82 %, détail 80/90/75/83 et intérêt commun avec des valeurs au format 0–1. Les actions Choisir/Passer existent dans l'arbre d'accessibilité. La fixture n'a volontairement aucune photo et aucun choix n'a été confirmé.
- V103 **validation positive** : l'onglet Messages affiche AlexRecette, ouvre le chat depuis la liste et la recherche locale affiche un état « Aucun résultat » cohérent pour `zzz`.
- V104 **P1 confirmé** : avec une `Conversation` valide en mémoire, l'en-tête du chat affiche AlexRecette et un compte à rebours proche de 20 h. L'état vide continue pourtant d'annoncer « Commencez une conversation avec Sophie » ; V82 est donc bien causé par V69, tandis que V83 est un texte en dur indépendant.
- V105 **P2 observé** : la liste d'archives affiche « Expiré le Aujourd'hui » (grammaire incorrecte). Le chat archivé répète trois fois l'expiration : badge en-tête, bannière « archivée - Lecture seule », deux encarts identiques « Cette conversation a expiré », puis un troisième bloc en pied. Réduire à une information claire. La consultation en lecture seule reste contraire à la décision produit d'inaccessibilité après 24 h (V50).
- V106 **P0 sécurité/confiance, source confirmée** : le dialogue du chat promet « Messages chiffrés de bout en bout » (`chat_page.dart:964`), mais le backend copie `sendMessageDto.content` dans `message.content` et la colonne TypeORM est un simple `varchar` (`chat.service.ts:292-299`, `message.entity.ts:35-36`). Aucun mécanisme E2E n'est présent dans ce chemin. Retirer immédiatement la promesse ou implémenter un protocole E2E audité ; vérifier séparément le chiffrement au repos exigé par la spec.
- V107 **P1 revalidation visuelle** : Genre et Genres recherchés montrent entièrement Homme/Femme, Non-binaire seulement en amorce et Autre hors écran derrière l'action fixe ; Localisation place « Continuer » au-dessus du bouton « Activer la localisation » ; Critères masque Distance maximale et Conseil sous l'action fixe. Les glissés automatisés n'ont pas déplacé ces vues. Les éléments restent présents dans AX ; conserver la réserve de prudence outil mais traiter les recouvrements visibles V17/V19/V24.
- V108 **P1 source** : `ArchivedChatsPage` construit l'avatar avec `NetworkImage(otherUser.photos.first as String)` alors que `Profile.photos` contient des `Photo`. Une archive réelle avec photo peut provoquer une erreur de type. Utiliser `.first.url` et tester archive avec/sans photo/URL invalide.

Mise à jour du backlog :

| Tâche | Références | Priorité | Résultat attendu / validation |
|---|---|---|---|
| [ ] AV-14 — Corriger les archives et leur politique produit | V50, V105, V108 | P1 | Politique 24 h alignée sur la décision produit ; aucune consultation si inaccessibilité retenue ; pas de cast photo ; libellé de date français ; une seule information d'expiration. |
| [x] AV-15 — Corriger la promesse de chiffrement du chat | V05, V106 | P0 | Aucune allégation E2E sans protocole réellement implémenté et audité ; chiffrement transit/au repos documenté et testé ; contenu juridique et UI alignés. |


### Traitement AV-01 et AV-15 (P0) — 19 septembre 2026, session Claude (Cowork)

Ces deux points P0 du backlog de recette ont été corrigés, sur demande explicite d'Adrien de commencer par eux :

- **AV-01** — `ClassSerializerInterceptor` enregistré globalement (`main-api/src/main.ts`, en dernière position de la chaîne d'interceptors pour s'exécuter au plus près du contrôleur, avant `ResponseInterceptor`/`CacheInterceptor`) + `@Exclude()` posé sur `User.passwordHash`, `emailVerificationToken`, `resetPasswordToken`, `resetPasswordExpires`, `twoFactorSecret` (`user.entity.ts`) et `Admin.passwordHash`, `resetPasswordToken`, `resetPasswordExpires` (`admin.entity.ts`). Correctif global : s'applique aussi aux relations imbriquées (`Chat.match.user1/user2`, `Message.sender`), donc pas seulement à l'endpoint chat visé par V70, conformément à la demande du plan de « vérifier la sérialisation récursive des autres endpoints ». Test ajouté : `main-api/src/database/entities/sensitive-fields.spec.ts` (5/5 verts), qui reproduit le cas réel (User imbriqué dans Message.sender et Match.user1/user2 via Chat.match) et vérifie l'absence des champs sensibles après passage dans le pipeline `ClassSerializerInterceptor` réel. `npx tsc --noEmit` propre ; suites `auth`/`admin`/`chat`/`database/entities` : 14 suites, 133 tests verts, aucune régression.
  **Reste à faire** : vérifier en conditions réelles (serveur + un vrai appel `GET /chat/:chatId` + logs Flutter) qu'aucun champ sensible n'apparaît plus dans la réponse ; et retirer/assainir les `debugPrint` de réponses API brutes côté Flutter (`chat_provider.dart`, cf. V81) qui recopiaient ces données dans les logs de l'appareil — ce correctif backend empêche le champ de sortir de l'API, mais ne nettoie pas un éventuel `debugPrint(response.data)` générique qui logguerait autre chose de sensible à l'avenir.
- **AV-15** — La promesse « Messages chiffrés de bout en bout » a été retirée de `chat_page.dart` (remplacée par la garantie réellement tenue : suppression définitive à l'expiration de la conversation). Dans `privacy_page.dart`, la section « 5. Sécurité des données » a été nettoyée des promesses non vérifiées par la recette (chiffrement des données sensibles au repos, audits de sécurité réguliers, formation du personnel) ; l'authentification à deux facteurs — réellement implémentée en TOTP (`two-factor.service.ts`, vérifié dans le code) — est reformulée comme une option que l'utilisateur active lui-même, pas comme une protection automatique appliquée à tous.
  **Reste à faire** : documenter et vérifier réellement le chiffrement en transit (TLS en production) et statuer sur un éventuel chiffrement au repos avant de le promettre à nouveau ; le site vitrine ne contient pas de promesse équivalente (vérifié, aucune occurrence de « chiffrement »/« audits »/« 2FA » dans `GoldWen-app-web`).

Couverture actualisée : le rendu nominal candidat/chat/archive est maintenant couvert avec objets en mémoire. Le parcours serveur reste bloqué par V68/V69/V80/V81/V85 et devra être rejoué après correction des DTO. Les recouvrements onboarding V17/V19/V24 sont reproduits ; Informations complémentaires possède un `SingleChildScrollView` et les contrôles bas ont été atteints via focus AX, mais la gestuelle automatisée n'a pas permis de conclure sur le geste utilisateur. Les sélections Sport, Running et Français ont été modifiées seulement dans l'état local de cette page puis abandonnées, sans sauvegarde serveur. Inscription UI reste reportée selon la demande utilisateur.

Plan externe Claude non modifié faute d'accès confirmé.

- V109 **P1 produit/source observé** : `MatchAcceptanceDialog`, utilisé seulement par la page legacy DailyMatchesPage, ajoute après le match une décision « Décliner » / « Commencer le chat » et appelle `acceptMatch`. La spécification crée automatiquement la conversation dès le choix mutuel ; ce troisième consentement peut perdre un match déjà mutuel et complexifie le cœur du MVP. Retirer avec la page legacy ou faire arbitrer explicitement ce parcours. Visuellement, le dialogue tient sur iPhone 16e ; aucune action n'a été exécutée.

- V110 **validation positive** : le dialogue `RateLimitDialog` pour blocage temporaire de connexion tient sur iPhone 16e, explique la cause en français et affiche un compte à rebours lisible. Variante inspectée avec exception fictive 429, sans requête externe.


### Exécution Phases 1 et 2 — 19 septembre 2026, session Codex

Les éléments des Phases 1 et 2 déjà présents dans l'historique ont été relus dans le code avant intervention (routes manquantes, quotas 5 profils / 1 ou 3 choix, notifications, migration initiale, validation d'environnement, client API principal, retrait admin mobile, Socket.IO, refresh JWT et configuration réseau). Cette passe a corrigé les derniers contrats bloquant le parcours réel :

- [x] **Sélection quotidienne** : `GET /matching/daily-selection` renvoie désormais des `Profile` réels (photos approuvées et prompts), et Flutter envoie `profile.userId` pour choisir/passer un candidat. L'app attend le succès API avant d'annoncer le choix.
- [x] **Matches et détail profil** : `GET /matching/matches` et `GET /matching/matches/:id` exposent un contrat mobile stable (`otherProfile`, `chatId`, expiration, score décimal normalisé). Les parseurs Flutter acceptent les décimaux PostgreSQL sérialisés en chaînes et les noms backend `firstName` / `lastName`.
- [x] **Conversations** : `GET /chat` et `GET /chat/:id` renvoient participants, interlocuteur, dernier message et nombre non lu calculé uniquement sur les messages reçus.
- [x] **Temps réel** : le `ChatProvider` est relié à la session authentifiée. L'envoi Socket.IO utilise un accusé de réception ; REST n'est utilisé qu'en repli hors connexion, supprimant la double persistance d'un même message.
- [x] **Historique** : normalisation de `selectionDate` corrige le HTTP 500 observé avec les colonnes PostgreSQL `date` (V60).
- [x] **Tests de contrat** : ajout de `test/api_contract_models_test.dart` pour les payloads réels sélection, match, conversation et message.
- [x] **Confidentialité des logs mobiles** : suppression des traces de réponses conversation/message brutes ; les erreurs de parsing ne recopient plus les payloads potentiellement personnels dans les logs appareil.

Vérifications de cette passe : backend `tsc --noEmit` propre, ESLint propre sur les fichiers Phase 1 modifiés, **72 suites / 645 tests backend verts** ; mobile `flutter analyze` propre et **700 tests verts** ; détecteur Impeccable sans constat sur les deux pages de matching touchées. Le lint backend global est momentanément bloqué dans `reports.service.ts:147` par un changement concurrent hors de cette passe ; ce fichier n'a pas été modifié ici. La recette bout-en-bout serveur + deux appareils (sélection, match mutuel, livraison Socket.IO, expiration) reste à rejouer avant de déclarer les phases validées en production.

Plan vivant externe Claude non modifié faute d'accès confirmé.

### Réponse au blocage lint signalé (session Codex, Phases 1/2) — 19 septembre 2026, session Claude (Cowork)

Investigation du blocage lint global rapporté dans `reports.service.ts:147` : confirmé qu'il ne s'agissait pas d'un défaut dans ce fichier. La config ESLint du backend (`eslint.config.mjs`) utilise `tseslint.configs.recommendedTypeChecked` avec `projectService: true`, qui exige que **tout** le projet TypeScript compile pour que le lint « type-aware » fonctionne sur n'importe quel fichier. Le blocage venait de l'import dupliqué de `Profile` dans `matching.service.ts` (lignes 21-22), qui a depuis été corrigé côté Codex. Après cette correction : `npx tsc --noEmit` propre, `npx eslint "{src,apps,libs,test}/**/*.ts"` propre (0 erreur), suite `reports.service.spec.ts` : 12/12 verts. Un unique problème prettier sans rapport (guillemets) trouvé dans un fichier ajouté par cette session (`public-key.dto.ts`) a été corrigé au passage. `reports.service.ts` lui-même n'a nécessité aucune modification.

**État en cours côté Claude (E2E chat, AV-15 approfondi)** : sur demande d'Adrien, implémentation d'un vrai chiffrement de bout en bout des messages (X25519 + HKDF-SHA256 + AES-256-GCM), pas seulement le retrait de la promesse. Décision produit validée par Adrien : signalement en clair (le client du signalant envoie le contenu déchiffré au moment du signalement, façon Signal/WhatsApp), pour concilier E2E et modération.
Backend déjà en place (ne devrait pas entrer en collision avec les fichiers touchés par la session Codex) :
- `User.publicKey` (colonne `text`, migration `1789656000000-AddPublicKeyToUsers.ts`) + `PUT /users/me/public-key`.
- `CreateReportDto.decryptedMessageContent` (optionnel) → alimente `Report.retainedEvidence` (mécanisme RGPD déjà existant, réutilisé tel quel) uniquement pour les signalements de message.
- `SendMessageDto.content` : `maxLength` porté de 1000 à 4000 pour absorber le surcoût base64 du ciphertext (`chat.dto.ts`). **Point d'attention pour la session Codex** : si les contrats de `chat.service.ts`/`chat.gateway.ts` sont retouchés, `content` restera une chaîne opaque côté serveur (le serveur ne déchiffre jamais) — aucun changement de forme du payload REST/Socket.IO n'est requis pour l'E2E côté backend, seul le contenu de `content` devient du ciphertext base64 côté client.

Côté mobile, `E2eKeyService` et `E2eMessageCryptoService` (nouveaux fichiers isolés, `lib/core/services/`) sont prêts, mais le branchement dans `chat_provider.dart` / `chat.dart` / `matching.dart` / `websocket_service.dart` est **volontairement mis en pause** côté Claude tant que ces fichiers sont en cours de modification par la session Codex (Socket.IO temps réel), pour ne rien écraser. À reprendre une fois cette passe Codex stabilisée — se coordonner via ce fichier avant modification de ces 4 fichiers.

Plan vivant externe Codex non modifié au-delà de cet ajout, pour ne rien écraser du contenu existant.

### Exécution Phases 3 et 4 — 19 septembre 2026, session Codex

Cette passe complète les écrans et durcit les garde-fous de qualité sans écraser les travaux E2E menés en parallèle. Les recommandations avancées restent volontairement hors navigation MVP : elles relèvent du matching V2 explicitement exclu du périmètre actuel. Le mobile reste français pour le MVP ; l'infrastructure anglaise existante est conservée pour une localisation ultérieure.

- [x] **Réglages et navigation** : préférences, localisation, sécurité, accessibilité, confidentialité, notifications, abonnement, export, suppression, modération, feedback, statistiques et gestion des photos disposent d'écrans ou d'actions fonctionnels. L'entrée « Qui m'a sélectionné » est maintenant visible et conserve son contrôle GoldWen Plus. Le support ne propose plus de faux chat ni de faux numéro : seul le contact confirmé `goldwen.supp.app@gmail.com` est affiché.
- [x] **Profil et consentement** : le profil résumé reste la vue principale, la déconnexion renvoie vers l'accueil public, et le parcours de sélection conserve le garde de consentement explicite. Aucun nouveau parcours legacy n'a été réintroduit.
- [x] **Actions UI fiables** : suppression de contrôles sans effet, correction de l'action du Snackbar de signalement et du réordonnancement des photos (le déplacement adjacent fonctionne désormais et conserve la photo principale). Un test widget couvre le glisser-déposer réel.
- [x] **Données et logs appareil** : suppression des traces contenant réponses d'authentification, jetons, e-mail, réponses de personnalité, réponses de prompts et données brutes de profil. Les candidats de démonstration ne peuvent être injectés qu'en build debug **et** dans l'environnement `development`.
- [x] **Phase 4.1 — CI backend** : `tsc --noEmit` et ESLint propres. La commande CI exacte `npm test -- --coverage --forceExit --detectOpenHandles` passe avec **72 suites / 647 tests** et sans handle ouvert détecté. Couverture globale : statements **55,43 %**, branches **49,31 %**, functions **38,22 %**, lines **55,43 %**, au-dessus des seuils configurés. Le service d'indicateur de saisie libère désormais ses timers à la destruction et dans les tests.
- [x] **Phase 4.2 — CI mobile** : `flutter analyze` ne remonte aucun problème ; `flutter test --coverage` passe avec **703 tests**. Les tests ciblés Réglages/Support/« Qui m'a sélectionné »/réordonnancement photo passent (**9/9**). Le détecteur Impeccable ne remonte aucun anti-pattern sur les fichiers UI modifiés.

Reste avant validation production : recette sur appareils réels de la sélection à midi local et des notifications, test à deux appareils du match/chat E2E et de l'expiration 24 h, achats sandbox RevenueCat/StoreKit, export/suppression réels, puis publication des artefacts de couverture dans la CI distante. Les travaux E2E concurrents présents dans le workspace ont été préservés et testés avec l'ensemble mobile ; ils ne sont pas revendiqués comme modifications de cette passe.

Plan vivant externe Claude non modifié faute d'accès confirmé.

### Exécution Phases 3 et 4 — 19 septembre 2026, session Codex

Cette passe complète les écrans et durcit les garde-fous de qualité sans écraser les travaux E2E menés en parallèle. Les recommandations avancées restent volontairement hors navigation MVP : elles relèvent du matching V2 explicitement exclu du périmètre actuel. Le mobile reste français pour le MVP ; l'infrastructure anglaise existante est conservée pour une localisation ultérieure.

- [x] **Réglages et navigation** : préférences, localisation, sécurité, accessibilité, confidentialité, notifications, abonnement, export, suppression, modération, feedback, statistiques et gestion des photos disposent d'écrans ou d'actions fonctionnels. L'entrée « Qui m'a sélectionné » est maintenant visible et conserve son contrôle GoldWen Plus. Le support ne propose plus de faux chat ni de faux numéro : seul le contact confirmé `goldwen.supp.app@gmail.com` est affiché.
- [x] **Profil et consentement** : le profil résumé reste la vue principale, la déconnexion renvoie vers l'accueil public, et le parcours de sélection conserve le garde de consentement explicite. Aucun nouveau parcours legacy n'a été réintroduit.
- [x] **Actions UI fiables** : suppression de contrôles sans effet, correction de l'action du Snackbar de signalement et du réordonnancement des photos (le déplacement adjacent fonctionne désormais et conserve la photo principale). Un test widget couvre le glisser-déposer réel.
- [x] **Données et logs appareil** : suppression des traces contenant réponses d'authentification, jetons, e-mail, réponses de personnalité, réponses de prompts et données brutes de profil. Les candidats de démonstration ne peuvent être injectés qu'en build debug **et** dans l'environnement `development`.
- [x] **Phase 4.1 — CI backend** : `tsc --noEmit` et ESLint propres. La commande CI exacte `npm test -- --coverage --forceExit --detectOpenHandles` passe avec **72 suites / 647 tests** et sans handle ouvert détecté. Couverture globale : statements **55,43 %**, branches **49,31 %**, functions **38,22 %**, lines **55,43 %**, au-dessus des seuils configurés. Le service d'indicateur de saisie libère désormais ses timers à la destruction et dans les tests.
- [x] **Phase 4.2 — CI mobile** : `flutter analyze` ne remonte aucun problème ; `flutter test --coverage` passe avec **703 tests**. Les tests ciblés Réglages/Support/« Qui m'a sélectionné »/réordonnancement photo passent (**9/9**). Le détecteur Impeccable ne remonte aucun anti-pattern sur les fichiers UI modifiés.

Reste avant validation production : recette sur appareils réels de la sélection à midi local et des notifications, test à deux appareils du match/chat E2E et de l'expiration 24 h, achats sandbox RevenueCat/StoreKit, export/suppression réels, puis publication des artefacts de couverture dans la CI distante. Les travaux E2E concurrents présents dans le workspace ont été préservés et testés avec l'ensemble mobile ; ils ne sont pas revendiqués comme modifications de cette passe.

Plan vivant externe Claude non modifié faute d'accès confirmé.

### Achèvement E2E mobile (Tâches 7/8) + correctif signalement — 19 septembre 2026, session Claude (Cowork)

Suite de l'AV-15 approfondi ci-dessus, une fois la passe Codex sur `chat_provider.dart`/`chat.dart`/`websocket_service.dart` stabilisée (confirmé par Adrien).

**Backend** (`chat.service.ts`) : ajout d'un champ `otherParticipantPublicKey: string | null` sur `ChatView` (renvoyé par `GET /chat` et `GET /chat/:id`), à plat plutôt que sur `Profile` pour ne pas toucher sa sérialisation. C'est la clé publique de l'AUTRE participant, valable pour toute la conversation quel que soit l'expéditeur d'un message donné (ECDH est symétrique) — le mobile n'a donc besoin de la connaître qu'une fois par conversation, pas par message. `tsc --noEmit` propre, `eslint` global propre, suites `src/modules/chat/tests/*` : 6/6, 73/73 tests verts.

**Mobile** :
- `chat.dart` : `Conversation.otherParticipantPublicKey` (parsing/toJson/copyWith) ; `ChatMessage.decryptedContent` + `decryptionFailed` (champs calculés côté client, jamais sérialisés) et le getter `displayContent` (texte déchiffré si disponible, "Message illisible" explicite si le déchiffrement a été tenté et a échoué, sinon `content` tel quel).
- `chat_provider.dart` : chiffrement à l'envoi (`_encryptForChat`) et déchiffrement à la réception/au chargement (`_decryptIfNeeded`, `_peerPublicKeyFor`) — REST, historique paginé et Socket.IO temps réel sont tous les trois couverts. Upload de la clé publique de l'appareil déclenché automatiquement dès qu'une session authentifiée est active (`updateSession` → `E2eKeyService.ensurePublicKeyUploaded`).
- UI : `chat_page.dart`, `chat_list_page.dart`, `archived_chats_page.dart` affichent désormais `message.displayContent` plutôt que `message.content` brut.
- **Limite connue et assumée** : les messages de test/QA déjà en base, envoyés avant ce correctif, s'afficheront "Message illisible" une fois que les deux comptes de test auront une clé publique enregistrée (on ne peut pas distinguer de façon fiable un ciphertext corrompu d'un message légitimement envoyé en clair avant l'E2E, sans marqueur de version en base — voir le commentaire de `_decryptIfNeeded`). Sans conséquence pour des comptes de recette ; à garder à l'esprit si des messages réels doivent être conservés lisibles au lancement.

**Signalement (Tâche 8) — bug de contrat découvert et corrigé** : en câblant le signalement d'un message depuis le chat (absence relevée en V100 — jusqu'ici signaler n'était possible que depuis la fiche profil, jamais depuis une conversation), il s'est avéré que **le signalement mobile était cassé pour tout le monde, pas seulement pour les messages** : `ApiService.submitReport` envoyait `targetUserId`/`type`/`reason`/`messageId`/`chatId`, alors que `CreateReportDto` attend `targetType` + `targetId` (l'ID du message quand il s'agit d'un signalement de message, sinon l'ID utilisateur) + `reason` (l'enum) + `description` (texte libre) + `decryptedMessageContent`. Le backend a `ValidationPipe({ forbidNonWhitelisted: true })` : le payload de l'app était donc systématiquement rejeté (400) avant même la validation métier — **aucun signalement n'a jamais pu aboutir depuis le mobile**. Corrigé dans `ApiService.submitReport` (calcule `targetType`/`targetId` en interne, garde la même signature Dart pour ne pas toucher tous les appelants). Un test (`test/api_history_validation_test.dart`) affirmait à tort l'ancien contrat cassé sous le nom trompeur "serializes the backend contract" ; corrigé, et un second test ajouté pour le cas signalement de message avec `decryptedMessageContent`.
- `chat_page.dart` : ajout de l'option "Signaler ce message" (menu long-press, uniquement sur les messages reçus) → `ReportDialog(targetUserId: message.senderId, messageId: message.id, chatId: chatId, messageDecryptedContent: ...)`. Le contenu transmis est celui vu par le signalant (`ChatMessage.displayContent`), jamais le ciphertext ni le texte de repli "Message illisible" (garde explicite).

**Non vérifié par cette session** : `flutter analyze` / `flutter test` n'ont pas pu être exécutés (pas de SDK Flutter accessible depuis ce shell distant) — vérification manuelle attentive de la syntaxe faite à la place (accolades/parenthèses comptées, relecture complète des fichiers modifiés), mais une passe `flutter analyze` + `flutter test` réelle avant merge reste recommandée (Codex ou Adrien).

**Reste hors périmètre de cette session** : le blocage (V100) — aucune fonction bloquer n'existe encore côté mobile ni serveur ; à traiter séparément si retenu pour la publication (Phase 5, règle Apple 1.2 sur le contenu généré par les utilisateurs peut être satisfaite par signaler seul, bloquer est un plus).

### Audit Phases 5 et 6 — 19 septembre 2026, session Claude (Cowork)

Sur demande d'Adrien de traiter les Phases 5 et 6. Avant de refaire ce travail, vérification systématique de l'état réel du code face à chaque point du plan (rédigé avant plusieurs passes ultérieures) : la quasi-totalité s'avère déjà faite, avec des fichiers réels et datés (17-18 septembre), pas des ébauches. Aucune modification de code apportée ici — seule cette section est nouvelle, pour remettre le plan à jour et lister ce qui reste réellement.

**Phase 5 (mobile) — déjà fait, vérifié fichier par fichier :**
- Android : signature de release configurée proprement (`android/key.properties`, gitignored, avec repli explicite sur la clé debug + avertissement si absent) ; `google-services.json` réel présent ; `android:label="GoldWen"` ; `usesCleartextTraffic` retiré du manifest au profit d'un `network_security_config.xml` scoping debug/release ; `queries` Google Sign-In présent ; icônes de lanceur réelles (toutes densités, pas les icônes Flutter par défaut).
- iOS : `GoogleService-Info.plist` réel présent ; bundle ID unifié `com.goldwen.app` partout (y compris `RunnerTests`, qui n'est plus `com.example.*`) ; `Runner.entitlements` avec Sign in with Apple (commentaire notant que l'activation de la capability sur le portail Apple Developer reste à faire par Adrien) ; `CFBundleURLTypes` pour Google Sign-In ; `NSMicrophoneUsageDescription` présent ; orientation verrouillée portrait (Info.plist + `main.dart`) ; l'exception ATS de développement pour l'IP LAN personnelle retirée (celle pour `localhost` reste, légitime, avec un avertissement honnête que cette exception atteint quand même les builds Release faute d'un réglage Xcode Debug/Release distinct) ; AppIcon et LaunchImage réels (icône App Store 1024×1024 incluse) ; `PrivacyInfo.xcprivacy` rédigé de bonne foi à partir des usages réels du code (géoloc, photos, contenu de chat, compte, analytics), avec note explicite pour le repasser si un SDK de tracking est ajouté un jour.
- Clés tierces : `firebase_config.dart` (fichier de clés fabriquées, mort) supprimé. Mixpanel reste désactivé silencieusement sans `--dart-define` (comportement honnête voulu, pas un bug). RevenueCat lève une exception explicite si `REVENUECAT_API_KEY` n'est pas fourni (idem, voulu).
- Métadonnées stores : `docs/store-listing-fr.md` (textes prêts à coller App Store Connect / Play Console) ; `android/fastlane` et `ios/fastlane` configurés ; `pubspec.yaml` a `flutter_launcher_icons`/`flutter_native_splash` pointant vers les vrais logos GoldWen (`assets/images/logo_*.png`, fichiers réels).

**Reste sur Phase 5 — nécessite une action d'Adrien, pas du code :**
- Activer la capability "Sign in with Apple" sur le portail Apple Developer (compte développeur actif requis) puis régénérer le profil de provisioning.
- Vraies captures d'écran et vidéo store — explicitement reportées par Adrien jusqu'à ce que le mobile soit plus avancé (déjà noté en Phase 6.4) ; le store-listing le rappelle lui-même.
- Renseigner les vraies clés Mixpanel/RevenueCat quand ces comptes existent.
- Recette réelle avant soumission (déjà notée par la session Codex, Phase 3/4) : sélection à midi sur appareil réel, achats sandbox StoreKit/RevenueCat, export/suppression de compte réels.

**Phase 6 (site vitrine) — déjà fait pour tout ce qui est du code**, comme documenté par la session précédente (17 septembre) dans ce même fichier : mentions légales, CGU, confidentialité, bandeau cookies, SEO, formulaire de contact sécurisé, nettoyage de l'ancien code NestJS/Handlebars, CI. `npm run lint`/`typecheck`/`test` (7/7)/`build` passent.

**Reste sur Phase 6 — nécessite une action ou une décision d'Adrien, pas du code :**
- Adresse de publication et téléphone à fournir pour les mentions légales (LCEN art. 6-III).
- Confirmer les prestataires SMTP et Redis en production sur Vercel, et vérifier réellement l'envoi d'e-mail et la limitation de débit avec ces prestataires réels (le formulaire de contact refuse actuellement d'envoyer en production si Redis est indisponible — comportement sûr par défaut, mais jamais testé en conditions réelles).
- Traduction complète des textes juridiques dans les six langues avant une ouverture internationale (actuellement : référence en français uniquement, avec avertissement de périmètre dans les six langues).
- Vraies captures mobiles pour la page d'accueil — même dépendance que Phase 5.

Aucun de ces points restants n'est du code que je peux écrire à la place d'Adrien : ce sont soit des informations personnelles/professionnelles qu'il doit fournir (adresse, téléphone, comptes Mixpanel/RevenueCat/Apple Developer), soit des vérifications qui nécessitent un compte ou un service réel (SMTP/Redis de production, App Store Connect), soit des captures qui nécessitent une app déjà avancée.
