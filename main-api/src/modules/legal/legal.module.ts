import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { LegalController } from './legal.controller';
import { LegalService } from './legal.service';
import { PrivacyPolicy } from '../../database/entities/privacy-policy.entity';

@Module({
  imports: [TypeOrmModule.forFeature([PrivacyPolicy])],
  controllers: [LegalController],
  providers: [LegalService],
  exports: [LegalService],
})
export class LegalModule {}
