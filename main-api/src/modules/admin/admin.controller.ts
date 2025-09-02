import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiResponse,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminService } from './admin.service';
import {
  AdminLoginDto,
  UpdateUserStatusDto,
  HandleReportDto,
  BroadcastNotificationDto,
  GetUsersDto,
  GetReportsDto,
} from './dto/admin.dto';

@ApiTags('admin')
@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Post('auth/login')
  @ApiOperation({ summary: 'Admin login' })
  @ApiResponse({ status: 200, description: 'Admin authenticated successfully' })
  async login(@Body() adminLoginDto: AdminLoginDto) {
    const admin = await this.adminService.authenticateAdmin(adminLoginDto);

    if (!admin) {
      throw new Error('Invalid credentials');
    }

    // In a real implementation, you'd generate a JWT token here
    return {
      admin: {
        id: admin.id,
        email: admin.email,
        role: admin.role,
      },
      message: 'Login successful',
    };
  }

  @Get('dashboard')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get dashboard statistics' })
  @ApiResponse({ status: 200, description: 'Dashboard statistics retrieved' })
  async getDashboard() {
    const stats = await this.adminService.getDashboardStats();
    const recentActivity = await this.adminService.getRecentActivity();

    return {
      stats,
      recentActivity,
    };
  }

  @Get('users')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get users list' })
  @ApiResponse({ status: 200, description: 'Users list retrieved' })
  async getUsers(@Query() getUsersDto: GetUsersDto) {
    return this.adminService.getUsers(getUsersDto);
  }

  @Get('users/:userId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get user details' })
  @ApiResponse({ status: 200, description: 'User details retrieved' })
  async getUserDetails(@Param('userId') userId: string) {
    return this.adminService.getUserDetails(userId);
  }

  @Put('users/:userId/status')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update user status' })
  @ApiResponse({ status: 200, description: 'User status updated successfully' })
  async updateUserStatus(
    @Param('userId') userId: string,
    @Body() updateStatusDto: UpdateUserStatusDto,
  ) {
    return this.adminService.updateUserStatus(userId, updateStatusDto);
  }

  @Delete('users/:userId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Delete user' })
  @ApiResponse({ status: 200, description: 'User deleted successfully' })
  async deleteUser(@Param('userId') userId: string) {
    await this.adminService.deleteUser(userId);
    return { message: 'User deleted successfully' };
  }

  @Get('reports')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get reports list' })
  @ApiResponse({ status: 200, description: 'Reports list retrieved' })
  async getReports(@Query() getReportsDto: GetReportsDto) {
    return this.adminService.getReports(getReportsDto);
  }

  @Put('reports/:reportId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Handle a report' })
  @ApiResponse({ status: 200, description: 'Report handled successfully' })
  async handleReport(
    @Param('reportId') reportId: string,
    @Body() handleReportDto: HandleReportDto,
  ) {
    return this.adminService.handleReport(reportId, handleReportDto);
  }

  @Get('analytics')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get platform analytics' })
  @ApiResponse({ status: 200, description: 'Analytics data retrieved' })
  async getAnalytics() {
    return this.adminService.getUserAnalytics();
  }

  @Post('notifications/broadcast')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Broadcast notification to all users' })
  @ApiResponse({
    status: 200,
    description: 'Notification broadcasted successfully',
  })
  async broadcastNotification(@Body() broadcastDto: BroadcastNotificationDto) {
    await this.adminService.broadcastNotification(broadcastDto);
    return { message: 'Notification broadcasted successfully' };
  }
}
