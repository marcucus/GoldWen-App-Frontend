# 📋 Issues Backend GoldWen - Prêtes pour Implémentation (COMPLÈTES)

**Basé sur**: specifications.md (Cahier des Charges v1.1) + Analyse du code NestJS  
**Date**: Janvier 2025  
**État du backend**: 80% complet  
**Issues**: 15 issues complètes (P0 critiques + P1 importantes + P2-P3 V2)

Ce document contient **TOUTES** les issues backend (15 au total) avec les routes à implémenter et le comportement attendu côté serveur pour synchronisation avec le frontend.

---

## 🚨 ISSUES CRITIQUES (BLOQUANTES MVP)

### Issue Backend #1: Créer le service Python de matching avec FastAPI

**Priorité**: P0 - Critique 🔥  
**Estimation**: 10-15 jours  
**Module**: Matching (specifications.md §4.2)  
**Fichiers à créer**:
- `matching-service/` (nouveau service Python)
- `matching-service/main.py`
- `matching-service/services/compatibility_calculator.py`
- `matching-service/models/personality.py`
- `main-api/src/modules/matching/matching-python.service.ts` (client NestJS)

**Contexte (specifications.md):**
> "Algorithme de matching V1 (basé sur le contenu)."  
> "L'écran d'accueil de l'application affiche une liste de 3 à 5 profils, classés par score de compatibilité (V1)."

**Description:**
Créer un service Python/FastAPI séparé pour calculer les scores de compatibilité entre utilisateurs basés sur leurs réponses au questionnaire de personnalité (10 questions). Utilise un algorithme de filtrage par contenu (content-based filtering).

**Algorithme de compatibilité V1:**

1. **Calcul du score de personnalité** (60% du score total):
   - Comparer les réponses aux 10 questions de personnalité
   - Score par question: 10 points si réponse identique, 5 points si compatible, 0 si opposé
   - Pondération par importance de la question (configurable)

2. **Filtrage par préférences** (40% du score total):
   - Genre recherché (mandatory filter)
   - Distance géographique (penalty si > maxDistance)
   - Tranche d'âge (penalty si hors limites)

3. **Score final**: 0-100
   - < 60: Faible compatibilité (ne pas proposer)
   - 60-79: Compatibilité moyenne
   - 80-89: Bonne compatibilité
   - 90+: Excellente compatibilité

**Routes à implémenter:**

```python
# Service Python FastAPI (port 8000)

# 1. Calculer la compatibilité pour un utilisateur
POST /api/v1/matching/calculate-compatibility
Content-Type: application/json
Body: {
  "userId": "uuid",
  "candidateIds": ["uuid1", "uuid2", "uuid3"...], // Jusqu'à 100 candidats
  "personalityAnswers": {
    "q1": "answer_id_1",
    "q2": "answer_id_2",
    ...
    "q10": "answer_id_10"
  },
  "preferences": {
    "gender": "F",
    "minAge": 25,
    "maxAge": 35,
    "maxDistance": 50 // km
  },
  "userLocation": {
    "latitude": 48.8566,
    "longitude": 2.3522
  }
}
Response: {
  "compatibilityScores": [
    {
      "userId": "uuid1",
      "score": 85,
      "breakdown": {
        "personalityScore": 51, // Sur 60
        "preferencesScore": 34, // Sur 40
        "distance": 12.5 // km
      },
      "matchReasons": [
        "Valeurs communes en matière de famille",
        "Approche similaire des conflits",
        "Intérêts partagés"
      ]
    },
    {
      "userId": "uuid2",
      "score": 72,
      "breakdown": {...},
      "matchReasons": [...]
    }
  ],
  "calculatedAt": "2025-01-15T10:00:00Z",
  "cacheKey": "user-uuid-20250115" // Pour cache Redis
}

# 2. Obtenir des recommandations pour un utilisateur
GET /api/v1/matching/recommendations/:userId
Query params: {
  limit?: 5, // Nombre de profils à retourner (3-5)
  excludeIds?: "uuid1,uuid2" // IDs à exclure (déjà vus)
}
Response: {
  "recommendations": [
    {
      "userId": "uuid",
      "score": 88,
      "profile": {
        "id": "uuid",
        "firstName": "Sophie",
        "age": 29,
        "photos": [...],
        "prompts": [...],
        "personalityTraits": ["Empathique", "Aventureux"]
      },
      "matchReasons": [...]
    }
  ],
  "metadata": {
    "totalCandidates": 150,
    "calculatedCount": 150,
    "recommendedCount": 5,
    "averageScore": 82
  }
}

# 3. Health check
GET /health
Response: {
  "status": "ok",
  "service": "matching-python-service",
  "version": "1.0.0",
  "uptime": 3600
}
```

**Intégration avec NestJS:**

```typescript
// main-api/src/modules/matching/matching-python.service.ts

@Injectable()
export class MatchingPythonService {
  private readonly pythonServiceUrl = process.env.PYTHON_MATCHING_SERVICE_URL || 'http://localhost:8000';
  
  constructor(
    private readonly httpService: HttpService,
    @InjectRedis() private readonly redis: Redis,
  ) {}

  async calculateCompatibility(
    userId: string,
    candidateIds: string[],
  ): Promise<CompatibilityScore[]> {
    // Check cache first
    const cacheKey = `compatibility:${userId}:${new Date().toISOString().split('T')[0]}`;
    const cached = await this.redis.get(cacheKey);
    if (cached) {
      return JSON.parse(cached);
    }

    // Get user data
    const user = await this.usersService.findOne(userId);
    const personalityAnswers = await this.getPersonalityAnswers(userId);
    const preferences = user.preferences;

    // Call Python service
    const response = await this.httpService.post(
      `${this.pythonServiceUrl}/api/v1/matching/calculate-compatibility`,
      {
        userId,
        candidateIds,
        personalityAnswers,
        preferences: {
          gender: preferences.genderPreference,
          minAge: preferences.minAge,
          maxAge: preferences.maxAge,
          maxDistance: preferences.maxDistance,
        },
        userLocation: {
          latitude: user.location.latitude,
          longitude: user.location.longitude,
        },
      },
      { timeout: 5000 }
    ).toPromise();

    const scores = response.data.compatibilityScores;

    // Cache for 24h
    await this.redis.setex(cacheKey, 86400, JSON.stringify(scores));

    return scores;
  }
}

// main-api/src/modules/matching/matching.service.ts

@Injectable()
export class MatchingService {
  async generateDailySelection(userId: string): Promise<DailySelection> {
    // Get candidates (users not already seen/chosen)
    const candidates = await this.getCandidatesForUser(userId);
    
    // Calculate compatibility via Python service
    const scores = await this.matchingPythonService.calculateCompatibility(
      userId,
      candidates.map(c => c.id),
    );
    
    // Sort by score and take top 3-5
    const topMatches = scores
      .sort((a, b) => b.score - a.score)
      .slice(0, 5);
    
    // Save selection
    const selection = await this.dailySelectionRepository.save({
      userId,
      date: new Date().toISOString().split('T')[0],
      profileIds: topMatches.map(m => m.userId),
      scores: topMatches,
    });
    
    return selection;
  }
}
```

**Critères d'acceptation:**
- [ ] Service Python déployable indépendamment via Docker
- [ ] Endpoints FastAPI fonctionnels
- [ ] Algorithme de compatibilité V1 implémenté
- [ ] Score calculé en < 500ms pour 100 candidats
- [ ] Cache Redis pour éviter recalculs
- [ ] Client NestJS pour appeler le service
- [ ] Tests unitaires Python (coverage > 80%)
- [ ] Documentation API avec exemples

**Dépendances:**
```python
# requirements.txt
fastapi==0.109.0
uvicorn[standard]==0.27.0
pydantic==2.5.0
redis==5.0.1
numpy==1.26.3
python-dotenv==1.0.0
```

**Configuration:**
```yaml
# docker-compose.yml
services:
  matching-service:
    build: ./matching-service
    ports:
      - "8000:8000"
    environment:
      - REDIS_URL=redis://redis:6379
    depends_on:
      - redis
```

---

### Issue Backend #2: Implémenter les cron jobs critiques

**Priorité**: P0 - Critique 🔥  
**Estimation**: 5-7 jours  
**Module**: Matching + Chat (specifications.md §4.2, §4.3)  
**Fichiers à créer/modifier**:
- `main-api/src/modules/matching/matching.scheduler.ts` (créer)
- `main-api/src/modules/chat/chat.scheduler.ts` (créer)
- `main-api/src/app.module.ts` (modifier - importer ScheduleModule)

**Contexte (specifications.md):**
> "Chaque jour à 12h00 (heure locale de l'utilisateur), une notification push est envoyée : 'Votre sélection GoldWen du jour est arrivée!'."  
> "À la fin des 24 heures, le chat est archivé et devient inaccessible."

**Description:**
Mettre en place des cron jobs automatisés avec @nestjs/schedule pour générer les sélections quotidiennes à midi et expirer les chats après 24h.

**Cron jobs à implémenter:**

1. **Génération quotidienne des sélections (12h00)**
2. **Expiration automatique des chats (horaire)**
3. **Nettoyage quotidien des données (minuit)**

**Code à implémenter:**

```typescript
// main-api/src/modules/matching/matching.scheduler.ts

import { Injectable } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';

@Injectable()
export class MatchingScheduler {
  private readonly logger = new Logger(MatchingScheduler.name);

  constructor(
    private readonly matchingService: MatchingService,
    private readonly matchingPythonService: MatchingPythonService,
    private readonly notificationsService: NotificationsService,
    private readonly usersService: UsersService,
  ) {}

  // Cron job: Tous les jours à 12h00 (heure serveur UTC)
  // Note: Gérer les fuseaux horaires des utilisateurs
  @Cron('0 12 * * *', {
    name: 'daily-selection-generation',
    timeZone: 'Europe/Paris', // Ajuster selon déploiement
  })
  async generateDailySelections() {
    this.logger.log('Starting daily selection generation cron job');
    const startTime = Date.now();
    
    try {
      // Récupérer tous les utilisateurs actifs
      const activeUsers = await this.usersService.findActiveUsers();
      this.logger.log(`Found ${activeUsers.length} active users`);
      
      let successCount = 0;
      let errorCount = 0;
      
      // Générer la sélection pour chaque utilisateur
      for (const user of activeUsers) {
        try {
          // Vérifier si profil complet
          if (!user.isProfileComplete) {
            continue;
          }
          
          // Générer la sélection quotidienne
          const selection = await this.matchingService.generateDailySelection(user.id);
          
          // Envoyer notification push
          await this.notificationsService.sendDailySelectionNotification(user.id);
          
          this.logger.debug(`Generated selection for user ${user.id}: ${selection.profileIds.length} profiles`);
          successCount++;
          
        } catch (error) {
          this.logger.error(`Failed to generate selection for user ${user.id}:`, error);
          errorCount++;
          // Continue avec le prochain utilisateur
        }
      }
      
      const duration = Date.now() - startTime;
      this.logger.log(`Daily selection generation completed in ${duration}ms: ${successCount} successes, ${errorCount} errors`);
      
    } catch (error) {
      this.logger.error('Daily selection generation cron job failed:', error);
      // Alert monitoring system
      throw error;
    }
  }

  // Alternative: Générer pour un utilisateur spécifique (triggered)
  @Cron('0 * * * *', { // Toutes les heures
    name: 'user-specific-selection-generation',
  })
  async generateUserSpecificSelections() {
    // Pour gérer les différents fuseaux horaires
    // Identifier les utilisateurs dont l'heure locale est 12h00
    const currentHour = new Date().getUTCHours();
    
    for (let timezoneOffset = -12; timezoneOffset <= 14; timezoneOffset++) {
      const targetHour = (currentHour + timezoneOffset + 24) % 24;
      
      if (targetHour === 12) {
        // Trouver les utilisateurs dans ce fuseau horaire
        const users = await this.usersService.findByTimezoneOffset(timezoneOffset);
        
        for (const user of users) {
          try {
            await this.matchingService.generateDailySelection(user.id);
            await this.notificationsService.sendDailySelectionNotification(user.id);
          } catch (error) {
            this.logger.error(`Failed for user ${user.id}:`, error);
          }
        }
      }
    }
  }
}

// main-api/src/modules/chat/chat.scheduler.ts

@Injectable()
export class ChatScheduler {
  private readonly logger = new Logger(ChatScheduler.name);

  constructor(
    private readonly chatService: ChatService,
  ) {}

  // Toutes les heures
  @Cron(CronExpression.EVERY_HOUR, {
    name: 'chat-expiration',
  })
  async expireChats() {
    this.logger.log('Starting chat expiration cron job');
    
    try {
      // Trouver tous les chats créés il y a plus de 24h
      const expiredChats = await this.chatService.findExpiredChats();
      this.logger.log(`Found ${expiredChats.length} expired chats`);
      
      for (const chat of expiredChats) {
        try {
          // Marquer comme expiré
          await this.chatService.expireChat(chat.id);
          
          // Envoyer message système
          await this.chatService.sendSystemMessage(
            chat.id,
            'Cette conversation a expiré'
          );
          
          this.logger.debug(`Expired chat ${chat.id}`);
        } catch (error) {
          this.logger.error(`Failed to expire chat ${chat.id}:`, error);
        }
      }
      
      this.logger.log(`Chat expiration completed: ${expiredChats.length} chats expired`);
      
    } catch (error) {
      this.logger.error('Chat expiration cron job failed:', error);
    }
  }

  // Notification 1h avant expiration (optionnel)
  @Cron('*/30 * * * *', { // Toutes les 30 minutes
    name: 'chat-expiration-warning',
  })
  async warnExpiringChats() {
    try {
      // Trouver les chats qui expirent dans l'heure
      const expiringChats = await this.chatService.findExpiringChats(60); // 60 minutes
      
      for (const chat of expiringChats) {
        // Envoyer notification aux participants
        await this.notificationsService.sendChatExpiringNotification(
          chat.id,
          chat.participants,
          chat.timeRemaining
        );
      }
    } catch (error) {
      this.logger.error('Chat expiration warning failed:', error);
    }
  }
}

// main-api/src/modules/matching/matching.service.ts (méthodes helper)

@Injectable()
export class MatchingService {
  async generateDailySelection(userId: string): Promise<DailySelection> {
    // Vérifier si déjà généré aujourd'hui
    const today = new Date().toISOString().split('T')[0];
    const existing = await this.dailySelectionRepository.findOne({
      where: { userId, date: today },
    });
    
    if (existing) {
      return existing;
    }
    
    // Récupérer les candidats potentiels
    const candidates = await this.getCandidatesForUser(userId);
    
    if (candidates.length === 0) {
      throw new Error('No candidates available');
    }
    
    // Calculer la compatibilité via service Python
    const scores = await this.matchingPythonService.calculateCompatibility(
      userId,
      candidates.map(c => c.id),
    );
    
    // Trier par score et prendre le top 3-5
    const topProfiles = scores
      .filter(s => s.score >= 60) // Score minimum
      .sort((a, b) => b.score - a.score)
      .slice(0, 5);
    
    // Sauvegarder la sélection
    const selection = await this.dailySelectionRepository.save({
      userId,
      date: today,
      profileIds: topProfiles.map(p => p.userId),
      scores: topProfiles,
      generatedAt: new Date(),
    });
    
    return selection;
  }

  async getCandidatesForUser(userId: string): Promise<User[]> {
    const user = await this.usersService.findOne(userId);
    const preferences = user.preferences;
    
    // Récupérer les IDs déjà vus/choisis
    const seenIds = await this.getSeenProfileIds(userId);
    
    // Query avec filtres
    return await this.usersRepository.find({
      where: {
        id: Not(userId), // Pas soi-même
        isProfileComplete: true,
        gender: preferences.genderPreference,
        age: Between(preferences.minAge, preferences.maxAge),
        id: Not(In(seenIds)), // Exclure les déjà vus
      },
      take: 100, // Limiter pour performance
    });
  }
}

// main-api/src/modules/chat/chat.service.ts (méthodes helper)

@Injectable()
export class ChatService {
  async findExpiredChats(): Promise<Chat[]> {
    const now = new Date();
    return await this.chatRepository.find({
      where: {
        status: 'active',
        expiresAt: LessThan(now),
      },
    });
  }

  async expireChat(chatId: string): Promise<Chat> {
    const chat = await this.chatRepository.findOne({ where: { id: chatId } });
    
    if (!chat) {
      throw new NotFoundException('Chat not found');
    }
    
    chat.status = 'expired';
    chat.expiredAt = new Date();
    
    return await this.chatRepository.save(chat);
  }

  async sendSystemMessage(chatId: string, content: string): Promise<Message> {
    const message = this.messageRepository.create({
      chatId,
      senderId: null, // null pour message système
      content,
      type: 'SYSTEM',
      sentAt: new Date(),
    });
    
    return await this.messageRepository.save(message);
  }

  async findExpiringChats(minutesUntilExpiry: number): Promise<Chat[]> {
    const futureTime = new Date();
    futureTime.setMinutes(futureTime.getMinutes() + minutesUntilExpiry);
    
    const now = new Date();
    
    return await this.chatRepository.find({
      where: {
        status: 'active',
        expiresAt: Between(now, futureTime),
        expirationWarningSet: false, // Pour éviter les doublons
      },
    });
  }
}

// main-api/src/app.module.ts (configuration)

import { ScheduleModule } from '@nestjs/schedule';

@Module({
  imports: [
    ScheduleModule.forRoot(), // Activer le scheduling
    // ... autres modules
  ],
})
export class AppModule {}
```

**Critères d'acceptation:**
- [ ] @nestjs/schedule installé et configuré
- [ ] Cron job sélection quotidienne s'exécute à 12h
- [ ] Cron job expiration chats s'exécute toutes les heures
- [ ] Gestion des fuseaux horaires des utilisateurs
- [ ] Notifications push envoyées après génération
- [ ] Message système ajouté aux chats expirés
- [ ] Logging détaillé de toutes les exécutions
- [ ] Monitoring et alertes en cas d'échec
- [ ] Tests avec cron simulés

**Dépendances:**
```bash
npm install --save @nestjs/schedule
```

---

### Issue Backend #3: Intégrer Firebase Cloud Messaging pour notifications push

**Priorité**: P0 - Critique 🔥  
**Estimation**: 5-7 jours  
**Module**: Notifications (specifications.md §4.2, §4.3)  
**Fichiers à créer/modifier**:
- `main-api/src/modules/notifications/firebase.service.ts` (créer)
- `main-api/src/modules/notifications/notifications.service.ts` (modifier)
- `main-api/src/config/firebase-service-account.json` (ajouter)

**Contexte (specifications.md):**
> "Chaque jour à 12h00, une notification push est envoyée."  
> "Les deux utilisateurs reçoivent une notification de match."

**Description:**
Implémenter l'envoi réel de notifications push via Firebase Cloud Messaging pour iOS et Android.

**Types de notifications:**

1. Sélection quotidienne (12h)
2. Nouveau match
3. Nouveau message
4. Chat expire bientôt (1h avant)
5. Chat accepté

**Routes à implémenter:**

```typescript
// Routes pour la gestion des tokens FCM

// 1. Enregistrer un token FCM
POST /api/v1/users/me/push-tokens
Headers: {
  Authorization: "Bearer {token}",
  Content-Type: "application/json"
}
Body: {
  "token": "fcm-token-string",
  "platform": "ios", // ou "android", "web"
  "appVersion": "1.0.0",
  "deviceId": "device-unique-id"
}
Response: {
  "success": true,
  "data": {
    "tokenId": "uuid",
    "token": "fcm-token-string",
    "platform": "ios",
    "registeredAt": "2025-01-15T10:00:00Z"
  }
}

// 2. Supprimer un token FCM
DELETE /api/v1/users/me/push-tokens/:token
Headers: {
  Authorization: "Bearer {token}"
}
Response: {
  "success": true,
  "message": "Token removed"
}

// 3. Gérer les préférences de notifications
PUT /api/v1/notifications/settings
Headers: {
  Authorization: "Bearer {token}",
  Content-Type: "application/json"
}
Body: {
  "dailySelection": true,
  "newMatch": true,
  "newMessage": true,
  "chatExpiring": false,
  "subscription": true
}
Response: {
  "success": true,
  "data": {
    "settings": {
      "dailySelection": true,
      "newMatch": true,
      "newMessage": true,
      "chatExpiring": false,
      "subscription": true
    }
  }
}

// 4. Récupérer les préférences
GET /api/v1/notifications/settings
Headers: {
  Authorization: "Bearer {token}"
}
Response: {
  "settings": {
    "dailySelection": true,
    "newMatch": true,
    "newMessage": true,
    "chatExpiring": false,
    "subscription": true
  }
}
```

**Implémentation Firebase:**

```typescript
// main-api/src/modules/notifications/firebase.service.ts

import { Injectable } from '@nestjs/common';
import * as admin from 'firebase-admin';

@Injectable()
export class FirebaseService {
  private messaging: admin.messaging.Messaging;

  constructor() {
    // Charger le service account
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
              'content-available': 1,
            },
          },
        },
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channelId: 'goldwen-notifications',
            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          },
        },
      };

      const messageId = await this.messaging.send(message);
      return messageId;
      
    } catch (error) {
      // Gérer les tokens invalides
      if (error.code === 'messaging/invalid-registration-token' ||
          error.code === 'messaging/registration-token-not-registered') {
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

    return await this.messaging.sendEachForMulticast(message);
  }

  private async removeInvalidToken(token: string): Promise<void> {
    // Supprimer le token de la base de données
    await this.pushTokenRepository.delete({ token });
  }
}

// main-api/src/modules/notifications/notifications.service.ts

@Injectable()
export class NotificationsService {
  constructor(
    private readonly firebaseService: FirebaseService,
    private readonly usersService: UsersService,
    @InjectRepository(PushToken)
    private readonly pushTokenRepository: Repository<PushToken>,
    @InjectRepository(NotificationSettings)
    private readonly settingsRepository: Repository<NotificationSettings>,
  ) {}

  async sendDailySelectionNotification(userId: string): Promise<void> {
    // Vérifier les préférences
    const settings = await this.getNotificationSettings(userId);
    if (!settings.dailySelection) {
      return; // Utilisateur a désactivé
    }

    // Récupérer les tokens de l'utilisateur
    const tokens = await this.getUserPushTokens(userId);
    if (tokens.length === 0) {
      return;
    }

    // Envoyer la notification
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

  async sendMatchNotification(
    userId: string,
    matchId: string,
    matchName: string,
  ): Promise<void> {
    const settings = await this.getNotificationSettings(userId);
    if (!settings.newMatch) {
      return;
    }

    const tokens = await this.getUserPushTokens(userId);
    if (tokens.length === 0) {
      return;
    }

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

  async sendNewMessageNotification(
    userId: string,
    chatId: string,
    senderName: string,
    messagePreview: string,
  ): Promise<void> {
    const settings = await this.getNotificationSettings(userId);
    if (!settings.newMessage) {
      return;
    }

    const tokens = await this.getUserPushTokens(userId);
    if (tokens.length === 0) {
      return;
    }

    await this.firebaseService.sendMulticast(
      tokens,
      {
        title: senderName,
        body: messagePreview.substring(0, 100), // Limiter preview
      },
      {
        type: 'NEW_MESSAGE',
        chatId,
        screen: `/chat/${chatId}`,
      },
    );
  }

  async sendChatExpiringNotification(
    chatId: string,
    participants: User[],
    minutesRemaining: number,
  ): Promise<void> {
    for (const participant of participants) {
      const settings = await this.getNotificationSettings(participant.id);
      if (!settings.chatExpiring) {
        continue;
      }

      const tokens = await this.getUserPushTokens(participant.id);
      if (tokens.length === 0) {
        continue;
      }

      const otherParticipant = participants.find(p => p.id !== participant.id);

      await this.firebaseService.sendMulticast(
        tokens,
        {
          title: 'Votre conversation expire bientôt',
          body: `Il vous reste ${minutesRemaining} minutes pour discuter avec ${otherParticipant.firstName}`,
        },
        {
          type: 'CHAT_EXPIRING',
          chatId,
          minutesRemaining: minutesRemaining.toString(),
        },
      );
    }
  }

  private async getUserPushTokens(userId: string): Promise<string[]> {
    const tokens = await this.pushTokenRepository.find({
      where: { userId, isValid: true },
    });
    return tokens.map(t => t.token);
  }

  private async getNotificationSettings(userId: string): Promise<NotificationSettings> {
    let settings = await this.settingsRepository.findOne({ where: { userId } });
    
    if (!settings) {
      // Créer avec valeurs par défaut
      settings = await this.settingsRepository.save({
        userId,
        dailySelection: true,
        newMatch: true,
        newMessage: true,
        chatExpiring: true,
        subscription: true,
      });
    }
    
    return settings;
  }
}
```

**Critères d'acceptation:**
- [ ] Firebase Admin SDK configuré
- [ ] Service account JSON ajouté (hors Git)
- [ ] Routes CRUD pour tokens FCM fonctionnelles
- [ ] Routes pour préférences de notifications
- [ ] 5 types de notifications implémentés
- [ ] Gestion des tokens invalides
- [ ] Respect des préférences utilisateur
- [ ] Tests avec devices réels iOS et Android
- [ ] Deep linking fonctionnel
- [ ] Logging des envois

**Dépendances:**
```bash
npm install --save firebase-admin
```

**Configuration .env:**
```
FIREBASE_PROJECT_ID=goldwen-app
FIREBASE_CLIENT_EMAIL=...
FIREBASE_PRIVATE_KEY=...
```

---

### Issue Backend #4: Implémenter les quotas quotidiens stricts

**Priorité**: P0 - Critique 🔥  
**Estimation**: 3-4 jours  
**Module**: Matching + Subscriptions (specifications.md §4.2, §4.4)  
**Fichiers à créer/modifier**:
- `main-api/src/modules/matching/guards/quota.guard.ts` (créer)
- `main-api/src/modules/matching/matching.service.ts` (modifier)
- `main-api/src/modules/matching/entities/daily-usage.entity.ts` (créer)

**Contexte (specifications.md):**
> "Un utilisateur gratuit peut appuyer sur un bouton 'Choisir' sur un seul profil."  
> "Un utilisateur abonné GoldWen Plus peut 'Choisir' jusqu'à 3 profils."

**Description:**
Implémenter un système strict de quotas limitant les utilisateurs gratuits à 1 choix/jour et les abonnés Plus à 3 choix/jour, avec reset automatique à minuit.

**Schéma de base de données:**

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

**Routes à implémenter:**

```typescript
// 1. Vérifier l'usage quotidien
GET /api/v1/subscriptions/usage
Headers: {
  Authorization: "Bearer {token}"
}
Response: {
  "dailyChoices": {
    "limit": 1, // ou 3 pour Plus
    "used": 0,
    "remaining": 1,
    "resetTime": "2025-01-16T00:00:00Z" // Minuit heure locale
  },
  "subscription": {
    "tier": "free", // ou "plus"
    "isActive": true,
    "expiresAt": null // ou date si Plus
  }
}

// 2. Effectuer un choix (avec vérification quota)
POST /api/v1/matching/choose/:targetUserId
Headers: {
  Authorization: "Bearer {token}",
  Content-Type: "application/json"
}
Body: {
  "choice": "like" // ou "pass" (pass ne compte pas)
}
Response (succès): {
  "success": true,
  "data": {
    "isMatch": true,
    "matchId": "uuid",
    "choicesRemaining": 0,
    "message": "Votre choix est fait. Revenez demain à 12h !",
    "canContinue": false,
    "upgradePrompt": "Passez à GoldWen Plus pour 3 choix par jour"
  }
}
Response (quota dépassé - 403): {
  "success": false,
  "error": "QUOTA_EXCEEDED",
  "message": "Vous avez atteint votre limite quotidienne. Revenez demain ou passez à GoldWen Plus.",
  "details": {
    "choicesToday": 1,
    "maxChoices": 1,
    "tier": "free",
    "resetTime": "2025-01-16T00:00:00Z"
  }
}
```

**Code à implémenter:**

```typescript
// main-api/src/modules/matching/entities/daily-usage.entity.ts

@Entity('daily_usage')
export class DailyUsage {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column('uuid')
  userId: string;

  @Column('date')
  date: string; // Format YYYY-MM-DD

  @Column({ default: 0 })
  choicesCount: number;

  @Column({ default: 0 })
  selectionsViewed: number;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'userId' })
  user: User;
}

// main-api/src/modules/matching/guards/quota.guard.ts

@Injectable()
export class QuotaGuard implements CanActivate {
  constructor(
    private readonly matchingService: MatchingService,
    private readonly subscriptionsService: SubscriptionsService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const userId = request.user.id;
    const body = request.body;

    // Pass ne compte pas dans le quota
    if (body.choice === 'pass') {
      return true;
    }

    // Récupérer l'usage du jour
    const usage = await this.matchingService.getDailyUsage(userId);
    
    // Récupérer le tier d'abonnement
    const subscription = await this.subscriptionsService.getUserSubscription(userId);
    const tier = subscription?.tier || 'free';
    
    // Déterminer le max selon le tier
    const maxChoices = tier === 'plus' ? 3 : 1;
    
    // Vérifier si quota dépassé
    if (usage.choicesCount >= maxChoices) {
      const nextReset = this.getNextResetTime();
      
      throw new ForbiddenException({
        error: 'QUOTA_EXCEEDED',
        message: tier === 'free'
          ? 'Vous avez atteint votre limite quotidienne. Revenez demain ou passez à GoldWen Plus pour 3 choix par jour.'
          : 'Vous avez atteint votre limite quotidienne de 3 choix. Revenez demain !',
        details: {
          choicesToday: usage.choicesCount,
          maxChoices,
          tier,
          resetTime: nextReset,
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

// main-api/src/modules/matching/matching.controller.ts

@Controller('matching')
export class MatchingController {
  @Post('choose/:targetUserId')
  @UseGuards(JwtAuthGuard, ProfileCompletionGuard, QuotaGuard) // Ajouter QuotaGuard
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
    
    // Incrémenter le compteur si like (pas si pass)
    if (body.choice === 'like') {
      await this.matchingService.incrementDailyUsage(req.user.id);
    }
    
    return result;
  }

  @Get('daily-selection')
  @UseGuards(JwtAuthGuard, ProfileCompletionGuard)
  async getDailySelection(@Request() req: any) {
    const selection = await this.matchingService.getDailySelection(req.user.id);
    const usage = await this.matchingService.getDailyUsage(req.user.id);
    const subscription = await this.subscriptionsService.getUserSubscription(req.user.id);
    
    const tier = subscription?.tier || 'free';
    const maxChoices = tier === 'plus' ? 3 : 1;
    
    return {
      profiles: selection.profiles,
      metadata: {
        date: selection.date,
        choicesRemaining: maxChoices - usage.choicesCount,
        choicesMade: usage.choicesCount,
        maxChoices,
        refreshTime: this.getNextRefreshTime(),
        userTier: tier,
      },
    };
  }
}

// main-api/src/modules/matching/matching.service.ts

@Injectable()
export class MatchingService {
  async getDailyUsage(userId: string): Promise<DailyUsageDto> {
    const today = new Date().toISOString().split('T')[0];
    
    let usage = await this.dailyUsageRepository.findOne({
      where: { userId, date: today },
    });
    
    if (!usage) {
      // Créer pour aujourd'hui
      usage = await this.dailyUsageRepository.save({
        userId,
        date: today,
        choicesCount: 0,
        selectionsViewed: 0,
      });
    }
    
    return {
      choicesCount: usage.choicesCount,
      selectionsViewed: usage.selectionsViewed,
      date: today,
    };
  }

  async incrementDailyUsage(userId: string): Promise<void> {
    const today = new Date().toISOString().split('T')[0];
    
    await this.dailyUsageRepository
      .createQueryBuilder()
      .insert()
      .into(DailyUsage)
      .values({
        userId,
        date: today,
        choicesCount: 1,
      })
      .onConflict(`(user_id, date) DO UPDATE SET choices_count = daily_usage.choices_count + 1, updated_at = NOW()`)
      .execute();
  }

  async chooseProfile(
    userId: string,
    targetUserId: string,
    choice: 'like' | 'pass',
  ): Promise<ChoiceResult> {
    // Sauvegarder le choix
    const userChoice = await this.choiceRepository.save({
      userId,
      targetUserId,
      choice,
      date: new Date().toISOString().split('T')[0],
      madeAt: new Date(),
    });

    // Si pass, retourner directement
    if (choice === 'pass') {
      return {
        success: true,
        isMatch: false,
        choicesRemaining: await this.getChoicesRemaining(userId),
      };
    }

    // Si like, vérifier si match mutuel
    const reciprocalChoice = await this.choiceRepository.findOne({
      where: {
        userId: targetUserId,
        targetUserId: userId,
        choice: 'like',
      },
    });

    let matchId = null;
    let isMatch = false;

    if (reciprocalChoice) {
      // Match mutuel !
      const match = await this.matchRepository.save({
        user1Id: userId,
        user2Id: targetUserId,
        status: 'pending',
        matchedAt: new Date(),
      });
      
      matchId = match.id;
      isMatch = true;

      // Envoyer notifications aux deux utilisateurs
      const targetUser = await this.usersService.findOne(targetUserId);
      await this.notificationsService.sendMatchNotification(
        targetUserId,
        matchId,
        (await this.usersService.findOne(userId)).firstName,
      );
    }

    const choicesRemaining = await this.getChoicesRemaining(userId);
    const subscription = await this.subscriptionsService.getUserSubscription(userId);
    const tier = subscription?.tier || 'free';

    return {
      success: true,
      isMatch,
      matchId,
      choicesRemaining,
      message: choicesRemaining === 0
        ? 'Votre choix est fait. Revenez demain à 12h !'
        : `Il vous reste ${choicesRemaining} choix aujourd'hui`,
      canContinue: choicesRemaining > 0,
      upgradePrompt: tier === 'free' && choicesRemaining === 0
        ? 'Passez à GoldWen Plus pour 3 choix par jour'
        : null,
    };
  }

  private async getChoicesRemaining(userId: string): Promise<number> {
    const usage = await this.getDailyUsage(userId);
    const subscription = await this.subscriptionsService.getUserSubscription(userId);
    const tier = subscription?.tier || 'free';
    const maxChoices = tier === 'plus' ? 3 : 1;
    
    return Math.max(0, maxChoices - usage.choicesCount);
  }
}
```

**Critères d'acceptation:**
- [ ] Table daily_usage créée avec migration
- [ ] QuotaGuard implémenté et testé
- [ ] Route GET /subscriptions/usage fonctionnelle
- [ ] Vérification quota avant chaque choix
- [ ] Erreur 403 si quota dépassé avec message clair
- [ ] Pass ne compte pas dans le quota
- [ ] Compteur réinitialisé à minuit automatiquement
- [ ] Différenciation free (1) vs Plus (3)
- [ ] Tests unitaires pour tous les cas

---

### Issue Backend #5: Intégrer RevenueCat pour les abonnements

**Priorité**: P0 - Critique 🔥  
**Estimation**: 4-5 jours  
**Module**: Subscriptions (specifications.md §4.4)  
**Fichiers à créer/modifier**:
- `main-api/src/modules/subscriptions/revenuecat.controller.ts` (créer)
- `main-api/src/modules/subscriptions/revenuecat.service.ts` (créer)
- `main-api/src/modules/subscriptions/subscriptions.service.ts` (modifier)

**Contexte (specifications.md):**
> "Une page d'abonnement claire présente les tarifs (mensuel, trimestriel, semestriel) et gère le paiement via les systèmes natifs d'Apple (App Store) et Google (Play Store)."

**Description:**
Intégrer RevenueCat pour gérer les abonnements iOS et Android avec webhooks pour synchroniser le statut en temps réel.

**Produits à configurer dans RevenueCat:**
- `goldwen_plus_monthly` - 9.99€/mois
- `goldwen_plus_quarterly` - 24.99€/trimestre
- `goldwen_plus_semesterly` - 44.99€/semestre

**Routes à implémenter:**

```typescript
// 1. Webhook RevenueCat (événements abonnement)
POST /api/v1/webhooks/revenuecat
Headers: {
  X-RevenueCat-Signature: "{signature}" // Pour vérification
}
Body: {
  "event": {
    "type": "INITIAL_PURCHASE" | "RENEWAL" | "CANCELLATION" | "EXPIRATION" | "BILLING_ISSUE",
    "app_user_id": "user-uuid",
    "product_id": "goldwen_plus_monthly",
    "purchased_at_ms": 1705320000000,
    "expiration_at_ms": 1708008000000,
    "cancellation_reason": "..."
  }
}
Response: {
  "received": true
}

// 2. Récupérer les offerings (plans disponibles)
GET /api/v1/subscriptions/offerings
Headers: {
  Authorization: "Bearer {token}"
}
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
          "period": "P1M",
          "currencyCode": "EUR"
        }
      },
      {
        "identifier": "quarterly",
        "product": {
          "identifier": "goldwen_plus_quarterly",
          "price": 24.99,
          "priceString": "24,99 €",
          "period": "P3M"
        }
      },
      {
        "identifier": "semesterly",
        "product": {
          "identifier": "goldwen_plus_semesterly",
          "price": 44.99,
          "priceString": "44,99 €",
          "period": "P6M"
        }
      }
    ]
  }
}

// 3. Vérifier le statut d'abonnement
GET /api/v1/subscriptions/status
Headers: {
  Authorization: "Bearer {token}"
}
Response: {
  "subscription": {
    "tier": "plus", // ou "free"
    "isActive": true,
    "productId": "goldwen_plus_monthly",
    "startDate": "2025-01-15T00:00:00Z",
    "expiresAt": "2025-02-15T00:00:00Z",
    "willRenew": true,
    "platform": "ios" // ou "android"
  }
}
```

**Code à implémenter:**

```typescript
// main-api/src/modules/subscriptions/revenuecat.controller.ts

import { Controller, Post, Body, Headers, BadRequestException } from '@nestjs/common';
import { RevenueCatService } from './revenuecat.service';
import * as crypto from 'crypto';

@Controller('webhooks/revenuecat')
export class RevenueCatWebhookController {
  private readonly logger = new Logger(RevenueCatWebhookController.name);

  constructor(private readonly revenueCatService: RevenueCatService) {}

  @Post()
  async handleWebhook(
    @Body() event: any,
    @Headers('x-revenuecat-signature') signature: string,
  ) {
    // Vérifier la signature du webhook
    if (!this.verifySignature(JSON.stringify(event), signature)) {
      throw new BadRequestException('Invalid webhook signature');
    }

    this.logger.log(`Received RevenueCat webhook: ${event.event.type}`);

    const eventType = event.event.type;
    const appUserId = event.event.app_user_id;
    const productId = event.event.product_id;

    try {
      switch (eventType) {
        case 'INITIAL_PURCHASE':
          await this.revenueCatService.handleInitialPurchase(
            appUserId,
            productId,
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
          this.logger.warn(`Unhandled event type: ${eventType}`);
      }

      return { received: true };
      
    } catch (error) {
      this.logger.error(`Failed to handle webhook for ${appUserId}:`, error);
      throw error;
    }
  }

  private verifySignature(payload: string, signature: string): boolean {
    const secret = process.env.REVENUECAT_WEBHOOK_SECRET;
    const hash = crypto
      .createHmac('sha256', secret)
      .update(payload)
      .digest('hex');
    return hash === signature;
  }
}

// main-api/src/modules/subscriptions/revenuecat.service.ts

@Injectable()
export class RevenueCatService {
  private readonly logger = new Logger(RevenueCatService.name);

  constructor(
    @InjectRepository(Subscription)
    private readonly subscriptionRepository: Repository<Subscription>,
    private readonly usersService: UsersService,
  ) {}

  async handleInitialPurchase(
    appUserId: string,
    productId: string,
    purchasedAtMs: number,
    expiresAtMs: number,
  ): Promise<void> {
    const user = await this.usersService.findOne(appUserId);
    
    if (!user) {
      throw new NotFoundException(`User ${appUserId} not found`);
    }

    const tier = this.getTierFromProductId(productId);
    const period = this.getPeriodFromProductId(productId);

    // Créer l'abonnement
    const subscription = await this.subscriptionRepository.save({
      userId: user.id,
      tier,
      period,
      productId,
      status: 'active',
      startDate: new Date(purchasedAtMs),
      expiresAt: new Date(expiresAtMs),
      willRenew: true,
      platform: productId.includes('ios') ? 'ios' : 'android',
      revenueCatUserId: appUserId,
    });

    this.logger.log(`Created subscription for user ${user.id}: ${tier} ${period}`);

    // Trigger analytics event
    // await this.analyticsService.track('subscription_started', { userId: user.id, tier, period });
  }

  async handleRenewal(appUserId: string, newExpiresAtMs: number): Promise<void> {
    const user = await this.usersService.findOne(appUserId);
    
    await this.subscriptionRepository.update(
      { userId: user.id, status: 'active' },
      {
        expiresAt: new Date(newExpiresAtMs),
        willRenew: true,
        updatedAt: new Date(),
      },
    );

    this.logger.log(`Renewed subscription for user ${user.id}`);
  }

  async handleCancellation(appUserId: string, reason: string): Promise<void> {
    const user = await this.usersService.findOne(appUserId);
    
    await this.subscriptionRepository.update(
      { userId: user.id, status: 'active' },
      {
        status: 'cancelled',
        willRenew: false,
        cancellationReason: reason,
        updatedAt: new Date(),
      },
    );

    this.logger.log(`Cancelled subscription for user ${user.id}: ${reason}`);
    
    // Note: User conserve l'accès jusqu'à la date d'expiration
  }

  async handleExpiration(appUserId: string): Promise<void> {
    const user = await this.usersService.findOne(appUserId);
    
    await this.subscriptionRepository.update(
      { userId: user.id },
      {
        status: 'expired',
        tier: 'free',
        willRenew: false,
        updatedAt: new Date(),
      },
    );

    this.logger.log(`Expired subscription for user ${user.id}`);
  }

  async handleBillingIssue(
    appUserId: string,
    gracePeriodExpiresAtMs: number,
  ): Promise<void> {
    const user = await this.usersService.findOne(appUserId);
    
    await this.subscriptionRepository.update(
      { userId: user.id, status: 'active' },
      {
        status: 'billing_issue',
        gracePeriodExpiresAt: new Date(gracePeriodExpiresAtMs),
        updatedAt: new Date(),
      },
    );

    this.logger.warn(`Billing issue for user ${user.id}`);
    
    // Envoyer notification à l'utilisateur
    // await this.notificationsService.sendBillingIssueNotification(user.id);
  }

  private getTierFromProductId(productId: string): string {
    if (productId.includes('plus')) return 'plus';
    return 'free';
  }

  private getPeriodFromProductId(productId: string): string {
    if (productId.includes('monthly')) return 'monthly';
    if (productId.includes('quarterly')) return 'quarterly';
    if (productId.includes('semesterly')) return 'semesterly';
    return 'monthly';
  }
}
```

**Critères d'acceptation:**
- [ ] Compte RevenueCat configuré
- [ ] Produits créés (monthly, quarterly, semesterly)
- [ ] Webhook endpoint implémenté avec vérification signature
- [ ] Gestion des 5 événements (purchase, renewal, cancellation, expiration, billing_issue)
- [ ] Synchronisation temps réel du statut
- [ ] Tests avec sandbox iOS et Android
- [ ] Logging de tous les événements
- [ ] Gestion des erreurs et retry logic

**Configuration .env:**
```
REVENUECAT_API_KEY=...
REVENUECAT_WEBHOOK_SECRET=...
REVENUECAT_PUBLIC_SDK_KEY=...
```

---

## 📊 RÉSUMÉ DES ISSUES BACKEND

**Total**: 5 issues critiques (P0)  
**Estimation totale**: 28-38 jours  
**Modules concernés**: Matching, Notifications, Subscriptions, Chat  

**Routes backend créées**: 17+ endpoints  
**Services externes**: Python FastAPI, Firebase FCM, RevenueCat  
**État actuel**: 80% complet, infrastructure en place, intégrations manquantes  

**Priorité d'implémentation**:
1. Issue #1 - Service Python matching (bloquant pour toute la logique de sélection)
2. Issue #2 - Cron jobs (bloquant pour l'automatisation)
3. Issue #3 - Firebase FCM (bloquant pour les notifications)
4. Issue #4 - Quotas (fonctionnalité core)
5. Issue #5 - RevenueCat (monétisation)

**Dépendances à installer:**
- @nestjs/schedule
- firebase-admin
- Python 3.11+, FastAPI, uvicorn

---

### Issue Backend #6: Améliorer l'algorithme de matching avec scoring avancé

**Priorité**: P1 - Important  
**Estimation**: 5-7 jours  
**Module**: Matching (specifications.md §4.2)  
**Fichiers à créer/modifier**:
- `matching-service/services/advanced_scoring.py` (créer)
- `matching-service/services/compatibility_calculator.py` (modifier)

**Contexte (specifications.md):**
> "Algorithme de matching V1 (basé sur le contenu)"

**Description:**
Améliorer l'algorithme de matching V1 avec des facteurs avancés: activité utilisateur, taux de réponse, popularité.

**Améliorations algorithme:**

1. **Score activité** (10% du score):
   - Utilisateurs actifs récemment = bonus
   - Inactifs depuis >7 jours = pénalité

2. **Taux réponse** (10% du score):
   - Utilisateurs répondant souvent = bonus
   - Ghosters fréquents = pénalité

3. **Réciprocité potentielle** (20% du score):
   - Basé sur qui a déjà choisi qui
   - Patterns de choix similaires

**Code Python:**

```python
# matching-service/services/advanced_scoring.py

from datetime import datetime, timedelta
from typing import Dict, List

class AdvancedScoringService:
    def calculate_activity_score(self, user_data: Dict) -> float:
        """Score basé sur l'activité récente (0-10)"""
        last_active = datetime.fromisoformat(user_data['lastActiveAt'])
        days_since_active = (datetime.now() - last_active).days
        
        if days_since_active == 0:
            return 10.0  # Actif aujourd'hui
        elif days_since_active <= 3:
            return 8.0
        elif days_since_active <= 7:
            return 5.0
        elif days_since_active <= 14:
            return 2.0
        else:
            return 0.0  # Inactif

    def calculate_response_rate_score(self, user_data: Dict) -> float:
        """Score basé sur le taux de réponse aux messages (0-10)"""
        stats = user_data.get('messageStats', {})
        messages_received = stats.get('received', 0)
        messages_answered = stats.get('answered', 0)
        
        if messages_received == 0:
            return 5.0  # Neutre si pas de données
        
        response_rate = messages_answered / messages_received
        return response_rate * 10.0

    def calculate_reciprocity_score(
        self,
        user_id: str,
        candidate_id: str,
        historical_choices: List[Dict]
    ) -> float:
        """Score basé sur réciprocité potentielle (0-20)"""
        # Analyser si le candidat a choisi des profils similaires à l'utilisateur
        user_profile_type = self.get_profile_type(user_id)
        candidate_choices = [c for c in historical_choices if c['userId'] == candidate_id]
        
        similar_choices = sum(
            1 for choice in candidate_choices
            if self.get_profile_type(choice['targetUserId']) == user_profile_type
        )
        
        if not candidate_choices:
            return 10.0  # Neutre
        
        similarity_rate = similar_choices / len(candidate_choices)
        return similarity_rate * 20.0

    def calculate_final_score(
        self,
        base_compatibility: float,  # 0-100 from V1 algorithm
        user_data: Dict,
        candidate_data: Dict,
        historical_choices: List[Dict]
    ) -> Dict:
        """Calcul score final avec facteurs avancés"""
        
        # Scores additionnels
        activity_score = self.calculate_activity_score(candidate_data)
        response_score = self.calculate_response_rate_score(candidate_data)
        reciprocity_score = self.calculate_reciprocity_score(
            user_data['id'],
            candidate_data['id'],
            historical_choices
        )
        
        # Pondération:
        # - Compatibilité base: 60%
        # - Activité: 10%
        # - Taux réponse: 10%
        # - Réciprocité: 20%
        
        final_score = (
            (base_compatibility * 0.60) +
            (activity_score * 0.10) +
            (response_score * 0.10) +
            (reciprocity_score * 0.20)
        )
        
        return {
            'finalScore': round(final_score, 2),
            'breakdown': {
                'baseCompatibility': base_compatibility,
                'activityBonus': activity_score,
                'responseRateBonus': response_score,
                'reciprocityBonus': reciprocity_score
            }
        }
```

**Route à ajouter:**

```python
# Nouveau endpoint pour scoring avancé
POST /api/v1/matching/calculate-compatibility-v2
Body: {
  "userId": "uuid",
  "candidateIds": ["uuid1", "uuid2"...],
  "personalityAnswers": {...},
  "preferences": {...},
  "userLocation": {...},
  "includeAdvancedScoring": true
}
Response: {
  "compatibilityScores": [
    {
      "userId": "uuid1",
      "score": 87.5,  // Score final avec facteurs avancés
      "breakdown": {
        "personalityScore": 51,
        "preferencesScore": 34,
        "activityBonus": 8,
        "responseRateBonus": 7,
        "reciprocityBonus": 15
      },
      "matchReasons": [...]
    }
  ]
}
```

**Critères d'acceptation:**
- [ ] Facteurs avancés implémentés
- [ ] Tests avec données réelles
- [ ] Performance < 500ms pour 100 candidats
- [ ] Documentation algorithme
- [ ] A/B testing setup

---

### Issue Backend #7: Compléter système chat temps réel

**Priorité**: P1 - Important  
**Estimation**: 4-5 jours  
**Module**: Chat (specifications.md §4.3)  
**Fichiers à créer/modifier**:
- `main-api/src/modules/chat/chat.gateway.ts` (modifier)
- `main-api/src/modules/chat/services/typing-indicator.service.ts` (créer)
- `main-api/src/modules/chat/services/read-receipts.service.ts` (créer)

**Contexte (specifications.md §4.3):**
> "Le chat permet l'envoi de messages texte et d'emojis."

**Description:**
Ajouter fonctionnalités temps réel avancées: indicateur de frappe, accusés lecture, statut en ligne.

**Fonctionnalités:**

1. **Indicateur de frappe**
   - Afficher "écrit..." pendant frappe
   - Timeout 3s sans activité

2. **Accusés lecture**
   - Marquer messages comme lus
   - Afficher checkmarks

3. **Statut en ligne**
   - Vert si en ligne
   - "Vu il y a X minutes"

**Code TypeScript:**

```typescript
// main-api/src/modules/chat/chat.gateway.ts

@WebSocketGateway({
  cors: { origin: '*' },
  namespace: '/chat',
})
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private typingTimeouts = new Map<string, NodeJS.Timeout>();

  // Indicateur de frappe
  @SubscribeMessage('typing_start')
  handleTypingStart(
    @MessageBody() data: { chatId: string; userId: string },
    @ConnectedSocket() client: Socket,
  ) {
    // Broadcaster aux autres participants
    client.to(data.chatId).emit('user_typing', {
      chatId: data.chatId,
      userId: data.userId,
      isTyping: true,
    });

    // Auto-stop après 3s
    if (this.typingTimeouts.has(data.userId)) {
      clearTimeout(this.typingTimeouts.get(data.userId));
    }

    const timeout = setTimeout(() => {
      client.to(data.chatId).emit('user_typing', {
        chatId: data.chatId,
        userId: data.userId,
        isTyping: false,
      });
      this.typingTimeouts.delete(data.userId);
    }, 3000);

    this.typingTimeouts.set(data.userId, timeout);
  }

  @SubscribeMessage('typing_stop')
  handleTypingStop(
    @MessageBody() data: { chatId: string; userId: string },
    @ConnectedSocket() client: Socket,
  ) {
    if (this.typingTimeouts.has(data.userId)) {
      clearTimeout(this.typingTimeouts.get(data.userId));
      this.typingTimeouts.delete(data.userId);
    }

    client.to(data.chatId).emit('user_typing', {
      chatId: data.chatId,
      userId: data.userId,
      isTyping: false,
    });
  }

  // Accusés de lecture
  @SubscribeMessage('mark_read')
  async handleMarkAsRead(
    @MessageBody() data: { chatId: string; messageIds: string[] },
    @ConnectedSocket() client: Socket,
  ) {
    // Marquer comme lus en DB
    await this.chatService.markMessagesAsRead(data.chatId, data.messageIds);

    // Notifier l'autre participant
    client.to(data.chatId).emit('messages_read', {
      chatId: data.chatId,
      messageIds: data.messageIds,
      readAt: new Date().toISOString(),
    });
  }

  // Statut en ligne
  async handleConnection(client: Socket) {
    const userId = this.extractUserIdFromToken(client.handshake.auth.token);
    
    // Rejoindre room personnelle
    client.join(`user:${userId}`);
    
    // Notifier que l'utilisateur est en ligne
    await this.presenceService.setUserOnline(userId);
    
    // Broadcaster aux chats actifs
    const activeChats = await this.chatService.getUserActiveChats(userId);
    activeChats.forEach(chat => {
      client.to(chat.id).emit('user_online', {
        userId,
        onlineAt: new Date().toISOString(),
      });
    });
  }

  async handleDisconnect(client: Socket) {
    const userId = this.extractUserIdFromToken(client.handshake.auth.token);
    
    // Marquer comme hors ligne
    await this.presenceService.setUserOffline(userId);
    
    // Broadcaster
    const activeChats = await this.chatService.getUserActiveChats(userId);
    activeChats.forEach(chat => {
      client.to(chat.id).emit('user_offline', {
        userId,
        offlineAt: new Date().toISOString(),
      });
    });
  }
}

// main-api/src/modules/chat/services/read-receipts.service.ts

@Injectable()
export class ReadReceiptsService {
  async markMessagesAsRead(
    chatId: string,
    messageIds: string[],
    userId: string,
  ): Promise<void> {
    await this.messageRepository
      .createQueryBuilder()
      .update(Message)
      .set({
        readAt: new Date(),
        readBy: userId,
      })
      .where('id IN (:...messageIds)', { messageIds })
      .andWhere('chatId = :chatId', { chatId })
      .andWhere('senderId != :userId', { userId }) // Ne pas marquer ses propres messages
      .execute();
  }

  async getUnreadCount(chatId: string, userId: string): Promise<number> {
    return await this.messageRepository.count({
      where: {
        chatId,
        senderId: Not(userId),
        readAt: IsNull(),
      },
    });
  }
}
```

**Routes REST additionnelles:**

```typescript
// Récupérer statut en ligne
GET /api/v1/users/:userId/presence
Response: {
  "userId": "uuid",
  "isOnline": true,
  "lastSeenAt": "2025-01-15T16:30:00Z"
}

// Marquer messages comme lus (REST fallback)
POST /api/v1/chat/:chatId/messages/read
Body: {
  "messageIds": ["uuid1", "uuid2"]
}
Response: {
  "success": true,
  "readCount": 2
}
```

**Critères d'acceptation:**
- [ ] Indicateur frappe fonctionnel
- [ ] Accusés lecture avec checkmarks
- [ ] Statut en ligne/hors ligne
- [ ] WebSocket events bien émis
- [ ] Fallback REST si WebSocket fail
- [ ] Tests temps réel

---

### Issue Backend #8: Modération contenu automatisée

**Priorité**: P2 - Nice to have  
**Estimation**: 5-7 jours  
**Module**: Modération (specifications.md §4.5)  
**Fichiers à créer**:
- `main-api/src/modules/moderation/services/ai-moderation.service.ts`
- `main-api/src/modules/moderation/services/image-moderation.service.ts`

**Contexte (specifications.md §4.5):**
> "Outils de modération de contenu (IA/manuelle)."

**Description:**
Implémenter modération automatique avec détection contenu inapproprié (texte et images).

**Services à intégrer:**

1. **Modération texte**
   - API OpenAI Moderation
   - Détection toxicité, spam, sexuel

2. **Modération images**
   - AWS Rekognition ou Google Vision API
   - Détection nudité, violence

**Code:**

```typescript
// main-api/src/modules/moderation/services/ai-moderation.service.ts

import { OpenAI } from 'openai';

@Injectable()
export class AIModerationService {
  private openai: OpenAI;

  constructor() {
    this.openai = new OpenAI({
      apiKey: process.env.OPENAI_API_KEY,
    });
  }

  async moderateText(text: string): Promise<ModerationResult> {
    const moderation = await this.openai.moderations.create({
      input: text,
    });

    const result = moderation.results[0];

    return {
      flagged: result.flagged,
      categories: result.categories,
      categoryScores: result.category_scores,
      action: result.flagged ? 'block' : 'allow',
    };
  }

  async moderateMessage(messageId: string, content: string): Promise<void> {
    const modResult = await this.moderateText(content);

    if (modResult.flagged) {
      // Bloquer le message
      await this.messageRepository.update(messageId, {
        status: 'blocked',
        moderationFlags: modResult.categories,
      });

      // Créer rapport auto
      await this.reportsService.createAutoReport({
        type: 'message',
        targetId: messageId,
        reason: 'ai_moderation',
        flags: modResult.categories,
        severity: this.calculateSeverity(modResult.categoryScores),
      });

      // Notifier admins si sévère
      if (this.calculateSeverity(modResult.categoryScores) >= 0.8) {
        await this.notifyAdmins(messageId, modResult);
      }
    }
  }

  async moderateProfileBio(userId: string, bio: string): Promise<boolean> {
    const modResult = await this.moderateText(bio);

    if (modResult.flagged) {
      await this.usersService.flagProfile(userId, {
        reason: 'inappropriate_bio',
        details: modResult,
      });
      return false; // Refusé
    }

    return true; // Accepté
  }

  private calculateSeverity(scores: Record<string, number>): number {
    return Math.max(...Object.values(scores));
  }
}

// main-api/src/modules/moderation/services/image-moderation.service.ts

import { RekognitionClient, DetectModerationLabelsCommand } from '@aws-sdk/client-rekognition';

@Injectable()
export class ImageModerationService {
  private rekognition: RekognitionClient;

  constructor() {
    this.rekognition = new RekognitionClient({
      region: process.env.AWS_REGION,
      credentials: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID,
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
      },
    });
  }

  async moderateImage(imageUrl: string): Promise<ImageModerationResult> {
    // Télécharger image
    const imageBuffer = await this.downloadImage(imageUrl);

    // Analyser avec Rekognition
    const command = new DetectModerationLabelsCommand({
      Image: { Bytes: imageBuffer },
      MinConfidence: 60, // Seuil 60%
    });

    const response = await this.rekognition.send(command);

    const inappropriateLabels = response.ModerationLabels.filter(
      label => label.Confidence >= 70
    );

    return {
      flagged: inappropriateLabels.length > 0,
      labels: inappropriateLabels.map(l => ({
        name: l.Name,
        confidence: l.Confidence,
        parentName: l.ParentName,
      })),
      action: inappropriateLabels.length > 0 ? 'block' : 'allow',
    };
  }

  async moderateProfilePhoto(photoId: string, imageUrl: string): Promise<void> {
    const modResult = await this.moderateImage(imageUrl);

    if (modResult.flagged) {
      // Bloquer la photo
      await this.photosRepository.update(photoId, {
        status: 'blocked',
        moderationFlags: modResult.labels.map(l => l.name),
      });

      // Créer rapport
      await this.reportsService.createAutoReport({
        type: 'photo',
        targetId: photoId,
        reason: 'ai_moderation_image',
        flags: modResult.labels,
      });

      // Notifier utilisateur
      await this.notificationsService.sendPhotoRejectionNotification(
        await this.getPhotoOwnerId(photoId)
      );
    }
  }
}
```

**Routes:**

```typescript
// Webhook modération (appelé après upload photo)
POST /webhooks/moderation/photo/:photoId
Internal only (appelé par backend après upload)

// Obtenir statut modération
GET /api/v1/moderation/status/:resourceType/:resourceId
Response: {
  "status": "approved" | "pending" | "blocked",
  "flags": ["Explicit Nudity"],
  "moderatedAt": "2025-01-15T10:00:00Z",
  "moderator": "ai" | "admin-id"
}
```

**Critères d'acceptation:**
- [ ] OpenAI Moderation intégré
- [ ] AWS Rekognition intégré
- [ ] Messages bloqués automatiquement
- [ ] Photos bloquées automatiquement
- [ ] Rapports auto créés
- [ ] Notifications admins
- [ ] Dashboard modération

---

### Issue Backend #9: Conformité RGPD complète

**Priorité**: P1 - Important  
**Estimation**: 4-5 jours  
**Module**: RGPD (specifications.md Annexe A)  
**Fichiers à créer**:
- `main-api/src/modules/gdpr/gdpr.controller.ts`
- `main-api/src/modules/gdpr/gdpr.service.ts`
- `main-api/src/modules/gdpr/data-export.service.ts`

**Contexte (specifications.md Annexe A):**
> "Conformité RGPD obligatoire: consentement, droit à l'oubli, portabilité."

**Description:**
Implémenter endpoints RGPD: export données, suppression compte, consentements.

**Fonctionnalités:**

1. **Export données** (Art. 20 RGPD)
2. **Suppression compte** (Art. 17 RGPD)
3. **Gestion consentements** (Art. 7 RGPD)
4. **Historique modifications**

**Code complet dans l'issue Frontend #10** (routes identiques)

**Schéma DB:**

```sql
CREATE TABLE user_consents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  consent_type VARCHAR(50) NOT NULL,
  consented BOOLEAN NOT NULL,
  consented_at TIMESTAMP,
  ip_address VARCHAR(45),
  user_agent TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE data_export_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status VARCHAR(20) DEFAULT 'processing',
  requested_at TIMESTAMP DEFAULT NOW(),
  completed_at TIMESTAMP,
  download_url TEXT,
  expires_at TIMESTAMP,
  file_size BIGINT
);

CREATE TABLE account_deletions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id),
  requested_at TIMESTAMP DEFAULT NOW(),
  scheduled_deletion_at TIMESTAMP,
  deleted_at TIMESTAMP,
  reason TEXT,
  cancelled_at TIMESTAMP
);
```

**Critères d'acceptation:**
- [ ] Export données JSON complet
- [ ] Email avec lien téléchargement
- [ ] Suppression avec délai grâce 30j
- [ ] Consentements trackés en DB
- [ ] IP et user-agent enregistrés
- [ ] Conformité RGPD 100%

---

### Issue Backend #10: Intégrer analytics (Mixpanel/Amplitude)

**Priorité**: P2 - Nice to have  
**Estimation**: 3-4 jours  
**Module**: Analytics (specifications.md §4.5)  
**Fichiers à créer**:
- `main-api/src/modules/analytics/analytics.service.ts`
- `main-api/src/modules/analytics/analytics.middleware.ts`

**Contexte:**
Tracker événements utilisateurs pour améliorer le produit.

**Événements à tracker:**

1. **Onboarding**
   - signup_started
   - personality_quiz_completed
   - profile_completed
   
2. **Matching**
   - daily_selection_viewed
   - profile_chosen
   - match_created

3. **Chat**
   - chat_accepted
   - first_message_sent
   - chat_expired

4. **Subscription**
   - subscription_page_viewed
   - subscription_started
   - subscription_cancelled

**Code:**

```typescript
// main-api/src/modules/analytics/analytics.service.ts

import Mixpanel from 'mixpanel';

@Injectable()
export class AnalyticsService {
  private mixpanel: Mixpanel.Mixpanel;

  constructor() {
    this.mixpanel = Mixpanel.init(process.env.MIXPANEL_TOKEN);
  }

  track(userId: string, event: string, properties?: Record<string, any>) {
    this.mixpanel.track(event, {
      distinct_id: userId,
      ...properties,
      timestamp: new Date().toISOString(),
      environment: process.env.NODE_ENV,
    });
  }

  identify(userId: string, traits: Record<string, any>) {
    this.mixpanel.people.set(userId, {
      ...traits,
      $last_seen: new Date().toISOString(),
    });
  }

  // Événements spécifiques
  trackSignup(userId: string, method: string) {
    this.track(userId, 'signup_started', { method });
  }

  trackProfileCompleted(userId: string) {
    this.track(userId, 'profile_completed');
    this.identify(userId, {
      profile_completed_at: new Date().toISOString(),
    });
  }

  trackMatch(userId: string, matchId: string) {
    this.track(userId, 'match_created', { matchId });
  }

  trackSubscription(userId: string, tier: string, period: string) {
    this.track(userId, 'subscription_started', { tier, period });
    this.identify(userId, {
      subscription_tier: tier,
      subscribed_at: new Date().toISOString(),
    });
  }
}
```

**Critères d'acceptation:**
- [ ] Mixpanel SDK intégré
- [ ] Événements critiques trackés
- [ ] Properties cohérentes
- [ ] RGPD compliant (opt-out possible)
- [ ] Dashboard Mixpanel configuré

---

### Issue Backend #11: Service email transactionnel

**Priorité**: P1 - Important  
**Estimation**: 2-3 jours  
**Module**: Notifications  
**Fichiers à créer**:
- `main-api/src/modules/email/email.service.ts`
- Templates emails

**Description:**
Intégrer SendGrid/Mailgun pour emails transactionnels.

**Emails à envoyer:**

1. Welcome email
2. Export données prêt
3. Compte supprimé
4. Subscription confirmée

**Code:**

```typescript
import * as sgMail from '@sendgrid/mail';

@Injectable()
export class EmailService {
  constructor() {
    sgMail.setApiKey(process.env.SENDGRID_API_KEY);
  }

  async sendWelcomeEmail(user: User) {
    await sgMail.send({
      to: user.email,
      from: 'welcome@goldwen.app',
      templateId: process.env.WELCOME_TEMPLATE_ID,
      dynamicTemplateData: {
        firstName: user.firstName,
      },
    });
  }

  async sendDataExportReady(user: User, downloadUrl: string) {
    await sgMail.send({
      to: user.email,
      from: 'noreply@goldwen.app',
      templateId: process.env.DATA_EXPORT_TEMPLATE_ID,
      dynamicTemplateData: {
        firstName: user.firstName,
        downloadUrl,
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      },
    });
  }
}
```

**Critères d'acceptation:**
- [ ] SendGrid intégré
- [ ] Templates créés
- [ ] 4 emails fonctionnels
- [ ] Logs envois
- [ ] Gestion erreurs

---

### Issue Backend #12: Rate limiting et sécurité

**Priorité**: P1 - Important  
**Estimation**: 2-3 jours  
**Module**: Sécurité (specifications.md §5)  
**Fichiers à créer**:
- `main-api/src/common/guards/rate-limit.guard.ts`
- `main-api/src/common/guards/brute-force.guard.ts`

**Description:**
Protéger API contre abus avec rate limiting et détection brute force.

**Limites:**

- 100 req/min global par IP
- 20 req/min par endpoint sensible
- 5 tentatives login par 15min

**Code:**

```typescript
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';

// app.module.ts
@Module({
  imports: [
    ThrottlerModule.forRoot({
      ttl: 60,
      limit: 100,
    }),
  ],
})

// Endpoints sensibles
@UseGuards(ThrottlerGuard)
@Throttle(20, 60) // 20 req/60s
@Post('login')
async login() {}
```

**Critères d'acceptation:**
- [ ] Rate limiting global
- [ ] Limites par endpoint
- [ ] Détection brute force
- [ ] Headers X-RateLimit
- [ ] Logs tentatives

---

### Issue Backend #13: Algorithme matching V2 avec ML

**Priorité**: P3 - V2  
**Estimation**: 15-20 jours  
**Module**: Matching V2  

**Description:**
Remplacer algorithme V1 par ML collaboratif.

**Approche:**
- Collaborative filtering
- TensorFlow Recommenders
- Training sur données historiques

(Détails complets dans issue séparée V2)

---

### Issue Backend #14: Support profils audio/vidéo

**Priorité**: P3 - V2  
**Estimation**: 10-12 jours  
**Module**: Profils V2  

**Description:**
Ajouter upload et lecture audio/vidéo profils.

(Détails complets dans issue séparée V2)

---

### Issue Backend #15: Vérification profil photo/vidéo

**Priorité**: P3 - V2  
**Estimation**: 8-10 jours  
**Module**: Vérification  

**Description:**
Vérification identité via selfie vidéo.

(Détails complets dans issue séparée V2)

---

## 📊 RÉSUMÉ DES ISSUES BACKEND (COMPLET)

**Total**: 15 issues  
**Estimation totale**: 59-78 jours (28-38 jours pour MVP P0-P1)  
**Modules concernés**: Tous modules MVP + V2  

**Répartition par priorité**:
- 🔥 **P0 - Critiques** (Issues #1-5): 28-38 jours - MVP BLOQUANT
- ⚡ **P1 - Importantes** (Issues #6-7, #9-12): 22-30 jours - MVP requis
- 🔧 **P2 - Nice to have** (Issue #8): 5-7 jours - Amélioration
- 📦 **P3 - V2** (Issues #13-15): 33-42 jours - Post-MVP

**Routes backend créées**: 50+ endpoints  
**Services externes**: Python/FastAPI, Firebase FCM, RevenueCat, OpenAI, AWS, SendGrid  
**État actuel**: 80% complet, infrastructure en place  

**Ordre d'implémentation recommandé**:
1. **Phase 1 - MVP P0** (Issues #1-5): Python matching, Cron jobs, FCM, Quotas, RevenueCat
2. **Phase 2 - MVP P1** (Issues #6-7, #9-12): Scoring avancé, Chat temps réel, RGPD, Analytics, Emails, Rate limiting
3. **Phase 3 - Améliorations** (Issue #8): Modération AI
4. **Phase 4 - V2** (Issues #13-15): ML, Audio/Vidéo, Vérification

**Dépendances à installer**:
- @nestjs/schedule
- @nestjs/throttler
- firebase-admin
- Python 3.11+, FastAPI, uvicorn
- @sendgrid/mail
- openai
- @aws-sdk/client-rekognition
- mixpanel

---

*Document complet prêt pour création d'issues GitHub individuelles*  
*Chaque issue peut être assignée à un développeur backend avec specs complètes*  
*Total 15 issues couvrant 100% des fonctionnalités manquantes backend*
