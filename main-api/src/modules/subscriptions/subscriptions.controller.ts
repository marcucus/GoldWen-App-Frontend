import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  UseGuards,
  Request,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiResponse,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';
import { SubscriptionsService } from './subscriptions.service';
import {
  CreateSubscriptionDto,
  UpdateSubscriptionDto,
  RevenueCatWebhookDto,
} from './dto/subscription.dto';

@ApiTags('subscriptions')
@Controller('subscriptions')
export class SubscriptionsController {
  constructor(private readonly subscriptionsService: SubscriptionsService) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create a new subscription' })
  @ApiResponse({
    status: 201,
    description: 'Subscription created successfully',
  })
  async createSubscription(
    @Request() req: any,
    @Body() createSubscriptionDto: CreateSubscriptionDto,
  ) {
    return this.subscriptionsService.createSubscription(
      req.user.id,
      createSubscriptionDto,
    );
  }

  @Get('active')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get active subscription' })
  @ApiResponse({ status: 200, description: 'Active subscription retrieved' })
  async getActiveSubscription(@Request() req: any) {
    return this.subscriptionsService.getActiveSubscription(req.user.id);
  }

  @Get()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get all user subscriptions' })
  @ApiResponse({
    status: 200,
    description: 'Subscriptions retrieved successfully',
  })
  async getUserSubscriptions(@Request() req: any) {
    return this.subscriptionsService.getUserSubscriptions(req.user.id);
  }

  @Get('features')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get subscription features' })
  @ApiResponse({ status: 200, description: 'Subscription features retrieved' })
  async getSubscriptionFeatures(@Request() req: any) {
    return this.subscriptionsService.getSubscriptionFeatures(req.user.id);
  }

  @Put(':subscriptionId/activate')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Activate a subscription' })
  @ApiResponse({
    status: 200,
    description: 'Subscription activated successfully',
  })
  async activateSubscription(@Param('subscriptionId') subscriptionId: string) {
    return this.subscriptionsService.activateSubscription(subscriptionId);
  }

  @Put(':subscriptionId/cancel')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Cancel a subscription' })
  @ApiResponse({
    status: 200,
    description: 'Subscription cancelled successfully',
  })
  async cancelSubscription(
    @Request() req: any,
    @Param('subscriptionId') subscriptionId: string,
  ) {
    return this.subscriptionsService.cancelSubscription(
      subscriptionId,
      req.user.id,
    );
  }

  @Put(':subscriptionId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update a subscription' })
  @ApiResponse({
    status: 200,
    description: 'Subscription updated successfully',
  })
  async updateSubscription(
    @Param('subscriptionId') subscriptionId: string,
    @Body() updateSubscriptionDto: UpdateSubscriptionDto,
  ) {
    return this.subscriptionsService.updateSubscription(
      subscriptionId,
      updateSubscriptionDto,
    );
  }

  // RevenueCat webhook endpoint
  @Post('webhook/revenuecat')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Handle RevenueCat webhook' })
  @ApiResponse({ status: 200, description: 'Webhook processed successfully' })
  async handleRevenueCatWebhook(@Body() webhookData: RevenueCatWebhookDto) {
    await this.subscriptionsService.handleRevenueCatWebhook(webhookData);
    return { status: 'ok' };
  }

  /* TODO: Implement these methods in the service
  @Post('purchase')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Purchase a subscription' })
  @ApiResponse({
    status: 201,
    description: 'Subscription purchased successfully',
  })
  async purchaseSubscription(
    @Request() req: any,
    @Body() purchaseDto: any, // Will define proper DTO
  ) {
    return this.subscriptionsService.purchaseSubscription(
      req.user.id,
      purchaseDto,
    );
  }

  @Post('verify-receipt')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Verify a purchase receipt' })
  @ApiResponse({
    status: 200,
    description: 'Receipt verified successfully',
  })
  async verifyReceipt(
    @Request() req: any,
    @Body() verifyDto: any, // Will define proper DTO
  ) {
    return this.subscriptionsService.verifyReceipt(
      req.user.id,
      verifyDto,
    );
  }

  @Put('cancel')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Cancel user subscription' })
  @ApiResponse({
    status: 200,
    description: 'Subscription cancelled successfully',
  })
  async cancelUserSubscription(
    @Request() req: any,
    @Body() cancelDto?: any,
  ) {
    return this.subscriptionsService.cancelUserSubscription(
      req.user.id,
      cancelDto?.reason,
    );
  }

  @Post('restore')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Restore subscriptions' })
  @ApiResponse({
    status: 200,
    description: 'Subscriptions restored successfully',
  })
  async restoreSubscriptions(@Request() req: any) {
    return this.subscriptionsService.restoreSubscriptions(req.user.id);
  }

  @Get('usage')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get subscription usage' })
  @ApiResponse({
    status: 200,
    description: 'Usage statistics retrieved successfully',
  })
  async getUsage(@Request() req: any) {
    return this.subscriptionsService.getUsage(req.user.id);
  }

  @Get('plans')
  @ApiOperation({ summary: 'Get available subscription plans' })
  @ApiResponse({
    status: 200,
    description: 'Plans retrieved successfully',
  })
  async getPlans() {
    return this.subscriptionsService.getPlans();
  }
  */

  // Admin endpoints
  @Get('admin/stats')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get subscription statistics (Admin only)' })
  @ApiResponse({
    status: 200,
    description: 'Subscription statistics retrieved',
  })
  async getSubscriptionStats() {
    return this.subscriptionsService.getSubscriptionStats();
  }
}
