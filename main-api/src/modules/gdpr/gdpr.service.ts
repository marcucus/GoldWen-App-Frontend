import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import {
  AccountDeletion,
  DeletionStatus,
} from '../../database/entities/account-deletion.entity';
import { ExportFormat } from '../../database/entities/data-export-request.entity';
import { User } from '../../database/entities/user.entity';
import { Profile } from '../../database/entities/profile.entity';
import { Match } from '../../database/entities/match.entity';
import { Message } from '../../database/entities/message.entity';
import { Subscription } from '../../database/entities/subscription.entity';
import { DailySelection } from '../../database/entities/daily-selection.entity';
import { UserConsent } from '../../database/entities/user-consent.entity';
import { PushToken } from '../../database/entities/push-token.entity';
import { Notification } from '../../database/entities/notification.entity';
import { Report } from '../../database/entities/report.entity';
import { DataExportService } from './data-export.service';

@Injectable()
export class GdprService {
  private readonly logger = new Logger(GdprService.name);

  constructor(
    @InjectRepository(AccountDeletion)
    private accountDeletionRepository: Repository<AccountDeletion>,
    @InjectRepository(User)
    private userRepository: Repository<User>,
    @InjectRepository(Profile)
    private profileRepository: Repository<Profile>,
    @InjectRepository(Match)
    private matchRepository: Repository<Match>,
    @InjectRepository(Message)
    private messageRepository: Repository<Message>,
    @InjectRepository(Subscription)
    private subscriptionRepository: Repository<Subscription>,
    @InjectRepository(DailySelection)
    private dailySelectionRepository: Repository<DailySelection>,
    @InjectRepository(UserConsent)
    private userConsentRepository: Repository<UserConsent>,
    @InjectRepository(PushToken)
    private pushTokenRepository: Repository<PushToken>,
    @InjectRepository(Notification)
    private notificationRepository: Repository<Notification>,
    @InjectRepository(Report)
    private reportRepository: Repository<Report>,
    private dataExportService: DataExportService,
  ) {}

  /**
   * Request data export for GDPR compliance
   * Art. 20 RGPD - Right to data portability
   */
  async requestDataExport(userId: string, format: 'json' | 'pdf' = 'json') {
    this.logger.log(
      `Data export requested for user ${userId} in format ${format}`,
    );

    const exportFormat =
      format === 'pdf' ? ExportFormat.PDF : ExportFormat.JSON;
    return this.dataExportService.createExportRequest(userId, exportFormat);
  }

  /**
   * Get data export request status
   */
  async getExportRequestStatus(userId: string, requestId: string) {
    const request = await this.dataExportService.getExportRequest(
      userId,
      requestId,
    );

    if (!request) {
      throw new NotFoundException('Export request not found');
    }

    return request;
  }

  /**
   * Get all export requests for a user
   */
  async getUserExportRequests(userId: string) {
    return this.dataExportService.getUserExportRequests(userId);
  }

  /**
   * Request account deletion
   * Art. 17 RGPD - Right to be forgotten
   */
  async requestAccountDeletion(
    userId: string,
    reason?: string,
  ): Promise<AccountDeletion> {
    this.logger.log(`Account deletion requested for user ${userId}`);

    const user = await this.userRepository.findOne({ where: { id: userId } });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const deletionRequest = this.accountDeletionRepository.create({
      userId,
      userEmail: user.email,
      status: DeletionStatus.PENDING,
      reason,
      requestedAt: new Date(),
    });

    const savedRequest =
      await this.accountDeletionRepository.save(deletionRequest);

    // Process deletion asynchronously
    this.processDeletionRequest(savedRequest.id).catch((error) => {
      this.logger.error(
        `Failed to process deletion request ${savedRequest.id}:`,
        error,
      );
    });

    return savedRequest;
  }

  /**
   * Process account deletion with full anonymization
   * Art. 17 RGPD - Complete data erasure
   */
  async processDeletionRequest(requestId: string): Promise<void> {
    const request = await this.accountDeletionRepository.findOne({
      where: { id: requestId },
    });

    if (!request) {
      this.logger.error(`Deletion request ${requestId} not found`);
      return;
    }

    try {
      // Update status to processing
      await this.accountDeletionRepository.update(requestId, {
        status: DeletionStatus.PROCESSING,
      });

      const userId = request.userId;

      // Anonymize and track metrics
      const messagesAnonymized = await this.anonymizeUserMessages(userId);
      const matchesAnonymized = await this.anonymizeUserMatches(userId);
      const reportsAnonymized = await this.anonymizeReportsAgainstUser(userId);

      // Delete related data in proper order
      await Promise.all([
        this.pushTokenRepository.delete({ userId }),
        this.userConsentRepository.delete({ userId }),
        this.notificationRepository.delete({ userId }),
        this.dailySelectionRepository.delete({ userId }),
      ]);

      // Delete reports made by user
      await this.reportRepository.delete({ reporterId: userId });

      // Delete subscriptions
      await this.subscriptionRepository.delete({ userId });

      // Delete profile
      await this.profileRepository.delete({ userId });

      // Finally delete the user
      await this.userRepository.delete({ id: userId });

      // Update deletion record with completion status
      await this.accountDeletionRepository.update(requestId, {
        status: DeletionStatus.COMPLETED,
        completedAt: new Date(),
        metadata: {
          messagesAnonymized,
          matchesAnonymized,
          reportsAnonymized,
          dataExported: false, // Could track if data was exported before deletion
        },
      });

      this.logger.log(`Account deletion ${requestId} completed successfully`);
    } catch (error) {
      this.logger.error(
        `Error processing deletion request ${requestId}:`,
        error,
      );
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      await this.accountDeletionRepository.update(requestId, {
        status: DeletionStatus.FAILED,
        errorMessage,
      });
    }
  }

  /**
   * Get deletion request status
   */
  async getDeletionRequestStatus(
    userId: string,
    requestId: string,
  ): Promise<AccountDeletion> {
    const request = await this.accountDeletionRepository.findOne({
      where: { id: requestId, userId },
    });

    if (!request) {
      throw new NotFoundException('Deletion request not found');
    }

    return request;
  }

  /**
   * Record user consent
   * Art. 7 RGPD - Consent management
   */
  async recordConsent(
    userId: string,
    consentData: {
      dataProcessing: boolean;
      marketing?: boolean;
      analytics?: boolean;
      consentedAt: string;
    },
  ): Promise<UserConsent> {
    // Deactivate previous consents
    await this.userConsentRepository.update(
      { userId, isActive: true },
      { isActive: false, revokedAt: new Date() },
    );

    // Create new consent record
    const consent = this.userConsentRepository.create({
      userId,
      dataProcessing: consentData.dataProcessing,
      marketing: consentData.marketing ?? false,
      analytics: consentData.analytics ?? false,
      consentedAt: new Date(consentData.consentedAt),
      isActive: true,
    });

    this.logger.log(`Consent recorded for user ${userId}`);

    return this.userConsentRepository.save(consent);
  }

  /**
   * Get current consent for a user
   */
  async getCurrentConsent(userId: string): Promise<UserConsent | null> {
    return this.userConsentRepository.findOne({
      where: { userId, isActive: true },
      order: { createdAt: 'DESC' },
    });
  }

  /**
   * Get consent history for a user
   * Art. 7 RGPD - Consent history tracking
   */
  async getConsentHistory(userId: string): Promise<UserConsent[]> {
    return this.userConsentRepository.find({
      where: { userId },
      order: { createdAt: 'DESC' },
    });
  }

  /**
   * Revoke current consent
   */
  async revokeConsent(userId: string): Promise<void> {
    await this.userConsentRepository.update(
      { userId, isActive: true },
      { isActive: false, revokedAt: new Date() },
    );

    this.logger.log(`Consent revoked for user ${userId}`);
  }

  // Private helper methods for anonymization

  /**
   * Anonymize user messages
   */
  private async anonymizeUserMessages(userId: string): Promise<number> {
    const result = await this.messageRepository.update(
      { senderId: userId },
      { senderId: 'deleted-user' },
    );

    return result.affected || 0;
  }

  /**
   * Anonymize user matches
   */
  private async anonymizeUserMatches(userId: string): Promise<number> {
    const result1 = await this.matchRepository.update(
      { user1Id: userId },
      { user1Id: 'deleted-user' },
    );

    const result2 = await this.matchRepository.update(
      { user2Id: userId },
      { user2Id: 'deleted-user' },
    );

    return (result1.affected || 0) + (result2.affected || 0);
  }

  /**
   * Anonymize reports against the user
   */
  private async anonymizeReportsAgainstUser(userId: string): Promise<number> {
    const result = await this.reportRepository.update(
      { reportedUserId: userId },
      { reportedUserId: 'deleted-user' },
    );

    return result.affected || 0;
  }
}
