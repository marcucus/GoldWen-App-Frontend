import { IsOptional, IsEnum, IsUUID } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { MatchStatus } from '../../../common/enums';

export class GetMatchesDto {
  @ApiPropertyOptional({ enum: MatchStatus })
  @IsOptional()
  @IsEnum(MatchStatus)
  status?: MatchStatus;
}

export class ChooseProfileDto {
  @ApiPropertyOptional()
  @IsUUID()
  targetUserId: string;
}
