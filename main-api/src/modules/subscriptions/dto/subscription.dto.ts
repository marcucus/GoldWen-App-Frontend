import {
  IsEnum,
  IsOptional,
  IsString,
  IsNumber,
  IsDateString,
  IsObject,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { SubscriptionPlan, SubscriptionStatus } from '../../../common/enums';

export class CreateSubscriptionDto {
  @ApiProperty({ enum: SubscriptionPlan })
  @IsEnum(SubscriptionPlan)
  plan: SubscriptionPlan;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  revenueCatCustomerId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  revenueCatSubscriptionId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  originalTransactionId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  price?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  currency?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  purchaseToken?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  platform?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsObject()
  metadata?: any;
}

export class UpdateSubscriptionDto {
  @ApiPropertyOptional({ enum: SubscriptionStatus })
  @IsOptional()
  @IsEnum(SubscriptionStatus)
  status?: SubscriptionStatus;

  @ApiPropertyOptional()
  @IsOptional()
  @IsDateString()
  expiresAt?: Date;

  @ApiPropertyOptional()
  @IsOptional()
  @IsObject()
  metadata?: any;
}

// RevenueCat webhook DTOs
export class RevenueCatEventDto {
  @IsString()
  type: string;

  @IsString()
  id: string;

  @IsOptional()
  @IsString()
  product_id?: string;

  @IsOptional()
  @IsString()
  original_transaction_id?: string;

  @IsOptional()
  @IsNumber()
  price_in_purchased_currency?: number;

  @IsOptional()
  @IsString()
  currency?: string;

  @IsOptional()
  @IsString()
  store?: string;

  @IsOptional()
  @IsDateString()
  purchased_at?: string;

  @IsOptional()
  @IsDateString()
  expiration_at?: string;

  @IsOptional()
  @IsObject()
  subscriber_attributes?: any;
}

export class RevenueCatWebhookDto {
  @ValidateNested()
  @Type(() => RevenueCatEventDto)
  event: RevenueCatEventDto;

  @IsString()
  app_user_id: string;

  @IsOptional()
  @IsString()
  api_version?: string;
}
