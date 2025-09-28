import { IsString, IsUUID } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateConversationDto {
  @ApiProperty({ description: 'Match ID for which to create conversation' })
  @IsString()
  @IsUUID()
  matchId: string;
}
