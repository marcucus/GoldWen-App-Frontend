# 📚 INDEX DES DOCUMENTS DE TÂCHES - GoldWen App

**Date de création**: 13 octobre 2025  
**Objectif**: Établir les tâches à effectuer pour le frontend et le backend selon specifications.md

---

## 📋 Documents Créés

| Document | Taille | Lignes | Pour qui ? | Contenu |
|----------|--------|--------|------------|---------|
| **[TACHES_FRONTEND.md](./TACHES_FRONTEND.md)** | 38KB | 1348 | Développeurs Flutter, PM Frontend | 28 tâches frontend avec routes backend |
| **[TACHES_BACKEND.md](./TACHES_BACKEND.md)** | 43KB | 1637 | Développeurs Backend, DevOps | 22 tâches backend avec exemples de code |
| **[RESUME_TACHES_FRONTEND_BACKEND.md](./RESUME_TACHES_FRONTEND_BACKEND.md)** | 15KB | 553 | Product Owner, Management | Vue d'ensemble et correspondances |
| **[GUIDE_UTILISATION_TACHES.md](./GUIDE_UTILISATION_TACHES.md)** | 12KB | 470 | Toute l'équipe | Guide d'utilisation pratique |

**Total**: 108KB, 4008 lignes de documentation technique détaillée

---

## 🚀 Par Où Commencer ?

### 👔 Product Owner / Chef de Projet
1. ✅ Lire [RESUME_TACHES_FRONTEND_BACKEND.md](./RESUME_TACHES_FRONTEND_BACKEND.md) (15 min)
2. ✅ Consulter la section "PLANNING RECOMMANDÉ"
3. ✅ Valider les priorités avec l'équipe technique
4. ✅ Planifier les premiers sprints

### 💻 Développeur Backend
1. ✅ Lire [RESUME_TACHES_FRONTEND_BACKEND.md](./RESUME_TACHES_FRONTEND_BACKEND.md) - Vue d'ensemble (10 min)
2. ✅ Ouvrir [TACHES_BACKEND.md](./TACHES_BACKEND.md) - Détails techniques (30 min)
3. ✅ Commencer par les tâches P0 :
   - #B1.1: Service Python Matching (10-15j) ← **PRIORITÉ ABSOLUE**
   - #B2.1: Cron jobs (5-7j)
   - #B3.1: Firebase Cloud Messaging (5-7j)
4. ✅ Consulter [GUIDE_UTILISATION_TACHES.md](./GUIDE_UTILISATION_TACHES.md) pour les bonnes pratiques

### 📱 Développeur Frontend
1. ✅ Lire [RESUME_TACHES_FRONTEND_BACKEND.md](./RESUME_TACHES_FRONTEND_BACKEND.md) - Vue d'ensemble (10 min)
2. ✅ Ouvrir [TACHES_FRONTEND.md](./TACHES_FRONTEND.md) - Détails techniques (30 min)
3. ✅ Commencer par les tâches 🔥 Critiques :
   - #1.1: Gestion photos (2-3j)
   - #2.1: Système prompts (3-4j)
   - #3.1: Quotas de sélection (3-4j)
4. ✅ Vérifier les routes backend requises pour chaque tâche

### 🛠️ DevOps
1. ✅ Lire [TACHES_BACKEND.md](./TACHES_BACKEND.md) sections :
   - Module 2: Cron jobs (pour scheduling)
   - Module 3: Firebase (pour configuration)
   - Module 9-10: Monitoring et logging
2. ✅ Préparer l'infrastructure pour :
   - Service Python FastAPI séparé
   - Redis pour le cache
   - Firebase Cloud Messaging
   - RevenueCat webhooks

---

## 📊 Résumé des Estimations

### Frontend
| Priorité | Tâches | Temps |
|----------|--------|-------|
| 🔥 Priorité 1 (Critiques) | 10 | 15-20 jours |
| ⚡ Priorité 2 (Importantes) | 10 | 10-15 jours |
| 🔧 Priorité 3 (Optimisations) | 8 | 8-12 jours |
| **TOTAL** | **28** | **33-47 jours** |

### Backend
| Priorité | Tâches | Temps |
|----------|--------|-------|
| 🔥 P0 (Critiques MVP) | 5 | 25-35 jours |
| ⚡ P1 (Importantes) | 8 | 18-25 jours |
| 🔧 P2 (Optimisations) | 7 | 12-18 jours |
| 🌟 P3 (V2 - Optionnel) | 2 | 13-19 jours |
| **TOTAL MVP** | **20** | **55-78 jours** |

### En Parallèle
- **MVP Minimal** (Phase 1): 6-8 semaines
- **MVP Complet** (Phase 1+2): 9-12 semaines
- **Avec Optimisations** (Phase 1+2+3): 11-16 semaines

---

## 🎯 Tâches Critiques Prioritaires

### Backend - À démarrer IMMÉDIATEMENT

#### 1. Service de Matching Python (#B1.1)
**Estimation**: 10-15 jours  
**Bloquant pour**: Toutes les fonctionnalités de sélection quotidienne  
**Contenu**:
- Architecture FastAPI
- Algorithme de compatibilité V1 (filtrage par contenu)
- Endpoints de génération de sélection

👉 **[Voir détails dans TACHES_BACKEND.md ligne 43-264](./TACHES_BACKEND.md#module-1--service-de-matching-python)**

#### 2. Cron Jobs Automatisés (#B2.1)
**Estimation**: 5-7 jours  
**Dépend de**: #B1.1  
**Contenu**:
- Génération sélection quotidienne à midi
- Expiration automatique chats 24h
- Reset quotas quotidiens
- Nettoyage automatique données

👉 **[Voir détails dans TACHES_BACKEND.md ligne 266-415](./TACHES_BACKEND.md#module-2--cron-jobs-et-automatisations)**

#### 3. Firebase Cloud Messaging (#B3.1)
**Estimation**: 5-7 jours  
**Contenu**:
- Configuration Firebase
- 5 types de notifications push
- Gestion des tokens FCM
- Deep linking

👉 **[Voir détails dans TACHES_BACKEND.md ligne 417-600](./TACHES_BACKEND.md#module-3--firebase-cloud-messaging-notifications-push)**

### Frontend - Peut démarrer en parallèle

#### 1. Gestion des Photos (#1.1, #1.2)
**Estimation**: 3-4 jours total  
**État**: ✅ UI déjà implémentée (drag & drop), backend à finaliser  
**Contenu**:
- Upload multipart/form-data
- Compression côté client
- Validation 3 photos minimum

👉 **[Voir détails dans TACHES_FRONTEND.md ligne 37-159](./TACHES_FRONTEND.md#module-1--gestion-des-photos-de-profil)**

#### 2. Système de Prompts (#2.1)
**Estimation**: 3-4 jours  
**État**: 🚨 À créer  
**Contenu**:
- Interface de sélection
- Validation 3 prompts obligatoires
- Réponses max 150 caractères

👉 **[Voir détails dans TACHES_FRONTEND.md ligne 161-266](./TACHES_FRONTEND.md#module-2--système-de-prompts-textuels)**

---

## 🔗 Correspondances Clés Frontend ⟷ Backend

### 1. Sélection Quotidienne
- **Frontend**: Tâche #3.1, #3.2 (6-6 jours)
- **Backend**: Tâches #B1.1, #B2.1, #B4.1, #B6.3 (21-30 jours)
- **Routes**: 
  - `GET /api/v1/matching/daily-selection`
  - `POST /api/v1/matching/choose/:targetUserId`
  - `GET /api/v1/subscriptions/usage`
  - `GET /api/v1/matching/daily-selection/status` (nouvelle)

### 2. Match Mutuel et Chat
- **Frontend**: Tâche #4.1, #4.2 (4-6 jours)
- **Backend**: Tâches #B6.3, #B6.4 (5-7 jours)
- **Routes**:
  - `GET /api/v1/matching/matches`
  - `POST /api/v1/chat/accept/:matchId` (nouvelle)
  - `GET /api/v1/matching/pending-matches` (nouvelle)

### 3. Notifications Push
- **Frontend**: Tâche #6.1 (3-4 jours)
- **Backend**: Tâches #B3.1, #B8.1 (7-9 jours)
- **Routes**:
  - `POST /api/v1/users/me/push-tokens` (nouvelle)
  - `GET /api/v1/notifications/settings` (nouvelle)

### 4. Conformité RGPD
- **Frontend**: Tâches #9.1, #9.2, #9.3 (4-6 jours)
- **Backend**: Tâche #B6.5 (3-4 jours)
- **Routes**:
  - `POST /api/v1/users/consent` (nouvelle)
  - `POST /api/v1/users/me/export-data` (nouvelle)
  - `DELETE /api/v1/users/me` (existante à enrichir)

👉 **[Voir toutes les correspondances dans RESUME ligne 107-294](./RESUME_TACHES_FRONTEND_BACKEND.md#-correspondance-frontend--backend)**

---

## 📖 Navigation Rapide

### Rechercher une Fonctionnalité

```bash
# Rechercher dans tous les documents
grep -i "photos" TACHES_*.md RESUME_*.md

# Rechercher une route spécifique
grep -r "/api/v1/profiles/me/photos" .

# Lister toutes les tâches critiques
grep "🔥" TACHES_*.md | grep "Tâche"

# Voir les estimations totales
grep -A 5 "ESTIMATION" RESUME_*.md
```

### Filtrer par Priorité

```bash
# Backend P0
grep -A 10 "🔥 P0" TACHES_BACKEND.md

# Frontend Priorité 1
grep -A 10 "🔥 PRIORITÉ 1" TACHES_FRONTEND.md

# Toutes les tâches importantes
grep "⚡" TACHES_*.md
```

---

## 📚 Documents de Référence

En complément de ces documents de tâches, consulter :

1. **[specifications.md](./specifications.md)** - Cahier des charges complet (v1.1)
2. **[API_ROUTES_DOCUMENTATION.md](./API_ROUTES_DOCUMENTATION.md)** - Documentation API existante
3. **[FRONTEND_FEATURES_ANALYSIS.md](./FRONTEND_FEATURES_ANALYSIS.md)** - Analyse détaillée du code frontend
4. **[PROJECT_ANALYSIS_SUMMARY.md](./PROJECT_ANALYSIS_SUMMARY.md)** - Analyse globale du projet
5. **[MISSING_FEATURES_ISSUES.md](./MISSING_FEATURES_ISSUES.md)** - Issues détaillées (ancien format)

---

## ✅ Checklist Avant de Commencer

### Pour l'Équipe Complète
- [ ] Tous les documents lus et compris
- [ ] Priorités validées par le Product Owner
- [ ] Dépendances identifiées (frontend ⟷ backend)
- [ ] Environnements de développement prêts
- [ ] Premier sprint planifié

### Pour le Backend
- [ ] PostgreSQL configuré
- [ ] Environnement Python (FastAPI) préparé
- [ ] Firebase projet créé
- [ ] RevenueCat compte créé
- [ ] Redis installé (pour cache)

### Pour le Frontend
- [ ] Flutter SDK à jour
- [ ] Dépendances installées (`flutter pub get`)
- [ ] Firebase configuré (iOS + Android)
- [ ] RevenueCat SDK intégré
- [ ] Backend API URL configurée

---

## 🎉 Prêt à Démarrer !

**Prochaine étape immédiate** :

1. **Réunion de kick-off** (2h)
   - Présenter les 4 documents à toute l'équipe
   - Valider les priorités
   - Assigner les premières tâches
   - Planifier Sprint 1

2. **Sprint 1 Backend** (10-15 jours)
   - Développeur Backend : Commencer #B1.1 (Service Python Matching)
   - DevOps : Préparer l'infrastructure

3. **Sprint 1 Frontend** (en parallèle, 5-7 jours)
   - Développeur Frontend : Commencer #1.1 et #2.1 (Photos + Prompts)

---

**Dernière mise à jour** : 13 octobre 2025  
**Auteur** : Expert développeur full stack mobile  
**Basé sur** : Analyse complète du code et specifications.md v1.1

**Questions ?** Consulter [GUIDE_UTILISATION_TACHES.md](./GUIDE_UTILISATION_TACHES.md) section "Support et Questions"

---

## 📞 Contact

Pour toute question ou clarification sur ces documents :
- Consulter specifications.md pour le contexte métier
- Ouvrir une issue GitHub pour les questions techniques
- Contacter le Product Owner pour les priorités

**Bonne chance pour le développement ! 🚀**
