import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../../../database/entities/user.entity';
import { CustomLoggerService } from '../../../common/logger';

export interface PresenceStatus {
  userId: string;
  isOnline: boolean;
  lastSeen: Date;
}

@Injectable()
export class PresenceService {
  private onlineUsers: Map<string, Date> = new Map();
  private readonly ONLINE_THRESHOLD_MS = 30000; // 30 seconds

  constructor(
    @InjectRepository(User)
    private userRepository: Repository<User>,
    private readonly logger: CustomLoggerService,
  ) {}

  /**
   * Mark user as online
   */
  async setUserOnline(userId: string): Promise<void> {
    const now = new Date();
    this.onlineUsers.set(userId, now);

    // Update lastActiveAt in database
    await this.userRepository.update(userId, {
      lastActiveAt: now,
    });

    this.logger.info('User marked as online', { userId });
  }

  /**
   * Mark user as offline
   */
  async setUserOffline(userId: string): Promise<void> {
    this.onlineUsers.delete(userId);

    // Update lastActiveAt in database
    await this.userRepository.update(userId, {
      lastActiveAt: new Date(),
    });

    this.logger.info('User marked as offline', { userId });
  }

  /**
   * Update user activity timestamp
   */
  updateUserActivity(userId: string): void {
    this.onlineUsers.set(userId, new Date());
  }

  /**
   * Check if user is currently online
   */
  isUserOnline(userId: string): boolean {
    const lastActivity = this.onlineUsers.get(userId);
    if (!lastActivity) {
      return false;
    }

    const now = Date.now();
    const lastActivityTime = lastActivity.getTime();

    // Consider user online if activity within threshold
    return now - lastActivityTime < this.ONLINE_THRESHOLD_MS;
  }

  /**
   * Get user's last seen time
   */
  async getLastSeen(userId: string): Promise<Date | null> {
    // Check in-memory first
    const onlineActivity = this.onlineUsers.get(userId);
    if (onlineActivity) {
      return onlineActivity;
    }

    // Fall back to database
    const user = await this.userRepository.findOne({
      where: { id: userId },
      select: ['id', 'lastActiveAt'],
    });

    return user?.lastActiveAt || null;
  }

  /**
   * Get presence status for a user
   */
  async getPresenceStatus(userId: string): Promise<PresenceStatus> {
    const isOnline = this.isUserOnline(userId);
    const lastSeen = await this.getLastSeen(userId);

    return {
      userId,
      isOnline,
      lastSeen: lastSeen || new Date(),
    };
  }

  /**
   * Get presence status for multiple users
   */
  async getMultiplePresenceStatus(
    userIds: string[],
  ): Promise<PresenceStatus[]> {
    const statuses = await Promise.all(
      userIds.map((userId) => this.getPresenceStatus(userId)),
    );

    return statuses;
  }

  /**
   * Get all currently online users
   */
  getOnlineUsers(): string[] {
    const now = Date.now();
    const onlineUsers: string[] = [];

    for (const [userId, lastActivity] of this.onlineUsers.entries()) {
      if (now - lastActivity.getTime() < this.ONLINE_THRESHOLD_MS) {
        onlineUsers.push(userId);
      }
    }

    return onlineUsers;
  }

  /**
   * Clean up stale online statuses
   */
  cleanupStaleStatuses(): number {
    const now = Date.now();
    let cleaned = 0;

    for (const [userId, lastActivity] of this.onlineUsers.entries()) {
      if (now - lastActivity.getTime() >= this.ONLINE_THRESHOLD_MS * 2) {
        this.onlineUsers.delete(userId);
        cleaned++;
      }
    }

    if (cleaned > 0) {
      this.logger.info('Cleaned up stale presence statuses', {
        count: cleaned,
      });
    }

    return cleaned;
  }

  /**
   * Format last seen time in a human-readable format
   */
  formatLastSeen(lastSeen: Date): string {
    const now = Date.now();
    const lastSeenTime = lastSeen.getTime();
    const diffMs = now - lastSeenTime;

    const diffMinutes = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMs / 3600000);
    const diffDays = Math.floor(diffMs / 86400000);

    if (diffMinutes < 1) {
      return "À l'instant";
    } else if (diffMinutes < 60) {
      return `Il y a ${diffMinutes} min`;
    } else if (diffHours < 24) {
      return `Il y a ${diffHours}h`;
    } else if (diffDays === 1) {
      return 'Hier';
    } else if (diffDays < 7) {
      return `Il y a ${diffDays} jours`;
    } else {
      return lastSeen.toLocaleDateString('fr-FR');
    }
  }
}
