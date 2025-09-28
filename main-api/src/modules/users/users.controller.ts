import {
  Controller,
  Get,
  Put,
  Post,
  Body,
  UseGuards,
  Req,
  Delete,
  Query,
  Param,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import type { Request } from 'express';

import { UsersService } from './users.service';
import { ProfilesService } from '../profiles/profiles.service';
import { UpdateUserDto, UpdateUserSettingsDto } from './dto/update-user.dto';
import {
  AccessibilitySettingsDto,
  UpdateAccessibilitySettingsDto,
} from './dto/accessibility-settings.dto';
import { RegisterPushTokenDto, DeletePushTokenDto } from './dto/push-token.dto';
import { ConsentDto, ExportDataDto } from './dto/consent.dto';
import {
  UpdateUserRoleDto,
  UserRolesListResponseDto,
} from './dto/role-management.dto';
import { SuccessResponseDto } from '../../common/dto/response.dto';
import { GdprService } from './gdpr.service';
import { Roles, RoleGuard } from '../auth/guards/role.guard';
import { User } from '../../database/entities/user.entity';
import { Profile } from '../../database/entities/profile.entity';
import { PromptAnswer } from '../../database/entities/prompt-answer.entity';
import { SubmitPromptAnswersDto } from '../profiles/dto/profiles.dto';
import { UserRole } from '../../common/enums';

@ApiTags('Users')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'))
@Controller('users')
export class UsersController {
  constructor(
    private usersService: UsersService,
    private profilesService: ProfilesService,
    private gdprService: GdprService,
    @InjectRepository(Profile)
    private profileRepository: Repository<Profile>,
    @InjectRepository(PromptAnswer)
    private promptAnswerRepository: Repository<PromptAnswer>,
  ) {}

  @ApiOperation({ summary: 'Get current user profile' })
  @ApiResponse({ status: 200, description: 'User profile retrieved' })
  @Get('me')
  async getMyProfile(@Req() req: Request) {
    const user = req.user as User;
    const userProfile = await this.usersService.findById(user.id);

    return {
      success: true,
      data: {
        id: userProfile.id,
        email: userProfile.email,
        status: userProfile.status,
        isEmailVerified: userProfile.isEmailVerified,
        isOnboardingCompleted: userProfile.isOnboardingCompleted,
        isProfileCompleted: userProfile.isProfileCompleted,
        notificationsEnabled: userProfile.notificationsEnabled,
        lastLoginAt: userProfile.lastLoginAt,
        createdAt: userProfile.createdAt,
        profile: userProfile.profile,
      },
    };
  }

  @ApiOperation({ summary: 'Update current user profile' })
  @ApiResponse({ status: 200, description: 'User profile updated' })
  @Put('me')
  async updateMyProfile(
    @Req() req: Request,
    @Body() updateUserDto: UpdateUserDto,
  ) {
    const user = req.user as User;
    const updatedUser = await this.usersService.updateUser(
      user.id,
      updateUserDto,
    );

    return {
      success: true,
      message: 'Profile updated successfully',
      data: {
        id: updatedUser.id,
        email: updatedUser.email,
        profile: updatedUser.profile,
      },
    };
  }

  @ApiOperation({ summary: 'Update user settings' })
  @ApiResponse({ status: 200, description: 'Settings updated' })
  @Put('me/settings')
  async updateSettings(
    @Req() req: Request,
    @Body() settingsDto: UpdateUserSettingsDto,
  ) {
    const user = req.user as User;
    await this.usersService.updateSettings(user.id, settingsDto);

    return new SuccessResponseDto('Settings updated successfully');
  }

  @ApiOperation({ summary: 'Get user statistics' })
  @ApiResponse({ status: 200, description: 'User statistics retrieved' })
  @Get('me/stats')
  async getUserStats(@Req() req: Request) {
    const user = req.user as User;
    const stats = await this.usersService.getUserStats(user.id);

    return {
      success: true,
      data: stats,
    };
  }

  @ApiOperation({ summary: 'Deactivate user account' })
  @ApiResponse({ status: 200, description: 'Account deactivated' })
  @Put('me/deactivate')
  async deactivateAccount(@Req() req: Request) {
    const user = req.user as User;
    await this.usersService.deactivateUser(user.id);

    return new SuccessResponseDto('Account deactivated successfully');
  }

  @ApiOperation({ summary: 'Submit user prompt answers' })
  @ApiResponse({
    status: 201,
    description: 'Prompt answers submitted successfully',
  })
  @Post('me/prompts')
  async submitPrompts(
    @Req() req: Request,
    @Body() promptAnswersDto: SubmitPromptAnswersDto,
  ) {
    const user = req.user as User;

    // Delegate to ProfilesService which now handles dynamic validation
    await this.profilesService.submitPromptAnswers(user.id, promptAnswersDto);

    return {
      success: true,
      message: 'Prompt answers submitted successfully',
    };
  }

  @ApiOperation({ summary: 'Get user prompt answers' })
  @ApiResponse({
    status: 200,
    description: 'User prompt answers retrieved successfully',
  })
  @Get('me/prompts')
  async getUserPrompts(@Req() req: Request) {
    const user = req.user as User;
    return this.profilesService.getUserPromptAnswers(user.id);
  }

  @ApiOperation({ summary: 'Upload user photos' })
  @ApiResponse({ status: 201, description: 'Photos uploaded successfully' })
  @Post('me/photos')
  async uploadPhotos(@Req() req: Request) {
    const user = req.user as User;

    // For now, return a response indicating the endpoint structure is ready
    // In a full implementation, this would handle multipart/form-data file uploads
    return {
      success: true,
      message:
        'Photo upload endpoint ready - requires multipart/form-data implementation',
      data: {
        userId: user.id,
        maxPhotos: 6,
        supportedFormats: ['jpg', 'jpeg', 'png'],
        maxFileSize: '10MB',
      },
    };
  }

  @ApiOperation({ summary: 'Delete user photo' })
  @ApiResponse({ status: 200, description: 'Photo deleted successfully' })
  @Delete('me/photos/:photoId')
  async deletePhoto(@Req() req: Request) {
    const user = req.user as User;
    // const photoId = req.params.photoId; // Would extract from params

    // For now, return a response indicating the endpoint structure is ready
    return {
      success: true,
      message:
        'Photo deletion endpoint ready - requires photo ID parameter handling',
      data: {
        userId: user.id,
      },
    };
  }

  @ApiOperation({ summary: 'Delete user account' })
  @ApiResponse({ status: 200, description: 'Account deleted' })
  @Delete('me')
  async deleteAccount(@Req() req: Request) {
    const user = req.user as User;

    // Use GDPR service for complete deletion with anonymization
    await this.gdprService.deleteUserCompletely(user.id);

    return new SuccessResponseDto(
      'Account deleted successfully with complete anonymization',
    );
  }

  @ApiOperation({ summary: 'Register device push token' })
  @ApiResponse({
    status: 201,
    description: 'Push token registered successfully',
  })
  @Post('me/push-tokens')
  async registerPushToken(
    @Req() req: Request,
    @Body() registerPushTokenDto: RegisterPushTokenDto,
  ) {
    const user = req.user as User;
    const pushToken = await this.usersService.registerPushToken(
      user.id,
      registerPushTokenDto,
    );

    return {
      success: true,
      message: 'Push token registered successfully',
      data: {
        id: pushToken.id,
        platform: pushToken.platform,
        createdAt: pushToken.createdAt,
      },
    };
  }

  @ApiOperation({ summary: 'Delete device push token' })
  @ApiResponse({ status: 200, description: 'Push token deleted successfully' })
  @Delete('me/push-tokens')
  async deletePushToken(
    @Req() req: Request,
    @Body() deletePushTokenDto: DeletePushTokenDto,
  ) {
    const user = req.user as User;
    await this.usersService.deletePushToken(user.id, deletePushTokenDto.token);

    return {
      success: true,
      message: 'Push token deleted successfully',
    };
  }

  @ApiOperation({ summary: 'Get accessibility settings' })
  @ApiResponse({
    status: 200,
    description: 'Accessibility settings retrieved successfully',
    type: AccessibilitySettingsDto,
  })
  @Get('me/accessibility-settings')
  async getAccessibilitySettings(@Req() req: Request) {
    const user = req.user as User;
    const settings = await this.usersService.getAccessibilitySettings(user.id);

    return {
      success: true,
      data: settings,
    };
  }

  @ApiOperation({ summary: 'Update accessibility settings' })
  @ApiResponse({
    status: 200,
    description: 'Accessibility settings updated successfully',
  })
  @Put('me/accessibility-settings')
  async updateAccessibilitySettings(
    @Req() req: Request,
    @Body() updateDto: UpdateAccessibilitySettingsDto,
  ) {
    const user = req.user as User;
    await this.usersService.updateAccessibilitySettings(user.id, updateDto);

    return new SuccessResponseDto(
      'Accessibility settings updated successfully',
    );
  }

  @ApiOperation({ summary: 'Record user consent for GDPR compliance' })
  @ApiResponse({ status: 201, description: 'Consent recorded successfully' })
  @Post('consent')
  async recordConsent(@Req() req: Request, @Body() consentDto: ConsentDto) {
    const user = req.user as User;
    const consent = await this.usersService.recordConsent(user.id, consentDto);

    return {
      success: true,
      message: 'Consent recorded successfully',
      data: {
        id: consent.id,
        dataProcessing: consent.dataProcessing,
        marketing: consent.marketing,
        analytics: consent.analytics,
        consentedAt: consent.consentedAt,
        createdAt: consent.createdAt,
      },
    };
  }

  @ApiOperation({
    summary: 'Export user data for GDPR compliance (data portability)',
  })
  @ApiResponse({ status: 200, description: 'User data export generated' })
  @Get('me/export')
  async exportUserData(@Req() req: Request, @Query() exportDto: ExportDataDto) {
    const user = req.user as User;
    const exportData = await this.gdprService.exportUserData(
      user.id,
      exportDto.format,
    );

    return {
      success: true,
      message: `User data exported successfully in ${exportDto.format || 'json'} format`,
      data: exportData,
    };
  }

  @ApiOperation({ summary: 'Get current user consent status' })
  @ApiResponse({ status: 200, description: 'Current consent status retrieved' })
  @Get('consent')
  async getCurrentConsent(@Req() req: Request) {
    const user = req.user as User;
    const consent = await this.usersService.getCurrentConsent(user.id);

    return {
      success: true,
      data: consent
        ? {
            id: consent.id,
            dataProcessing: consent.dataProcessing,
            marketing: consent.marketing,
            analytics: consent.analytics,
            consentedAt: consent.consentedAt,
            isActive: consent.isActive,
            createdAt: consent.createdAt,
          }
        : null,
    };
  }

  // Role Management Routes
  @ApiOperation({
    summary: 'Get list of users with their roles (Admin/Moderator only)',
  })
  @ApiResponse({
    status: 200,
    description: 'List of users with roles retrieved',
    type: UserRolesListResponseDto,
  })
  @UseGuards(RoleGuard)
  @Roles([UserRole.ADMIN, UserRole.MODERATOR])
  @Get('roles')
  async getUsersRoles(
    @Query('page') page: number = 1,
    @Query('limit') limit: number = 10,
  ) {
    const result = await this.usersService.getUsersWithRoles(page, limit);
    return {
      success: true,
      data: result,
    };
  }

  @ApiOperation({ summary: 'Update user role (Admin only)' })
  @ApiResponse({ status: 200, description: 'User role updated successfully' })
  @UseGuards(RoleGuard)
  @Roles([UserRole.ADMIN])
  @Put(':userId/role')
  async updateUserRole(
    @Req() req: Request,
    @Param('userId') userId: string,
    @Body() updateRoleDto: UpdateUserRoleDto,
  ) {
    const admin = req.user as User;
    const result = await this.usersService.updateUserRole(
      userId,
      updateRoleDto,
      admin.id,
    );

    return {
      success: true,
      message: `User role updated to ${updateRoleDto.role} successfully`,
      data: result,
    };
  }
}
