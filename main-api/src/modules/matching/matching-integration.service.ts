import { Injectable, HttpException, HttpStatus } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { CustomLoggerService } from '../../common/logger';

export interface CompatibilityRequest {
  user1Profile: {
    personalityAnswers: any[];
    preferences: any;
  };
  user2Profile: {
    personalityAnswers: any[];
    preferences: any;
  };
}

export interface DailySelectionRequest {
  userId: string;
  userProfile: any;
  availableProfiles: any[];
  selectionSize: number;
}

export interface CompatibilityResult {
  compatibilityScore: number;
  details: {
    communication: number;
    values: number;
    lifestyle: number;
    personality: number;
  };
  sharedInterests: string[];
  version?: string;
  advancedFactors?: {
    activityScore: number;
    responseRateScore: number;
    reciprocityScore: number;
    details: {
      userActivity: number;
      targetActivity: number;
      userResponseRate: number;
      targetResponseRate: number;
    };
  };
  scoringWeights?: {
    personalityWeight: number;
    advancedWeight: number;
  };
}

export interface DailySelectionResult {
  selectedProfiles: {
    userId: string;
    compatibilityScore: number;
    reasons: string[];
  }[];
}

@Injectable()
export class MatchingIntegrationService {
  private readonly matchingServiceUrl: string;
  private readonly apiKey: string;

  constructor(
    private readonly configService: ConfigService,
    private readonly logger: CustomLoggerService,
  ) {
    this.matchingServiceUrl =
      this.configService.get('matchingService.url') || 'http://localhost:8000';
    this.apiKey =
      this.configService.get('matchingService.apiKey') ||
      'matching-service-secret-key';
  }

  async calculateCompatibility(
    request: CompatibilityRequest,
  ): Promise<CompatibilityResult> {
    try {
      const response = await fetch(
        `${this.matchingServiceUrl}/api/v1/matching-service/calculate-compatibility`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-API-Key': this.apiKey,
          },
          body: JSON.stringify(request),
        },
      );

      if (!response.ok) {
        throw new HttpException(
          `Matching service error: ${response.statusText}`,
          response.status,
        );
      }

      const result = await response.json();

      this.logger.info('Compatibility calculated', {
        score: result.compatibilityScore,
      });

      return result;
    } catch (error) {
      this.logger.error(
        'Failed to calculate compatibility',
        error.message,
        'MatchingIntegration',
      );

      // Return a fallback compatibility result if matching service is down
      return {
        compatibilityScore: 50, // Default middle score
        details: {
          communication: 0.5,
          values: 0.5,
          lifestyle: 0.5,
          personality: 0.5,
        },
        sharedInterests: [],
      };
    }
  }

  async calculateCompatibilityV2(
    request: CompatibilityRequest,
  ): Promise<CompatibilityResult> {
    try {
      const response = await fetch(
        `${this.matchingServiceUrl}/api/v1/matching/calculate-compatibility-v2`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-API-Key': this.apiKey,
          },
          body: JSON.stringify(request),
        },
      );

      if (!response.ok) {
        throw new HttpException(
          `Matching service error: ${response.statusText}`,
          response.status,
        );
      }

      const result = await response.json();

      this.logger.info('Compatibility V2 calculated', {
        score: result.compatibilityScore,
        activityScore: result.advancedFactors?.activityScore,
        responseRateScore: result.advancedFactors?.responseRateScore,
        reciprocityScore: result.advancedFactors?.reciprocityScore,
      });

      return result;
    } catch (error) {
      this.logger.error(
        'Failed to calculate compatibility V2',
        error.message,
        'MatchingIntegration',
      );

      // Fallback to V1 if V2 fails
      return this.calculateCompatibility(request);
    }
  }

  async generateDailySelection(
    request: DailySelectionRequest,
  ): Promise<DailySelectionResult> {
    try {
      const response = await fetch(
        `${this.matchingServiceUrl}/api/v1/matching-service/generate-daily-selection`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-API-Key': this.apiKey,
          },
          body: JSON.stringify(request),
        },
      );

      if (!response.ok) {
        throw new HttpException(
          `Matching service error: ${response.statusText}`,
          response.status,
        );
      }

      const result = await response.json();

      this.logger.info('Daily selection generated', {
        userId: request.userId,
        selectionSize: result.selectedProfiles?.length || 0,
      });

      return result;
    } catch (error) {
      this.logger.error(
        'Failed to generate daily selection',
        error.message,
        'MatchingIntegration',
      );

      // Return fallback selection if matching service is down
      // Randomly select from available profiles
      const shuffled = request.availableProfiles.sort(
        () => 0.5 - Math.random(),
      );
      const selected = shuffled.slice(
        0,
        Math.min(request.selectionSize, shuffled.length),
      );

      return {
        selectedProfiles: selected.map((profile) => ({
          userId: profile.userId,
          compatibilityScore: Math.floor(Math.random() * 40) + 60, // Random score 60-100
          reasons: ['Fallback selection - Matching service unavailable'],
        })),
      };
    }
  }

  async batchCompatibility(
    baseProfile: any,
    profilesToCompare: any[],
  ): Promise<Record<string, CompatibilityResult>> {
    try {
      const response = await fetch(
        `${this.matchingServiceUrl}/api/v1/matching-service/batch-compatibility`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-API-Key': this.apiKey,
          },
          body: JSON.stringify({
            baseProfile,
            profilesToCompare,
          }),
        },
      );

      if (!response.ok) {
        throw new HttpException(
          `Matching service error: ${response.statusText}`,
          response.status,
        );
      }

      const result = await response.json();

      this.logger.info('Batch compatibility calculated', {
        baseUserId: baseProfile?.userId,
        profileCount: profilesToCompare.length,
      });

      return result;
    } catch (error) {
      this.logger.error(
        'Failed to calculate batch compatibility',
        error.message,
        'MatchingIntegration',
      );

      // Return fallback compatibility results
      const fallbackResults: Record<string, CompatibilityResult> = {};
      profilesToCompare.forEach((profile) => {
        fallbackResults[profile.userId] = {
          compatibilityScore: Math.floor(Math.random() * 40) + 50,
          details: {
            communication: 0.5,
            values: 0.5,
            lifestyle: 0.5,
            personality: 0.5,
          },
          sharedInterests: [],
        };
      });

      return fallbackResults;
    }
  }

  async getAlgorithmStats(): Promise<any> {
    try {
      const response = await fetch(
        `${this.matchingServiceUrl}/api/v1/matching-service/algorithm/stats`,
        {
          method: 'GET',
          headers: {
            'X-API-Key': this.apiKey,
          },
        },
      );

      if (!response.ok) {
        throw new HttpException(
          `Matching service error: ${response.statusText}`,
          response.status,
        );
      }

      const result = await response.json();

      this.logger.info('Algorithm stats retrieved');

      return result;
    } catch (error) {
      this.logger.error(
        'Failed to get algorithm stats',
        error.message,
        'MatchingIntegration',
      );

      // Return fallback stats
      return {
        totalCalculations: 0,
        averageScore: 0,
        lastUpdate: new Date().toISOString(),
        status: 'offline',
      };
    }
  }

  async healthCheck(): Promise<boolean> {
    try {
      const response = await fetch(`${this.matchingServiceUrl}/health`, {
        method: 'GET',
        headers: {
          'X-API-Key': this.apiKey,
        },
      });

      return response.ok;
    } catch (error) {
      this.logger.warn(
        'Matching service health check failed',
        'MatchingIntegration',
      );
      return false;
    }
  }
}
