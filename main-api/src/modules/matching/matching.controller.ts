import {
  Controller,
  Get,
  Post,
  Delete,
  Param,
  Query,
  Body,
  UseGuards,
  Request,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiResponse,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ProfileCompletionGuard } from '../auth/guards/profile-completion.guard';
import { PremiumGuard } from '../auth/guards/premium.guard';
import { QuotaGuard } from './guards/quota.guard';
import { MatchingService } from './matching.service';
import { GetMatchesDto } from './dto/matching.dto';

@ApiTags('matching')
@Controller('matching')
@UseGuards(JwtAuthGuard, ProfileCompletionGuard)
@ApiBearerAuth()
export class MatchingController {
  constructor(private readonly matchingService: MatchingService) {}

  @Get('user-choices')
  @ApiOperation({ summary: 'Get user choices history' })
  @ApiResponse({
    status: 200,
    description: 'User choices retrieved successfully',
  })
  async getUserChoices(@Request() req: any, @Query('date') date?: string) {
    const data = await this.matchingService.getUserChoices(req.user.id, date);
    return {
      success: true,
      data,
    };
  }

  @Get('daily-selection/status')
  @ApiOperation({ summary: 'Get daily selection status' })
  @ApiResponse({
    status: 200,
    description: 'Daily selection status retrieved successfully',
  })
  async getDailySelectionStatus(@Request() req: any) {
    return this.matchingService.getDailySelectionStatus(req.user.id);
  }

  @Get('daily-selection')
  @ApiOperation({ summary: 'Get daily selection of profiles' })
  @ApiResponse({
    status: 200,
    description: 'Daily selection retrieved successfully',
  })
  async getDailySelection(
    @Request() req: any,
    @Query('preload') preload?: boolean,
  ) {
    const data = await this.matchingService.getDailySelection(
      req.user.id,
      preload,
    );
    return {
      success: true,
      data,
    };
  }

  @Post('daily-selection/generate')
  @ApiOperation({ summary: 'Manually generate daily selection (for testing)' })
  @ApiResponse({
    status: 201,
    description: 'Daily selection generated successfully',
  })
  async generateDailySelection(@Request() req: any) {
    return this.matchingService.generateDailySelection(req.user.id);
  }

  @Post('choose/:targetUserId')
  @UseGuards(QuotaGuard)
  @ApiOperation({ summary: 'Choose a profile from daily selection' })
  @ApiResponse({
    status: 201,
    description: 'Profile choice registered successfully',
  })
  @ApiResponse({
    status: 403,
    description: 'Daily quota exceeded',
  })
  async chooseProfile(
    @Request() req: any,
    @Param('targetUserId') targetUserId: string,
    @Body() body: { choice: 'like' | 'pass' },
  ) {
    return this.matchingService.chooseProfile(
      req.user.id,
      targetUserId,
      body.choice,
    );
  }

  @Get('matches')
  @ApiOperation({ summary: 'Get user matches' })
  @ApiResponse({ status: 200, description: 'Matches retrieved successfully' })
  async getMatches(@Request() req: any, @Query() query: GetMatchesDto) {
    const matches = await this.matchingService.getUserMatches(
      req.user.id,
      query.status,
    );
    return {
      success: true,
      data: matches,
    };
  }

  @Get('pending-matches')
  @ApiOperation({ summary: 'Get pending matches awaiting chat acceptance' })
  @ApiResponse({
    status: 200,
    description: 'Pending matches retrieved successfully',
  })
  async getPendingMatches(@Request() req: any) {
    const pendingMatches = await this.matchingService.getPendingMatches(
      req.user.id,
    );
    return {
      success: true,
      data: pendingMatches,
    };
  }

  @Get('matches/:matchId')
  @ApiOperation({ summary: 'Get specific match details' })
  @ApiResponse({
    status: 200,
    description: 'Match details retrieved successfully',
  })
  async getMatch(@Request() req: any, @Param('matchId') matchId: string) {
    const matches = await this.matchingService.getUserMatches(req.user.id);
    const match = matches.find((m) => m.id === matchId);

    if (!match) {
      throw new Error('Match not found');
    }

    return match;
  }

  @Delete('matches/:matchId')
  @ApiOperation({ summary: 'Delete a match' })
  @ApiResponse({ status: 200, description: 'Match deleted successfully' })
  async deleteMatch(@Request() req: any, @Param('matchId') matchId: string) {
    await this.matchingService.deleteMatch(req.user.id, matchId);
    return { message: 'Match deleted successfully' };
  }

  @Get('compatibility/:targetUserId')
  @ApiOperation({ summary: 'Get compatibility score with another user' })
  @ApiResponse({ status: 200, description: 'Compatibility score calculated' })
  async getCompatibilityScore(
    @Request() req: any,
    @Param('targetUserId') targetUserId: string,
  ) {
    const score = await this.matchingService.getCompatibilityScore(
      req.user.id,
      targetUserId,
    );
    return { compatibilityScore: score };
  }

  @Get('history')
  @ApiOperation({ summary: 'Get matching history' })
  @ApiResponse({
    status: 200,
    description: 'Matching history retrieved successfully',
  })
  async getMatchingHistory(
    @Request() req: any,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    const options = {
      startDate: startDate ? new Date(startDate) : undefined,
      endDate: endDate ? new Date(endDate) : undefined,
      page: page ? parseInt(page, 10) : 1,
      limit: limit ? parseInt(limit, 10) : 20,
    };

    return this.matchingService.getHistory(req.user.id, options);
  }

  @Get('who-liked-me')
  @UseGuards(PremiumGuard)
  @ApiOperation({
    summary: 'Get users who liked me (Premium feature)',
  })
  @ApiResponse({
    status: 200,
    description: 'Users who liked me retrieved successfully',
  })
  @ApiResponse({
    status: 403,
    description: 'Premium subscription required',
  })
  async getWhoLikedMe(@Request() req: any) {
    const likedBy = await this.matchingService.getWhoLikedMe(req.user.id);
    return {
      success: true,
      data: likedBy,
    };
  }
}
