import sharp from 'sharp';
import * as fs from 'fs';
import * as path from 'path';

export interface ImageProcessingOptions {
  maxWidth?: number;
  maxHeight?: number;
  quality?: number;
  format?: 'jpeg' | 'png' | 'webp';
}

export interface ProcessedImageResult {
  filename: string;
  originalSize: number;
  processedSize: number;
  width: number;
  height: number;
  format: string;
}

export class ImageProcessorUtil {
  private static readonly DEFAULT_MAX_WIDTH = 1200;
  private static readonly DEFAULT_MAX_HEIGHT = 1600;
  private static readonly DEFAULT_QUALITY = 80;
  private static readonly DEFAULT_FORMAT = 'jpeg';

  /**
   * Process and optimize an image file
   */
  static async processImage(
    inputPath: string,
    outputPath: string,
    options: ImageProcessingOptions = {},
  ): Promise<ProcessedImageResult> {
    const {
      maxWidth = this.DEFAULT_MAX_WIDTH,
      maxHeight = this.DEFAULT_MAX_HEIGHT,
      quality = this.DEFAULT_QUALITY,
      format = this.DEFAULT_FORMAT,
    } = options;

    try {
      // Get original file stats
      const originalStats = fs.statSync(inputPath);
      const originalSize = originalStats.size;

      // Process the image
      const sharpInstance = sharp(inputPath);

      // Get image metadata
      const metadata = await sharpInstance.metadata();

      // Resize if necessary (maintain aspect ratio)
      const shouldResize =
        (metadata.width && metadata.width > maxWidth) ||
        (metadata.height && metadata.height > maxHeight);

      if (shouldResize) {
        sharpInstance.resize(maxWidth, maxHeight, {
          fit: 'inside',
          withoutEnlargement: true,
        });
      }

      // Apply format and quality
      switch (format) {
        case 'jpeg':
          sharpInstance.jpeg({ quality });
          break;
        case 'png':
          sharpInstance.png({ quality });
          break;
        case 'webp':
          sharpInstance.webp({ quality });
          break;
      }

      // Save the processed image
      await sharpInstance.toFile(outputPath);

      // Get processed file stats
      const processedStats = fs.statSync(outputPath);
      const processedSize = processedStats.size;

      // Get final dimensions
      const finalMetadata = await sharp(outputPath).metadata();

      return {
        filename: path.basename(outputPath),
        originalSize,
        processedSize,
        width: finalMetadata.width || 0,
        height: finalMetadata.height || 0,
        format: finalMetadata.format || format,
      };
    } catch (_error) {
      // If processing fails, copy the original file
      fs.copyFileSync(inputPath, outputPath);

      const stats = fs.statSync(outputPath);
      const metadata = await sharp(outputPath).metadata();

      return {
        filename: path.basename(outputPath),
        originalSize: stats.size,
        processedSize: stats.size,
        width: metadata.width || 0,
        height: metadata.height || 0,
        format: metadata.format || 'unknown',
      };
    }
  }

  /**
   * Validate image file type and size
   */
  static validateImage(file: Express.Multer.File): {
    isValid: boolean;
    error?: string;
  } {
    // Check file type
    const allowedMimeTypes = [
      'image/jpeg',
      'image/jpg',
      'image/png',
      'image/webp',
    ];
    if (!allowedMimeTypes.includes(file.mimetype)) {
      return {
        isValid: false,
        error: 'Only JPEG, PNG, and WebP images are allowed',
      };
    }

    // Check file size (max 10MB as configured in multer)
    const maxSize = 10 * 1024 * 1024; // 10MB
    if (file.size > maxSize) {
      return {
        isValid: false,
        error: 'File size must be less than 10MB',
      };
    }

    return { isValid: true };
  }

  /**
   * Generate unique filename with proper extension
   */
  static generateUniqueFilename(originalName: string, format?: string): string {
    const ext =
      format || path.extname(originalName).toLowerCase().slice(1) || 'jpg';
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    return `photo-${uniqueSuffix}.${ext}`;
  }
}
