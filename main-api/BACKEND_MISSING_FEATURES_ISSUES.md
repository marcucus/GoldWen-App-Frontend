# 📋 Issues des Fonctionnalités Backend Manquantes - GoldWen App

Ce document liste toutes les issues à créer pour compléter le développement du backend GoldWen, basé sur l'analyse du fichier `BACKEND_FEATURES_ANALYSIS.md` et des spécifications dans `specifications.md`.

**Date de création**: Janvier 2025  
**Basé sur**: BACKEND_FEATURES_ANALYSIS.md  
**Spécifications**: specifications.md v1.1  
**Stack**: NestJS, PostgreSQL, Python/FastAPI, Redis

---

## 🚨 ISSUES CRITIQUES (BLOQUANTES MVP)

### Issue #1: Créer le service de matching Python avec FastAPI

**Priorité**: P0 - Critique 🔥  
**Estimation**: 10-15 jours  
**Labels**: `backend`, `critical`, `matching`, `python`, `mvp`  
**Sprint**: Phase 1  

**Description**:
Implémenter le service de matching Python avec FastAPI tel que spécifié dans le cahier des charges. Ce service doit calculer les scores de compatibilité basés sur l'algorithme de filtrage par contenu (content-based filtering V1).

**Contexte**:
Le cahier des charges spécifie explicitement un service Python séparé pour le matching (section 6.3). Actuellement, seul le backend NestJS existe, sans logique réelle de compatibilité.

**Fonctionnalités requises**:
- [ ] Créer un nouveau service Python/FastAPI séparé
- [ ] Endpoint de calcul de compatibilité basé sur les réponses de personnalité
- [ ] Algorithme de scoring (0-100) avec pondération des 10 questions
- [ ] Filtrage par préférences (genre, distance, tranche d'âge)
- [ ] Cache Redis pour les scores calculés
- [ ] Client HTTP dans NestJS pour appeler le service Python
- [ ] Gestion des erreurs et fallback
- [ ] Tests unitaires et d'intégration
- [ ] Dockerfile et docker-compose pour déploiement

**Routes à créer**:
```python
# Service Python FastAPI
POST /api/v1/matching/calculate-compatibility
Body: {
  "userId": "uuid",
  "candidateIds": ["uuid1", "uuid2", ...],
  "personalityAnswers": {
    "q1": "answer1",
    "q2": "answer2",
    ...
  },
  "preferences": {
    "gender": "F",
    "minAge": 25,
    "maxAge": 35,
    "maxDistance": 50
  }
}
Response: {
  "compatibilityScores": [
    { "userId": "uuid1", "score": 85, "matchReasons": ["Valeurs communes", "Objectifs alignés"] },
    { "userId": "uuid2", "score": 72, "matchReasons": [...] }
  ]
}

GET /api/v1/matching/recommendations/:userId?limit=5
Response: {
  "recommendations": [
    { "userId": "uuid", "score": 88, "profile": {...} }
  ]
}

GET /health
Response: { "status": "ok", "service": "matching-python" }
```

**Intégration NestJS**:
```typescript
// src/modules/matching/matching-python.service.ts
@Injectable()
export class MatchingPythonService {
  constructor(private httpService: HttpService) {}

  async calculateCompatibility(
    userId: string,
    candidateIds: string[],
  ): Promise<CompatibilityScore[]> {
    const response = await this.httpService.post(
      `${PYTHON_SERVICE_URL}/api/v1/matching/calculate-compatibility`,
      {
        userId,
        candidateIds,
        personalityAnswers: await this.getPersonalityAnswers(userId),
        preferences: await this.getUserPreferences(userId),
      },
    ).toPromise();
    
    return response.data.compatibilityScores;
  }
}
```

**Critères d'acceptation**:
- [ ] Service Python déployable indépendamment via Docker
- [ ] Temps de calcul < 500ms pour 100 candidats
- [ ] Score de compatibilité cohérent et reproductible
- [ ] Cache Redis implémenté pour éviter les recalculs
- [ ] Tests couvrant 80%+ du code
- [ ] Documentation API complète avec exemples
- [ ] Intégration fonctionnelle avec NestJS
- [ ] Logging et monitoring configurés

**Dépendances**:
- FastAPI, Pydantic, uvicorn
- Redis client Python
- NumPy pour calculs vectoriels
- Scikit-learn pour algorithmes ML futurs

**Référence spécifications**: Section 6.3 - Service de Matching Python

---

### Issue #2: Implémenter les cron jobs critiques avec @nestjs/schedule

**Priorité**: P0 - Critique 🔥  
**Estimation**: 5-7 jours  
**Labels**: `backend`, `critical`, `automation`, `cron`, `mvp`  
**Sprint**: Phase 1  

**Description**:
Mettre en place tous les cron jobs automatisés requis pour le fonctionnement de l'application, notamment la génération quotidienne des sélections à midi et l'expiration automatique des chats après 24h.

**Contexte**:
Le cahier des charges spécifie explicitement des actions automatisées quotidiennes (section 4.2 et 4.3). Actuellement, aucun cron job n'est configuré.

**Fonctionnalités requises**:

**1. Génération quotidienne des sélections (12h00)**
- [ ] Installer et configurer `@nestjs/schedule`
- [ ] Cron job s'exécutant chaque jour à 12h00
- [ ] Gestion des fuseaux horaires par utilisateur
- [ ] Génération de 3-5 profils par utilisateur actif
- [ ] Appel du service Python pour le scoring
- [ ] Filtrage des profils déjà vus/choisis
- [ ] Stockage des sélections en base de données
- [ ] Trigger des notifications push
- [ ] Logging détaillé des exécutions
- [ ] Gestion des erreurs et retry logic

**2. Expiration automatique des chats (horaire)**
- [ ] Cron job s'exécutant toutes les heures
- [ ] Identification des chats créés il y a > 24h
- [ ] Changement du statut à 'expired'
- [ ] Envoi d'un message système "Cette conversation a expiré"
- [ ] Archivage des conversations expirées
- [ ] Notification aux utilisateurs (optionnel)

**3. Nettoyage quotidien des données (minuit)**
- [ ] Suppression des sélections quotidiennes > 7 jours
- [ ] Anonymisation des comptes supprimés > 30 jours
- [ ] Nettoyage des logs > 90 jours
- [ ] Nettoyage des sessions expirées

**Code à implémenter**:
```typescript
// src/modules/matching/matching.scheduler.ts
import { Injectable } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';

@Injectable()
export class MatchingScheduler {
  constructor(
    private matchingService: MatchingService,
    private matchingPythonService: MatchingPythonService,
    private notificationsService: NotificationsService,
    private logger: LoggerService,
  ) {}

  // Every day at 12:00 PM (configurable per user timezone)
  @Cron('0 12 * * *', {
    name: 'daily-selection-generation',
    timeZone: 'Europe/Paris',
  })
  async generateDailySelections() {
    this.logger.log('Starting daily selection generation cron job');
    
    try {
      const activeUsers = await this.matchingService.getActiveUsers();
      
      for (const user of activeUsers) {
        try {
          // Generate selection for this user
          await this.matchingService.generateDailySelection(user.id);
          
          // Send push notification
          await this.notificationsService.sendDailySelectionNotification(user.id);
          
          this.logger.log(`Generated selection for user ${user.id}`);
        } catch (error) {
          this.logger.error(`Failed to generate selection for user ${user.id}`, error);
          // Continue with next user
        }
      }
      
      this.logger.log(`Completed daily selection generation for ${activeUsers.length} users`);
    } catch (error) {
      this.logger.error('Daily selection generation cron job failed', error);
      throw error;
    }
  }

  // Every hour
  @Cron(CronExpression.EVERY_HOUR, {
    name: 'chat-expiration',
  })
  async expireChats() {
    this.logger.log('Starting chat expiration cron job');
    
    try {
      const expiredChats = await this.chatService.findExpiredChats();
      
      for (const chat of expiredChats) {
        await this.chatService.expireChat(chat.id);
      }
      
      this.logger.log(`Expired ${expiredChats.length} chats`);
    } catch (error) {
      this.logger.error('Chat expiration cron job failed', error);
    }
  }

  // Every day at midnight
  @Cron('0 0 * * *', {
    name: 'data-cleanup',
  })
  async cleanupOldData() {
    this.logger.log('Starting data cleanup cron job');
    
    try {
      // Delete old selections
      const deletedSelections = await this.matchingService.deleteOldSelections(7);
      
      // Anonymize deleted accounts
      const anonymizedAccounts = await this.usersService.anonymizeDeletedAccounts(30);
      
      // Clean old logs
      const cleanedLogs = await this.logger.cleanOldLogs(90);
      
      this.logger.log(`Cleanup complete: ${deletedSelections} selections, ${anonymizedAccounts} accounts, ${cleanedLogs} logs`);
    } catch (error) {
      this.logger.error('Data cleanup cron job failed', error);
    }
  }
}
```

**Critères d'acceptation**:
- [ ] Sélections quotidiennes générées automatiquement à midi
- [ ] Chats expirés automatiquement après 24h
- [ ] Nettoyage des données quotidien fonctionnel
- [ ] Gestion des fuseaux horaires par utilisateur
- [ ] Logging complet de toutes les exécutions
- [ ] Monitoring des échecs avec alertes
- [ ] Tests avec cron simulés
- [ ] Documentation des cron jobs configurés

**Dépendances**:
```bash
npm install --save @nestjs/schedule
```

**Référence spécifications**: Section 4.2 (notification à midi), Section 4.3 (chat 24h)

---

### Issue #3: Intégrer Firebase Cloud Messaging pour les notifications push

**Priorité**: P0 - Critique 🔥  
**Estimation**: 5-7 jours  
**Labels**: `backend`, `critical`, `notifications`, `firebase`, `mvp`  
**Sprint**: Phase 1  

**Description**:
Implémenter l'envoi réel de notifications push via Firebase Cloud Messaging (FCM) pour iOS et Android.

**Contexte**:
Le cahier des charges spécifie explicitement les notifications push (section 4.2, 4.3, 6.6). Le service de notifications existe mais n'envoie pas de vraies notifications.

**Fonctionnalités requises**:
- [ ] Créer un projet Firebase
- [ ] Configurer FCM pour iOS (APNs)
- [ ] Configurer FCM pour Android
- [ ] Télécharger et configurer le service account key
- [ ] Installer Firebase Admin SDK
- [ ] Implémenter FirebaseService
- [ ] Gestion des tokens FCM par utilisateur
- [ ] Envoi de notifications unicast et multicast
- [ ] Gestion des erreurs (tokens invalides, etc.)
- [ ] Tests avec appareils réels iOS et Android

**Types de notifications à implémenter**:

**1. Notification quotidienne (12h00)**
```json
{
  "title": "Votre sélection GoldWen du jour est arrivée !",
  "body": "Découvrez 5 nouveaux profils sélectionnés pour vous",
  "data": {
    "type": "DAILY_SELECTION",
    "screen": "/daily-selection"
  }
}
```

**2. Nouveau match**
```json
{
  "title": "Félicitations ! Vous avez un match 🎉",
  "body": "Vous avez un match avec [Prénom]. Commencez la conversation !",
  "data": {
    "type": "NEW_MATCH",
    "matchId": "uuid",
    "screen": "/chat/:matchId"
  }
}
```

**3. Nouveau message**
```json
{
  "title": "[Prénom]",
  "body": "Message preview...",
  "data": {
    "type": "NEW_MESSAGE",
    "chatId": "uuid",
    "screen": "/chat/:chatId"
  }
}
```

**4. Chat expire bientôt**
```json
{
  "title": "Votre conversation expire bientôt",
  "body": "Il vous reste 1h pour discuter avec [Prénom]",
  "data": {
    "type": "CHAT_EXPIRING",
    "chatId": "uuid"
  }
}
```

**5. Demande de chat acceptée**
```json
{
  "title": "Demande acceptée !",
  "body": "[Prénom] a accepté de discuter avec vous",
  "data": {
    "type": "CHAT_ACCEPTED",
    "chatId": "uuid"
  }
}
```

**Code à implémenter**:
```typescript
// src/modules/notifications/firebase.service.ts
import { Injectable } from '@nestjs/common';
import * as admin from 'firebase-admin';

@Injectable()
export class FirebaseService {
  private messaging: admin.messaging.Messaging;

  constructor() {
    const serviceAccount = require('../../config/firebase-service-account.json');
    
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    
    this.messaging = admin.messaging();
  }

  async sendPushNotification(
    token: string,
    notification: { title: string; body: string },
    data?: Record<string, string>,
  ): Promise<string> {
    try {
      const message: admin.messaging.Message = {
        token,
        notification,
        data,
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channelId: 'goldwen-notifications',
          },
        },
      };

      const messageId = await this.messaging.send(message);
      return messageId;
    } catch (error) {
      if (error.code === 'messaging/invalid-registration-token' ||
          error.code === 'messaging/registration-token-not-registered') {
        // Remove invalid token from database
        await this.removeInvalidToken(token);
      }
      throw error;
    }
  }

  async sendMulticast(
    tokens: string[],
    notification: { title: string; body: string },
    data?: Record<string, string>,
  ): Promise<admin.messaging.BatchResponse> {
    const message: admin.messaging.MulticastMessage = {
      tokens,
      notification,
      data,
    };

    return await this.messaging.sendEachForMulticast(message);
  }

  async subscribeToTopic(tokens: string[], topic: string): Promise<void> {
    await this.messaging.subscribeToTopic(tokens, topic);
  }

  private async removeInvalidToken(token: string): Promise<void> {
    // Implementation to remove token from database
  }
}

// src/modules/notifications/notifications.service.ts (enhanced)
@Injectable()
export class NotificationsService {
  constructor(
    private firebaseService: FirebaseService,
    private usersService: UsersService,
  ) {}

  async sendDailySelectionNotification(userId: string): Promise<void> {
    const tokens = await this.usersService.getUserPushTokens(userId);
    const preferences = await this.getNotificationPreferences(userId);
    
    if (!preferences.dailySelection) {
      return; // User disabled this notification
    }

    await this.firebaseService.sendMulticast(
      tokens,
      {
        title: 'Votre sélection GoldWen du jour est arrivée !',
        body: 'Découvrez 5 nouveaux profils sélectionnés pour vous',
      },
      {
        type: 'DAILY_SELECTION',
        screen: '/daily-selection',
      },
    );
  }

  async sendMatchNotification(userId: string, matchId: string, matchName: string): Promise<void> {
    const tokens = await this.usersService.getUserPushTokens(userId);
    
    await this.firebaseService.sendMulticast(
      tokens,
      {
        title: 'Félicitations ! Vous avez un match 🎉',
        body: `Vous avez un match avec ${matchName}. Commencez la conversation !`,
      },
      {
        type: 'NEW_MATCH',
        matchId,
        screen: `/chat/${matchId}`,
      },
    );
  }
}
```

**Routes à créer/modifier**:
```typescript
// Déjà existantes, à compléter avec Firebase
POST /api/v1/users/me/push-tokens
DELETE /api/v1/users/me/push-tokens/:token
PUT /api/v1/notifications/settings
GET /api/v1/notifications/settings
```

**Configuration .env**:
```
FIREBASE_PROJECT_ID=goldwen-app
FIREBASE_CLIENT_EMAIL=...
FIREBASE_PRIVATE_KEY=...
```

**Critères d'acceptation**:
- [ ] Notifications reçues sur iOS et Android
- [ ] Tous les 5 types de notifications implémentés
- [ ] Gestion des tokens invalides
- [ ] Respect des préférences utilisateur
- [ ] Badge count correct sur iOS
- [ ] Deep linking fonctionnel
- [ ] Retry logic en cas d'échec
- [ ] Tests avec appareils réels
- [ ] Documentation complète

**Dépendances**:
```bash
npm install --save firebase-admin
```

**Référence spécifications**: Section 4.2, 4.3, 6.6

---

### Issue #4: Implémenter les quotas quotidiens stricts (1 gratuit / 3 Plus)

**Priorité**: P0 - Critique 🔥  
**Estimation**: 3-4 jours  
**Labels**: `backend`, `critical`, `subscriptions`, `mvp`  
**Sprint**: Phase 1  

**Description**:
Implémenter un système strict de quotas quotidiens limitant les utilisateurs gratuits à 1 choix par jour et les abonnés Plus à 3 choix.

**Contexte**:
Le cahier des charges spécifie explicitement cette limitation (section 4.2 et 4.4). Le système actuel ne l'applique pas strictement.

**Fonctionnalités requises**:
- [ ] Table de tracking quotidien `daily_usage`
- [ ] Guard NestJS pour vérification des quotas
- [ ] Compteur incrémental à chaque choix
- [ ] Vérification du tier d'abonnement
- [ ] Messages d'erreur clairs
- [ ] Reset automatique quotidien
- [ ] API pour consulter l'usage quotidien

**Schéma de base de données**:
```sql
CREATE TABLE daily_usage (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  choices_count INT DEFAULT 0,
  selections_viewed INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, date)
);

CREATE INDEX idx_daily_usage_user_date ON daily_usage(user_id, date);
```

**Code à implémenter**:
```typescript
// src/modules/matching/guards/quota.guard.ts
import { Injectable, CanActivate, ExecutionContext, ForbiddenException } from '@nestjs/common';
import { MatchingService } from '../matching.service';
import { SubscriptionsService } from '../../subscriptions/subscriptions.service';

@Injectable()
export class QuotaGuard implements CanActivate {
  constructor(
    private matchingService: MatchingService,
    private subscriptionsService: SubscriptionsService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const userId = request.user.id;
    
    // Get today's usage
    const usage = await this.matchingService.getDailyUsage(userId);
    
    // Get user subscription tier
    const subscription = await this.subscriptionsService.getUserSubscription(userId);
    const tier = subscription?.tier || 'FREE';
    
    // Determine max choices based on tier
    const maxChoices = tier === 'PLUS' ? 3 : 1;
    
    // Check if quota is exceeded
    if (usage.choicesToday >= maxChoices) {
      const message = tier === 'FREE'
        ? 'Vous avez atteint votre limite quotidienne. Revenez demain ou passez à GoldWen Plus pour 3 choix par jour.'
        : 'Vous avez atteint votre limite quotidienne de 3 choix. Revenez demain !';
      
      throw new ForbiddenException({
        message,
        error: 'QUOTA_EXCEEDED',
        details: {
          choicesToday: usage.choicesToday,
          maxChoices,
          tier,
          resetTime: this.getNextResetTime(),
        },
      });
    }
    
    return true;
  }

  private getNextResetTime(): string {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(0, 0, 0, 0);
    return tomorrow.toISOString();
  }
}

// src/modules/matching/matching.controller.ts (modifier)
@Post('choose/:targetUserId')
@UseGuards(JwtAuthGuard, ProfileCompletionGuard, QuotaGuard) // Add QuotaGuard
async chooseProfile(
  @Request() req: any,
  @Param('targetUserId') targetUserId: string,
  @Body() body: { choice: 'like' | 'pass' },
) {
  const result = await this.matchingService.chooseProfile(
    req.user.id,
    targetUserId,
    body.choice,
  );
  
  // Increment usage counter
  await this.matchingService.incrementDailyUsage(req.user.id);
  
  return result;
}

// src/modules/matching/matching.service.ts (ajouter)
async getDailyUsage(userId: string): Promise<DailyUsageDto> {
  const today = new Date().toISOString().split('T')[0];
  
  const usage = await this.dailyUsageRepository.findOne({
    where: { userId, date: today },
  });
  
  return {
    choicesToday: usage?.choicesCount || 0,
    selectionsViewed: usage?.selectionsViewed || 0,
    date: today,
  };
}

async incrementDailyUsage(userId: string): Promise<void> {
  const today = new Date().toISOString().split('T')[0];
  
  await this.dailyUsageRepository
    .createQueryBuilder()
    .insert()
    .values({
      userId,
      date: today,
      choicesCount: 1,
    })
    .onConflict(`(user_id, date) DO UPDATE SET choices_count = daily_usage.choices_count + 1`)
    .execute();
}
```

**Routes à créer**:
```typescript
GET /api/v1/matching/usage/today
Response: {
  "choicesToday": 1,
  "maxChoices": 1,
  "tier": "FREE",
  "resetTime": "2025-01-16T00:00:00Z"
}
```

**Critères d'acceptation**:
- [ ] Utilisateur gratuit bloqué après 1 choix
- [ ] Utilisateur Plus peut faire 3 choix
- [ ] Message d'erreur clair avec temps de reset
- [ ] Compteur réinitialisé à minuit automatiquement
- [ ] API pour consulter l'usage disponible
- [ ] Tests unitaires couvrant tous les cas
- [ ] Incitation à l'upgrade pour les gratuits

**Référence spécifications**: Section 4.2, 4.4

---

### Issue #5: Intégrer RevenueCat pour la gestion réelle des abonnements

**Priorité**: P0 - Critique 🔥  
**Estimation**: 4-5 jours  
**Labels**: `backend`, `critical`, `subscriptions`, `revenuecat`, `mvp`  
**Sprint**: Phase 1  

**Description**:
Intégrer RevenueCat pour gérer les abonnements iOS (App Store) et Android (Play Store) avec synchronisation temps réel via webhooks.

**Contexte**:
Le cahier des charges recommande explicitement RevenueCat (section 6.6). Le service d'abonnements existe mais n'est pas connecté à un système de paiement réel.

**Fonctionnalités requises**:
- [ ] Créer un compte RevenueCat
- [ ] Configurer App Store Connect
- [ ] Configurer Google Play Console
- [ ] Configurer les produits d'abonnement dans RevenueCat
- [ ] Installer RevenueCat SDK backend
- [ ] Implémenter le webhook handler
- [ ] Synchroniser le statut d'abonnement
- [ ] Gérer les événements (achat, renouvellement, annulation, expiration)
- [ ] Tests avec sandbox iOS et Android

**Configuration RevenueCat**:

**Produits à configurer**:
- `goldwen_plus_monthly` - GoldWen Plus (Mensuel) - 9.99€
- `goldwen_plus_quarterly` - GoldWen Plus (Trimestriel) - 24.99€
- `goldwen_plus_semesterly` - GoldWen Plus (Semestriel) - 44.99€

**Code à implémenter**:
```typescript
// src/modules/subscriptions/revenuecat.controller.ts
import { Controller, Post, Body, Headers, BadRequestException } from '@nestjs/common';
import { RevenueCatService } from './revenuecat.service';
import * as crypto from 'crypto';

@Controller('webhooks/revenuecat')
export class RevenueCatWebhookController {
  constructor(private revenueCatService: RevenueCatService) {}

  @Post()
  async handleWebhook(
    @Body() event: any,
    @Headers('x-revenuecat-signature') signature: string,
  ) {
    // Verify webhook signature
    if (!this.verifySignature(event, signature)) {
      throw new BadRequestException('Invalid webhook signature');
    }

    const eventType = event.event.type;
    const appUserId = event.event.app_user_id;

    switch (eventType) {
      case 'INITIAL_PURCHASE':
        await this.revenueCatService.handleInitialPurchase(
          appUserId,
          event.event.product_id,
          event.event.purchased_at_ms,
          event.event.expiration_at_ms,
        );
        break;

      case 'RENEWAL':
        await this.revenueCatService.handleRenewal(
          appUserId,
          event.event.expiration_at_ms,
        );
        break;

      case 'CANCELLATION':
        await this.revenueCatService.handleCancellation(
          appUserId,
          event.event.cancellation_reason,
        );
        break;

      case 'EXPIRATION':
        await this.revenueCatService.handleExpiration(appUserId);
        break;

      case 'BILLING_ISSUE':
        await this.revenueCatService.handleBillingIssue(
          appUserId,
          event.event.grace_period_expiration_at_ms,
        );
        break;

      default:
        console.log(`Unhandled event type: ${eventType}`);
    }

    return { received: true };
  }

  private verifySignature(payload: any, signature: string): boolean {
    const secret = process.env.REVENUECAT_WEBHOOK_SECRET;
    const hash = crypto
      .createHmac('sha256', secret)
      .update(JSON.stringify(payload))
      .digest('hex');
    return hash === signature;
  }
}

// src/modules/subscriptions/revenuecat.service.ts
@Injectable()
export class RevenueCatService {
  constructor(
    @InjectRepository(Subscription)
    private subscriptionRepository: Repository<Subscription>,
    private usersService: UsersService,
  ) {}

  async handleInitialPurchase(
    appUserId: string,
    productId: string,
    purchasedAt: number,
    expiresAt: number,
  ): Promise<void> {
    const user = await this.usersService.findByAppUserId(appUserId);
    
    const tier = this.getTierFromProductId(productId);
    const period = this.getPeriodFromProductId(productId);

    await this.subscriptionRepository.save({
      userId: user.id,
      tier,
      period,
      status: 'ACTIVE',
      startDate: new Date(purchasedAt),
      endDate: new Date(expiresAt),
      revenueCatUserId: appUserId,
      productId,
    });

    // Trigger analytics event
    // await this.analyticsService.track('subscription_started', { userId: user.id, tier, period });
  }

  async handleRenewal(appUserId: string, newExpiresAt: number): Promise<void> {
    const user = await this.usersService.findByAppUserId(appUserId);
    
    await this.subscriptionRepository.update(
      { userId: user.id, status: 'ACTIVE' },
      {
        endDate: new Date(newExpiresAt),
        updatedAt: new Date(),
      },
    );

    // Trigger analytics event
    // await this.analyticsService.track('subscription_renewed', { userId: user.id });
  }

  async handleCancellation(appUserId: string, reason: string): Promise<void> {
    const user = await this.usersService.findByAppUserId(appUserId);
    
    await this.subscriptionRepository.update(
      { userId: user.id, status: 'ACTIVE' },
      {
        status: 'CANCELLED',
        cancellationReason: reason,
        updatedAt: new Date(),
      },
    );

    // Note: User keeps access until expiration date
  }

  async handleExpiration(appUserId: string): Promise<void> {
    const user = await this.usersService.findByAppUserId(appUserId);
    
    await this.subscriptionRepository.update(
      { userId: user.id },
      {
        status: 'EXPIRED',
        tier: 'FREE',
        updatedAt: new Date(),
      },
    );
  }

  private getTierFromProductId(productId: string): string {
    if (productId.includes('plus')) return 'PLUS';
    return 'FREE';
  }

  private getPeriodFromProductId(productId: string): string {
    if (productId.includes('monthly')) return 'MONTHLY';
    if (productId.includes('quarterly')) return 'QUARTERLY';
    if (productId.includes('semesterly')) return 'SEMESTERLY';
    return 'MONTHLY';
  }
}
```

**Routes à créer**:
```typescript
POST /api/v1/webhooks/revenuecat
Headers: { "x-revenuecat-signature": "..." }

GET /api/v1/subscriptions/offerings
Response: {
  "current": {
    "identifier": "goldwen_plus",
    "packages": [
      {
        "identifier": "monthly",
        "product": {
          "identifier": "goldwen_plus_monthly",
          "price": 9.99,
          "priceString": "9,99 €",
          "period": "P1M"
        }
      },
      // ... quarterly, semesterly
    ]
  }
}

POST /api/v1/subscriptions/verify-purchase
Body: {
  "receiptData": "...", // iOS
  "purchaseToken": "...", // Android
  "productId": "goldwen_plus_monthly"
}
```

**Configuration .env**:
```
REVENUECAT_API_KEY=...
REVENUECAT_WEBHOOK_SECRET=...
REVENUECAT_APP_USER_ID_PREFIX=goldwen_
```

**Critères d'acceptation**:
- [ ] Abonnements iOS fonctionnels via TestFlight
- [ ] Abonnements Android fonctionnels via Google Play
- [ ] Webhooks traités en temps réel
- [ ] Synchronisation correcte du statut
- [ ] Gestion des renouvellements automatiques
- [ ] Gestion des annulations
- [ ] Gestion des essais gratuits (si configurés)
- [ ] Tests avec sandbox iOS et Android
- [ ] Documentation complète

**Dépendances**:
```bash
npm install --save @revenuecat/purchases-typescript
```

**Référence spécifications**: Section 4.4, 6.6

---

## 🔧 ISSUES IMPORTANTES (PHASE 2)

### Issue #6: Améliorer l'algorithme de matching avec scoring avancé

**Priorité**: P1 - Important ⚡  
**Estimation**: 8-10 jours  
**Labels**: `backend`, `matching`, `enhancement`  
**Sprint**: Phase 2  

**Description**:
Affiner l'algorithme de matching V1 avec pondération intelligente, diversité, et filtrage avancé.

**Fonctionnalités requises**:
- [ ] Pondération des questions de personnalité
- [ ] Facteur de distance géographique
- [ ] Préférences d'âge
- [ ] Éviter les profils déjà vus
- [ ] Diversité dans les recommandations
- [ ] Cache Redis pour optimisation
- [ ] A/B testing infrastructure

**Critères d'acceptation**:
- [ ] Score de compatibilité cohérent et reproductible
- [ ] Diversité des profils recommandés
- [ ] Performance < 500ms pour génération
- [ ] Tests avec datasets réels

---

### Issue #7: Compléter le système de chat temps réel

**Priorité**: P1 - Important ⚡  
**Estimation**: 5-6 jours  
**Labels**: `backend`, `chat`, `websocket`, `enhancement`  
**Sprint**: Phase 2  

**Description**:
Ajouter les fonctionnalités temps réel manquantes au chat (typing indicator, read receipts, presence).

**Fonctionnalités requises**:
- [ ] Indicateur "en train d'écrire..."
- [ ] Accusés de réception (envoyé, délivré, lu)
- [ ] Statut online/offline
- [ ] Dernier vu
- [ ] Événements WebSocket additionnels
- [ ] Gestion des reconnexions
- [ ] Replay des messages manqués

**Events WebSocket à implémenter**:
```typescript
'user:online'
'user:offline'
'user:typing'
'user:stop-typing'
'message:delivered'
'message:read'
'chat:expires-in' // { minutesLeft: 60 }
```

**Critères d'acceptation**:
- [ ] Typing indicator fonctionnel
- [ ] Read receipts précis
- [ ] Présence temps réel
- [ ] Reconnexion sans perte de messages
- [ ] Tests avec plusieurs clients simultanés

---

### Issue #8: Implémenter la modération de contenu automatisée

**Priorité**: P1 - Important ⚡  
**Estimation**: 6-8 jours  
**Labels**: `backend`, `moderation`, `ai`, `security`  
**Sprint**: Phase 2  

**Description**:
Intégrer un service de modération IA pour filtrer automatiquement les contenus inappropriés (photos et messages).

**Fonctionnalités requises**:
- [ ] Choisir un service (AWS Rekognition, Sightengine, Azure)
- [ ] Modération automatique des photos à l'upload
- [ ] Modération des messages en temps réel
- [ ] File de modération pour les cas limites
- [ ] Dashboard admin pour la revue manuelle
- [ ] Bannissement automatique pour récidive

**Services recommandés**:
- AWS Rekognition (nudité, violence)
- Azure Content Moderator (texte)
- Sightengine (alternative tout-en-un)

**Critères d'acceptation**:
- [ ] Photos inappropriées rejetées automatiquement
- [ ] Messages offensants bloqués
- [ ] Cas limites en file de modération
- [ ] Admin peut approuver/rejeter manuellement
- [ ] Faux positifs < 5%

---

### Issue #9: Compléter la conformité RGPD

**Priorité**: P1 - Important ⚡  
**Estimation**: 4-5 jours  
**Labels**: `backend`, `gdpr`, `compliance`, `security`  
**Sprint**: Phase 2  

**Description**:
Finaliser tous les endpoints RGPD pour une conformité totale.

**Fonctionnalités requises**:
- [ ] Export complet des données en JSON
- [ ] Génération asynchrone avec notification email
- [ ] Anonymisation automatique après 30 jours
- [ ] Consentements granulaires
- [ ] Audit trail des modifications
- [ ] Page de politique de confidentialité

**Routes à compléter**:
```typescript
POST /api/v1/users/me/gdpr/export-request
GET /api/v1/users/me/gdpr/export-status
GET /api/v1/users/me/gdpr/export-download
DELETE /api/v1/users/me/gdpr/anonymize
PUT /api/v1/users/me/gdpr/consents
GET /api/v1/users/me/gdpr/consents
```

**Export JSON structure**:
```json
{
  "profile": { ... },
  "photos": [ ... ],
  "personalityAnswers": [ ... ],
  "promptAnswers": [ ... ],
  "matches": [ ... ],
  "messages": [ ... ],
  "choices": [ ... ],
  "subscription": { ... },
  "exportedAt": "2025-01-15T12:00:00Z"
}
```

**Critères d'acceptation**:
- [ ] Export complet fonctionnel
- [ ] Anonymisation automatique
- [ ] Consentements trackés
- [ ] Conformité RGPD vérifiée
- [ ] Documentation juridique

---

## 🔧 ISSUES NICE TO HAVE (PHASE 3)

### Issue #10: Intégrer Mixpanel/Amplitude pour les analytics

**Priorité**: P2 - Nice to have 🔧  
**Estimation**: 5-6 jours  
**Labels**: `backend`, `analytics`, `monitoring`  
**Sprint**: Phase 3  

**Description**:
Intégrer un service d'analytics pour tracker les événements utilisateur et mesurer l'engagement.

**Fonctionnalités requises**:
- [ ] Installation SDK Mixpanel ou Amplitude
- [ ] Tracking des événements clés
- [ ] Funnels de conversion
- [ ] Retention cohorts
- [ ] Dashboard de métriques

**Événements à tracker**:
- User signup
- Profile completed
- Daily selection viewed
- Profile liked/passed
- Match created
- Message sent
- Subscription started
- Subscription cancelled

---

### Issue #11: Implémenter le service email transactionnel

**Priorité**: P2 - Nice to have 🔧  
**Estimation**: 3-4 jours  
**Labels**: `backend`, `email`, `notifications`  
**Sprint**: Phase 3  

**Description**:
Créer des templates email professionnels et intégrer SendGrid/Mailgun.

**Emails à implémenter**:
- Email de bienvenue
- Confirmation d'inscription
- Notification de match (en complément du push)
- Rappels de chat
- Newsletter

---

### Issue #12: Ajouter rate limiting et sécurité avancée

**Priorité**: P2 - Nice to have 🔧  
**Estimation**: 3-4 jours  
**Labels**: `backend`, `security`, `performance`  
**Sprint**: Phase 3  

**Description**:
Renforcer la sécurité avec rate limiting, Helmet.js, et protections anti-spam.

**Fonctionnalités**:
- [ ] Rate limiting global par IP
- [ ] Rate limiting par utilisateur
- [ ] Helmet.js headers sécurisés
- [ ] CORS configuré strictement
- [ ] Input validation renforcée
- [ ] XSS/CSRF protection

---

## 🌟 ISSUES V2 (PHASE 4 - FUTURE)

### Issue #13: Développer l'algorithme de matching V2 avec ML

**Priorité**: P3 - Future 🌟  
**Estimation**: 15-20 jours  
**Labels**: `backend`, `ml`, `v2`  

**Description**:
Implémenter un algorithme de matching avancé avec filtrage collaboratif et apprentissage automatique.

---

### Issue #14: Ajouter le support des profils audio/vidéo

**Priorité**: P3 - Future 🌟  
**Estimation**: 10-12 jours  
**Labels**: `backend`, `media`, `v2`  

**Description**:
Permettre l'upload de clips audio (présentation vocale) et vidéos courtes avec stockage S3 et CDN.

---

### Issue #15: Implémenter la vérification de profil

**Priorité**: P3 - Future 🌟  
**Estimation**: 8-10 jours  
**Labels**: `backend`, `security`, `v2`  

**Description**:
Système de vérification d'identité avec selfie et comparaison faciale pour badge "Profil vérifié".

---

## 📊 RÉSUMÉ DES ISSUES

### Par Priorité
- **P0 - Critiques (MVP bloquantes)** : 5 issues (28-38 jours)
- **P1 - Importantes (Phase 2)** : 4 issues (23-29 jours)
- **P2 - Nice to have (Phase 3)** : 3 issues (11-14 jours)
- **P3 - Future (V2)** : 3 issues (33-42 jours)

**Total** : 15 issues

### Estimation temporelle globale
- **MVP complet (P0 + P1 + P2)** : 62-81 jours (~3-4 mois)
- **Avec V2 (P0 + P1 + P2 + P3)** : 95-123 jours (~4.5-6 mois)

### Ordre de priorité recommandé

**Sprint 1 (Phase 1 - MVP Critique)** :
1. Issue #1 : Service Python matching (10-15j)
2. Issue #2 : Cron jobs (5-7j)
3. Issue #3 : Firebase notifications (5-7j)
4. Issue #4 : Quotas stricts (3-4j)
5. Issue #5 : RevenueCat (4-5j)

**Sprint 2 (Phase 2 - Fonctionnalités importantes)** :
6. Issue #6 : Algorithme matching avancé (8-10j)
7. Issue #7 : Chat temps réel complet (5-6j)
8. Issue #8 : Modération automatisée (6-8j)
9. Issue #9 : RGPD complet (4-5j)

**Sprint 3 (Phase 3 - Optimisations)** :
10. Issue #10 : Analytics (5-6j)
11. Issue #11 : Service email (3-4j)
12. Issue #12 : Rate limiting (3-4j)

**Sprint 4 (Phase 4 - V2)** :
13. Issue #13 : ML matching V2 (15-20j)
14. Issue #14 : Audio/Vidéo (10-12j)
15. Issue #15 : Vérification profil (8-10j)

---

## 🏷️ Labels GitHub Recommandés

**Par priorité** :
- `p0-critical` (rouge) - Bloquant MVP
- `p1-important` (orange) - Important pour UX
- `p2-nice-to-have` (jaune) - Amélioration
- `p3-future` (bleu) - V2

**Par module** :
- `backend`
- `matching`
- `notifications`
- `subscriptions`
- `chat`
- `security`
- `analytics`

**Par type** :
- `feature` - Nouvelle fonctionnalité
- `enhancement` - Amélioration
- `integration` - Intégration tierce
- `compliance` - Conformité légale

---

## 🎯 MILESTONES GitHub Recommandés

1. **MVP Phase 1 - Core Backend** (28-38 jours)
2. **MVP Phase 2 - Enhanced Features** (23-29 jours)
3. **MVP Phase 3 - Optimizations** (11-14 jours)
4. **V2 - Advanced Features** (33-42 jours)

---

*Ce document servira de base pour la création des issues GitHub individuelles dans le repository GoldWen-App-Frontend.*

**Auteur** : Analyse technique backend  
**Date** : Janvier 2025  
**Version** : 1.0  
**Référence** : specifications.md v1.1, BACKEND_FEATURES_ANALYSIS.md
