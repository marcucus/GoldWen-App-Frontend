# Rapport d'Audit Professionnel — GoldWen MVP
**Date :** 18 mai 2026 | **Version :** 1.0  
**Scope :** GoldWen-App-Backend · GoldWen-App-Frontend · GoldWen-app-web  
**Objectif :** Liste exhaustive des correctifs, refactorisations et développements manquants pour atteindre 100% du MVP livrable en production.

---

## Context

GoldWen est une application de rencontre "slow dating" (dating sans swipe, 3-5 profils/jour, chat éphémère 24h, freemium via GoldWen Plus). Le MVP est défini dans `specifications.md` partagé sur les 3 repos.

L'analyse porte sur 3 dépôts interconnectés :
- **Backend** : NestJS/TypeScript, PostgreSQL, Redis, Socket.IO, RevenueCat
- **Frontend** : Flutter/Dart, GoRouter, Provider, Firebase, RevenueCat
- **Web** : Next.js 14, Tailwind CSS, next-i18next (6 langues)

---

## État Global — Scorecard

| Repo | Complétion | Statut | Bloquants prod |
|------|-----------|--------|----------------|
| **Backend** | ~75% | Beta-ready (non prod) | 6 bloquants critiques |
| **Frontend** | ~55-60% | Dev avancé (non prod) | Fonctionnalités MVP incomplètes |
| **Web** | ~80% | Quasi prêt | 5 strings hardcodées, liens morts |

---

## PHASE 1 — BLOQUANTS CRITIQUES (P0)
> À corriger AVANT tout déploiement beta. Sécurité ou données corrompues.

### Backend — P0

#### B-P0-1 · CORS wildcard ouvert
- **Fichier :** `main-api/src/main.ts` — `app.enableCors({ origin: '*' })`
- **Risque :** N'importe quel site web peut appeler l'API (CSRF, vol de tokens)
- **Fix :** Remplacer par `origin: [process.env.FRONTEND_URL, process.env.WEB_URL]`

#### B-P0-2 · TypeORM `synchronize: true` en production
- **Fichier :** `main-api/src/app.module.ts` — `TypeOrmModule.forRoot({ synchronize: true })`
- **Risque :** Au redémarrage en prod, TypeORM peut supprimer/recréer des tables = perte de données
- **Fix :** `synchronize: false` + utiliser uniquement les migrations

#### B-P0-3 · JWT secret avec fallback faible
- **Fichier :** `main-api/src/config/` — `secret: process.env.JWT_SECRET || 'your-super-secret-jwt-key'`
- **Risque :** Si la variable d'env est absente, tous les tokens sont signés avec une clé connue
- **Fix :** Supprimer le fallback, lancer une exception au démarrage si `JWT_SECRET` absent

#### B-P0-4 · Secrets hardcodés dans docker-compose.yml
- **Fichier :** `docker-compose.yml` — mots de passe Postgres, clé API matching service
- **Risque :** Secrets committés dans le repo git
- **Fix :** Passer par `.env` (git-ignoré), référencer `${VAR}` dans docker-compose

#### B-P0-5 · Stockage fichiers local (pas de cloud storage)
- **Fichier :** Upload service — stockage dans `./uploads` local
- **Risque :** Photos perdues au redéploiement, non compatible multi-instances
- **Fix :** Intégrer AWS S3 (ou GCS) + CDN pour la livraison des images

#### B-P0-6 · Utilisateur Docker non-root commenté
- **Fichier :** `Dockerfile.api` lignes 29-34 — bloc `USER nestjs` commenté
- **Risque :** Container tourne en root = escalade de privilèges si compromis
- **Fix :** Décommenter le bloc non-root user

---

### Web — P0

#### W-P0-1 · 5 strings hardcodées en français (mobile menu)
- **Fichier :** `components/Layout.tsx` lignes 293, 336, 358, 360, 382
- **Strings :** "Navigation", "Paramètres", "Téléchargez l'App", "Commencez votre voyage...", "Bientôt disponible sur"
- **Fix :** Ajouter les clés dans `public/locales/*/common.json` sous `nav.mobile.*` + utiliser `t()` dans Layout.tsx

#### W-P0-2 · Liens App Store / Google Play cassés
- **Fichier :** `pages/index.tsx` — boutons CTA avec `href="#"`
- **Risque :** Aucun utilisateur ne peut télécharger l'app depuis le site vitrine
- **Fix :** Renseigner les vraies URLs App Store et Google Play (ou désactiver visuellement avec badge "Bientôt")

---

## PHASE 2 — HAUTE PRIORITÉ (P1)
> Fonctionnalités MVP manquantes ou gaps sécurité importants. Obligatoires avant beta publique.

### Backend — P1

#### B-P1-1 · Absence de CI/CD
- **Impact :** Aucun test automatisé avant déploiement, risque de régression élevé
- **Fix :** Créer `.github/workflows/ci.yml` avec : lint → test → build → docker push

#### B-P1-2 · Absence de refresh token
- **Fichier :** `modules/auth/` — seul un access token 24h est émis
- **Impact :** Expérience dégradée (déconnexion toutes les 24h), no security rotation
- **Fix :** Implémenter refresh token (7 jours) + rotation à chaque usage + révocation

#### B-P1-3 · Absence de Helmet (security headers)
- **Fichier :** `main.ts`
- **Headers manquants :** X-Content-Type-Options, X-Frame-Options, HSTS, CSP
- **Fix :** `npm install @nestjs/helmet` + `app.use(helmet())` dans main.ts

#### B-P1-4 · Rate limiting non distribué (pas Redis-backed)
- **Fichier :** `main.ts` + throttle config
- **Impact :** Bypass facile via rotation d'IP, ne scale pas multi-instances
- **Fix :** `@nestjs/throttler` avec `ThrottlerStorageRedisService`

#### B-P1-5 · 81 `console.log` en code production
- **Impact :** Logs non structurés, fuite potentielle d'informations sensibles
- **Fix :** Remplacer par `this.logger.log/warn/error` (Logger NestJS déjà configuré) — opération `grep -r "console.log" src/ --include="*.ts"` puis remplacement systématique

#### B-P1-6 · Notification quotidienne à midi non timezone-aware
- **Fichier :** `modules/cron-jobs/matching.scheduler.ts` — TODO commenté
- **Impact :** Spec §4.2 : "notification à midi heure locale" — non respecté
- **Fix :** Stocker le fuseau horaire utilisateur en profil, scheduler adapté ou envoi à midi UTC avec offset stocké

#### B-P1-7 · Endpoint admin sans vérification de rôle
- **Fichier :** `modules/notifications/notifications.controller.ts` — TODO commenté `// TODO: Add admin role check here`
- **Fix :** Ajouter `@Roles(UserRole.ADMIN)` + `@UseGuards(RolesGuard)` sur les endpoints concernés

#### B-P1-8 · Pas de stratégie de backup base de données
- **Impact :** Perte totale possible en cas de crash
- **Fix :** Documenter + implémenter backup automatique (pg_dump via cron ou managed DB snapshots)

---

### Frontend Flutter — P1

#### F-P1-1 · Refresh quotidien de la sélection non implémenté
- **Fichier :** `lib/features/home/` — `HomePage`
- **Spec §4.2 :** Sélection reset à midi chaque jour
- **Fix :** Implémenter un timer/listener qui vérifie l'heure locale au foreground, vide la selection si date changée + appel `GET /api/v1/matching/daily-selection`

#### F-P1-2 · TODO critiques dans AdvancedRecommendationsPage
- **Fichier :** `lib/features/matching/advanced_recommendations_page.dart`
- **Code :** `personalityAnswers: {}, // TODO: Get from user profile` + `preferences: {}, // TODO`
- **Fix :** Lire depuis `UserProvider` et `PreferencesProvider` déjà disponibles

#### F-P1-3 · WebSocket — reconnexion limitée à 3 tentatives puis abandon
- **Fichier :** `lib/services/websocket_service.dart`
- **Impact :** Chat coupé silencieusement après 3 déconnexions réseau
- **Fix :** Reconnexion exponentielle illimitée (1s → 2s → 4s → max 30s) avec indicateur visuel "Reconnexion..."

#### F-P1-4 · Emoji picker non intégré dans le chat
- **Fichier :** `lib/features/chat/chat_page.dart`
- **Spec §4.3 :** "Le chat permet l'envoi de messages texte et d'emojis"
- **Dépendance :** `emoji_picker_flutter` déjà dans pubspec.yaml — non utilisée
- **Fix :** Ajouter bouton emoji + panneau picker sous le TextField du chat

#### F-P1-5 · Différenciation Free vs Plus non connectée à l'UI
- **Fichier :** `lib/features/home/home_page.dart` / daily selection
- **Spec §4.2 :** Free = 1 choix/jour, Plus = 3 choix/jour
- **Fix :** Lire `SubscriptionProvider.isPlus` → limiter le bouton "Choisir" (désactiver après N choix)

#### F-P1-6 · Plans d'abonnement en mock hardcodé (fallback dev)
- **Fichier :** `lib/features/subscription/subscription_page.dart`
- **Impact :** En dev/test sans RevenueCat configuré, les faux plans peuvent être présentés à des vrais utilisateurs
- **Fix :** Conditionner le fallback mock à `kDebugMode` uniquement

#### F-P1-7 · Drag & drop photos non testé / potentiellement cassé
- **Fichier :** `lib/features/profile/photo_management_page.dart`
- **Fix :** Tester sur iOS et Android, corriger le `ReorderableListView` si nécessaire

#### F-P1-8 · Timezone push notifications locales non utilisée
- **Fichier :** `lib/services/custom_notification_manager.dart`
- **Impact :** Notification "sélection prête" ne se déclenche pas à midi heure locale
- **Fix :** Utiliser le package `timezone` déjà importé avec `tz.TZDateTime.from(noonLocal, location)`

---

### Web — P1

#### W-P1-1 · Langue PT absente de la détection navigateur
- **Fichier :** `lib/useBrowserLanguageDetection.ts` ligne 4
- **Fix :** Ajouter `'pt'` à `supportedLocales: ['fr', 'en', 'es', 'de', 'it', 'pt']`

#### W-P1-2 · Sitemap.xml incomplet (3 pages manquantes)
- **Fichier :** `public/sitemap.xml` — contient 4 URLs, manque /support, /contact, /confidentialite, /conditions, /mentions-legales
- **Fix :** Ajouter les 5 pages manquantes avec `priority` et `lastmod` appropriés

#### W-P1-3 · Absence de hreflang pour le SEO international
- **Fichier :** `components/Layout.tsx` — section `<Head>`
- **Impact :** Google ne sait pas quelle version linguistique indexer pour quel pays
- **Fix :** Générer dynamiquement les balises `<link rel="alternate" hreflang="fr" href="https://goldwen.app/fr/..." />` pour les 6 langues

#### W-P1-4 · Pages d'erreur 404 et 500 manquantes
- **Fichiers à créer :** `pages/404.tsx`, `pages/500.tsx`
- **Fix :** Pages branded GoldWen avec lien retour accueil

#### W-P1-5 · Formulaire de contact sans backend
- **Fichier :** `pages/contact.tsx` — lien mailto seulement, aucun formulaire
- **Fix :** Implémenter un formulaire avec `pages/api/contact.ts` → envoi email via le service mail du backend (ou Resend/SendGrid)

---

## PHASE 3 — PRIORITÉ MOYENNE (P2)
> Qualité production, UX manquante, dette technique. Obligatoire avant lancement public large.

### Backend — P2

#### B-P2-1 · 246 usages de `any` TypeScript
- **Fix :** Remplacer progressivement par des types explicites — commencer par les services core (auth, matching, chat)

#### B-P2-2 · Absence de tests E2E sur les flux critiques
- **Flux manquants :** signup complet → questionnaire → matching → chat → subscription
- **Fix :** Ajouter tests E2E avec supertest/Jest pour ces 5 flux

#### B-P2-3 · Socket.IO sans Redis adapter (non scalable multi-instances)
- **Fichier :** `modules/chat/chat.gateway.ts`
- **Impact :** Avec 2+ instances, les messages ne sont pas broadcastés cross-instance
- **Fix :** `@nestjs/platform-socket.io` + `socket.io-redis` adapter

#### B-P2-4 · Modèle de matching externe sans timeout ni circuit-breaker
- **Fichier :** `modules/matching/matching-integration.service.ts`
- **Fix :** Ajouter `timeout: 10000` sur les appels HTTP + pattern circuit-breaker (ex: `opossum`)

#### B-P2-5 · Swagger/OpenAPI incomplet
- **Fix :** Compléter les `@ApiOperation`, `@ApiResponse`, `@ApiBody` manquants sur tous les endpoints

#### B-P2-6 · Politique de rétention des données non définie
- **Impact :** RGPD — les données doivent avoir une durée de vie définie
- **Fix :** Implémenter un cron job de nettoyage : comptes inactifs >2 ans, messages archivés >6 mois, notifications >3 mois

---

### Frontend Flutter — P2

#### F-P2-1 · Suppression de message (UI manquante)
- **Fichier :** `lib/features/chat/chat_page.dart`
- **API :** Endpoint de suppression existe côté backend
- **Fix :** Ajouter long-press sur message → menu contextuel → "Supprimer"

#### F-P2-2 · Indicateur de force du profil absent
- **Spec implicite :** Guidage utilisateur pour compléter son profil
- **Fix :** Progress indicator (photos: 3/6, prompts: 2/3, questionnaire: 10/10) sur la page profil

#### F-P2-3 · Détail du score de compatibilité non affiché
- **Fichier :** `lib/features/matching/profile_detail_page.dart`
- **Fix :** Afficher le breakdown (valeurs, personnalité, proximité) si disponible dans la réponse API

#### F-P2-4 · Notification granulaire (on/off par catégorie) incomplète
- **Fichier :** `lib/features/settings/settings_page.dart`
- **Fix :** Exposer les préférences par type (matches, messages, daily_selection) via `NotificationPreferencesProvider`

#### F-P2-5 · Page de bienvenue sans animation de chargement (shimmer)
- **Dépendance :** `shimmer` déjà dans pubspec.yaml
- **Fix :** Ajouter shimmer skeleton sur les cards de profil pendant le chargement API

#### F-P2-6 · Réduction des animations absente (accessibilité)
- **Fichier :** `lib/services/accessibility_service.dart` — toggle existe mais non appliqué
- **Fix :** Conditionner les animations sur `AccessibilityService.reduceMotion`

---

### Web — P2

#### W-P2-1 · Stats dynamiques hardcodées
- **Fichier :** `components/Layout.tsx` footer — "10K+ Utilisateurs", "4.9★", "95%"
- **Fix :** Rendre configurables via env vars ou `lib/app-service.ts`

#### W-P2-2 · Absence de service worker (PWA)
- **Fix :** `next-pwa` ou manifest service worker pour cache offline des assets statiques

#### W-P2-3 · Alt text vide sur logos dans le footer
- **Fichier :** `components/Layout.tsx` — `<img alt="">`
- **Fix :** `alt="GoldWen"` sur tous les logos non-décoratifs

#### W-P2-4 · Balise canonical manquante pour les locales
- **Fix :** La canonical actuelle pointe sur le path sans locale prefix — ajouter `/{locale}` dans l'URL canonique

---

## PHASE 4 — DETTE TECHNIQUE & AMÉLIORATIONS (P3)
> Post-lancement, amélioration continue.

### Backend — P3

- Migrer vers secrets manager (AWS Secrets Manager ou Vault) pour les clés API
- Mettre en place Kubernetes + Helm charts pour le déploiement cloud
- Ajouter Prometheus metrics + Grafana dashboards
- Implémenter 2FA (TOTP via `otpauth`)
- Centraliser les logs (ELK ou CloudWatch)
- Load testing avec k6 ou Artillery

### Frontend Flutter — P3

- Implémenter le partage de médias dans le chat (images)
- Message reactions (emoji)
- Recherche dans la liste des chats
- Profils audio/vidéo (V2 specs)
- Onboarding tutoriel animé (première connexion)
- Indicateur "vu" sur les messages (double tick)

### Web — P3

- Mettre en place A/B testing (Vercel Edge Config)
- Section témoignages/reviews utilisateurs
- Blog marketing (articles SEO)
- Tracking conversions App Store (via SKAdNetwork link / branch.io)

---

## Récapitulatif — Vue Complète Par Fichier

### Fichiers Backend à modifier (prioritaires)

| Fichier | Changements | Priorité |
|---------|-------------|----------|
| `main-api/src/main.ts` | Fix CORS + ajouter Helmet | P0 |
| `main-api/src/app.module.ts` | `synchronize: false` | P0 |
| `main-api/src/config/*.ts` | Supprimer fallback JWT_SECRET | P0 |
| `docker-compose.yml` | Passer les secrets en variables `.env` | P0 |
| `Dockerfile.api` | Décommenter USER nestjs | P0 |
| `modules/auth/auth.service.ts` | Implémenter refresh token + rotation | P1 |
| `modules/notifications/notifications.controller.ts` | Ajouter @Roles(ADMIN) guard | P1 |
| `modules/cron-jobs/matching.scheduler.ts` | Timezone-aware scheduling | P1 |
| `modules/chat/chat.gateway.ts` | Ajouter Redis adapter Socket.IO | P2 |
| `modules/matching/matching-integration.service.ts` | Timeout + circuit-breaker | P2 |
| `.github/workflows/ci.yml` | Créer pipeline CI/CD | P1 |

### Fichiers Frontend à modifier (prioritaires)

| Fichier | Changements | Priorité |
|---------|-------------|----------|
| `lib/features/home/home_page.dart` | Daily refresh + Free/Plus gate | P1 |
| `lib/features/matching/advanced_recommendations_page.dart` | Supprimer TODO, lire les providers | P1 |
| `lib/services/websocket_service.dart` | Reconnexion exponentielle | P1 |
| `lib/features/chat/chat_page.dart` | Intégrer emoji_picker + suppression | P1/P2 |
| `lib/features/subscription/subscription_page.dart` | Conditionner mock à kDebugMode | P1 |
| `lib/services/custom_notification_manager.dart` | Fix timezone notifications | P1 |
| `lib/features/profile/photo_management_page.dart` | Tester/fixer drag & drop | P1 |

### Fichiers Web à modifier (prioritaires)

| Fichier | Changements | Priorité |
|---------|-------------|----------|
| `components/Layout.tsx` | Fix 5 strings FR hardcodées + hreflang | P0/P1 |
| `lib/useBrowserLanguageDetection.ts` | Ajouter 'pt' | P1 |
| `pages/index.tsx` | Fix liens App Store/Google Play | P0 |
| `public/sitemap.xml` | Ajouter les 5 pages manquantes | P1 |
| `public/locales/*/common.json` | Ajouter clés `nav.mobile.*` | P0 |
| `pages/404.tsx` | Créer | P1 |
| `pages/500.tsx` | Créer | P1 |
| `pages/api/contact.ts` | Créer handler formulaire contact | P1 |

---

## Roadmap d'Implémentation Recommandée

### Sprint 1 — 1 semaine (Bloquants sécurité + données)
1. B-P0-1 à B-P0-6 (sécurité backend)
2. W-P0-1 (strings hardcodées) (a voir si c'est normal car l'appli n'est pas encore sortie)
3. W-P0-2 (liens morts App Store) (normal l'appli n'est pas encore sortie donc pas de lien)

### Sprint 2 — 2 semaines (Fonctionnalités MVP manquantes)
1. B-P1-1 (CI/CD)
2. B-P1-2 (refresh token)
3. B-P1-3 à B-P1-5 (Helmet, rate limiting distribué, console.log)
4. F-P1-1 (daily refresh Flutter)
5. F-P1-2 (TODO matching page)
6. F-P1-3 (WebSocket reconnexion)
7. F-P1-4 (emoji chat)
8. F-P1-5 (Free vs Plus gate)

### Sprint 3 — 1 semaine (Web production-ready)
1. W-P1-1 à W-P1-5 (PT detection, sitemap, hreflang, 404/500, contact form)
2. B-P1-6 à B-P1-8 (timezone notifs, admin role, backup DB)

### Sprint 4 — 2 semaines (Qualité + dette)
1. P2 Backend (tests E2E, Socket.IO Redis, circuit-breaker)
2. P2 Frontend (shimmer, profil strength, score détail)
3. P2 Web (stats dynamiques, alt text)

### Sprint 5+ — Continu
1. Items P3 selon priorité business

---

## Estimation de Complétion Post-Corrections

| Repo | Avant | Après Sprint 1-2 | Après Sprint 1-4 |
|------|-------|------------------|------------------|
| Backend | 75% | 88% | 95% |
| Frontend | 57% | 72% | 87% |
| Web | 80% | 92% | 98% |
| **Global** | **~70%** | **~84%** | **~93%** |
