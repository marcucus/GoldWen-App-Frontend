# Guide de Test - Correction Sélection Prompts et Validation Profil

## 🎯 Objectif des Tests

Vérifier que:
1. L'utilisateur peut choisir parmi TOUS les prompts disponibles (pas seulement les 3 premiers)
2. La validation du profil fonctionne correctement avec 3 prompts
3. Le statut de completion est correctement affiché

## ✅ Scénario 1: Sélection des Prompts

### Étapes
1. Créer un nouveau compte (ou utiliser un compte sans prompts)
2. Avancer jusqu'à la page "Prompts" (page 4/6)
3. Observer l'interface de sélection

### Comportement Attendu
- ✅ Tous les prompts disponibles sont affichés (pas seulement 3)
- ✅ Barre de recherche fonctionnelle
- ✅ Filtres par catégorie fonctionnels (Valeurs, Loisirs, etc.)
- ✅ Compteur affiche "0/3 prompts sélectionnés"
- ✅ Bouton "Continuer" est désactivé tant que 3 prompts ne sont pas sélectionnés
- ✅ Chaque prompt peut être sélectionné/désélectionné en cliquant
- ✅ Les prompts sélectionnés ont une bordure dorée
- ✅ Maximum 3 prompts peuvent être sélectionnés
- ✅ Message d'erreur si tentative de sélectionner plus de 3

### Logs Console Attendus
```
Successfully loaded X personality questions
```
(où X est le nombre total de prompts disponibles dans le backend)

## ✅ Scénario 2: Réponses aux Prompts

### Étapes
1. Sélectionner 3 prompts
2. Cliquer sur "Continuer"
3. Remplir les réponses

### Comportement Attendu
- ✅ Affichage de 3 champs de texte avec les questions sélectionnées
- ✅ Compteur de caractères "X/150" pour chaque réponse
- ✅ Indicateur "Réponses complétées: X/3"
- ✅ Bouton "Continuer" désactivé tant que les 3 réponses ne sont pas complètes
- ✅ Possibilité de revenir à la sélection avec le bouton "←"
- ✅ Validation: maximum 150 caractères par réponse

### Logs Console Attendus
```
DEBUG: Current _promptAnswers state: {promptId1: réponse1, promptId2: réponse2, promptId3: réponse3}
Submitting 3 prompt answers
Prompt answers data: [{promptId: ..., answer: ...}, ...]
Prompt answers submitted successfully
```

## ✅ Scénario 3: Validation du Profil

### Étapes
1. Compléter tous les champs requis (photos, prompts, questionnaire)
2. Naviguer vers la page "Validation" (page 5/6)

### Comportement Attendu
- ✅ Widget de completion affiche les 4 critères:
  - Photos (minimum 3) - avec icône ✅ si complété
  - Prompts (3 réponses) - avec icône ✅ si complété
  - Questionnaire personnalité - avec icône ✅ si complété
  - Informations de base - avec icône ✅ si complété
- ✅ Barre de progression affiche le pourcentage correct
- ✅ Message "Profil complet et validé" si tous les critères sont satisfaits
- ✅ Bouton "Continuer" activé seulement si le profil est complet

### Logs Console Attendus
```
Profile completion raw response: {...}
Requirements section: {minimumPhotos: {...}, minimumPrompts: {...}, ...}
Minimum prompts section: {required: 3, current: 3, satisfied: true}
Mapped completion data: {isCompleted: true, hasPhotos: true, hasPrompts: true, ...}
```

**Points Clés à Vérifier dans les Logs:**
- `minimumPrompts.satisfied: true` (pas `promptAnswers`)
- `current: 3` (nombre de prompts répondus)
- `hasPrompts: true` dans les données mappées

## ✅ Scénario 4: Profil Incomplet

### Étapes
1. Compléter seulement 2 prompts au lieu de 3
2. Naviguer vers la page de validation

### Comportement Attendu
- ⚠️ Widget de completion affiche:
  - Prompts (3 réponses) - avec icône ⭕ (incomplet)
- ⚠️ Liste des "Étapes manquantes" affichée
- ⚠️ Message "Votre profil n'est pas encore visible"
- ⚠️ Bouton "Continuer" désactivé
- ✅ Possibilité de cliquer sur "Compléter le profil" pour revenir aux prompts

### Logs Console Attendus
```
Minimum prompts section: {required: 3, current: 2, satisfied: false}
Mapped completion data: {hasPrompts: false, ...}
```

## 🔧 Test de Régression

### Vérifier que la correction n'a pas cassé d'autres fonctionnalités

1. **Photos:**
   - Ajout/suppression de photos fonctionne
   - Validation "minimum 3 photos" fonctionne
   - `hasPhotos` est correctement mappé

2. **Questionnaire de Personnalité:**
   - Soumission des réponses fonctionne
   - `hasPersonalityAnswers` est correctement mappé

3. **Informations de Base:**
   - Saisie pseudo, date de naissance, bio fonctionne
   - `hasRequiredProfileFields` est correctement mappé

## 📊 Matrice de Test

| Critère | Valeur | hasPhotos | hasPrompts | hasPersonality | hasBasicInfo | isCompleted |
|---------|--------|-----------|------------|----------------|--------------|-------------|
| Aucun critère | 0 | ❌ | ❌ | ❌ | ❌ | ❌ |
| Photos seules | 3 | ✅ | ❌ | ❌ | ❌ | ❌ |
| Photos + Prompts | 3 + 3 | ✅ | ✅ | ❌ | ❌ | ❌ |
| Tous sauf questionnaire | - | ✅ | ✅ | ❌ | ✅ | ❌ |
| Tous sauf prompts | - | ✅ | ❌ | ✅ | ✅ | ❌ |
| Tous les critères | - | ✅ | ✅ | ✅ | ✅ | ✅ |

## 🐛 Problèmes Connus à Éviter

### ❌ AVANT la Correction
- `hasPrompts` était toujours `false` même avec 3 prompts complétés
- Backend retournait `minimumPrompts` mais frontend cherchait `promptAnswers`
- Profil ne pouvait jamais être marqué comme complet

### ✅ APRÈS la Correction
- `hasPrompts` est correctement défini selon `minimumPrompts.satisfied`
- Mapping cohérent avec la structure du backend
- Profil peut être complété et validé

## 🎬 Cas de Test Complets

### Test 1: Nouveau Compte (Happy Path)
```
1. Inscription email
2. Questionnaire personnalité ✅
3. Informations de base ✅
4. 3 photos ✅
5. Sélection de 3 prompts parmi tous ✅
6. Réponse aux 3 prompts ✅
7. Page validation → Profil complet ✅
8. Activation du profil ✅
9. Navigation vers l'app principale ✅
```

### Test 2: Reprise d'Inscription
```
1. Utilisateur avec profil incomplet se reconnecte
2. Navigation automatique vers la page manquante
3. Completion des étapes manquantes
4. Validation finale
5. Activation
```

### Test 3: Modification de Prompts
```
1. Profil déjà complet
2. Accès aux paramètres → Modifier prompts
3. Changement de 1 ou plusieurs prompts
4. Sauvegarde
5. Vérification que le profil reste complet
```

## 📝 Checklist de Validation

- [ ] Tous les prompts sont visibles dans la sélection
- [ ] Sélection de 3 prompts fonctionne
- [ ] Réponses limitées à 150 caractères
- [ ] Soumission au backend réussit
- [ ] `hasPrompts` est `true` après soumission
- [ ] Page de validation affiche le bon statut
- [ ] Profil peut être activé
- [ ] Navigation vers l'app fonctionne
- [ ] Logs console sont propres (pas d'erreurs)
- [ ] UI responsive et fluide

## 🔍 Débogage

Si un test échoue, vérifier dans cet ordre:

1. **Logs console:**
   - Rechercher "Error" ou "Exception"
   - Vérifier la structure de la réponse API

2. **Données backend:**
   - Faire un GET `/profiles/completion`
   - Vérifier que `requirements.minimumPrompts` existe
   - Vérifier `satisfied: true/false`

3. **État frontend:**
   - Inspecter `ProfileProvider.profileCompletion`
   - Vérifier `hasPrompts` est mappé correctement
   - Vérifier `_promptAnswers` contient 3 entrées

4. **UI:**
   - Vérifier que le widget de completion s'affiche
   - Vérifier les icônes (✅/⭕)
   - Vérifier l'état des boutons (activé/désactivé)

## 📞 Support

Si un bug est détecté:
1. Noter le scénario exact
2. Copier les logs console
3. Faire une capture d'écran
4. Vérifier la réponse API brute
5. Créer une issue avec tous ces éléments
