# GoldWen Backend API

GoldWen is a modern dating application focused on quality connections over quantity. This repository contains the main backend API built with NestJS, TypeScript, and PostgreSQL.

## 🌟 Features

- **Authentication & Authorization**: JWT-based auth with Google/Apple OAuth
- **Profile Management**: Complete user profiles with photos and personality questionnaires
- **Smart Matching**: Content-based matching algorithm with daily selections
- **Real-time Chat**: Ephemeral messaging with 24-hour expiration
- **Push Notifications**: FCM integration with user preferences
- **Premium Subscriptions**: RevenueCat integration for subscription management
- **Admin Panel**: User management, moderation, and analytics
- **Comprehensive Logging**: Structured logging with request tracing
- **Error Handling**: Global exception filters with proper error responses

## 🚀 Quick Start

### Prerequisites

- Node.js 18+ and npm
- PostgreSQL 13+
- Redis 6+
- Firebase project (for FCM notifications)

### Setup

1. **Clone and install dependencies**:
   ```bash
   cd main-api
   ./setup-dev.sh
   ```

2. **Configure environment**:
   ```bash
   cp .env.example .env
   # Edit .env with your actual configuration
   ```

3. **Start databases** (using Docker):
   ```bash
   docker run -d --name goldwen-postgres \
     -e POSTGRES_DB=goldwen_db \
     -e POSTGRES_USER=goldwen \
     -e POSTGRES_PASSWORD=goldwen_password \
     -p 5432:5432 postgres:13

   docker run -d --name goldwen-redis \
     -p 6379:6379 redis:6-alpine
   ```

4. **Start the API**:
   ```bash
   npm run start:dev
   ```

5. **Access the API**:
   - API: http://localhost:3000/api/v1
   - Documentation: http://localhost:3000/api/v1/docs
   - Health check: http://localhost:3000/api/v1/health

## 📊 API Documentation

The API follows RESTful conventions with comprehensive Swagger documentation available at `/api/v1/docs` in development mode.

### Authentication

All endpoints (except auth and health) require Bearer token authentication:

```bash
Authorization: Bearer <jwt_token>
```

### Example Requests

**Register a new user**:
```bash
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "securepassword",
    "firstName": "John",
    "lastName": "Doe"
  }'
```

**Get daily selection**:
```bash
curl -X GET http://localhost:3000/api/v1/matching/daily-selection \
  -H "Authorization: Bearer <token>"
```

**Send a message**:
```bash
curl -X POST http://localhost:3000/api/v1/chat/conversations/:chatId/messages \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "text",
    "content": "Hello! Nice to meet you 😊"
  }'
```

### Response Format

All API responses follow a consistent format:

**Success Response**:
```json
{
  "success": true,
  "message": "Operation completed successfully",
  "data": {
    // Response data
  }
}
```

**Error Response**:
```json
{
  "success": false,
  "message": "Error message",
  "code": "ERROR_CODE",
  "errors": ["Validation error details"],
  "timestamp": "2024-01-XX...",
  "path": "/api/v1/endpoint"
}
```

## 🏗️ Architecture

### Tech Stack

- **Framework**: NestJS (Node.js/TypeScript)
- **Database**: PostgreSQL with TypeORM
- **Cache/Queues**: Redis with Bull
- **Authentication**: JWT with Passport.js
- **Validation**: class-validator and class-transformer
- **Documentation**: Swagger/OpenAPI
- **Logging**: Winston with structured logging
- **Testing**: Jest

### Project Structure

```
src/
├── common/           # Shared utilities, DTOs, filters, interceptors
├── config/           # Configuration files
├── database/         # Database entities and migrations
├── modules/          # Feature modules
│   ├── auth/         # Authentication & authorization
│   ├── users/        # User management
│   ├── profiles/     # Profile and photo management
│   ├── matching/     # Matching algorithm and daily selections
│   ├── chat/         # Real-time messaging
│   ├── notifications/ # Push notifications
│   ├── subscriptions/ # Premium subscriptions
│   └── admin/        # Administrative functions
├── app.module.ts     # Main application module
└── main.ts           # Application entry point
```

## 🔧 Development

### Available Scripts

- `npm run start:dev` - Start in development mode with hot reload
- `npm run build` - Build for production
- `npm run start:prod` - Start in production mode
- `npm run test` - Run tests
- `npm run test:watch` - Run tests in watch mode
- `npm run lint` - Run ESLint
- `npm run format` - Format code with Prettier

### Environment Variables

Key environment variables (see `.env.example` for full list):

```bash
NODE_ENV=development          # Environment (development/production)
PORT=3000                    # API port
LOG_LEVEL=info              # Logging level (debug/info/warn/error)
DATABASE_HOST=localhost     # PostgreSQL host
REDIS_HOST=localhost        # Redis host
JWT_SECRET=your-secret      # JWT signing secret
FCM_SERVER_KEY=your-key     # Firebase Cloud Messaging key
```

### Database

The application uses TypeORM with PostgreSQL. Database schema is managed through entity definitions with automatic synchronization in development.

**Key Entities**:
- User: Core user account and authentication
- Profile: User profile information and photos
- Match: Matching relationships between users
- Chat/Message: Messaging system
- Notification: Push notification history
- Subscription: Premium subscription management

### Logging

The application uses structured logging with Winston:

- **Development**: Colorized console output with readable format
- **Production**: JSON structured logs suitable for log aggregation
- **Request Logging**: All HTTP requests/responses are logged
- **Error Tracking**: Comprehensive error logging with stack traces

Log levels can be controlled via the `LOG_LEVEL` environment variable.

## 📊 Monitoring & Health Checks

### Health Check

The `/health` endpoint provides application health status:

```bash
GET /api/v1/health
```

Response includes:
- Application status and uptime
- Database connectivity
- Redis connectivity
- Environment information

### Logging

All operations are logged with structured data including:
- Request/response logging
- User action tracking
- Business event logging
- Security event monitoring
- Performance metrics

## 🔒 Security

### Authentication & Authorization

- JWT-based authentication with configurable expiration
- Role-based access control (User, Admin, Moderator)
- OAuth integration with Google and Apple
- Password hashing with bcrypt

### Data Protection

- Input validation on all endpoints
- SQL injection prevention via TypeORM
- XSS protection through sanitization
- CORS configuration
- Rate limiting (configurable)

### Privacy

- GDPR compliance features
- Data minimization principles
- User data export capabilities
- Account deletion with data purging

## 🚀 Deployment

### Production Setup

1. **Environment Configuration**:
   ```bash
   NODE_ENV=production
   LOG_LEVEL=warn
   DATABASE_SSL=true
   # Configure all production values
   ```

2. **Build and Deploy**:
   ```bash
   npm run build
   npm run start:prod
   ```

3. **Database Migrations**:
   ```bash
   npm run migration:run
   ```

### Docker Support

A Dockerfile is provided for containerized deployment:

```bash
docker build -t goldwen-api .
docker run -p 3000:3000 goldwen-api
```

### Health Monitoring

Monitor the application using:
- Health check endpoint: `/api/v1/health`
- Structured logs for error tracking
- Performance metrics in log output

## 🤝 Contributing

1. Follow the existing code style and patterns
2. Add tests for new features
3. Update documentation for API changes
4. Use conventional commit messages
5. Ensure all tests pass before submitting

## 📄 License

This project is proprietary and confidential. All rights reserved.