# 🖥️ TÂCHES BACKEND - GoldWen App (Main-API)

**Date de création**: 13 octobre 2025  
**Basé sur**: specifications.md v1.1 + API_ROUTES_DOCUMENTATION.md + Analyses backend existantes  
**Architecture**: NestJS (API principale) + Python/FastAPI (Service de matching)  
**État actuel**: ~80% d'infrastructure technique complète  
**Temps estimé total**: 59-78 jours de développement

---

## 📊 RÉSUMÉ EXÉCUTIF

Le backend GoldWen présente une architecture NestJS solide et modulaire avec environ 80% de l'infrastructure en place. Les tâches restantes concernent principalement :
- **Service de matching Python** (algorithme de compatibilité V1)
- **Cron jobs automatisés** (sélection quotidienne, expiration chats)
- **Intégrations tierces** (Firebase Cloud Messaging, RevenueCat)
- **Quotas et limites quotidiennes strictes**
- **Nouvelles routes pour fonctionnalités frontend**

**Modules existants** : Auth, Profiles, Matching, Chat, Subscriptions, Notifications, Admin, Reports, Legal, Feedback

---

## 🎯 PRIORITÉS DE DÉVELOPPEMENT

### 🔥 P0 - FONCTIONNALITÉS CRITIQUES (MVP BLOQUANTES)
**Temps estimé**: 25-35 jours

### ⚡ P1 - FONCTIONNALITÉS IMPORTANTES
**Temps estimé**: 18-25 jours

### 🔧 P2 - AMÉLIORATIONS ET OPTIMISATIONS
**Temps estimé**: 12-15 jours

### 🌟 P3 - FONCTIONNALITÉS AVANCÉES (V2)
**Temps estimé**: 4-8 jours (optionnel)

---

# 🔥 PRIORITÉ 0 - CRITIQUES (MVP BLOQUANTES)

## MODULE 1 : SERVICE DE MATCHING PYTHON

### Tâche #B1.1 : Créer le service de matching Python avec FastAPI
**Estimation**: 10-15 jours  
**Priorité**: 🔥 P0 - Critique  
**État actuel**: 🚨 Non existant - À créer de zéro

**Description**:
Développer un service Python indépendant avec FastAPI pour gérer l'algorithme de matching V1 (filtrage par contenu). Ce service sera appelé par l'API NestJS principale.

**Fonctionnalités requises**:

### A) Infrastructure FastAPI (2-3 jours)
- [ ] Créer le projet FastAPI avec structure modulaire
- [ ] Configurer l'environnement (venv, requirements.txt)
- [ ] Mettre en place la connexion à PostgreSQL (SQLAlchemy)
- [ ] Créer les modèles de données (User, Profile, PersonalityAnswers)
- [ ] Configuration CORS pour communication avec NestJS
- [ ] Health check endpoint

**Structure de fichiers**:
```
matching-service/
├── app/
│   ├── main.py
│   ├── config.py
│   ├── database.py
│   ├── models/
│   │   ├── user.py
│   │   ├── profile.py
│   │   └── personality.py
│   ├── services/
│   │   ├── matching_algorithm.py
│   │   └── compatibility_score.py
│   ├── routes/
│   │   └── matching.py
│   └── utils/
│       └── filters.py
├── requirements.txt
└── Dockerfile
```

### B) Algorithme de Compatibilité V1 (5-7 jours)
- [ ] **Filtrage par critères de base** :
  - Genre et préférence de genre
  - Âge (min/max)
  - Distance géographique
  - Statut relationnel souhaité
  
- [ ] **Score de personnalité** (40% du score total) :
  - Comparaison des réponses au questionnaire (10 questions)
  - Calcul de similarité (cosine similarity ou Jaccard)
  - Pondération par importance des questions
  
- [ ] **Score d'intérêts** (30% du score total) :
  - Tags/centres d'intérêt en commun
  - Catégories de style de vie
  
- [ ] **Score de valeurs** (30% du score total) :
  - Intentions relationnelles
  - Valeurs de vie (famille, carrière, voyages, etc.)

- [ ] **Calcul score final** :
  ```python
  final_score = (
    personality_score * 0.40 +
    interests_score * 0.30 +
    values_score * 0.30
  ) * 100  # Score sur 100
  ```

### C) Endpoints API FastAPI (3-5 jours)
- [ ] **POST /api/matching/generate-selection**
  ```json
  Request:
  {
    "userId": "string",
    "count": 3-5,
    "excludeUserIds": ["array of already shown user IDs"]
  }
  
  Response:
  {
    "selection": [{
      "userId": "string",
      "compatibilityScore": number (0-100),
      "scoreBreakdown": {
        "personality": number,
        "interests": number,
        "values": number
      },
      "matchReasons": ["string array"]
    }],
    "generatedAt": "ISO date string"
  }
  ```

- [ ] **POST /api/matching/calculate-compatibility**
  ```json
  Request:
  {
    "userId1": "string",
    "userId2": "string"
  }
  
  Response:
  {
    "score": number (0-100),
    "breakdown": {
      "personality": number,
      "interests": number,
      "values": number
    },
    "matchReasons": ["string array"]
  }
  ```

**Technologies**:
- FastAPI
- SQLAlchemy (ORM)
- PostgreSQL
- NumPy/Pandas (calculs de similarité)
- Pydantic (validation)

**Critères d'acceptation**:
- ✅ Service FastAPI déployable et documenté (Swagger)
- ✅ Algorithme de matching retourne 3-5 profils pertinents
- ✅ Score de compatibilité entre 0-100 avec breakdown détaillé
- ✅ Filtrage par critères de base fonctionnel
- ✅ Performances acceptables (<2s pour générer une sélection)
- ✅ Tests unitaires pour l'algorithme (coverage >80%)

**Intégration avec NestJS**:
- Le service NestJS appellera le service Python via HTTP
- Configuration des URLs dans les variables d'environnement
- Gestion des erreurs et fallback si service indisponible

---

## MODULE 2 : CRON JOBS ET AUTOMATISATIONS

### Tâche #B2.1 : Configurer NestJS Schedule et créer les cron jobs
**Estimation**: 5-7 jours  
**Priorité**: 🔥 P0 - Critique  
**État actuel**: 🚨 Package @nestjs/schedule non installé

**Fonctionnalités requises**:

### A) Configuration de base (1 jour)
- [ ] Installer `@nestjs/schedule`
- [ ] Créer le module `CronJobsModule`
- [ ] Configurer les services de cron jobs

**Fichiers à créer**:
```
src/modules/cron-jobs/
├── cron-jobs.module.ts
├── services/
│   ├── daily-selection.service.ts
│   ├── chat-expiration.service.ts
│   ├── quota-reset.service.ts
│   └── cleanup.service.ts
└── cron-jobs.service.ts
```

### B) Cron Job : Génération Sélection Quotidienne (2-3 jours)
- [ ] **Scheduler** : Tous les jours à 12h00 (heure locale de chaque utilisateur)
- [ ] **Logique** :
  1. Récupérer tous les utilisateurs actifs avec profil complet
  2. Pour chaque utilisateur, appeler le service Python de matching
  3. Générer une sélection de 3-5 profils compatibles
  4. Exclure les profils déjà vus dans les 7 derniers jours
  5. Enregistrer la sélection dans `daily_selections` table
  6. Envoyer notification push "Votre sélection est prête !"

**Code de référence**:
```typescript
@Injectable()
export class DailySelectionService {
  constructor(
    private readonly matchingService: MatchingService,
    private readonly notificationService: NotificationService,
  ) {}

  @Cron('0 12 * * *', { timeZone: 'Europe/Paris' })
  async generateDailySelections() {
    const activeUsers = await this.getActiveUsers();
    
    for (const user of activeUsers) {
      try {
        const selection = await this.matchingService.generateSelection(user.id);
        await this.saveDailySelection(user.id, selection);
        await this.notificationService.sendDailySelectionNotification(user.id);
      } catch (error) {
        this.logger.error(`Failed for user ${user.id}`, error);
      }
    }
  }
}
```

### C) Cron Job : Expiration automatique des chats 24h (2 jours)
- [ ] **Scheduler** : Toutes les heures
- [ ] **Logique** :
  1. Récupérer tous les chats actifs (status = 'active')
  2. Vérifier `expiresAt < now()`
  3. Mettre à jour status = 'expired'
  4. Créer un message système "Cette conversation a expiré"
  5. Optionnel : Notification "Votre chat avec [Prénom] a expiré"

**Code de référence**:
```typescript
@Cron('0 * * * *') // Toutes les heures
async expireChats() {
  const expiredChats = await this.chatRepository
    .createQueryBuilder('chat')
    .where('chat.status = :status', { status: 'active' })
    .andWhere('chat.expiresAt < :now', { now: new Date() })
    .getMany();

  for (const chat of expiredChats) {
    await this.chatService.expireChat(chat.id);
  }
}
```

### D) Cron Job : Reset des quotas quotidiens (1 jour)
- [ ] **Scheduler** : Tous les jours à 00h00
- [ ] **Logique** :
  1. Reset de la table `daily_usage` pour tous les utilisateurs
  2. Remise à zéro des compteurs (daily_choices_used = 0)
  3. Logging pour monitoring

### E) Cron Job : Nettoyage des données (1 jour)
- [ ] **Scheduler** : Tous les jours à 03h00
- [ ] **Logique** :
  1. Supprimer les sessions expirées (>30 jours)
  2. Supprimer les exports de données téléchargés (>7 jours)
  3. Archiver les chats expirés (>90 jours)
  4. Supprimer les notifications anciennes (>30 jours)

**Critères d'acceptation**:
- ✅ Cron job de sélection quotidienne s'exécute à midi pour chaque timezone
- ✅ Chats expirés après 24h automatiquement
- ✅ Quotas reset à minuit chaque jour
- ✅ Nettoyage automatique des données anciennes
- ✅ Logs détaillés pour chaque exécution
- ✅ Gestion des erreurs robuste (retry, alertes)

**Table daily_selections** (à créer):
```typescript
@Entity('daily_selections')
export class DailySelection {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  userId: string;

  @Column({ type: 'date' })
  selectionDate: Date;

  @Column({ type: 'jsonb' })
  profileIds: string[]; // Liste des profils sélectionnés

  @Column({ type: 'jsonb' })
  scores: Record<string, number>; // userId => score

  @Column({ type: 'timestamp' })
  createdAt: Date;

  @Column({ type: 'timestamp' })
  expiresAt: Date; // Minuit du jour suivant
}
```

---

## MODULE 3 : FIREBASE CLOUD MESSAGING (NOTIFICATIONS PUSH)

### Tâche #B3.1 : Intégrer Firebase Cloud Messaging
**Estimation**: 5-7 jours  
**Priorité**: 🔥 P0 - Critique  
**État actuel**: 🚨 Non configuré

**Fonctionnalités requises**:

### A) Configuration Firebase (1-2 jours)
- [ ] Créer un projet Firebase
- [ ] Télécharger le fichier de configuration (service account JSON)
- [ ] Installer `firebase-admin` SDK
- [ ] Configurer dans le module Notifications
- [ ] Stocker les credentials de manière sécurisée (variables d'environnement)

**Fichiers à modifier/créer**:
```
src/modules/notifications/
├── notifications.module.ts
├── services/
│   ├── fcm.service.ts (À créer)
│   └── notifications.service.ts (Modifier)
├── entities/
│   └── push-token.entity.ts (À créer)
└── dto/
    └── send-notification.dto.ts (À créer)
```

### B) Gestion des tokens FCM (2 jours)
- [ ] Créer l'entité `PushToken`
- [ ] Route `POST /users/me/push-tokens` - Enregistrer token
- [ ] Route `DELETE /users/me/push-tokens/:tokenId` - Supprimer token
- [ ] Route `GET /users/me/push-tokens` - Lister tokens
- [ ] Gestion multi-device (un utilisateur peut avoir plusieurs tokens)

**Entity PushToken**:
```typescript
@Entity('push_tokens')
export class PushToken {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User)
  user: User;

  @Column({ type: 'text' })
  token: string;

  @Column({ type: 'enum', enum: ['ios', 'android'] })
  platform: 'ios' | 'android';

  @Column({ type: 'varchar', nullable: true })
  deviceModel: string;

  @Column({ type: 'boolean', default: true })
  isActive: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @Column({ type: 'timestamp', nullable: true })
  lastUsedAt: Date;
}
```

### C) Types de notifications à implémenter (2-3 jours)
- [ ] **NEW_DAILY_SELECTION** : "Votre sélection GoldWen du jour est arrivée !"
  - Déclencheur : Cron job à midi
  - Données : Nombre de nouveaux profils
  - Action : Ouvrir page Daily Selection

- [ ] **NEW_MATCH** : "Félicitations ! Vous avez un match avec [Prénom]"
  - Déclencheur : Match mutuel détecté
  - Données : matchId, prénom du match
  - Action : Ouvrir page Match Details

- [ ] **NEW_MESSAGE** : "[Prénom] vous a envoyé un message"
  - Déclencheur : Nouveau message reçu
  - Données : chatId, prénom, aperçu du message
  - Action : Ouvrir le chat

- [ ] **CHAT_EXPIRING_SOON** : "Votre chat avec [Prénom] expire dans 2 heures"
  - Déclencheur : 2h avant expiration
  - Données : chatId, prénom, temps restant
  - Action : Ouvrir le chat

- [ ] **CHAT_EXPIRED** : "Votre conversation avec [Prénom] a expiré"
  - Déclencheur : Expiration du chat
  - Données : chatId, prénom
  - Action : Ouvrir historique archivé

**Service FCM**:
```typescript
@Injectable()
export class FcmService {
  private firebaseApp: admin.app.App;

  constructor() {
    this.firebaseApp = admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
  }

  async sendNotification(
    tokens: string[],
    notification: {
      title: string;
      body: string;
      data?: Record<string, string>;
    }
  ): Promise<void> {
    const message = {
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: notification.data || {},
      tokens: tokens,
    };

    const response = await admin.messaging().sendMulticast(message);
    
    // Gérer les tokens invalides
    if (response.failureCount > 0) {
      await this.handleFailedTokens(tokens, response.responses);
    }
  }
}
```

### D) Routes de notification (1 jour)
- [ ] `POST /notifications/send` (Admin seulement)
- [ ] `GET /notifications/settings`
- [ ] `PUT /notifications/settings`

**Critères d'acceptation**:
- ✅ Firebase configuré et fonctionnel
- ✅ Tokens FCM enregistrés et gérés
- ✅ 5 types de notifications implémentés
- ✅ Notifications envoyées avec succès (iOS + Android)
- ✅ Deep linking fonctionnel (navigation vers bon écran)
- ✅ Gestion des tokens invalides/expirés
- ✅ Paramètres utilisateur pour activer/désactiver les notifications

---

## MODULE 4 : QUOTAS ET LIMITES QUOTIDIENNES

### Tâche #B4.1 : Implémenter le système de quotas stricts
**Estimation**: 3-4 jours  
**Priorité**: 🔥 P0 - Critique  
**État actuel**: ⚠️ Logique partielle présente

**Fonctionnalités requises**:

### A) Table daily_usage (1 jour)
- [ ] Créer l'entité `DailyUsage`
- [ ] Relations avec User et Subscription

**Entity DailyUsage**:
```typescript
@Entity('daily_usage')
export class DailyUsage {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User)
  user: User;

  @Column({ type: 'date' })
  date: Date; // Date du jour

  @Column({ type: 'int', default: 0 })
  dailyChoicesUsed: number;

  @Column({ type: 'int' })
  dailyChoicesLimit: number; // 1 (free) ou 3 (premium)

  @Column({ type: 'timestamp' })
  resetAt: Date; // Minuit du jour suivant

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
```

### B) Guard de vérification des quotas (1-2 jours)
- [ ] Créer `QuotaGuard` pour protéger les routes sensibles
- [ ] Vérifier avant chaque action si quota atteint
- [ ] Retourner erreur 429 (Too Many Requests) si quota dépassé

**QuotaGuard**:
```typescript
@Injectable()
export class QuotaGuard implements CanActivate {
  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const user = request.user;

    const usage = await this.getOrCreateDailyUsage(user.id);
    
    if (usage.dailyChoicesUsed >= usage.dailyChoicesLimit) {
      throw new HttpException(
        {
          statusCode: 429,
          message: 'Daily quota exceeded',
          remainingChoices: 0,
          resetTime: usage.resetAt,
        },
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    return true;
  }
}
```

### C) Routes de gestion des quotas (1 jour)
- [ ] `GET /subscriptions/usage` - Consulter l'usage quotidien
- [ ] `POST /matching/choose/:targetUserId` - Incrémenter le compteur après choix

**Route GET /subscriptions/usage**:
```typescript
@Get('usage')
@UseGuards(JwtAuthGuard)
async getUsage(@Request() req) {
  const usage = await this.subscriptionService.getDailyUsage(req.user.id);
  const subscription = await this.subscriptionService.getUserSubscription(req.user.id);

  return {
    dailyChoices: {
      limit: usage.dailyChoicesLimit,
      used: usage.dailyChoicesUsed,
      remaining: usage.dailyChoicesLimit - usage.dailyChoicesUsed,
      resetTime: usage.resetAt,
    },
    subscription: {
      tier: subscription.tier,
      isActive: subscription.isActive,
    },
  };
}
```

**Critères d'acceptation**:
- ✅ Table daily_usage créée et fonctionnelle
- ✅ QuotaGuard appliqué sur les routes sensibles
- ✅ Utilisateurs gratuits limités à 1 choix/jour
- ✅ Utilisateurs premium limités à 3 choix/jour
- ✅ Compteurs incrémentés correctement
- ✅ Reset automatique à minuit (cron job)
- ✅ Erreur 429 avec détails si quota dépassé

---

## MODULE 5 : REVENUECAT (ABONNEMENTS IN-APP)

### Tâche #B5.1 : Intégrer RevenueCat pour les abonnements
**Estimation**: 5-7 jours  
**Priorité**: 🔥 P0 - Critique  
**État actuel**: 🚨 Non configuré

**Fonctionnalités requises**:

### A) Configuration RevenueCat (1-2 jours)
- [ ] Créer compte RevenueCat
- [ ] Configurer les produits d'abonnement :
  - `goldwen_plus_monthly` : 9.99€/mois
  - `goldwen_plus_quarterly` : 24.99€/3 mois
  - `goldwen_plus_biannual` : 44.99€/6 mois
- [ ] Installer SDK RevenueCat (npm package)
- [ ] Configurer les webhooks

**Fichiers à créer**:
```
src/modules/subscriptions/
├── subscriptions.module.ts (Modifier)
├── services/
│   ├── revenuecat.service.ts (À créer)
│   └── subscriptions.service.ts (Modifier)
├── controllers/
│   └── webhooks.controller.ts (À créer)
└── dto/
    └── revenuecat-webhook.dto.ts (À créer)
```

### B) Service RevenueCat (2-3 jours)
- [ ] Créer `RevenueCatService`
- [ ] Méthodes pour vérifier les abonnements
- [ ] Synchronisation avec la base de données locale

**RevenueCatService**:
```typescript
@Injectable()
export class RevenueCatService {
  private readonly apiKey = process.env.REVENUECAT_API_KEY;

  async getSubscriberInfo(userId: string): Promise<SubscriberInfo> {
    const response = await axios.get(
      `https://api.revenuecat.com/v1/subscribers/${userId}`,
      {
        headers: { 'Authorization': `Bearer ${this.apiKey}` }
      }
    );
    return response.data;
  }

  async verifyPurchase(userId: string, receipt: string): Promise<boolean> {
    // Vérifier la validité de l'achat
  }

  async getOfferings(userId: string): Promise<Offerings> {
    // Récupérer les offres disponibles
  }
}
```

### C) Webhooks RevenueCat (2 jours)
- [ ] Endpoint `POST /subscriptions/webhook`
- [ ] Validation de la signature
- [ ] Gestion des événements :
  - `INITIAL_PURCHASE` : Premier abonnement
  - `RENEWAL` : Renouvellement
  - `CANCELLATION` : Annulation
  - `EXPIRATION` : Expiration
  - `BILLING_ISSUE` : Problème de paiement

**Webhook Controller**:
```typescript
@Controller('subscriptions/webhook')
export class WebhooksController {
  @Post()
  async handleWebhook(@Body() body: RevenueCatWebhookDto) {
    // Valider la signature
    if (!this.validateSignature(body)) {
      throw new UnauthorizedException();
    }

    switch (body.event.type) {
      case 'INITIAL_PURCHASE':
        await this.handleInitialPurchase(body);
        break;
      case 'RENEWAL':
        await this.handleRenewal(body);
        break;
      case 'CANCELLATION':
        await this.handleCancellation(body);
        break;
      case 'EXPIRATION':
        await this.handleExpiration(body);
        break;
    }

    return { received: true };
  }
}
```

### D) Routes d'abonnement (1 jour)
- [ ] `GET /subscriptions/offerings` - Offres disponibles
- [ ] `POST /subscriptions/purchase` - Valider un achat
- [ ] `GET /subscriptions/status` - Statut de l'abonnement
- [ ] `POST /subscriptions/restore` - Restaurer achats

**Critères d'acceptation**:
- ✅ RevenueCat configuré et fonctionnel
- ✅ Webhooks reçus et traités correctement
- ✅ Synchronisation en temps réel du statut d'abonnement
- ✅ Utilisateurs premium débloqués automatiquement
- ✅ Annulation et expiration gérées correctement
- ✅ Gestion des problèmes de paiement
- ✅ Tests sandbox fonctionnels

---

# ⚡ PRIORITÉ 1 - IMPORTANTES

## MODULE 6 : NOUVELLES ROUTES POUR FONCTIONNALITÉS FRONTEND

### Tâche #B6.1 : Créer les routes de gestion des photos
**Estimation**: 2-3 jours  
**Priorité**: ⚡ P1  
**État actuel**: ⚠️ Route POST existante, autres à créer

**Routes à créer/modifier**:

### A) PUT /profiles/me/photos/:photoId/order
```typescript
@Put('me/photos/:photoId/order')
@UseGuards(JwtAuthGuard)
async updatePhotoOrder(
  @Param('photoId') photoId: string,
  @Body() dto: UpdatePhotoOrderDto,
  @Request() req
) {
  await this.profilesService.updatePhotoOrder(
    req.user.id,
    photoId,
    dto.newOrder
  );
  return { success: true };
}
```

### B) PUT /profiles/me/photos/:photoId/primary
```typescript
@Put('me/photos/:photoId/primary')
@UseGuards(JwtAuthGuard)
async setPhotoAsPrimary(
  @Param('photoId') photoId: string,
  @Request() req
) {
  await this.profilesService.setPhotoAsPrimary(req.user.id, photoId);
  return { success: true };
}
```

### C) GET /profiles/completion (enrichir)
```typescript
@Get('completion')
@UseGuards(JwtAuthGuard)
async getProfileCompletion(@Request() req) {
  const profile = await this.profilesService.findOne(req.user.id);
  
  return {
    isComplete: profile.isComplete,
    completionPercentage: this.calculateCompletion(profile),
    requirements: {
      minimumPhotos: {
        required: 3,
        current: profile.photos.length,
        satisfied: profile.photos.length >= 3,
      },
      minimumPrompts: {
        required: 3,
        current: profile.promptAnswers.length,
        satisfied: profile.promptAnswers.length >= 3,
      },
      personalityQuestionnaire: {
        required: true,
        completed: profile.hasCompletedQuestionnaire,
        satisfied: profile.hasCompletedQuestionnaire,
      },
    },
    missingSteps: this.getMissingSteps(profile),
    nextStep: this.getNextStep(profile),
  };
}
```

**Critères d'acceptation**:
- ✅ Réorganisation des photos fonctionnelle
- ✅ Photo principale définie correctement
- ✅ Endpoint completion retourne toutes les informations nécessaires

---

### Tâche #B6.2 : Créer les routes de gestion des prompts
**Estimation**: 2 jours  
**Priorité**: ⚡ P1  
**État actuel**: ⚠️ Routes GET et POST existantes, PUT à créer

**Routes à créer**:

### A) PUT /profiles/me/prompt-answers
```typescript
@Put('me/prompt-answers')
@UseGuards(JwtAuthGuard)
async updatePromptAnswers(
  @Body() dto: UpdatePromptAnswersDto,
  @Request() req
) {
  const updated = await this.profilesService.updatePromptAnswers(
    req.user.id,
    dto.answers
  );
  return { success: true, promptAnswers: updated };
}
```

**DTO**:
```typescript
class UpdatePromptAnswersDto {
  @IsArray()
  @ValidateNested({ each: true })
  answers: PromptAnswerDto[];
}

class PromptAnswerDto {
  @IsUUID()
  id?: string; // Optionnel pour update

  @IsUUID()
  promptId: string;

  @IsString()
  @MaxLength(150)
  answer: string;
}
```

**Critères d'acceptation**:
- ✅ Modification des prompts fonctionnelle
- ✅ Validation des limites (3 prompts, 150 caractères)
- ✅ Réponses sauvegardées correctement

---

### Tâche #B6.3 : Créer les routes de matching avancées
**Estimation**: 3-4 jours  
**Priorité**: ⚡ P1  
**État actuel**: ⚠️ Routes de base existantes

**Routes à créer**:

### A) GET /matching/daily-selection/status
```typescript
@Get('daily-selection/status')
@UseGuards(JwtAuthGuard)
async getDailySelectionStatus(@Request() req) {
  const latestSelection = await this.matchingService.getLatestSelection(req.user.id);
  const now = new Date();
  const nextSelection = this.getNextSelectionTime(now);

  return {
    hasNewSelection: latestSelection 
      ? latestSelection.selectionDate < new Date().setHours(0,0,0,0)
      : true,
    lastSelectionDate: latestSelection?.selectionDate,
    nextSelectionTime: nextSelection,
    hoursUntilNext: this.calculateHoursUntil(nextSelection),
  };
}
```

### B) GET /matching/user-choices
```typescript
@Get('user-choices')
@UseGuards(JwtAuthGuard)
async getUserChoices(
  @Request() req,
  @Query('date') date?: string
) {
  const choices = await this.matchingService.getUserChoices(
    req.user.id,
    date ? new Date(date) : new Date()
  );

  return {
    choices: choices.map(c => ({
      userId: c.targetUserId,
      choiceType: c.choiceType,
      date: c.createdAt,
    })),
    todayChoicesCount: choices.filter(c => 
      this.isToday(c.createdAt)
    ).length,
  };
}
```

### C) GET /matching/pending-matches
```typescript
@Get('pending-matches')
@UseGuards(JwtAuthGuard)
async getPendingMatches(@Request() req) {
  // Trouver les utilisateurs qui ont choisi l'utilisateur actuel
  // mais que l'utilisateur actuel n'a pas encore choisi
  const pending = await this.matchingService.findPendingMatches(req.user.id);

  return {
    pending: pending.map(p => ({
      id: p.id,
      user: this.sanitizeUserProfile(p.user),
      waitingSince: p.createdAt,
    })),
  };
}
```

### D) GET /matching/history
```typescript
@Get('history')
@UseGuards(JwtAuthGuard)
async getMatchingHistory(
  @Request() req,
  @Query('startDate') startDate?: string,
  @Query('endDate') endDate?: string,
  @Query('page') page = 1,
  @Query('limit') limit = 20,
) {
  const history = await this.matchingService.getHistory(req.user.id, {
    startDate: startDate ? new Date(startDate) : undefined,
    endDate: endDate ? new Date(endDate) : undefined,
    page,
    limit,
  });

  return {
    history: history.map(h => ({
      date: h.date,
      profiles: h.profiles.map(p => ({
        userId: p.userId,
        user: this.sanitizeUserProfile(p.user),
        choice: p.choice,
        wasMatch: p.wasMatch,
      })),
    })),
    pagination: {
      page,
      limit,
      total: history.length,
    },
  };
}
```

### E) GET /matching/who-liked-me (Premium feature)
```typescript
@Get('who-liked-me')
@UseGuards(JwtAuthGuard, PremiumGuard)
async getWhoLikedMe(@Request() req) {
  const likedBy = await this.matchingService.findWhoLikedUser(req.user.id);

  return {
    likedBy: likedBy.map(like => ({
      userId: like.userId,
      user: this.sanitizeUserProfile(like.user),
      likedDate: like.createdAt,
    })),
  };
}
```

**Critères d'acceptation**:
- ✅ Toutes les routes fonctionnelles
- ✅ Statut de sélection quotidienne correct
- ✅ Historique complet des choix
- ✅ Matches en attente affichés
- ✅ Feature premium "Qui m'a aimé" protégée

---

### Tâche #B6.4 : Créer les routes de chat avancées
**Estimation**: 2-3 jours  
**Priorité**: ⚡ P1  
**État actuel**: ⚠️ Routes de base existantes

**Routes à créer**:

### A) POST /chat/accept/:matchId
```typescript
@Post('accept/:matchId')
@UseGuards(JwtAuthGuard)
async acceptMatch(
  @Param('matchId') matchId: string,
  @Request() req
) {
  const match = await this.matchingService.findMatch(matchId);
  
  // Vérifier que l'utilisateur fait partie du match
  if (!this.isUserInMatch(req.user.id, match)) {
    throw new ForbiddenException();
  }

  // Créer le chat avec expiration 24h
  const chat = await this.chatService.createChatFromMatch(match);

  return {
    success: true,
    chatId: chat.id,
    expiresAt: chat.expiresAt,
  };
}
```

### B) PUT /chat/:chatId/expire
```typescript
@Put(':chatId/expire')
@UseGuards(JwtAuthGuard)
async expireChat(
  @Param('chatId') chatId: string,
  @Request() req
) {
  const chat = await this.chatService.findOne(chatId);
  
  // Vérifier que l'utilisateur fait partie du chat
  if (!this.isUserInChat(req.user.id, chat)) {
    throw new ForbiddenException();
  }

  await this.chatService.expireChat(chatId);

  return { success: true };
}
```

**ExpireChat Logic**:
```typescript
async expireChat(chatId: string): Promise<void> {
  await this.chatRepository.update(chatId, {
    status: 'expired',
    expiredAt: new Date(),
  });

  // Créer un message système
  await this.messagesService.create({
    chatId,
    type: 'system',
    content: 'Cette conversation a expiré',
  });

  // Optionnel : Envoyer notification
  await this.notificationService.sendChatExpiredNotification(chatId);
}
```

### C) GET /chat/archived
```typescript
@Get('archived')
@UseGuards(JwtAuthGuard)
async getArchivedChats(@Request() req) {
  const archived = await this.chatService.findArchivedChats(req.user.id);

  return {
    archivedChats: archived.map(chat => ({
      id: chat.id,
      participants: chat.participants.map(p => this.sanitizeUser(p)),
      lastMessage: chat.lastMessage,
      expiredAt: chat.expiredAt,
    })),
  };
}
```

**Critères d'acceptation**:
- ✅ Acceptation de match crée un chat avec expiration 24h
- ✅ Expiration manuelle fonctionnelle
- ✅ Chats archivés accessibles en lecture seule
- ✅ Message système créé lors de l'expiration

---

### Tâche #B6.5 : Créer les routes RGPD
**Estimation**: 3-4 jours  
**Priorité**: ⚡ P1 (Légalement obligatoire)  
**État actuel**: 🚨 Non existantes

**Routes à créer**:

### A) POST /users/consent
```typescript
@Post('consent')
@UseGuards(JwtAuthGuard)
async recordConsent(
  @Body() dto: ConsentDto,
  @Request() req
) {
  await this.usersService.recordConsent(req.user.id, {
    dataProcessing: dto.dataProcessing,
    marketing: dto.marketing,
    analytics: dto.analytics,
    timestamp: new Date(),
  });

  return { success: true };
}
```

**Entity Consent**:
```typescript
@Entity('user_consents')
export class UserConsent {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User)
  user: User;

  @Column({ type: 'boolean' })
  dataProcessing: boolean;

  @Column({ type: 'boolean' })
  marketing: boolean;

  @Column({ type: 'boolean' })
  analytics: boolean;

  @Column({ type: 'timestamp' })
  consentedAt: Date;

  @Column({ type: 'varchar', nullable: true })
  ipAddress: string;

  @CreateDateColumn()
  createdAt: Date;
}
```

### B) POST /users/me/export-data
```typescript
@Post('me/export-data')
@UseGuards(JwtAuthGuard)
async requestDataExport(@Request() req) {
  const exportId = await this.usersService.createDataExport(req.user.id);

  // Job asynchrone pour générer l'export
  await this.dataExportQueue.add('generate-export', {
    userId: req.user.id,
    exportId,
  });

  return {
    exportId,
    status: 'processing',
    estimatedTime: 300, // 5 minutes
  };
}
```

### C) GET /users/me/export-data/:exportId
```typescript
@Get('me/export-data/:exportId')
@UseGuards(JwtAuthGuard)
async getDataExport(
  @Param('exportId') exportId: string,
  @Request() req
) {
  const exportData = await this.usersService.findDataExport(exportId);

  if (exportData.userId !== req.user.id) {
    throw new ForbiddenException();
  }

  return {
    status: exportData.status,
    downloadUrl: exportData.status === 'ready' ? exportData.downloadUrl : null,
    expiresAt: exportData.expiresAt,
  };
}
```

### D) GET /legal/privacy-policy
```typescript
@Get('privacy-policy')
async getPrivacyPolicy(
  @Query('version') version?: string,
  @Query('format') format: 'json' | 'html' = 'json'
) {
  const policy = await this.legalService.getPrivacyPolicy(version || 'latest');

  if (format === 'html') {
    return policy.htmlContent;
  }

  return {
    version: policy.version,
    content: policy.content,
    lastUpdated: policy.lastUpdated,
  };
}
```

### E) PUT /users/me/privacy-settings
```typescript
@Put('me/privacy-settings')
@UseGuards(JwtAuthGuard)
async updatePrivacySettings(
  @Body() dto: PrivacySettingsDto,
  @Request() req
) {
  await this.usersService.updatePrivacySettings(req.user.id, dto);
  return { success: true };
}
```

**Critères d'acceptation**:
- ✅ Consentement enregistré avec timestamp et IP
- ✅ Export de données généré (JSON avec toutes les données personnelles)
- ✅ Politique de confidentialité accessible en JSON et HTML
- ✅ Paramètres de confidentialité personnalisables
- ✅ Suppression complète du compte avec anonymisation

---

## MODULE 7 : SYSTÈME DE SIGNALEMENT

### Tâche #B7.1 : Créer le module de signalement complet
**Estimation**: 2-3 jours  
**Priorité**: ⚡ P1  
**État actuel**: ⚠️ Module existant, logique à compléter

**Routes à créer/enrichir**:

### A) POST /reports
```typescript
@Post()
@UseGuards(JwtAuthGuard)
async createReport(
  @Body() dto: CreateReportDto,
  @Request() req
) {
  const report = await this.reportsService.create({
    reporterId: req.user.id,
    targetType: dto.targetType,
    targetId: dto.targetId,
    reason: dto.reason,
    description: dto.description,
  });

  // Notification à l'équipe de modération
  await this.notificationService.notifyModerators('NEW_REPORT', report.id);

  return {
    success: true,
    reportId: report.id,
  };
}
```

### B) Logique anti-spam
- [ ] Vérifier que l'utilisateur n'a pas déjà signalé cette cible
- [ ] Limiter à 5 signalements par jour par utilisateur
- [ ] Créer une table `report_history` pour tracking

**Critères d'acceptation**:
- ✅ Signalement de profil et de message fonctionnel
- ✅ Anti-spam implémenté
- ✅ Modérateurs notifiés automatiquement
- ✅ Interface admin pour gérer les signalements

---

## MODULE 8 : NOTIFICATIONS ET PARAMÈTRES

### Tâche #B8.1 : Créer les paramètres de notifications
**Estimation**: 2 jours  
**Priorité**: ⚡ P1  
**État actuel**: ⚠️ Structure de base présente

**Routes à créer**:

### A) GET /notifications/settings
```typescript
@Get('settings')
@UseGuards(JwtAuthGuard)
async getSettings(@Request() req) {
  const settings = await this.notificationService.getSettings(req.user.id);

  return {
    settings: {
      dailySelection: settings.dailySelection,
      newMatches: settings.newMatches,
      newMessages: settings.newMessages,
      chatExpiringSoon: settings.chatExpiringSoon,
    },
  };
}
```

### B) PUT /notifications/settings
```typescript
@Put('settings')
@UseGuards(JwtAuthGuard)
async updateSettings(
  @Body() dto: NotificationSettingsDto,
  @Request() req
) {
  await this.notificationService.updateSettings(req.user.id, dto);
  return { success: true };
}
```

**Entity NotificationSettings**:
```typescript
@Entity('notification_settings')
export class NotificationSettings {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @OneToOne(() => User)
  user: User;

  @Column({ type: 'boolean', default: true })
  dailySelection: boolean;

  @Column({ type: 'boolean', default: true })
  newMatches: boolean;

  @Column({ type: 'boolean', default: true })
  newMessages: boolean;

  @Column({ type: 'boolean', default: true })
  chatExpiringSoon: boolean;

  @UpdateDateColumn()
  updatedAt: Date;
}
```

**Critères d'acceptation**:
- ✅ Paramètres de notifications personnalisables
- ✅ Sauvegarde et récupération fonctionnelles
- ✅ Respect des préférences lors de l'envoi de notifications

---

# 🔧 PRIORITÉ 2 - AMÉLIORATIONS

## MODULE 9 : OPTIMISATIONS ET PERFORMANCES

### Tâche #B9.1 : Implémenter le cache Redis pour les sélections
**Estimation**: 3-4 jours  
**Priorité**: 🔧 P2  
**État actuel**: 🚨 Non implémenté

**Fonctionnalités**:
- [ ] Installer et configurer Redis
- [ ] Cacher les sélections quotidiennes (TTL: 24h)
- [ ] Cacher les profils fréquemment consultés (TTL: 1h)
- [ ] Invalidation du cache lors des mises à jour

**Critères d'acceptation**:
- ✅ Temps de réponse amélioré pour les sélections quotidiennes
- ✅ Cache invalidé correctement lors des updates
- ✅ Fallback sur la DB si Redis indisponible

---

### Tâche #B9.2 : Ajouter la pagination sur toutes les listes
**Estimation**: 2-3 jours  
**Priorité**: 🔧 P2  
**État actuel**: ⚠️ Partiel

**Routes à paginer**:
- `GET /matching/history`
- `GET /chat/archived`
- `GET /notifications`
- `GET /admin/reports`
- `GET /admin/users`

**Standard de pagination**:
```typescript
interface PaginationDto {
  page: number = 1;
  limit: number = 20;
}

interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
    hasNext: boolean;
    hasPrev: boolean;
  };
}
```

**Critères d'acceptation**:
- ✅ Toutes les listes paginées
- ✅ Limite maximale : 100 items par page
- ✅ Métadonnées de pagination cohérentes

---

### Tâche #B9.3 : Implémenter le rate limiting
**Estimation**: 2 jours  
**Priorité**: 🔧 P2  
**État actuel**: 🚨 Non implémenté

**Fonctionnalités**:
- [ ] Installer `@nestjs/throttler`
- [ ] Configurer rate limits par route :
  - `/auth/*` : 10 requêtes/minute
  - `/profiles/*` : 30 requêtes/minute
  - `/matching/*` : 20 requêtes/minute
  - `/chat/*` : 60 requêtes/minute
  - Autres : 100 requêtes/minute

**Critères d'acceptation**:
- ✅ Rate limiting appliqué sur toutes les routes
- ✅ Headers de réponse avec limites
- ✅ Erreur 429 avec temps d'attente

---

## MODULE 10 : MONITORING ET LOGGING

### Tâche #B10.1 : Mettre en place le logging structuré
**Estimation**: 2-3 jours  
**Priorité**: 🔧 P2  
**État actuel**: ⚠️ Console.log basique

**Fonctionnalités**:
- [ ] Installer Winston logger
- [ ] Logs structurés (JSON)
- [ ] Niveaux : error, warn, info, debug
- [ ] Rotation des fichiers de log
- [ ] Logs séparés par module

**Critères d'acceptation**:
- ✅ Tous les logs en JSON structuré
- ✅ Logs d'erreur avec stack trace complète
- ✅ Rotation automatique (1 fichier/jour)
- ✅ Conservation 30 jours

---

### Tâche #B10.2 : Ajouter le monitoring de santé avancé
**Estimation**: 2 jours  
**Priorité**: 🔧 P2  
**État actuel**: ⚠️ Endpoint /health basique

**Fonctionnalités**:
- [ ] Health checks pour :
  - PostgreSQL (DB connectivity)
  - Redis (cache)
  - Service Python (matching)
  - RevenueCat (API)
  - Firebase (FCM)
- [ ] Métriques : uptime, latence, requêtes/s
- [ ] Endpoint `/metrics` pour Prometheus

**Critères d'acceptation**:
- ✅ Health checks pour tous les services externes
- ✅ Métriques exportées pour monitoring
- ✅ Alertes si service down

---

## MODULE 11 : TESTS AUTOMATISÉS

### Tâche #B11.1 : Compléter les tests unitaires
**Estimation**: 5-7 jours  
**Priorité**: 🔧 P2  
**État actuel**: ⚠️ 39 tests existants, coverage partiel

**Tests à ajouter**:
- [ ] Services de matching (algorithme)
- [ ] Cron jobs (mocking des schedulers)
- [ ] Quotas et limites
- [ ] Notifications FCM (mocking)
- [ ] RevenueCat webhooks
- [ ] Export de données RGPD

**Objectif de coverage**: 80%

**Critères d'acceptation**:
- ✅ Coverage >80% sur les modules critiques
- ✅ Tests unitaires pour toute la logique métier
- ✅ Mocks appropriés pour les services externes

---

### Tâche #B11.2 : Ajouter des tests d'intégration
**Estimation**: 3-5 jours  
**Priorité**: 🔧 P2  
**État actuel**: 🚨 Non existants

**Tests à créer**:
- [ ] Flow complet d'inscription
- [ ] Flow de matching quotidien
- [ ] Flow de match mutuel et chat
- [ ] Flow d'abonnement premium
- [ ] Flow de signalement

**Critères d'acceptation**:
- ✅ Tous les flows critiques testés
- ✅ Tests isolés (DB de test)
- ✅ CI/CD avec exécution automatique

---

## MODULE 12 : ACCESSIBILITÉ API

### Tâche #B12.1 : Créer la documentation Swagger complète
**Estimation**: 2-3 jours  
**Priorité**: 🔧 P2  
**État actuel**: ⚠️ Partiel

**Fonctionnalités**:
- [ ] Annotations Swagger sur toutes les routes
- [ ] Exemples de requêtes/réponses
- [ ] Description des erreurs possibles
- [ ] Schémas de validation

**Critères d'acceptation**:
- ✅ Documentation Swagger à 100%
- ✅ Exemples clairs pour chaque endpoint
- ✅ Accessible sur `/api/docs`

---

### Tâche #B12.2 : Paramètres d'accessibilité backend
**Estimation**: 1-2 jours  
**Priorité**: 🔧 P2  
**État actuel**: 🚨 Non existant

**Routes à créer**:
- `GET /users/me/accessibility-settings`
- `PUT /users/me/accessibility-settings`

**Settings**:
```typescript
interface AccessibilitySettings {
  fontSize: 'small' | 'medium' | 'large';
  highContrast: boolean;
  reduceAnimations: boolean;
}
```

**Critères d'acceptation**:
- ✅ Paramètres sauvegardés et récupérables
- ✅ Synchronisation avec le frontend

---

# 🌟 PRIORITÉ 3 - FONCTIONNALITÉS V2 (OPTIONNELLES)

## MODULE 13 : ALGORITHME DE MATCHING V2

### Tâche #B13.1 : Améliorer l'algorithme avec filtrage collaboratif
**Estimation**: 10-15 jours  
**Priorité**: 🌟 P3 - V2  
**État actuel**: 🚨 Non planifié pour MVP

**Fonctionnalités**:
- [ ] Collecte de données d'interaction (likes, passes, matches)
- [ ] Matrice utilisateurs-utilisateurs
- [ ] Filtrage collaboratif (User-Based)
- [ ] Hybride : Contenu (60%) + Collaboratif (40%)
- [ ] Machine Learning basique (scikit-learn)

**Critères d'acceptation**:
- ✅ Recommandations améliorées avec données d'interaction
- ✅ Score hybride contenu + collaboratif
- ✅ Performances acceptables (<3s)

---

## MODULE 14 : ANALYTICS ET MÉTRIQUES

### Tâche #B14.1 : Intégrer Mixpanel/Amplitude
**Estimation**: 3-4 jours  
**Priorité**: 🌟 P3 - V2  
**État actuel**: 🚨 Non planifié pour MVP

**Events à tracker**:
- User Registered
- Profile Completed
- Daily Selection Viewed
- Profile Liked/Passed
- Match Created
- Message Sent
- Subscription Started
- Subscription Cancelled

**Critères d'acceptation**:
- ✅ Events envoyés à Mixpanel/Amplitude
- ✅ Funnels configurés
- ✅ Dashboards de KPIs

---

# 📊 RÉSUMÉ DES ESTIMATIONS

| Priorité | Modules | Tâches | Temps (jours) |
|----------|---------|--------|---------------|
| 🔥 P0 | 5 | 5 | 25-35 |
| ⚡ P1 | 4 | 8 | 18-25 |
| 🔧 P2 | 4 | 9 | 12-18 |
| 🌟 P3 (V2) | 2 | 2 | 13-19 |
| **TOTAL MVP** | **13** | **22** | **59-78** |
| **TOTAL V2** | **15** | **24** | **72-97** |

---

# 🎯 CONCLUSION ET RECOMMANDATIONS

Le backend GoldWen API est à **80% de complétude** pour l'infrastructure technique. Les tâches critiques restantes sont :

## Phase 1 (MVP Minimal - 25-35 jours)
1. **Service de matching Python** (10-15j)
2. **Cron jobs automatisés** (5-7j)
3. **Firebase Cloud Messaging** (5-7j)
4. **Quotas quotidiens stricts** (3-4j)
5. **RevenueCat** (5-7j)

## Phase 2 (MVP Complet - 18-25 jours)
6. **Nouvelles routes frontend** (12-15j)
7. **Routes RGPD** (3-4j)
8. **Système de signalement** (2-3j)

## Phase 3 (Optimisations - 12-18 jours)
9. **Cache Redis** (3-4j)
10. **Rate limiting** (2j)
11. **Logging et monitoring** (4-5j)
12. **Tests** (8-12j)

## Phase 4 (V2 - 13-19 jours)
13. **Algorithme V2** (10-15j)
14. **Analytics** (3-4j)

**Temps total MVP**: **59-78 jours** (12-16 semaines)  
**Temps total avec V2**: **72-97 jours** (14-19 semaines)

---

**Document généré le 13 octobre 2025**  
**Basé sur l'analyse complète des spécifications et de l'architecture existante**
