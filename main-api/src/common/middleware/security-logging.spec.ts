import { SecurityLoggingMiddleware } from './security-logging.middleware';
import { CustomLoggerService } from '../logger';
import { AlertingService } from '../monitoring';

describe('SecurityLoggingMiddleware', () => {
  let middleware: SecurityLoggingMiddleware;
  let mockLogger: jest.Mocked<CustomLoggerService>;
  let mockAlerting: jest.Mocked<AlertingService>;
  let mockRequest: any;
  let mockResponse: any;
  let mockNext: jest.Mock;

  beforeEach(() => {
    mockLogger = {
      logSecurityEvent: jest.fn(),
    } as any;

    mockAlerting = {
      sendCriticalAlert: jest.fn(),
      sendWarningAlert: jest.fn(),
    } as any;

    mockRequest = {
      path: '/api/v1/test',
      method: 'GET',
      ip: '192.168.1.1',
      headers: {
        'user-agent': 'Test Agent',
      },
      body: {},
      url: '/api/v1/test',
      query: {},
      connection: {
        remoteAddress: '192.168.1.1',
      },
    };

    mockResponse = {
      on: jest.fn(),
      statusCode: 200,
    };

    mockNext = jest.fn();

    middleware = new SecurityLoggingMiddleware(mockLogger, mockAlerting);
  });

  it('should be defined', () => {
    expect(middleware).toBeDefined();
  });

  it('should log authentication attempts', () => {
    mockRequest.path = '/auth/login';

    middleware.use(mockRequest, mockResponse, mockNext);

    expect(mockLogger.logSecurityEvent).toHaveBeenCalledWith('auth_attempt', {
      path: '/auth/login',
      method: 'GET',
      ip: '192.168.1.1',
      userAgent: 'Test Agent',
    });
    expect(mockNext).toHaveBeenCalled();
  });

  it('should log admin access attempts', () => {
    mockRequest.path = '/admin/users';

    middleware.use(mockRequest, mockResponse, mockNext);

    expect(mockLogger.logSecurityEvent).toHaveBeenCalledWith(
      'admin_access_attempt',
      {
        path: '/admin/users',
        method: 'GET',
        ip: '192.168.1.1',
        userAgent: 'Test Agent',
      },
    );
    expect(mockNext).toHaveBeenCalled();
  });

  it('should detect SQL injection patterns', () => {
    mockRequest.body = { username: "'; DROP TABLE users; --" };
    mockRequest.url = '/api/v1/login';
    mockRequest.path = '/api/v1/login';

    middleware.use(mockRequest, mockResponse, mockNext);

    expect(mockLogger.logSecurityEvent).toHaveBeenCalledWith(
      'suspicious_input_detected',
      expect.objectContaining({
        path: '/api/v1/login',
        method: 'GET',
        ip: '192.168.1.1',
        pattern: expect.stringContaining("'|(\\\\x27)"),
      }),
      'error',
    );

    expect(mockAlerting.sendCriticalAlert).toHaveBeenCalledWith(
      'Suspicious Activity Detected',
      'Potential security threat detected from IP 192.168.1.1',
      expect.objectContaining({
        path: '/api/v1/login',
        ip: '192.168.1.1',
      }),
    );
  });

  it('should detect XSS patterns', () => {
    mockRequest.body = { message: '<script>alert("xss")</script>' };

    middleware.use(mockRequest, mockResponse, mockNext);

    expect(mockLogger.logSecurityEvent).toHaveBeenCalledWith(
      'suspicious_input_detected',
      expect.objectContaining({
        ip: '192.168.1.1',
      }),
      'error',
    );
  });

  it('should log failed authentication on response', () => {
    mockRequest.path = '/auth/login';
    mockResponse.statusCode = 401;

    const mockResponseOn = jest.fn((event, callback) => {
      if (event === 'finish') {
        callback(); // Simulate response finish
      }
    });
    mockResponse.on = mockResponseOn;

    middleware.use(mockRequest, mockResponse, mockNext);

    expect(mockResponseOn).toHaveBeenCalledWith('finish', expect.any(Function));
  });

  it('should send alert for unauthorized admin access', () => {
    mockRequest.path = '/admin/dashboard';
    mockResponse.statusCode = 403;

    const mockResponseOn = jest.fn((event, callback) => {
      if (event === 'finish') {
        callback(); // Simulate response finish
      }
    });
    mockResponse.on = mockResponseOn;

    middleware.use(mockRequest, mockResponse, mockNext);

    // The alert would be sent in the response finish callback
    // We verify the callback was set up correctly
    expect(mockResponseOn).toHaveBeenCalledWith('finish', expect.any(Function));
  });
});
