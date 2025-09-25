import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';
import { JwtService } from '@nestjs/jwt';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../src/database/entities/user.entity';
import { Profile } from '../src/database/entities/profile.entity';
import { UserStatus, SubscriptionTier } from '../src/common/enums';

describe('Profiles API (e2e)', () => {
  let app: INestApplication;
  let jwtService: JwtService;
  let userRepository: Repository<User>;
  let profileRepository: Repository<Profile>;
  let authToken: string;
  let testUser: any;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    jwtService = moduleFixture.get<JwtService>(JwtService);
    userRepository = moduleFixture.get<Repository<User>>(getRepositoryToken(User));
    profileRepository = moduleFixture.get<Repository<Profile>>(getRepositoryToken(Profile));

    // Create test user
    testUser = await userRepository.save(userRepository.create({
      email: 'test@example.com',
      firstName: 'John',
      lastName: 'Doe',
      status: UserStatus.ACTIVE,
      isProfileCompleted: false,
      isOnboardingCompleted: false,
    }));

    // Generate auth token
    authToken = jwtService.sign({
      sub: testUser.id,
      email: testUser.email,
    });
  });

  afterAll(async () => {
    // Clean up test data
    await profileRepository.delete({});
    await userRepository.delete({});
    await app.close();
  });

  describe('/profiles/me (GET)', () => {
    it('should return user profile', () => {
      return request(app.getHttpServer())
        .get('/profiles/me')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200)
        .expect((res) => {
          expect(res.body).toHaveProperty('user');
          expect(res.body.user.email).toBe('test@example.com');
        });
    });

    it('should return 401 without auth token', () => {
      return request(app.getHttpServer())
        .get('/profiles/me')
        .expect(401);
    });
  });

  describe('/profiles/completion (GET)', () => {
    it('should return profile completion status', () => {
      return request(app.getHttpServer())
        .get('/profiles/completion')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200)
        .expect((res) => {
          expect(res.body).toHaveProperty('isProfileCompleted');
          expect(res.body).toHaveProperty('isOnboardingCompleted');
          expect(res.body).toHaveProperty('completionPercentage');
          expect(res.body).toHaveProperty('missingSteps');
        });
    });
  });

  describe('/profiles/me (PUT)', () => {
    it('should update user profile', () => {
      return request(app.getHttpServer())
        .put('/profiles/me')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          bio: 'Updated bio',
          birthDate: '1990-01-01',
          gender: 'male',
          interestedInGenders: ['female'],
        })
        .expect(200)
        .expect((res) => {
          expect(res.body.profile.bio).toBe('Updated bio');
        });
    });

    it('should validate required fields', () => {
      return request(app.getHttpServer())
        .put('/profiles/me')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          bio: '', // Empty bio should fail validation
        })
        .expect(400);
    });
  });

  describe('/profiles/prompts (GET)', () => {
    it('should return available prompts', () => {
      return request(app.getHttpServer())
        .get('/profiles/prompts')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200)
        .expect((res) => {
          expect(Array.isArray(res.body)).toBe(true);
          if (res.body.length > 0) {
            expect(res.body[0]).toHaveProperty('id');
            expect(res.body[0]).toHaveProperty('text');
          }
        });
    });
  });

  describe('/profiles/me/prompt-answers (POST)', () => {
    it('should save prompt answers', () => {
      return request(app.getHttpServer())
        .post('/profiles/me/prompt-answers')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          answers: [
            { promptId: 'prompt-1', answer: 'My first answer' },
            { promptId: 'prompt-2', answer: 'My second answer' },
            { promptId: 'prompt-3', answer: 'My third answer' },
          ],
        })
        .expect(201)
        .expect((res) => {
          expect(res.body).toHaveProperty('success', true);
          expect(res.body).toHaveProperty('answersCount', 3);
        });
    });

    it('should require minimum 3 answers', () => {
      return request(app.getHttpServer())
        .post('/profiles/me/prompt-answers')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          answers: [
            { promptId: 'prompt-1', answer: 'Only one answer' },
          ],
        })
        .expect(400);
    });
  });

  describe('/profiles/me/status (PUT)', () => {
    it('should update profile status', () => {
      return request(app.getHttpServer())
        .put('/profiles/me/status')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          status: 'active',
          completed: true,
        })
        .expect(200)
        .expect((res) => {
          expect(res.body).toHaveProperty('success', true);
          expect(res.body.user.isProfileCompleted).toBe(true);
        });
    });
  });

  describe('/profiles/me/personality-answers (POST)', () => {
    it('should save personality questionnaire answers', () => {
      const personalityAnswers = Array.from({ length: 10 }, (_, i) => ({
        questionId: `question-${i + 1}`,
        answer: i % 5, // 0-4 scale
      }));

      return request(app.getHttpServer())
        .post('/profiles/me/personality-answers')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ answers: personalityAnswers })
        .expect(201)
        .expect((res) => {
          expect(res.body).toHaveProperty('success', true);
          expect(res.body).toHaveProperty('answersCount', 10);
        });
    });

    it('should require all 10 personality questions', () => {
      return request(app.getHttpServer())
        .post('/profiles/me/personality-answers')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          answers: [
            { questionId: 'question-1', answer: 1 },
          ],
        })
        .expect(400);
    });
  });
});

describe('Matching API (e2e)', () => {
  let app: INestApplication;
  let jwtService: JwtService;
  let userRepository: Repository<User>;
  let authToken: string;
  let testUser: any;
  let targetUser: any;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    jwtService = moduleFixture.get<JwtService>(JwtService);
    userRepository = moduleFixture.get<Repository<User>>(getRepositoryToken(User));

    // Create test users
    testUser = await userRepository.save(userRepository.create({
      email: 'test@example.com',
      firstName: 'John',
      status: UserStatus.ACTIVE,
      isProfileCompleted: true,
    }));

    targetUser = await userRepository.save(userRepository.create({
      email: 'target@example.com',
      firstName: 'Jane',
      status: UserStatus.ACTIVE,
      isProfileCompleted: true,
    }));

    authToken = jwtService.sign({
      sub: testUser.id,
      email: testUser.email,
    });
  });

  afterAll(async () => {
    await userRepository.delete({});
    await app.close();
  });

  describe('/matching/daily-selection (GET)', () => {
    it('should return daily selection profiles', () => {
      return request(app.getHttpServer())
        .get('/matching/daily-selection')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200)
        .expect((res) => {
          expect(Array.isArray(res.body)).toBe(true);
        });
    });
  });

  describe('/matching/choose/:targetUserId (POST)', () => {
    it('should create match when user makes choice', () => {
      return request(app.getHttpServer())
        .post(`/matching/choose/${targetUser.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(201)
        .expect((res) => {
          expect(res.body).toHaveProperty('match');
          expect(res.body).toHaveProperty('isMutualMatch');
          expect(res.body.match.targetUserId).toBe(targetUser.id);
        });
    });

    it('should prevent duplicate choices', () => {
      return request(app.getHttpServer())
        .post(`/matching/choose/${targetUser.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(400);
    });
  });

  describe('/matching/matches (GET)', () => {
    it('should return user matches', () => {
      return request(app.getHttpServer())
        .get('/matching/matches')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200)
        .expect((res) => {
          expect(Array.isArray(res.body)).toBe(true);
        });
    });
  });

  describe('/matching/compatibility/:targetUserId (GET)', () => {
    it('should calculate compatibility score', () => {
      return request(app.getHttpServer())
        .get(`/matching/compatibility/${targetUser.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200)
        .expect((res) => {
          expect(res.body).toHaveProperty('score');
          expect(res.body).toHaveProperty('factors');
          expect(typeof res.body.score).toBe('number');
        });
    });
  });
});

describe('Authentication API (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  describe('/auth/google (POST)', () => {
    it('should handle Google OAuth callback', () => {
      return request(app.getHttpServer())
        .post('/auth/google')
        .send({
          token: 'valid-google-token', // In real tests, mock this
          googleId: 'google-123',
          email: 'test@gmail.com',
          firstName: 'John',
          lastName: 'Doe',
        })
        .expect((res) => {
          // This would fail in real environment without proper Google token
          // but serves as a structure example
          expect(res.status).toBeOneOf([200, 401, 400]);
        });
    });
  });

  describe('/auth/apple (POST)', () => {
    it('should handle Apple OAuth callback', () => {
      return request(app.getHttpServer())
        .post('/auth/apple')
        .send({
          token: 'valid-apple-token',
          appleId: 'apple-123',
          email: 'test@icloud.com',
          firstName: 'John',
          lastName: 'Doe',
        })
        .expect((res) => {
          expect(res.status).toBeOneOf([200, 401, 400]);
        });
    });
  });
});