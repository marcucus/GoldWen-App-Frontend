import { Global, Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { CustomLoggerService } from './logger.service';

@Global()
@Module({
  imports: [ConfigModule],
  providers: [CustomLoggerService],
  exports: [CustomLoggerService],
})
export class LoggerModule {}
