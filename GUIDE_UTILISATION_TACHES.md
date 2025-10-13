# 📖 Guide d'Utilisation des Documents de Tâches

**Date**: 13 octobre 2025  
**Version**: 1.0

---

## 🎯 Objectif

Ce guide explique comment utiliser les trois documents de tâches créés pour le projet GoldWen App.

---

## 📚 Documents Disponibles

### 1. TACHES_FRONTEND.md (38KB, 1348 lignes)
**Pour qui ?** Développeurs Flutter, Chef de projet Frontend

**Contenu :**
- 28 tâches organisées en 14 modules
- 3 niveaux de priorité (🔥 Critique, ⚡ Important, 🔧 Normal)
- Pour chaque tâche :
  - Estimation temporelle
  - Fichiers concernés
  - Fonctionnalités détaillées
  - **Routes backend attendues avec exemples**
  - Critères d'acceptation

**Utilisation :**
```bash
# Consulter les tâches critiques
grep -A 10 "🔥 PRIORITÉ 1" TACHES_FRONTEND.md

# Rechercher une fonctionnalité spécifique
grep -i "photos" TACHES_FRONTEND.md

# Voir toutes les routes backend requises
grep -A 5 "Routes backend attendues" TACHES_FRONTEND.md
```

---

### 2. TACHES_BACKEND.md (43KB, 1637 lignes)
**Pour qui ?** Développeurs Backend (NestJS/Python), DevOps, Chef de projet Backend

**Contenu :**
- 22 tâches organisées en 14 modules
- 4 niveaux de priorité (P0 à P3)
- Pour chaque tâche :
  - Estimation temporelle
  - Code exemples TypeScript/Python
  - Structure de fichiers à créer
  - Routes API avec body/response
  - Critères d'acceptation

**Utilisation :**
```bash
# Consulter les tâches P0 (critiques)
grep -A 10 "🔥 P0" TACHES_BACKEND.md

# Rechercher une fonctionnalité spécifique
grep -i "matching" TACHES_BACKEND.md

# Voir les exemples de code
grep -A 20 "```typescript" TACHES_BACKEND.md | head -50
```

---

### 3. RESUME_TACHES_FRONTEND_BACKEND.md (15KB, 553 lignes)
**Pour qui ?** Product Owner, Chef de projet, Management, Équipe complète

**Contenu :**
- Vue d'ensemble du projet
- Correspondance Frontend ⟷ Backend
- Planning recommandé par phases
- Estimation totale
- Checklist de lancement MVP
- Recommandations stratégiques

**Utilisation :**
```bash
# Voir le planning
grep -A 20 "PLANNING RECOMMANDÉ" RESUME_TACHES_FRONTEND_BACKEND.md

# Consulter les estimations
grep -A 10 "ESTIMATION TOTALE" RESUME_TACHES_FRONTEND_BACKEND.md

# Voir la checklist MVP
grep -A 30 "CHECKLIST DE LANCEMENT" RESUME_TACHES_FRONTEND_BACKEND.md
```

---

## 🗺️ Workflow d'Utilisation Recommandé

### Phase 1 : Découverte et Planification

1. **Lire RESUME_TACHES_FRONTEND_BACKEND.md** (15 min)
   - Comprendre la vue d'ensemble
   - Identifier les phases critiques
   - Consulter le planning recommandé

2. **Consulter les estimations globales**
   - MVP Minimal : 6-8 semaines en parallèle
   - MVP Complet : 9-12 semaines en parallèle
   - Avec Optimisations : 11-16 semaines

3. **Valider les priorités avec l'équipe**

---

### Phase 2 : Planification Détaillée

#### Pour le Product Owner / Chef de Projet :

1. **Créer les sprints** basés sur le planning recommandé
2. **Prioriser les tâches** selon le business
3. **Assigner les ressources**

#### Pour les Développeurs Backend :

1. **Ouvrir TACHES_BACKEND.md**
2. **Filtrer par priorité** :
   ```bash
   # Voir toutes les tâches P0
   grep -B 3 "P0 - Critique" TACHES_BACKEND.md
   ```
3. **Lire les tâches en détail** :
   - Commencer par #B1.1 (Service Python Matching)
   - Puis #B2.1 (Cron jobs)
   - Etc.

#### Pour les Développeurs Frontend :

1. **Ouvrir TACHES_FRONTEND.md**
2. **Filtrer par priorité** :
   ```bash
   # Voir toutes les tâches critiques
   grep -B 3 "🔥 Critique" TACHES_FRONTEND.md
   ```
3. **Lire les tâches en détail** :
   - Commencer par #1.1 (Photos)
   - Puis #2.1 (Prompts)
   - Etc.

---

### Phase 3 : Développement

#### Workflow pour une tâche :

1. **Consulter la tâche dans le document approprié**
   - Lire la description complète
   - Noter les fichiers concernés
   - Comprendre les critères d'acceptation

2. **Vérifier les dépendances**
   - Frontend : Consulter "Routes backend attendues"
   - Backend : Vérifier si routes utilisées par frontend

3. **Utiliser RESUME pour les correspondances**
   - Section "CORRESPONDANCE FRONTEND ⟷ BACKEND"
   - Identifier les tâches liées

4. **Développer**
   - Suivre les exemples de code (backend)
   - Respecter les critères d'acceptation

5. **Tester**
   - Vérifier tous les critères d'acceptation
   - Tester l'intégration frontend-backend

---

## 🔍 Cas d'Usage Pratiques

### Cas 1 : "Je veux implémenter la gestion des photos"

1. **Frontend** : Lire TACHES_FRONTEND.md → Tâche #1.1 et #1.2
2. **Backend requis** : Voir les "Routes backend attendues"
3. **Backend** : Lire TACHES_BACKEND.md → Tâche #B6.1
4. **Correspondance** : RESUME section "1. Gestion des photos"

### Cas 2 : "Je veux savoir combien de temps prendra le MVP"

1. **Lire RESUME** → Section "ESTIMATION TOTALE"
2. **MVP Minimal** (Phase 1) : 6-8 semaines en parallèle
3. **MVP Complet** (Phase 1+2) : 9-12 semaines en parallèle

### Cas 3 : "Quelles sont les tâches critiques backend ?"

```bash
cd /home/runner/work/GoldWen-App-Frontend/GoldWen-App-Frontend
grep -A 5 "🔥 P0 - Critique" TACHES_BACKEND.md | grep "Tâche"
```

Résultat :
- #B1.1 : Service de matching Python (10-15j)
- #B2.1 : Cron jobs (5-7j)
- #B3.1 : Firebase Cloud Messaging (5-7j)
- #B4.1 : Quotas quotidiens (3-4j)
- #B5.1 : RevenueCat (5-7j)

### Cas 4 : "Quelles routes backend dois-je créer pour le frontend ?"

```bash
# Voir toutes les routes à créer
grep -A 10 "Nouvelles routes à créer" TACHES_FRONTEND.md

# Ou consulter le résumé
grep -A 20 "Routes backend requises" RESUME_TACHES_FRONTEND_BACKEND.md
```

---

## 📋 Checklists Rapides

### ✅ Checklist Démarrage Sprint Backend

- [ ] Lire TACHES_BACKEND.md pour le sprint
- [ ] Identifier les dépendances entre tâches
- [ ] Vérifier si routes utilisées par frontend
- [ ] Préparer l'environnement (DB, Redis, etc.)
- [ ] Créer les branches Git appropriées

### ✅ Checklist Démarrage Sprint Frontend

- [ ] Lire TACHES_FRONTEND.md pour le sprint
- [ ] Vérifier que les routes backend sont prêtes
- [ ] Tester les endpoints backend en Postman/Swagger
- [ ] Créer les branches Git appropriées
- [ ] Préparer les mocks si backend pas prêt

### ✅ Checklist Revue de Code

- [ ] Tous les critères d'acceptation respectés ?
- [ ] Code correspondant aux exemples (backend) ?
- [ ] Routes backend testées ?
- [ ] Intégration frontend-backend fonctionnelle ?
- [ ] Tests unitaires ajoutés ?
- [ ] Documentation mise à jour ?

---

## 🛠️ Outils et Scripts Utiles

### Script : Extraire toutes les routes backend d'une tâche

```bash
#!/bin/bash
# extract_routes.sh
TASK_NUMBER=$1
grep -A 50 "Tâche #${TASK_NUMBER}" TACHES_FRONTEND.md | grep -A 10 "Routes backend attendues"
```

Usage :
```bash
./extract_routes.sh 1.1  # Extraire routes de la tâche #1.1
```

### Script : Générer une checklist de tâches

```bash
#!/bin/bash
# generate_checklist.sh
PRIORITY=$1  # "🔥 PRIORITÉ 1" ou "⚡ PRIORITÉ 2" ou "🔧 PRIORITÉ 3"
grep -A 3 "$PRIORITY" TACHES_FRONTEND.md | grep "Tâche #" | sed 's/^/- [ ] /'
```

Usage :
```bash
./generate_checklist.sh "🔥 PRIORITÉ 1"
```

### Script : Compter les tâches par priorité

```bash
#!/bin/bash
# count_tasks.sh
echo "=== Frontend ==="
echo "Priorité 1 (Critiques):"
grep "🔥 Critique" TACHES_FRONTEND.md | wc -l
echo "Priorité 2 (Importantes):"
grep "⚡ Importante" TACHES_FRONTEND.md | wc -l
echo "Priorité 3 (Normales):"
grep "🔧 Normale" TACHES_FRONTEND.md | wc -l

echo ""
echo "=== Backend ==="
echo "P0 (Critiques):"
grep "🔥 P0" TACHES_BACKEND.md | wc -l
echo "P1 (Importantes):"
grep "⚡ P1" TACHES_BACKEND.md | wc -l
echo "P2 (Optimisations):"
grep "🔧 P2" TACHES_BACKEND.md | wc -l
```

---

## 📊 Métriques et Suivi

### Métriques à suivre :

1. **Tâches complétées** : X / 28 (frontend) + X / 22 (backend)
2. **Temps passé vs estimé** : Ajuster les estimations futures
3. **Blocages** : Dépendances frontend-backend non résolues
4. **Qualité** : Critères d'acceptation respectés à 100% ?

### Template de rapport hebdomadaire :

```markdown
## Rapport Sprint X - Semaine du DD/MM/YYYY

### Frontend
- Tâches complétées : #1.1, #2.1
- Tâches en cours : #3.1
- Blocages : Attente routes backend #B6.3

### Backend  
- Tâches complétées : #B1.1
- Tâches en cours : #B2.1, #B3.1
- Blocages : Aucun

### Intégration
- Routes testées : 5 / 8
- Problèmes identifiés : Format de réponse à ajuster sur /profiles/completion

### Prochains sprints
- Sprint X+1 : Tâches #3.2, #4.1 (frontend) + #B6.3 (backend)
```

---

## 🎓 Bonnes Pratiques

### DO ✅

- **Lire toujours le RESUME en premier** pour comprendre le contexte
- **Vérifier les dépendances** entre tâches avant de commencer
- **Utiliser les exemples de code** fournis (backend)
- **Respecter 100% des critères d'acceptation**
- **Tester l'intégration** frontend-backend
- **Documenter** les écarts par rapport aux spécifications

### DON'T ❌

- **Ne pas commencer sans lire la tâche complète**
- **Ne pas ignorer les routes backend** requises (frontend)
- **Ne pas développer une tâche si dépendance non prête**
- **Ne pas modifier les critères** sans validation Product Owner
- **Ne pas sauter les tests** unitaires/intégration

---

## 🆘 Support et Questions

### Questions fréquentes :

**Q: "La route backend n'existe pas encore, que faire ?"**
R: Consulter TACHES_BACKEND.md pour voir si elle est planifiée. Si oui, attendre ou utiliser un mock. Si non, remonter au Product Owner.

**Q: "L'estimation me semble incorrecte"**
R: Ajuster votre estimation et documenter pourquoi. Partager avec l'équipe pour ajuster les futures estimations.

**Q: "Une dépendance n'est pas documentée"**
R: Consulter RESUME section "CORRESPONDANCE". Si toujours pas clair, vérifier specifications.md ou demander clarification.

**Q: "Comment prioriser si plusieurs tâches P0 ?"**
R: Suivre l'ordre du RESUME section "Ordre de priorité absolu" :
1. Service Python Matching
2. Cron jobs + Quotas
3. Firebase + RevenueCat
4. Logique métier frontend
5. Nouvelles routes backend
6. RGPD

---

## 📝 Modèles de Documentation

### Modèle de Pull Request

```markdown
## Tâche #X.X : [Nom de la tâche]

**Document référence** : TACHES_[FRONTEND|BACKEND].md ligne XXX

### Changements
- [ ] Fonctionnalité 1
- [ ] Fonctionnalité 2

### Routes backend utilisées
- GET /api/v1/...
- POST /api/v1/...

### Critères d'acceptation
- [x] Critère 1
- [x] Critère 2
- [ ] Critère 3 (en cours)

### Tests
- [ ] Tests unitaires ajoutés
- [ ] Tests d'intégration ajoutés
- [ ] Tests manuels effectués

### Temps passé
Estimé : X jours  
Réel : Y jours  
Écart : Z jours (raison : ...)
```

### Modèle d'Issue GitHub

```markdown
## Tâche #X.X : [Nom de la tâche]

**Priorité** : [🔥 Critique | ⚡ Important | 🔧 Normal]  
**Estimation** : X jours  
**Assigné à** : @username

### Description
[Copier depuis TACHES_*.md]

### Fichiers concernés
- file1.dart
- file2.ts

### Critères d'acceptation
- [ ] Critère 1
- [ ] Critère 2

### Dépendances
- Tâche #Y.Y (doit être terminée avant)
- Route backend : POST /api/v1/... (doit être implémentée)

### Liens
- [TACHES_FRONTEND.md ligne XXX](./TACHES_FRONTEND.md)
- [Specifications.md section X.X](./specifications.md)
```

---

## 🚀 Pour Commencer Maintenant

### Étape 1 : Lecture initiale (30 min)
```bash
# Lire le résumé
cat RESUME_TACHES_FRONTEND_BACKEND.md | less

# Voir les priorités
grep -A 5 "PRIORITÉ" TACHES_FRONTEND.md
grep -A 5 "P0" TACHES_BACKEND.md
```

### Étape 2 : Planifier le premier sprint (1h)
1. Ouvrir RESUME_TACHES_FRONTEND_BACKEND.md
2. Section "PLANNING RECOMMANDÉ" → Phase 1
3. Créer les issues/tickets pour les tâches P0/Priorité 1

### Étape 3 : Commencer le développement
1. Backend : Tâche #B1.1 (Service Python Matching)
2. Frontend : Tâche #1.1 (Photos) en parallèle

---

**Dernière mise à jour** : 13 octobre 2025  
**Version** : 1.0

Pour toute question, consulter specifications.md ou contacter le Product Owner.
