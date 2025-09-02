import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { Strategy, VerifyCallback } from 'passport-google-oauth20';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class GoogleStrategy extends PassportStrategy(Strategy, 'google') {
  constructor(private configService: ConfigService) {
    const clientId = configService.get('oauth.google.clientId');
    const clientSecret = configService.get('oauth.google.clientSecret');
    const environment = configService.get('app.environment');

    // Only require OAuth credentials in production
    if (environment === 'production' && (!clientId || !clientSecret)) {
      throw new Error('Google OAuth credentials not configured');
    }

    // Skip OAuth initialization in development if credentials are missing
    if (!clientId || !clientSecret) {
      return;
    }

    super({
      clientID: clientId,
      clientSecret: clientSecret,
      callbackURL: '/auth/google/callback',
      scope: ['email', 'profile'],
    });
  }

  async validate(
    accessToken: string,
    refreshToken: string,
    profile: any,
    done: VerifyCallback,
  ): Promise<any> {
    const { id, name, emails, photos } = profile;

    const user = {
      socialId: id,
      provider: 'google',
      email: emails[0].value,
      firstName: name.givenName,
      lastName: name.familyName,
      profilePicture: photos[0].value,
    };

    done(null, user);
  }
}
