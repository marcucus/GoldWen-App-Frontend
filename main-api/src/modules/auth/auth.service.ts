import {
  Injectable,
  UnauthorizedException,
  ConflictException,
  NotFoundException,
  InternalServerErrorException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';

import { User } from '../../database/entities/user.entity';
import { Profile } from '../../database/entities/profile.entity';
import { UserStatus } from '../../common/enums';
import { PasswordUtil, StringUtil } from '../../common/utils';
import { EmailService } from '../../common/email.service';

import {
  LoginDto,
  RegisterDto,
  SocialLoginDto,
  ForgotPasswordDto,
  ResetPasswordDto,
  ChangePasswordDto,
} from './dto/auth.dto';

export interface AuthResponse {
  user: User;
  accessToken: string;
  refreshToken?: string;
}

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User)
    private userRepository: Repository<User>,
    @InjectRepository(Profile)
    private profileRepository: Repository<Profile>,
    private jwtService: JwtService,
    private configService: ConfigService,
    private emailService: EmailService,
  ) {}

  async register(registerDto: RegisterDto): Promise<AuthResponse> {
    const { email, password, firstName, lastName } = registerDto;
    try {
      // Check if user already exists
      const existingUser = await this.userRepository.findOne({
        where: { email },
      });
      if (existingUser) {
        throw new ConflictException('User with this email already exists');
      }

      // Hash password
      const passwordHash = await PasswordUtil.hash(password);

      // Create user
      const user = this.userRepository.create({
        email,
        passwordHash,
        status: UserStatus.ACTIVE,
        emailVerificationToken: StringUtil.generateRandomString(32),
      });

      const savedUser = await this.userRepository.save(user);

      // Create basic profile
      const profile = this.profileRepository.create({
        userId: savedUser.id,
        firstName,
        lastName,
      });

      await this.profileRepository.save(profile);

      // Send welcome email (async, don't wait)
      this.emailService
        .sendWelcomeEmail(savedUser.email, firstName)
        .catch(() => {
          // Email sending is not critical, so we don't throw errors
        });

      // Generate JWT token
      const accessToken = this.generateAccessToken(savedUser);

      return { user: savedUser, accessToken };
    } catch (error) {
      console.log('Error registering user:', error);
      throw new InternalServerErrorException('Error registering user');
    }
  }

  async login(loginDto: LoginDto): Promise<AuthResponse> {
    const { email, password } = loginDto;

    // Find user with profile
    const user = await this.userRepository.findOne({
      where: { email },
      relations: ['profile'],
    });

    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    if (user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException('Account is not active');
    }

    // Check password
    const isPasswordValid = await PasswordUtil.compare(
      password,
      user.passwordHash,
    );
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Update last login
    user.lastLoginAt = new Date();
    await this.userRepository.save(user);

    // Generate JWT token
    const accessToken = this.generateAccessToken(user);

    return { user, accessToken };
  }

  async validateGoogleUser(profile: any) {
    let user = await this.userRepository.findOne({
      where: { email: profile.email },
    });

    if (!user) {
      user = this.userRepository.create({
        email: profile.email,
        // Add these properties only if they exist in your User entity
        ...(profile.googleId && { googleId: profile.googleId }),
        ...(profile.name && { name: profile.name }),
        ...(profile.picture && { picture: profile.picture }),
      } as Partial<User>);
    }

    const token = this.jwtService.sign({ sub: user.id, email: user.email });
    return { token, user };
  }

  async socialLogin(socialLoginDto: SocialLoginDto): Promise<AuthResponse> {
    const { socialId, provider, email, firstName, lastName } = socialLoginDto;

    // Check if user exists with social ID
    let user = await this.userRepository.findOne({
      where: { socialId, socialProvider: provider },
      relations: ['profile'],
    });

    if (!user) {
      // Check if user exists with email
      user = await this.userRepository.findOne({
        where: { email },
        relations: ['profile'],
      });

      if (user) {
        // Link social account to existing user
        user.socialId = socialId;
        user.socialProvider = provider;
        await this.userRepository.save(user);
      } else {
        // Create new user
        user = this.userRepository.create({
          email,
          socialId,
          socialProvider: provider,
          status: UserStatus.ACTIVE,
          isEmailVerified: true,
        });

        const savedUser = await this.userRepository.save(user);

        // Create profile
        const profile = this.profileRepository.create({
          userId: savedUser.id,
          firstName,
          lastName,
        });

        await this.profileRepository.save(profile);
        user.profile = profile;
      }
    }

    // Update last login
    user.lastLoginAt = new Date();
    await this.userRepository.save(user);

    // Generate JWT token
    const accessToken = this.generateAccessToken(user);

    return { user, accessToken };
  }

  async forgotPassword(forgotPasswordDto: ForgotPasswordDto): Promise<void> {
    const { email } = forgotPasswordDto;

    const user = await this.userRepository.findOne({ where: { email } });
    if (!user) {
      // Don't reveal if email exists
      return;
    }

    // Generate reset token
    const resetToken = StringUtil.generateRandomString(32);
    const resetExpires = new Date();
    resetExpires.setHours(resetExpires.getHours() + 1); // 1 hour expiry

    user.resetPasswordToken = resetToken;
    user.resetPasswordExpires = resetExpires;

    await this.userRepository.save(user);

    // Send email with reset link
    await this.emailService.sendPasswordResetEmail(user.email, resetToken);
  }

  async resetPassword(resetPasswordDto: ResetPasswordDto): Promise<void> {
    const { token, newPassword } = resetPasswordDto;

    const user = await this.userRepository.findOne({
      where: { resetPasswordToken: token },
    });

    if (
      !user ||
      !user.resetPasswordExpires ||
      user.resetPasswordExpires < new Date()
    ) {
      throw new UnauthorizedException('Invalid or expired reset token');
    }

    // Hash new password
    const passwordHash = await PasswordUtil.hash(newPassword);

    user.passwordHash = passwordHash;
    user.resetPasswordToken = null as any;
    user.resetPasswordExpires = null as any;

    await this.userRepository.save(user);
  }

  async changePassword(
    userId: string,
    changePasswordDto: ChangePasswordDto,
  ): Promise<void> {
    const { currentPassword, newPassword } = changePasswordDto;

    const user = await this.userRepository.findOne({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Verify current password
    const isCurrentPasswordValid = await PasswordUtil.compare(
      currentPassword,
      user.passwordHash,
    );
    if (!isCurrentPasswordValid) {
      throw new UnauthorizedException('Current password is incorrect');
    }

    // Hash new password
    const passwordHash = await PasswordUtil.hash(newPassword);
    user.passwordHash = passwordHash;

    await this.userRepository.save(user);
  }

  async verifyEmail(token: string): Promise<void> {
    const user = await this.userRepository.findOne({
      where: { emailVerificationToken: token },
    });

    if (!user) {
      throw new UnauthorizedException('Invalid verification token');
    }

    user.isEmailVerified = true;
    user.emailVerificationToken = null as any;

    await this.userRepository.save(user);
  }

  private generateAccessToken(user: User): string {
    const payload = {
      sub: user.id,
      email: user.email,
    };

    return this.jwtService.sign(payload);
  }

  async getUserById(id: string): Promise<User> {
    const user = await this.userRepository.findOne({
      where: { id },
      relations: ['profile'],
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return user;
  }
}
