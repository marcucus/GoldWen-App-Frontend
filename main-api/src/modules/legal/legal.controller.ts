import { Controller, Get, Query, Header } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiQuery } from '@nestjs/swagger';
import { LegalService } from './legal.service';
import { GetPrivacyPolicyDto } from './dto/privacy-policy.dto';

@ApiTags('Legal')
@Controller('legal')
export class LegalController {
  constructor(private legalService: LegalService) {}

  @ApiOperation({
    summary: 'Get privacy policy (RGPD compliance)',
    description:
      'Retrieve the privacy policy in JSON or HTML format. Returns the latest active version by default.',
  })
  @ApiQuery({
    name: 'version',
    required: false,
    description: 'Version of the privacy policy (default: latest)',
    example: 'latest',
  })
  @ApiQuery({
    name: 'format',
    required: false,
    description: 'Response format (json or html)',
    example: 'json',
    enum: ['json', 'html'],
  })
  @ApiResponse({
    status: 200,
    description: 'Privacy policy retrieved successfully',
    schema: {
      oneOf: [
        {
          type: 'object',
          properties: {
            version: { type: 'string', example: '1.0.0' },
            content: { type: 'object' },
            lastUpdated: { type: 'string', format: 'date-time' },
          },
        },
        {
          type: 'string',
          description: 'HTML content (when format=html)',
        },
      ],
    },
  })
  @Get('privacy-policy')
  async getPrivacyPolicy(@Query() query: GetPrivacyPolicyDto) {
    const { version = 'latest', format = 'json' } = query;

    const policy = await this.legalService.getPrivacyPolicy(version);

    if (format === 'html') {
      return policy.htmlContent || policy.content;
    }

    return {
      version: policy.version,
      content: JSON.parse(policy.content),
      lastUpdated: policy.effectiveDate,
      effectiveDate: policy.effectiveDate,
    };
  }
}
