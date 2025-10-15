import {
  Controller,
  Get,
  Post,
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
import { ProfilesService } from './profiles.service';
import { SubmitPersonalityAnswersDto } from './dto/profiles.dto';

@ApiTags('Personality')
@Controller()
export class PersonalityController {
  constructor(private readonly profilesService: ProfilesService) {}

  @Get('personality-questions')
  @ApiOperation({ summary: 'Get personality questionnaire questions' })
  @ApiResponse({ status: 200, description: 'Personality questions retrieved' })
  async getPersonalityQuestions() {
    return this.profilesService.getPersonalityQuestions();
  }

  @Post('personality-answers')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Submit personality questionnaire answers',
    description:
      'Submit answers to the personality questionnaire. Text answers and multiple choice answers will be moderated for inappropriate content and forbidden words.',
  })
  @ApiResponse({
    status: 201,
    description: 'Personality answers submitted successfully',
  })
  @ApiResponse({
    status: 400,
    description:
      'Invalid request or content moderation failed. Answers contain forbidden words or inappropriate content.',
  })
  async submitPersonalityAnswers(
    @Request() req: any,
    @Body() answersDto: SubmitPersonalityAnswersDto,
  ) {
    await this.profilesService.submitPersonalityAnswers(
      req.user.id,
      answersDto,
    );
    return { message: 'Personality answers submitted successfully' };
  }
}
