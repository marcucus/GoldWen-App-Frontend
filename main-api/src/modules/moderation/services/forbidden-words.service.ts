import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { CustomLoggerService } from '../../../common/logger';

export interface ForbiddenWordsResult {
  containsForbiddenWords: boolean;
  foundWords?: string[];
  reason?: string;
}

@Injectable()
export class ForbiddenWordsService {
  private readonly enabled: boolean;
  private readonly forbiddenWords: string[];

  constructor(
    private configService: ConfigService,
    private logger: CustomLoggerService,
  ) {
    this.enabled = this.configService.get<boolean>(
      'moderation.forbiddenWords.enabled',
      false,
    );
    this.forbiddenWords = this.configService.get<string[]>(
      'moderation.forbiddenWords.words',
      [],
    );

    if (this.enabled && this.forbiddenWords.length > 0) {
      this.logger.info(
        `Forbidden Words Service initialized with ${this.forbiddenWords.length} forbidden words`,
      );
    } else if (this.enabled && this.forbiddenWords.length === 0) {
      this.logger.warn(
        'Forbidden Words Service enabled but no forbidden words configured',
      );
    }
  }

  /**
   * Check if text contains any forbidden words
   */
  checkText(text: string): ForbiddenWordsResult {
    if (!this.enabled) {
      return { containsForbiddenWords: false };
    }

    if (!text || text.trim().length === 0) {
      return { containsForbiddenWords: false };
    }

    // Normalize text for comparison (lowercase, preserve spaces)
    const normalizedText = text.toLowerCase();

    // Check for forbidden words (case-insensitive, whole word matching)
    const foundWords: string[] = [];

    for (const forbiddenWord of this.forbiddenWords) {
      const normalizedForbiddenWord = forbiddenWord.toLowerCase();

      // Create regex for whole word matching with word boundaries
      // \b matches word boundaries (start/end of word)
      const regex = new RegExp(
        `\\b${this.escapeRegex(normalizedForbiddenWord)}\\b`,
        'i',
      );

      if (regex.test(normalizedText)) {
        foundWords.push(forbiddenWord);
      }
    }

    if (foundWords.length > 0) {
      this.logger.logSecurityEvent('forbidden_words_detected', {
        foundWords,
        textLength: text.length,
      });

      return {
        containsForbiddenWords: true,
        foundWords,
        reason: `Content contains forbidden words: ${foundWords.join(', ')}`,
      };
    }

    return { containsForbiddenWords: false };
  }

  /**
   * Check multiple texts for forbidden words
   */
  checkTextBatch(texts: string[]): ForbiddenWordsResult[] {
    return texts.map((text) => this.checkText(text));
  }

  /**
   * Escape special regex characters in a string
   */
  private escapeRegex(str: string): string {
    return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  }

  /**
   * Get the list of configured forbidden words (for admin purposes)
   */
  getForbiddenWords(): string[] {
    return [...this.forbiddenWords];
  }

  /**
   * Check if forbidden words checking is enabled
   */
  isEnabled(): boolean {
    return this.enabled;
  }
}
