import { Controller, Get, Put, Body, UseGuards, Req } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import {
  ApiTags,
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
} from '@nestjs/swagger';
import type { Request } from 'express';

import { User } from '../../database/entities/user.entity';
import { PreferencesService } from './preferences.service';
import {
  UserPreferencesDto,
  UpdateUserPreferencesDto,
} from './dto/preferences.dto';

@ApiTags('Preferences')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'))
@Controller('preferences')
export class PreferencesController {
  constructor(private readonly preferencesService: PreferencesService) {}

  @ApiOperation({ summary: 'Get current user preferences' })
  @ApiResponse({
    status: 200,
    description: 'User preferences retrieved successfully',
    type: UserPreferencesDto,
  })
  @Get('me')
  async getMyPreferences(@Req() req: Request) {
    const user = req.user as User;
    const preferences = await this.preferencesService.getUserPreferences(
      user.id,
    );

    return {
      success: true,
      data: preferences,
    };
  }

  @ApiOperation({ summary: 'Update current user preferences' })
  @ApiResponse({
    status: 200,
    description: 'User preferences updated successfully',
    type: UserPreferencesDto,
  })
  @Put('me')
  async updateMyPreferences(
    @Req() req: Request,
    @Body() updateDto: UpdateUserPreferencesDto,
  ) {
    const user = req.user as User;
    const result = await this.preferencesService.updateUserPreferences(
      user.id,
      updateDto,
    );

    return {
      success: true,
      message: result.message,
      data: result.preferences,
    };
  }
}
