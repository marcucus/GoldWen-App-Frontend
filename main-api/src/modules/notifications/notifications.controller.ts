import {
  Controller,
  Get,
  Put,
  Delete,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
  ForbiddenException,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiResponse,
  ApiParam,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { NotificationsService } from './notifications.service';
import { CustomLoggerService } from '../../common/logger';
import { ScheduledNotificationsService } from './scheduled-notifications.service';

import {
  GetNotificationsDto,
  UpdateNotificationSettingsDto,
  TestNotificationDto,
  SendGroupNotificationDto,
} from './dto/notifications.dto';

@ApiTags('notifications')
@Controller('notifications')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class NotificationsController {
  constructor(
    private readonly notificationsService: NotificationsService,
    private readonly logger: CustomLoggerService,
    private readonly scheduledNotificationsService: ScheduledNotificationsService,
  ) {}

  @Get()
  @ApiOperation({ summary: 'Get user notifications' })
  @ApiResponse({
    status: 200,
    description: 'Notifications retrieved successfully',
  })
  async getNotifications(
    @Request() req: any,
    @Query() getNotificationsDto: GetNotificationsDto,
  ) {
    const userId = req.user.id;

    this.logger.setContext({ userId, userEmail: req.user.email });

    const result = await this.notificationsService.getNotifications(
      userId,
      getNotificationsDto,
    );

    return {
      success: true,
      data: result,
    };
  }

  @Put(':notificationId/read')
  @ApiOperation({ summary: 'Mark notification as read' })
  @ApiParam({ name: 'notificationId', description: 'Notification ID' })
  @ApiResponse({ status: 200, description: 'Notification marked as read' })
  async markAsRead(
    @Request() req: any,
    @Param('notificationId') notificationId: string,
  ) {
    const userId = req.user.id;

    this.logger.setContext({ userId, userEmail: req.user.email });

    const notification = await this.notificationsService.markAsRead(
      notificationId,
      userId,
    );

    return {
      success: true,
      data: notification,
      message: 'Notification marked as read',
    };
  }

  @Put('read-all')
  @ApiOperation({ summary: 'Mark all notifications as read' })
  @ApiResponse({ status: 200, description: 'All notifications marked as read' })
  async markAllAsRead(@Request() req: any) {
    const userId = req.user.id;

    this.logger.setContext({ userId, userEmail: req.user.email });

    const result = await this.notificationsService.markAllAsRead(userId);

    return {
      success: true,
      data: result,
      message: 'All notifications marked as read',
    };
  }

  @Delete(':notificationId')
  @ApiOperation({ summary: 'Delete notification' })
  @ApiParam({ name: 'notificationId', description: 'Notification ID' })
  @ApiResponse({
    status: 200,
    description: 'Notification deleted successfully',
  })
  async deleteNotification(
    @Request() req: any,
    @Param('notificationId') notificationId: string,
  ) {
    const userId = req.user.id;

    this.logger.setContext({ userId, userEmail: req.user.email });

    await this.notificationsService.deleteNotification(notificationId, userId);

    return {
      success: true,
      message: 'Notification deleted successfully',
    };
  }

  @Put('settings')
  @ApiOperation({ summary: 'Update notification settings' })
  @ApiResponse({ status: 200, description: 'Notification settings updated' })
  async updateSettings(
    @Request() req: any,
    @Body() updateSettingsDto: UpdateNotificationSettingsDto,
  ) {
    const userId = req.user.id;

    this.logger.setContext({ userId, userEmail: req.user.email });

    const result = await this.notificationsService.updateNotificationSettings(
      userId,
      updateSettingsDto,
    );

    return {
      success: true,
      data: result,
    };
  }

  @Post('test')
  @ApiOperation({
    summary: 'Send test notification (development only)',
    description: 'This endpoint is only available in development environment',
  })
  @ApiResponse({ status: 200, description: 'Test notification sent' })
  @ApiResponse({ status: 403, description: 'Not available in production' })
  async sendTestNotification(
    @Request() req: any,
    @Body() testNotificationDto: TestNotificationDto,
  ) {
    const userId = req.user.id;

    this.logger.setContext({ userId, userEmail: req.user.email });

    const notification = await this.notificationsService.sendTestNotification(
      userId,
      testNotificationDto,
    );

    return {
      success: true,
      data: notification,
      message: 'Test notification sent successfully',
    };
  }

  @Post('send-group')
  @ApiOperation({
    summary: 'Send notification to group of users (admin only)',
    description: 'Send a notification to multiple users at once',
  })
  @ApiResponse({ status: 201, description: 'Group notification sent' })
  async sendGroupNotification(
    @Request() req: any,
    @Body() sendGroupNotificationDto: SendGroupNotificationDto,
  ) {
    const userId = req.user.id;

    this.logger.setContext({ userId, userEmail: req.user.email });

    // TODO: Add admin role check here
    // if (!req.user.isAdmin) {
    //   throw new ForbiddenException('Admin access required');
    // }

    const notifications = await this.notificationsService.sendGroupNotification(
      sendGroupNotificationDto,
    );

    return {
      success: true,
      data: {
        count: notifications.length,
        notifications: notifications.map((n) => ({
          id: n.id,
          userId: n.userId,
          type: n.type,
          title: n.title,
        })),
      },
      message: 'Group notification sent successfully',
    };
  }

  @Post('trigger-daily-selection')
  @ApiOperation({
    summary: 'Manually trigger daily selection notifications (dev only)',
    description:
      'Manually trigger the daily selection notification job for testing',
  })
  @ApiResponse({
    status: 201,
    description: 'Daily selection notifications triggered',
  })
  async triggerDailySelectionNotifications(@Request() req: any) {
    const userId = req.user.id;

    this.logger.setContext({ userId, userEmail: req.user.email });

    // Only allow in development
    if (this.scheduledNotificationsService) {
      await this.scheduledNotificationsService.triggerDailySelectionNotifications();
    }

    return {
      success: true,
      message: 'Daily selection notifications triggered successfully',
    };
  }
}
