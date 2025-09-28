import { ImageProcessorUtil } from '../../../common/utils/image-processor.util';

describe('ImageProcessorUtil', () => {
  describe('validateImage', () => {
    it('should validate JPEG files as valid', () => {
      const mockFile = {
        mimetype: 'image/jpeg',
        size: 5 * 1024 * 1024, // 5MB
      } as Express.Multer.File;

      const result = ImageProcessorUtil.validateImage(mockFile);
      expect(result.isValid).toBe(true);
      expect(result.error).toBeUndefined();
    });

    it('should validate PNG files as valid', () => {
      const mockFile = {
        mimetype: 'image/png',
        size: 2 * 1024 * 1024, // 2MB
      } as Express.Multer.File;

      const result = ImageProcessorUtil.validateImage(mockFile);
      expect(result.isValid).toBe(true);
      expect(result.error).toBeUndefined();
    });

    it('should validate WebP files as valid', () => {
      const mockFile = {
        mimetype: 'image/webp',
        size: 3 * 1024 * 1024, // 3MB
      } as Express.Multer.File;

      const result = ImageProcessorUtil.validateImage(mockFile);
      expect(result.isValid).toBe(true);
      expect(result.error).toBeUndefined();
    });

    it('should reject non-image files', () => {
      const mockFile = {
        mimetype: 'application/pdf',
        size: 1 * 1024 * 1024, // 1MB
      } as Express.Multer.File;

      const result = ImageProcessorUtil.validateImage(mockFile);
      expect(result.isValid).toBe(false);
      expect(result.error).toBe('Only JPEG, PNG, and WebP images are allowed');
    });

    it('should reject files that are too large', () => {
      const mockFile = {
        mimetype: 'image/jpeg',
        size: 15 * 1024 * 1024, // 15MB - over 10MB limit
      } as Express.Multer.File;

      const result = ImageProcessorUtil.validateImage(mockFile);
      expect(result.isValid).toBe(false);
      expect(result.error).toBe('File size must be less than 10MB');
    });
  });

  describe('generateUniqueFilename', () => {
    it('should generate unique filename with correct extension', () => {
      const filename1 = ImageProcessorUtil.generateUniqueFilename('test.jpg');
      const filename2 = ImageProcessorUtil.generateUniqueFilename('test.jpg');

      expect(filename1).toMatch(/^photo-\d+-\d+\.jpg$/);
      expect(filename2).toMatch(/^photo-\d+-\d+\.jpg$/);
      expect(filename1).not.toBe(filename2);
    });

    it('should use specified format', () => {
      const filename = ImageProcessorUtil.generateUniqueFilename(
        'test.png',
        'jpeg',
      );
      expect(filename).toMatch(/^photo-\d+-\d+\.jpeg$/);
    });

    it('should handle files without extensions', () => {
      const filename = ImageProcessorUtil.generateUniqueFilename('test');
      expect(filename).toMatch(/^photo-\d+-\d+\.jpg$/);
    });
  });
});
