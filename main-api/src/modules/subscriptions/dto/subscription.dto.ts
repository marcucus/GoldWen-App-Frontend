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

export class PurchaseDto {
  @ApiProperty({
    description: 'The product identifier (e.g., goldwen_plus_monthly)',
    example: 'goldwen_plus_monthly',
  })
  @IsString()
  productId: string;

  @ApiProperty({
    description: 'RevenueCat transaction/receipt identifier',
    example: 'rc_transaction_123456',
  })
  @IsString()
  transactionId: string;

  @ApiPropertyOptional({
    description: 'Original transaction ID for subscription',
    example: 'original_transaction_123456',
  })
  @IsOptional()
  @IsString()
  originalTransactionId?: string;

  @ApiPropertyOptional({
    description: 'Purchase receipt/token from app store',
    example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
  })
  @IsOptional()
  @IsString()
  purchaseToken?: string;

  @ApiPropertyOptional({
    description: 'Price paid for the subscription',
    example: 19.99,
  })
  @IsOptional()
  @IsNumber()
  price?: number;

  @ApiPropertyOptional({
    description: 'Currency code',
    example: 'EUR',
  })
  @IsOptional()
  @IsString()
  currency?: string;

  @ApiPropertyOptional({
    description: 'Platform of purchase (ios, android)',
    example: 'ios',
  })
  @IsOptional()
  @IsString()
  platform?: string;
}
