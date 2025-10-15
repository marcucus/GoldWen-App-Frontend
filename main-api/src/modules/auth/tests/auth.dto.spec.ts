import { validate } from 'class-validator';
import {
  RegisterDto,
  ResetPasswordDto,
  ChangePasswordDto,
} from '../dto/auth.dto';

describe('Auth DTOs Password Validation', () => {
  describe('RegisterDto', () => {
    it('should pass validation with a strong password', async () => {
      const dto = new RegisterDto();
      dto.email = 'test@example.com';
      dto.password = 'Password123!';
      dto.firstName = 'John';
      dto.lastName = 'Doe';

      const errors = await validate(dto);
      expect(errors.length).toBe(0);
    });

    it('should fail validation when password has no uppercase letter', async () => {
      const dto = new RegisterDto();
      dto.email = 'test@example.com';
      dto.password = 'password123!';
      dto.firstName = 'John';

      const errors = await validate(dto);
      expect(errors.length).toBeGreaterThan(0);
      const passwordError = errors.find(
        (error) => error.property === 'password',
      );
      expect(passwordError).toBeDefined();
      expect(passwordError?.constraints?.matches).toContain('uppercase letter');
    });

    it('should fail validation when password has no special character', async () => {
      const dto = new RegisterDto();
      dto.email = 'test@example.com';
      dto.password = 'Password123';
      dto.firstName = 'John';

      const errors = await validate(dto);
      expect(errors.length).toBeGreaterThan(0);
      const passwordError = errors.find(
        (error) => error.property === 'password',
      );
      expect(passwordError).toBeDefined();
      expect(passwordError?.constraints?.matches).toContain(
        'special character',
      );
    });

    it('should fail validation when password is too short', async () => {
      const dto = new RegisterDto();
      dto.email = 'test@example.com';
      dto.password = 'Pas1!';
      dto.firstName = 'John';

      const errors = await validate(dto);
      expect(errors.length).toBeGreaterThan(0);
      const passwordError = errors.find(
        (error) => error.property === 'password',
      );
      expect(passwordError).toBeDefined();
      expect(passwordError?.constraints?.minLength).toContain(
        'at least 6 characters',
      );
    });

    it('should fail validation when password has no uppercase and no special character', async () => {
      const dto = new RegisterDto();
      dto.email = 'test@example.com';
      dto.password = 'password123';
      dto.firstName = 'John';

      const errors = await validate(dto);
      expect(errors.length).toBeGreaterThan(0);
      const passwordError = errors.find(
        (error) => error.property === 'password',
      );
      expect(passwordError).toBeDefined();
      expect(passwordError?.constraints?.matches).toBeDefined();
    });

    it('should pass validation with various special characters', async () => {
      const specialChars = [
        '!',
        '@',
        '#',
        '$',
        '%',
        '^',
        '&',
        '*',
        '(',
        ')',
        '-',
        '_',
        '+',
        '=',
      ];

      for (const char of specialChars) {
        const dto = new RegisterDto();
        dto.email = 'test@example.com';
        dto.password = `Password123${char}`;
        dto.firstName = 'John';

        const errors = await validate(dto);
        expect(errors.length).toBe(0);
      }
    });

    it('should pass validation with minimum length password that meets all criteria', async () => {
      const dto = new RegisterDto();
      dto.email = 'test@example.com';
      dto.password = 'Pass1!';
      dto.firstName = 'John';

      const errors = await validate(dto);
      expect(errors.length).toBe(0);
    });
  });

  describe('ResetPasswordDto', () => {
    it('should pass validation with a strong password', async () => {
      const dto = new ResetPasswordDto();
      dto.token = 'valid-token';
      dto.newPassword = 'NewPassword123!';

      const errors = await validate(dto);
      expect(errors.length).toBe(0);
    });

    it('should fail validation when newPassword has no uppercase letter', async () => {
      const dto = new ResetPasswordDto();
      dto.token = 'valid-token';
      dto.newPassword = 'newpassword123!';

      const errors = await validate(dto);
      expect(errors.length).toBeGreaterThan(0);
      const passwordError = errors.find(
        (error) => error.property === 'newPassword',
      );
      expect(passwordError).toBeDefined();
      expect(passwordError?.constraints?.matches).toContain('uppercase letter');
    });

    it('should fail validation when newPassword has no special character', async () => {
      const dto = new ResetPasswordDto();
      dto.token = 'valid-token';
      dto.newPassword = 'NewPassword123';

      const errors = await validate(dto);
      expect(errors.length).toBeGreaterThan(0);
      const passwordError = errors.find(
        (error) => error.property === 'newPassword',
      );
      expect(passwordError).toBeDefined();
      expect(passwordError?.constraints?.matches).toContain(
        'special character',
      );
    });

    it('should fail validation when newPassword is too short', async () => {
      const dto = new ResetPasswordDto();
      dto.token = 'valid-token';
      dto.newPassword = 'New1!';

      const errors = await validate(dto);
      expect(errors.length).toBeGreaterThan(0);
      const passwordError = errors.find(
        (error) => error.property === 'newPassword',
      );
      expect(passwordError).toBeDefined();
      expect(passwordError?.constraints?.minLength).toContain(
        'at least 6 characters',
      );
    });
  });

  describe('ChangePasswordDto', () => {
    it('should pass validation with a strong newPassword', async () => {
      const dto = new ChangePasswordDto();
      dto.currentPassword = 'OldPassword123!';
      dto.newPassword = 'NewPassword123!';

      const errors = await validate(dto);
      expect(errors.length).toBe(0);
    });

    it('should fail validation when newPassword has no uppercase letter', async () => {
      const dto = new ChangePasswordDto();
      dto.currentPassword = 'OldPassword123!';
      dto.newPassword = 'newpassword123!';

      const errors = await validate(dto);
      expect(errors.length).toBeGreaterThan(0);
      const passwordError = errors.find(
        (error) => error.property === 'newPassword',
      );
      expect(passwordError).toBeDefined();
      expect(passwordError?.constraints?.matches).toContain('uppercase letter');
    });

    it('should fail validation when newPassword has no special character', async () => {
      const dto = new ChangePasswordDto();
      dto.currentPassword = 'OldPassword123!';
      dto.newPassword = 'NewPassword123';

      const errors = await validate(dto);
      expect(errors.length).toBeGreaterThan(0);
      const passwordError = errors.find(
        (error) => error.property === 'newPassword',
      );
      expect(passwordError).toBeDefined();
      expect(passwordError?.constraints?.matches).toContain(
        'special character',
      );
    });

    it('should fail validation when newPassword is too short', async () => {
      const dto = new ChangePasswordDto();
      dto.currentPassword = 'OldPassword123!';
      dto.newPassword = 'New1!';

      const errors = await validate(dto);
      expect(errors.length).toBeGreaterThan(0);
      const passwordError = errors.find(
        (error) => error.property === 'newPassword',
      );
      expect(passwordError).toBeDefined();
      expect(passwordError?.constraints?.minLength).toContain(
        'at least 6 characters',
      );
    });

    it('should not validate currentPassword strength (only newPassword)', async () => {
      const dto = new ChangePasswordDto();
      dto.currentPassword = 'weak'; // weak password is ok for current
      dto.newPassword = 'NewPassword123!';

      const errors = await validate(dto);
      expect(errors.length).toBe(0);
    });
  });
});
