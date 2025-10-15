import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { InjectRedis } from '@nestjs-modules/ioredis';
import Redis from 'ioredis';
import { User } from '../../../database/entities/user.entity';
import { UserStatus } from '../../../common/enums';

export interface JwtPayload {
  sub: string;
  email: string;
  iat?: number;
  exp?: number;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    @InjectRepository(User)
    private userRepository: Repository<User>,
    private configService: ConfigService,
    @InjectRedis() private redis: Redis,
  ) {
    const secret = configService.get('jwt.secret');
    if (!secret) {
      throw new Error('JWT secret not configured');
    }

    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: secret,
      passReqToCallback: true, // Enable to get the request object
    });
  }

  async validate(req: any, payload: JwtPayload): Promise<User> {
    const { sub: userId } = payload;

    // Extract token from request
    const token = ExtractJwt.fromAuthHeaderAsBearerToken()(req);
    
    // Check if token is blacklisted
    if (token) {
      const isBlacklisted = await this.redis.get(`blacklist:token:${token}`);
      if (isBlacklisted) {
        throw new UnauthorizedException('Token has been revoked');
      }
    }

    const user = await this.userRepository.findOne({
      where: { id: userId },
      relations: [
        'profile',
        'profile.photos',
        'profile.promptAnswers',
        'personalityAnswers',
      ],
    });

    if (!user) {
      throw new UnauthorizedException('User not found');
    }

    if (user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException('User account is not active');
    }

    return user;
  }
}
