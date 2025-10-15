import { validate } from 'class-validator';
import { UpdateProfileDto } from '../dto/profiles.dto';

/**
 * DTO-level validation tests for bio character limit
 *
 * These tests verify that the class-validator decorators properly enforce
 * the 600 character limit for the bio field, including spaces and newlines.
 */
describe('UpdateProfileDto - Bio Validation', () => {
  it('should pass validation with a bio of exactly 600 characters', async () => {
    const dto = new UpdateProfileDto();
    dto.bio = 'a'.repeat(600);

    const errors = await validate(dto);
    expect(errors.length).toBe(0);
  });

  it('should pass validation with a bio of less than 600 characters', async () => {
    const dto = new UpdateProfileDto();
    dto.bio = 'This is a short bio.';

    const errors = await validate(dto);
    expect(errors.length).toBe(0);
  });

  it('should fail validation with a bio of 601 characters', async () => {
    const dto = new UpdateProfileDto();
    dto.bio = 'a'.repeat(601);

    const errors = await validate(dto);

    expect(errors.length).toBeGreaterThan(0);
    expect(errors[0].property).toBe('bio');
    expect(errors[0].constraints).toHaveProperty('maxLength');
    expect(errors[0].constraints?.maxLength).toContain('600');
  });

  it('should fail validation with a bio of more than 600 characters', async () => {
    const dto = new UpdateProfileDto();
    dto.bio = 'a'.repeat(1000);

    const errors = await validate(dto);

    expect(errors.length).toBeGreaterThan(0);
    expect(errors[0].property).toBe('bio');
    expect(errors[0].constraints).toHaveProperty('maxLength');
  });

  it('should count spaces in the character limit', async () => {
    const dto = new UpdateProfileDto();
    // 590 characters + 11 spaces = 601 total (should fail)
    dto.bio = 'a'.repeat(590) + ' '.repeat(11);

    const errors = await validate(dto);

    expect(errors.length).toBeGreaterThan(0);
    expect(errors[0].property).toBe('bio');
    expect(errors[0].constraints).toHaveProperty('maxLength');
  });

  it('should count newlines in the character limit', async () => {
    const dto = new UpdateProfileDto();
    // 590 characters + 11 newlines = 601 total (should fail)
    dto.bio = 'a'.repeat(590) + '\n'.repeat(11);

    const errors = await validate(dto);

    expect(errors.length).toBeGreaterThan(0);
    expect(errors[0].property).toBe('bio');
    expect(errors[0].constraints).toHaveProperty('maxLength');
  });

  it('should accept bio with exactly 600 characters including spaces', async () => {
    const dto = new UpdateProfileDto();
    // 590 characters + 10 spaces = 600 total (should pass)
    dto.bio = 'a'.repeat(590) + ' '.repeat(10);

    const errors = await validate(dto);
    expect(errors.length).toBe(0);
  });

  it('should accept bio with exactly 600 characters including newlines', async () => {
    const dto = new UpdateProfileDto();
    // 590 characters + 10 newlines = 600 total (should pass)
    dto.bio = 'a'.repeat(590) + '\n'.repeat(10);

    const errors = await validate(dto);
    expect(errors.length).toBe(0);
  });

  it('should accept bio with mixed content within limit', async () => {
    const dto = new UpdateProfileDto();
    dto.bio = `Hi, I'm John! I love hiking, reading, and spending time with friends.

I work as a software engineer and enjoy building cool projects in my spare time.

Some of my hobbies include:
- Photography
- Cooking
- Travel

Looking for someone who shares similar interests!`;

    expect(dto.bio.length).toBeLessThanOrEqual(600);

    const errors = await validate(dto);
    expect(errors.length).toBe(0);
  });

  it('should allow empty bio (optional field)', async () => {
    const dto = new UpdateProfileDto();
    // bio is not set

    const errors = await validate(dto);
    expect(errors.length).toBe(0);
  });

  it('should allow null bio (optional field)', async () => {
    const dto = new UpdateProfileDto();
    dto.bio = undefined;

    const errors = await validate(dto);
    expect(errors.length).toBe(0);
  });

  it('should reject bio that is not a string', async () => {
    const dto = new UpdateProfileDto();
    (dto as any).bio = 12345; // Invalid type

    const errors = await validate(dto);

    expect(errors.length).toBeGreaterThan(0);
    const bioError = errors.find((e) => e.property === 'bio');
    expect(bioError).toBeDefined();
    expect(bioError?.constraints).toHaveProperty('isString');
  });
});
