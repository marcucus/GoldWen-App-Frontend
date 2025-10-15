import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  RekognitionClient,
  DetectModerationLabelsCommand,
  DetectModerationLabelsCommandInput,
} from '@aws-sdk/client-rekognition';
import { CustomLoggerService } from '../../../common/logger';
import * as fs from 'fs';

export interface ImageModerationLabel {
  name: string;
  confidence: number;
  parentName?: string;
}

export interface ImageModerationResult {
  flagged: boolean;
  labels: ImageModerationLabel[];
  shouldBlock: boolean;
  reason?: string;
  moderationModelVersion?: string;
}

@Injectable()
export class ImageModerationService {
  private rekognitionClient: RekognitionClient | null = null;
  private readonly imageThreshold: number;
  private readonly autoBlockEnabled: boolean;

  constructor(
    private configService: ConfigService,
    private logger: CustomLoggerService,
  ) {
    const region = this.configService.get<string>('moderation.aws.region');
    const accessKeyId = this.configService.get<string>(
      'moderation.aws.accessKeyId',
    );
    const secretAccessKey = this.configService.get<string>(
      'moderation.aws.secretAccessKey',
    );

    this.imageThreshold = this.configService.get<number>(
      'moderation.autoBlock.imageThreshold',
      80,
    );
    this.autoBlockEnabled = this.configService.get<boolean>(
      'moderation.autoBlock.enabled',
      false,
    );

    if (accessKeyId && secretAccessKey && region) {
      this.rekognitionClient = new RekognitionClient({
        region,
        credentials: {
          accessKeyId,
          secretAccessKey,
        },
      });
      this.logger.info(
        'Image Moderation Service initialized with AWS Rekognition',
      );
    } else {
      this.logger.warn(
        'AWS credentials not configured. Image moderation will be disabled.',
      );
    }
  }

  /**
   * Moderate image using AWS Rekognition
   * @param imagePath Path to the image file on disk
   */
  async moderateImage(imagePath: string): Promise<ImageModerationResult> {
    if (!this.rekognitionClient) {
      this.logger.warn(
        'AWS Rekognition not configured, skipping image moderation',
      );
      return this.createSafeResult();
    }

    try {
      // Read image file
      const imageBytes = await fs.promises.readFile(imagePath);

      const params: DetectModerationLabelsCommandInput = {
        Image: {
          Bytes: imageBytes,
        },
        MinConfidence: 50, // Only return labels with at least 50% confidence
      };

      const command = new DetectModerationLabelsCommand(params);
      const response = await this.rekognitionClient.send(command);

      const labels: ImageModerationLabel[] = (
        response.ModerationLabels || []
      ).map((label) => ({
        name: label.Name || 'Unknown',
        confidence: label.Confidence || 0,
        parentName: label.ParentName,
      }));

      const flagged = labels.length > 0;
      const shouldBlock = this.shouldBlockImage(labels);
      const reason = shouldBlock ? this.getBlockReason(labels) : undefined;

      this.logger.logBusinessEvent('image_moderation_completed', {
        flagged,
        shouldBlock,
        labelsCount: labels.length,
        highestConfidence:
          labels.length > 0 ? Math.max(...labels.map((l) => l.confidence)) : 0,
      });

      return {
        flagged,
        labels,
        shouldBlock,
        reason,
        moderationModelVersion: response.ModerationModelVersion,
      };
    } catch (error) {
      this.logger.error(
        `Error moderating image: ${imagePath}`,
        error.stack,
        'ImageModerationService',
      );
      // On error, return safe result (don't block) to avoid false positives
      return this.createSafeResult();
    }
  }

  /**
   * Moderate image from URL or S3
   * @param imageUrl URL of the image or S3 bucket/key
   */
  async moderateImageFromUrl(imageUrl: string): Promise<ImageModerationResult> {
    if (!this.rekognitionClient) {
      this.logger.warn(
        'AWS Rekognition not configured, skipping image moderation',
      );
      return this.createSafeResult();
    }

    try {
      // Check if it's an S3 URL
      const s3Match = imageUrl.match(/s3:\/\/([^\/]+)\/(.+)/);

      let params: DetectModerationLabelsCommandInput;

      if (s3Match) {
        // S3 image
        const [, bucket, key] = s3Match;
        params = {
          Image: {
            S3Object: {
              Bucket: bucket,
              Name: key,
            },
          },
          MinConfidence: 50,
        };
      } else {
        // External URL - fetch and convert to bytes
        const response = await fetch(imageUrl);
        if (!response.ok) {
          throw new Error(`Failed to fetch image: ${response.statusText}`);
        }
        const arrayBuffer = await response.arrayBuffer();
        const imageBytes = Buffer.from(arrayBuffer);

        params = {
          Image: {
            Bytes: imageBytes,
          },
          MinConfidence: 50,
        };
      }

      const command = new DetectModerationLabelsCommand(params);
      const awsResponse = await this.rekognitionClient.send(command);

      const labels: ImageModerationLabel[] = (
        awsResponse.ModerationLabels || []
      ).map((label) => ({
        name: label.Name || 'Unknown',
        confidence: label.Confidence || 0,
        parentName: label.ParentName,
      }));

      const flagged = labels.length > 0;
      const shouldBlock = this.shouldBlockImage(labels);
      const reason = shouldBlock ? this.getBlockReason(labels) : undefined;

      this.logger.logBusinessEvent('image_moderation_from_url_completed', {
        flagged,
        shouldBlock,
        labelsCount: labels.length,
      });

      return {
        flagged,
        labels,
        shouldBlock,
        reason,
        moderationModelVersion: awsResponse.ModerationModelVersion,
      };
    } catch (error) {
      this.logger.error(
        `Error moderating image from URL: ${imageUrl}`,
        error.stack,
        'ImageModerationService',
      );
      return this.createSafeResult();
    }
  }

  /**
   * Determine if image should be blocked based on labels and threshold
   */
  private shouldBlockImage(labels: ImageModerationLabel[]): boolean {
    if (!this.autoBlockEnabled) {
      return false;
    }

    if (labels.length === 0) {
      return false;
    }

    // Check if any label confidence exceeds the threshold
    const maxConfidence = Math.max(...labels.map((l) => l.confidence));
    return maxConfidence >= this.imageThreshold;
  }

  /**
   * Get human-readable reason for blocking
   */
  private getBlockReason(labels: ImageModerationLabel[]): string {
    const highConfidenceLabels = labels
      .filter((l) => l.confidence >= this.imageThreshold)
      .map((l) => l.name)
      .slice(0, 3); // Take top 3

    if (highConfidenceLabels.length === 0) {
      return 'Image flagged by moderation system';
    }

    return `Image contains inappropriate content: ${highConfidenceLabels.join(', ')}`;
  }

  /**
   * Create a safe/non-flagged result
   */
  private createSafeResult(): ImageModerationResult {
    return {
      flagged: false,
      labels: [],
      shouldBlock: false,
    };
  }
}
