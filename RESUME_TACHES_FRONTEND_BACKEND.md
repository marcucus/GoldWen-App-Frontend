# 📋 RÉSUMÉ DES TÂCHES FRONTEND ET BACKEND - GoldWen App

**Date de création**: 13 octobre 2025  
**Basé sur**: specifications.md v1.1  
**Documents générés**:
- ✅ TACHES_FRONTEND.md
- ✅ TACHES_BACKEND.md

---

## 🎯 VUE D'ENSEMBLE

Ce document résume l'analyse complète du projet GoldWen et présente les tâches nécessaires pour finaliser le MVP selon les spécifications.

### État actuel du projet
- **Frontend (Flutter)**: 78% de complétude - Infrastructure solide, logique métier à compléter
- **Backend (NestJS/Python)**: 80% de complétude - Architecture modulaire, intégrations critiques manquantes

---

## 📱 FRONTEND - Résumé Exécutif

**Document complet**: [TACHES_FRONTEND.md](./TACHES_FRONTEND.md)

### Temps estimé total: 33-47 jours

### Répartition par priorité

#### 🔥 PRIORITÉ 1 - CRITIQUES (15-20 jours)
- **Module 1**: Gestion des photos de profil
- **Module 2**: Système de prompts textuels
- **Module 3**: Sélection quotidienne et quotas
- **Module 4**: Système de match mutuel
- **Module 5**: Validation profil complet

#### ⚡ PRIORITÉ 2 - IMPORTANTES (10-15 jours)
- **Module 6**: Notifications push
- **Module 7**: Chat avec expiration 24h
- **Module 8**: Page de matches
- **Module 9**: Conformité RGPD
- **Module 10**: Améliorations UX critiques

#### 🔧 PRIORITÉ 3 - OPTIMISATIONS (8-12 jours)
- **Module 11**: Pages additionnelles
- **Module 12**: Système de feedback
- **Module 13**: Optimisations performances
- **Module 14**: Accessibilité

### Routes backend requises

**Routes existantes à utiliser**: 31
- Authentification, Profils, Matching, Chat, Abonnements, etc.

**Nouvelles routes à créer**: 15
- Gestion photos avancée, Matching avancé, RGPD, etc.

**Routes à modifier/enrichir**: 8
- Complétion profil, Quotas usage, etc.

---

## 🖥️ BACKEND - Résumé Exécutif

**Document complet**: [TACHES_BACKEND.md](./TACHES_BACKEND.md)

### Temps estimé total: 59-78 jours (MVP)

### Répartition par priorité

#### 🔥 P0 - CRITIQUES (25-35 jours)
1. **Service de matching Python** (10-15j)
   - Architecture FastAPI
   - Algorithme de compatibilité V1
   - Endpoints de génération de sélection

2. **Cron jobs automatisés** (5-7j)
   - Génération sélection quotidienne (midi)
   - Expiration chats 24h
   - Reset quotas quotidiens
   - Nettoyage automatique

3. **Firebase Cloud Messaging** (5-7j)
   - Configuration FCM
   - Gestion tokens push
   - 5 types de notifications
   - Deep linking

4. **Quotas quotidiens stricts** (3-4j)
   - Table daily_usage
   - QuotaGuard
   - Routes de vérification

5. **RevenueCat** (5-7j)
   - Configuration abonnements
   - Webhooks
   - Synchronisation statut

#### ⚡ P1 - IMPORTANTES (18-25 jours)
6. **Nouvelles routes photos** (2-3j)
7. **Routes prompts** (2j)
8. **Routes matching avancées** (3-4j)
9. **Routes chat avancées** (2-3j)
10. **Routes RGPD** (3-4j)
11. **Système de signalement** (2-3j)
12. **Paramètres notifications** (2j)

#### 🔧 P2 - OPTIMISATIONS (12-18 jours)
13. **Cache Redis** (3-4j)
14. **Pagination** (2-3j)
15. **Rate limiting** (2j)
16. **Logging structuré** (2-3j)
17. **Monitoring** (2j)
18. **Tests unitaires** (5-7j)
19. **Tests d'intégration** (3-5j)
20. **Documentation Swagger** (2-3j)

#### 🌟 P3 - V2 (13-19 jours - Optionnel)
21. **Algorithme matching V2** (10-15j)
22. **Analytics Mixpanel** (3-4j)

---

## 🔗 CORRESPONDANCE FRONTEND ⟷ BACKEND

### 1. Gestion des photos

#### Frontend (Tâche #1.1, #1.2)
- Upload multipart/form-data
- Validation 3 photos minimum
- Drag & drop réorganisation
- Compression côté client

#### Backend requis
✅ Existant:
- `POST /api/v1/profiles/me/photos`
- `DELETE /api/v1/profiles/me/photos/:photoId`

🆕 À créer:
- `PUT /api/v1/profiles/me/photos/:photoId/order`
- `PUT /api/v1/profiles/me/photos/:photoId/primary`
- `GET /api/v1/profiles/completion` (enrichir)

**Backend: Tâche #B6.1** (2-3 jours)

---

### 2. Système de prompts

#### Frontend (Tâche #2.1)
- Interface de sélection
- Validation 3 prompts obligatoires
- Réponses max 150 caractères
- Modification possible

#### Backend requis
✅ Existant:
- `GET /api/v1/profiles/prompts`
- `POST /api/v1/profiles/me/prompt-answers`
- `GET /api/v1/profiles/me`

🆕 À créer:
- `PUT /api/v1/profiles/me/prompt-answers`

**Backend: Tâche #B6.2** (2 jours)

---

### 3. Sélection quotidienne et quotas

#### Frontend (Tâche #3.1, #3.2)
- Affichage "X/Y choix disponibles"
- Blocage si quota atteint
- Bannière upgrade
- Timer prochaine sélection
- Reset quotidien

#### Backend requis
✅ Existant:
- `GET /api/v1/matching/daily-selection`
- `POST /api/v1/matching/choose/:targetUserId`
- `GET /api/v1/subscriptions/usage`

🆕 À créer:
- `GET /api/v1/matching/daily-selection/status`
- `GET /api/v1/matching/user-choices`
- Table `daily_usage`
- Cron job génération sélection (midi)
- Cron job reset quotas (minuit)

**Backend: Tâches critiques**
- #B2.1: Cron jobs (5-7 jours)
- #B4.1: Système quotas (3-4 jours)
- #B6.3: Routes matching (3-4 jours)
- #B1.1: Service Python matching (10-15 jours)

---

### 4. Système de match mutuel

#### Frontend (Tâche #4.1, #4.2)
- Détection match mutuel
- Page "Mes matches"
- Notification de match
- Badge nouveaux matches
- Animation célébration

#### Backend requis
✅ Existant:
- `GET /api/v1/matching/matches`
- `GET /api/v1/matching/matches/:matchId`

🆕 À créer:
- `POST /api/v1/chat/accept/:matchId`
- `GET /api/v1/matching/pending-matches`
- Logique de détection match mutuel
- Notification automatique NEW_MATCH

**Backend: Tâches**
- #B6.3: Routes matching (3-4 jours)
- #B6.4: Routes chat avancées (2-3 jours)
- #B3.1: Firebase notifications (5-7 jours)

---

### 5. Notifications push

#### Frontend (Tâche #6.1)
- Enregistrement token FCM
- Gestion permissions
- Deep linking
- Paramètres notifications

#### Backend requis
✅ Existant:
- Aucune route spécifique

🆕 À créer:
- `POST /api/v1/users/me/push-tokens`
- `DELETE /api/v1/users/me/push-tokens/:tokenId`
- `GET /api/v1/notifications/settings`
- `PUT /api/v1/notifications/settings`
- Configuration Firebase
- Service FCM
- 5 types de notifications
- Cron job notification quotidienne

**Backend: Tâches critiques**
- #B3.1: Firebase Cloud Messaging (5-7 jours)
- #B8.1: Paramètres notifications (2 jours)

---

### 6. Chat avec expiration 24h

#### Frontend (Tâche #7.1)
- Timer visible 24h
- Blocage après expiration
- Message "Conversation expirée"
- Notification 2h avant
- Chats archivés

#### Backend requis
✅ Existant:
- `GET /api/v1/chat/:chatId`
- `POST /api/v1/chat/:chatId/messages`

🆕 À créer:
- `PUT /api/v1/chat/:chatId/expire`
- `GET /api/v1/chat/archived`
- Cron job expiration automatique
- Message système auto-généré
- Notification CHAT_EXPIRING_SOON

**Backend: Tâches**
- #B6.4: Routes chat avancées (2-3 jours)
- #B2.1: Cron job expiration (5-7 jours)

---

### 7. Conformité RGPD

#### Frontend (Tâches #9.1, #9.2, #9.3)
- Modal de consentement
- Page suppression compte
- Export de données
- Politique de confidentialité

#### Backend requis
✅ Existant:
- `DELETE /api/v1/users/me`
- `GET /api/v1/legal/privacy-policy`

🆕 À créer:
- `POST /api/v1/users/consent`
- `POST /api/v1/users/me/export-data`
- `GET /api/v1/users/me/export-data/:exportId`
- `PUT /api/v1/users/me/privacy-settings`
- Table user_consents
- Job asynchrone génération export
- Anonymisation complète lors suppression

**Backend: Tâches critiques**
- #B6.5: Routes RGPD (3-4 jours)

---

### 8. Historique et fonctionnalités premium

#### Frontend (Tâches #11.2, #11.3)
- Historique des sélections
- Page "Qui m'a sélectionné" (premium)
- Filtres par date
- Badge nouveaux likes

#### Backend requis
🆕 À créer:
- `GET /api/v1/matching/history`
- `GET /api/v1/matching/who-liked-me`
- PremiumGuard pour protection
- Filtrage et pagination

**Backend: Tâche #B6.3** (3-4 jours)

---

## 📊 PLANNING RECOMMANDÉ

### Phase 1: MVP Minimal (5-7 semaines)

#### Backend - Sprint 1-2 (10-14 jours)
1. Service de matching Python (10-15j) ← **CRITIQUE**

#### Backend - Sprint 3 (5-7 jours)
2. Cron jobs automatisés (5-7j) ← **CRITIQUE**

#### Backend - Sprint 4 (5-7 jours)
3. Firebase Cloud Messaging (5-7j) ← **CRITIQUE**

#### Backend - Sprint 5 (3-4 jours)
4. Quotas quotidiens stricts (3-4j) ← **CRITIQUE**

#### Backend - Sprint 6 (5-7 jours)
5. RevenueCat (5-7j) ← **CRITIQUE**

**Total Backend Phase 1**: 28-39 jours

#### Frontend - Sprint 1-3 (15-20 jours) - Parallèle
1. Gestion photos (2-3j)
2. Système prompts (3-4j)
3. Sélection quotidienne (3-4j)
4. Match mutuel (3-4j)
5. Validation profil (2j)
6. Notifications push (3-4j)

**Total Frontend Phase 1**: 16-21 jours

### Phase 2: MVP Complet (4-5 semaines)

#### Backend - Sprint 7-8 (12-15 jours)
6. Nouvelles routes frontend (12-15j)

#### Backend - Sprint 9 (3-4 jours)
7. Routes RGPD (3-4j) ← **LÉGALEMENT OBLIGATOIRE**

#### Backend - Sprint 10 (2-3 jours)
8. Système signalement (2-3j)

**Total Backend Phase 2**: 17-22 jours

#### Frontend - Sprint 4-5 (10-15 jours)
7. Chat expiration 24h (2-3j)
8. Page matches (2-3j)
9. Conformité RGPD (4-6j)
10. Améliorations UX (2-3j)

**Total Frontend Phase 2**: 10-15 jours

### Phase 3: Optimisations (2-3 semaines)

#### Backend - Sprint 11-12 (12-18 jours)
9. Cache Redis (3-4j)
10. Rate limiting (2j)
11. Logging & monitoring (4-5j)
12. Tests (8-12j)

#### Frontend - Sprint 6 (8-12 jours)
11. Pages additionnelles (4-6j)
12. Optimisations performances (2-3j)
13. Accessibilité (2-3j)

---

## 📈 ESTIMATION TOTALE

### MVP Minimal (Phase 1)
- **Backend**: 28-39 jours (6-8 semaines)
- **Frontend**: 16-21 jours (3-4 semaines)
- **En parallèle**: ~6-8 semaines

### MVP Complet (Phase 1 + 2)
- **Backend**: 45-61 jours (9-12 semaines)
- **Frontend**: 26-36 jours (5-7 semaines)
- **En parallèle**: ~9-12 semaines

### Avec Optimisations (Phase 1 + 2 + 3)
- **Backend**: 57-79 jours (11-16 semaines)
- **Frontend**: 34-48 jours (7-10 semaines)
- **En parallèle**: ~11-16 semaines

---

## 🎯 RECOMMANDATIONS STRATÉGIQUES

### Ordre de priorité absolu

1. **Backend: Service de matching Python** (10-15j)
   - Bloquant pour toutes les fonctionnalités de sélection quotidienne
   - Développement en parallèle possible avec frontend

2. **Backend: Cron jobs + Quotas** (8-11j)
   - Critiques pour le fonctionnement quotidien
   - Dépendent du service de matching

3. **Backend: Firebase + RevenueCat** (10-14j)
   - Notifications essentielles pour l'engagement
   - Monétisation critique pour le business model

4. **Frontend: Logique métier core** (15-20j)
   - Photos, prompts, sélection quotidienne
   - Peut commencer pendant développement backend

5. **Backend: Nouvelles routes** (12-15j)
   - Support des fonctionnalités frontend
   - Développement itératif selon besoins frontend

6. **RGPD (Backend + Frontend)** (7-10j)
   - Légalement obligatoire avant lancement
   - Ne pas négliger

### Stratégie de développement recommandée

#### Option 1: Séquentielle (Plus sûre)
1. Backend Phase 1 complet (28-39j)
2. Frontend Phase 1 (16-21j)
3. Backend Phase 2 (17-22j)
4. Frontend Phase 2 (10-15j)
5. Phase 3 en parallèle (12-18j)

**Total**: 83-115 jours (17-23 semaines)

#### Option 2: Parallèle (Plus rapide)
1. Backend Service Matching + Frontend Infrastructure (en parallèle, 10-15j)
2. Backend Cron jobs/Quotas + Frontend Logique métier (en parallèle, 8-20j)
3. Backend FCM/RevenueCat + Frontend Notifications (en parallèle, 10-14j)
4. Backend Routes nouvelles + Frontend Intégration (en parallèle, 12-15j)
5. RGPD complet (Backend + Frontend, 7-10j)
6. Phase 3 optimisations (12-18j)

**Total**: 59-92 jours (12-18 semaines)

### Ressources recommandées

#### Équipe minimale
- 1 Développeur Backend senior (NestJS + Python)
- 1 Développeur Frontend senior (Flutter)
- 1 DevOps pour infrastructure (part-time)
- 1 QA pour tests (part-time)

#### Équipe optimale
- 2 Développeurs Backend (1 NestJS + 1 Python)
- 1 Développeur Frontend (Flutter)
- 1 DevOps (part-time)
- 1 QA (part-time)
- 1 Product Owner / Chef de projet

---

## 📝 DOCUMENTS DÉTAILLÉS

Pour les détails complets de chaque tâche :

- **[TACHES_FRONTEND.md](./TACHES_FRONTEND.md)** : 28 tâches frontend organisées en 14 modules
- **[TACHES_BACKEND.md](./TACHES_BACKEND.md)** : 22 tâches backend organisées en 14 modules

Chaque tâche inclut :
- ✅ Estimation temporelle
- ✅ Niveau de priorité
- ✅ État actuel du code
- ✅ Fichiers concernés
- ✅ Fonctionnalités détaillées
- ✅ Routes API avec exemples
- ✅ Critères d'acceptation

---

## ✅ CHECKLIST DE LANCEMENT MVP

### Backend
- [ ] Service de matching Python déployé
- [ ] Cron jobs configurés et testés
- [ ] Firebase Cloud Messaging fonctionnel
- [ ] Quotas quotidiens appliqués
- [ ] RevenueCat intégré et testé
- [ ] Toutes les routes frontend créées
- [ ] Routes RGPD complètes
- [ ] Tests unitaires >80% coverage
- [ ] Documentation Swagger complète
- [ ] Monitoring en place

### Frontend
- [ ] Upload photos fonctionnel (3 min)
- [ ] Système prompts complet (3 obligatoires)
- [ ] Sélection quotidienne avec quotas
- [ ] Match mutuel opérationnel
- [ ] Chat avec expiration 24h
- [ ] Notifications push configurées
- [ ] Conformité RGPD complète
- [ ] États de chargement cohérents
- [ ] Gestion d'erreurs robuste
- [ ] Tests manuels réussis

### Légal & Conformité
- [ ] Politique de confidentialité rédigée
- [ ] CGU rédigées
- [ ] Consentement utilisateur en place
- [ ] Export de données fonctionnel
- [ ] Suppression compte avec anonymisation
- [ ] Vérification conformité RGPD

### DevOps & Infrastructure
- [ ] Environnements staging/production séparés
- [ ] CI/CD configuré
- [ ] Backups automatiques
- [ ] Monitoring et alertes
- [ ] Logs centralisés
- [ ] Rate limiting en production

---

**Document généré le 13 octobre 2025**  
**Analyse complète basée sur specifications.md v1.1**

**Prochaines étapes** :
1. Validation de l'équipe technique
2. Priorisation finale avec le Product Owner
3. Planification des sprints
4. Attribution des tâches aux développeurs
5. Début du développement !

---

**Contact** :
Pour toute question sur ce plan de développement, consulter les documents détaillés ou contacter le chef de projet.
