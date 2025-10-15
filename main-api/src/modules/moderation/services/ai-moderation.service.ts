import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import OpenAI from 'openai';
import { CustomLoggerService } from '../../../common/logger';

export interface TextModerationResult {
  flagged: boolean;
  categories: {
    sexual: boolean;
    hate: boolean;
    harassment: boolean;
    selfHarm: boolean;
    sexualMinors: boolean;
    hateThreatening: boolean;
    violenceGraphic: boolean;
    violence: boolean;
  };
  categoryScores: {
    sexual: number;
    hate: number;
    harassment: number;
    selfHarm: number;
    sexualMinors: number;
    hateThreatening: number;
    violenceGraphic: number;
    violence: number;
  };
  shouldBlock: boolean;
  reason?: string;
}

@Injectable()
export class AiModerationService {
  private openai: OpenAI | null = null;
  private readonly textThreshold: number;
  private readonly autoBlockEnabled: boolean;

  constructor(
    private configService: ConfigService,
    private logger: CustomLoggerService,
  ) {
    const apiKey = this.configService.get<string>('moderation.openai.apiKey');
    this.textThreshold = this.configService.get<number>(
      'moderation.autoBlock.textThreshold',
      0.7,
    );
    this.autoBlockEnabled = this.configService.get<boolean>(
      'moderation.autoBlock.enabled',
      false,
    );

    if (apiKey) {
      this.openai = new OpenAI({ apiKey });
      this.logger.info('AI Moderation Service initialized with OpenAI');
    } else {
      this.logger.warn(
        'OpenAI API key not configured. Text moderation will be disabled.',
      );
    }
  }

  /**
   * Moderate text content using OpenAI's moderation API
   */
  async moderateText(text: string): Promise<TextModerationResult> {
    if (!this.openai) {
      this.logger.warn('OpenAI not configured, skipping text moderation');
      return this.createSafeResult();
    }

    if (!text || text.trim().length === 0) {
      return this.createSafeResult();
    }

    try {
      const moderation = await this.openai.moderations.create({
        model: this.configService.get<string>(
          'moderation.openai.model',
          'text-moderation-latest',
        ),
        input: text,
      });

      const result = moderation.results[0];

      // Map OpenAI's response to our interface
      const categoryScores = {
        sexual: result.category_scores.sexual,
        hate: result.category_scores.hate,
        harassment: result.category_scores.harassment,
        selfHarm: result.category_scores['self-harm'],
        sexualMinors: result.category_scores['sexual/minors'],
        hateThreatening: result.category_scores['hate/threatening'],
        violenceGraphic: result.category_scores['violence/graphic'],
        violence: result.category_scores.violence,
      };

      const categories = {
        sexual: result.categories.sexual,
        hate: result.categories.hate,
        harassment: result.categories.harassment,
        selfHarm: result.categories['self-harm'],
        sexualMinors: result.categories['sexual/minors'],
        hateThreatening: result.categories['hate/threatening'],
        violenceGraphic: result.categories['violence/graphic'],
        violence: result.categories.violence,
      };

      // Determine if content should be blocked
      const shouldBlock = this.shouldBlockContent(
        result.flagged,
        categoryScores,
      );
      const reason = shouldBlock ? this.getBlockReason(categories) : undefined;

      this.logger.logBusinessEvent('text_moderation_completed', {
        flagged: result.flagged,
        shouldBlock,
        categories,
      });

      return {
        flagged: result.flagged,
        categories,
        categoryScores,
        shouldBlock,
        reason,
      };
    } catch (error) {
      this.logger.error(
        'Error moderating text content',
        error.stack,
        'AiModerationService',
      );
      // On error, return safe result (don't block)
      return this.createSafeResult();
    }
  }

  /**
   * Batch moderate multiple text strings
   */
  async moderateTextBatch(texts: string[]): Promise<TextModerationResult[]> {
    if (!this.openai) {
      return texts.map(() => this.createSafeResult());
    }

    const results = await Promise.all(
      texts.map((text) => this.moderateText(text)),
    );

    return results;
  }

  /**
   * Determine if content should be blocked based on scores and threshold
   */
  private shouldBlockContent(
    flagged: boolean,
    categoryScores: Record<string, number>,
  ): boolean {
    if (!this.autoBlockEnabled) {
      return false;
    }

    if (!flagged) {
      return false;
    }

    // Check if any category score exceeds the threshold
    const maxScore = Math.max(...Object.values(categoryScores));
    return maxScore >= this.textThreshold;
  }

  /**
   * Get human-readable reason for blocking
   */
  private getBlockReason(categories: Record<string, boolean>): string {
    const flaggedCategories = Object.entries(categories)
      .filter(([_, flagged]) => flagged)
      .map(([category]) => this.formatCategoryName(category));

    if (flaggedCategories.length === 0) {
      return 'Content flagged by moderation system';
    }

    return `Content contains inappropriate ${flaggedCategories.join(', ')}`;
  }

  /**
   * Format category name for display
   */
  private formatCategoryName(category: string): string {
    const map: Record<string, string> = {
      sexual: 'sexual content',
      hate: 'hate speech',
      harassment: 'harassment',
      selfHarm: 'self-harm content',
      sexualMinors: 'sexual content involving minors',
      hateThreatening: 'threatening hate speech',
      violenceGraphic: 'graphic violence',
      violence: 'violence',
    };

    return map[category] || category;
  }

  /**
   * Create a safe/non-flagged result
   */
  private createSafeResult(): TextModerationResult {
    return {
      flagged: false,
      categories: {
        sexual: false,
        hate: false,
        harassment: false,
        selfHarm: false,
        sexualMinors: false,
        hateThreatening: false,
        violenceGraphic: false,
        violence: false,
      },
      categoryScores: {
        sexual: 0,
        hate: 0,
        harassment: 0,
        selfHarm: 0,
        sexualMinors: 0,
        hateThreatening: 0,
        violenceGraphic: 0,
        violence: 0,
      },
      shouldBlock: false,
    };
  }
}
