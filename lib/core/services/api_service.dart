import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../config/app_config.dart';
import '../models/models.dart';

class ApiService {
  static String get baseUrl => AppConfig.isDevelopment
      ? AppConfig.devMainApiBaseUrl
      : AppConfig.mainApiBaseUrl;
  static String? _token;

  // Dio is initialized lazily so that `baseUrl` (a getter itself) is resolved
  // at the first call time, not at class loading time.
  static Dio? _dioInstance;

  static Dio get _dio {
    if (_dioInstance == null) {
      _dioInstance = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: AppConfig.defaultTimeout,
        receiveTimeout: AppConfig.defaultTimeout,
        headers: {
          'Content-Type': 'application/json',
        },
      ));
      _dioInstance!.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            clearToken();
          }
          return handler.next(e);
        },
      ));
    }
    return _dioInstance!;
  }

  static void setToken(String token) {
    _token = token;
  }

  static String? get token => _token;

  static void clearToken() {
    _token = null;
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // Helper method to handle HTTP requests with timeout and error handling
    static Future<Response> _makeRequest(
    Future<Response> request, [
    Duration? timeout,
  ]) async {
    try {
      return await request;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        throw ApiException(
          statusCode: 0,
          message: 'Request timeout - Please check your internet connection and try again',
          code: 'TIMEOUT_ERROR',
        );
      }
      if (e.response != null) {
        return e.response!; // Let _handleResponse manage the error parsing from response body
      }
      throw ApiException(
        statusCode: 0,
        message: 'Network error - Unable to connect to server',
        code: 'NETWORK_ERROR',
      );
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Network error - Unable to connect to server',
        code: 'NETWORK_ERROR',
      );
    }
  }


  // Health check endpoints
  static Future<Map<String, dynamic>> healthCheck() async {
    final response = await _makeRequest(
      _dio.get('/health'),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getWelcome() async {
    final response = await _dio.get(
      '${baseUrl.replaceAll('/api/v1', '')}/',
    );

    return _handleResponse(response);
  }

  // Authentication endpoints
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final response = await _dio.post('/auth/register', data: jsonEncode({
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _makeRequest(
      _dio.post('/auth/login', data: jsonEncode({
          'email': email,
          'password': password,
        }),
      ),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> socialLogin({
    required String socialId,
    required String provider,
    required String email,
    required String firstName,
    String? lastName,
  }) async {
    final response = await _makeRequest(
      _dio.post('/auth/social-login', data: jsonEncode({
          'socialId': socialId,
          'provider': provider,
          'email': email,
          'firstName': firstName,
          'lastName': lastName,
        }),
      ),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> logout() async {
    final response = await _dio.post('/auth/logout');

    return _handleResponse(response);
  }

  // Profile endpoints
  static Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> profileData) async {
    final response = await _dio.put('/profiles/me', data: jsonEncode(profileData),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> submitPersonalityAnswers(
      List<Map<String, dynamic>> answers) async {
    
    if (AppConfig.isDevelopment) {
      print('Submitting personality answers: $answers');
      print('Request body: ${jsonEncode({'answers': answers})}');
    }
    
    final response = await _dio.post('/profiles/me/personality-answers', data: jsonEncode({
        'answers': answers
      }), // Wrap answers in object as expected by DTO
    );

    return _handleResponse(response);
  }

  static Future<List<dynamic>> getPersonalityQuestions() async {
    final response = await _makeRequest(
      _dio.get('/profiles/personality-questions'),
    );
    
    final result = _handleResponse(response);
    
    // Handle both direct array and wrapped response formats
    if (result is List) {
      return result;
    } else if (result is Map<String, dynamic>) {
      // If response is wrapped (e.g., {"success": true, "data": [...]})
      if (result.containsKey('data') && result['data'] is List) {
        return result['data'] as List<dynamic>;
      } else if (result.containsKey('questions') && result['questions'] is List) {
        return result['questions'] as List<dynamic>;
      }
    }
    
    // If we can't find a list, throw an error with debug info
    throw ApiException(
      statusCode: 200,
      message: 'Invalid response format for personality questions. Expected List but got: ${result.runtimeType}',
      code: 'INVALID_RESPONSE_FORMAT',
    );
  }

  static Future<List<dynamic>> getPrompts() async {
    final response = await _makeRequest(
      _dio.get('/profiles/prompts'),
    );
    
    final result = _handleResponse(response);
    
    // Debug: Print the response structure
    print('getPrompts response structure: ${result.runtimeType}');
    print('getPrompts response data: $result');
    
    // Handle the wrapped response format from ResponseInterceptor
    if (result is Map<String, dynamic>) {
      // Standard wrapped response: {"success": true, "data": [...], "metadata": {...}}
      if (result.containsKey('data')) {
        final data = result['data'];
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        } else {
          print('Error: data field is not a List, got: ${data.runtimeType}');
        }
      }
      // Legacy format (direct prompts field)
      else if (result.containsKey('prompts') && result['prompts'] is List) {
        return (result['prompts'] as List).cast<Map<String, dynamic>>();
      }
      // If it's a Map but no data/prompts field, maybe it's the direct object
      else {
        print('Error: No data or prompts field found in response');
      }
    } 
    // Handle direct array response (shouldn't happen with ResponseInterceptor)
    else if (result is List) {
      return result.cast<Map<String, dynamic>>();
    }
    
    // If we can't find a list, throw an error with debug info
    throw ApiException(
      statusCode: 200,
      message: 'Invalid response format for prompts. Expected wrapped response with data field containing List, but got: ${result.runtimeType}\nResponse: $result',
      code: 'INVALID_RESPONSE_FORMAT',
    );
  }

  static Future<Map<String, dynamic>> submitPromptAnswers(
      List<Map<String, dynamic>> answers) async {
    final response = await _dio.post('/profiles/me/prompt-answers', data: jsonEncode(
          {'answers': answers}), // Wrap in answers object as expected by DTO
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateProfileStatus({
    bool? isVisible,
  }) async {
    final response = await _dio.put('/profiles/me/status', data: jsonEncode({
        if (isVisible != null) 'isVisible': isVisible,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getProfileCompletion() async {
    final response = await _makeRequest(
      _dio.get('/profiles/completion'),
    );

    return _handleResponse(response);
  }

  // Authentication extensions
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await _dio.post('/auth/forgot-password', data: jsonEncode({'email': email}),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> resetPassword(
      String token, String newPassword) async {
    final response = await _dio.post('/auth/reset-password', data: jsonEncode({
        'token': token,
        'newPassword': newPassword,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> changePassword(
      String currentPassword, String newPassword) async {
    final response = await _dio.post('/auth/change-password', data: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> verifyEmail(String token) async {
    final response = await _dio.post('/auth/verify-email', data: jsonEncode({'token': token}),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _dio.get('/auth/me');

    return _handleResponse(response);
  }

  // User endpoints
  static Future<Map<String, dynamic>> getUserProfile() async {
    final response = await _dio.get('/users/me');

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateUser(
      Map<String, dynamic> userData) async {
    final response = await _dio.put('/users/me', data: jsonEncode(userData),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateUserSettings(
      Map<String, dynamic> settings) async {
    final response = await _dio.put('/users/me/settings', data: jsonEncode(settings),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getUserStats() async {
    final response = await _dio.get('/users/me/stats');

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> deactivateAccount() async {
    final response = await _dio.put('/users/me/deactivate');

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> deleteAccount() async {
    final response = await _dio.delete('/users/me');

    return _handleResponse(response);
  }

  // Enhanced Profile endpoints
  static Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get('/profiles/me');

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getProfileById(String userId) async {
    final response = await _dio.get('/profiles/$userId');

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> uploadPhoto(String filePath,
      {int? order}) async {
    String extension = filePath.split('.').last.toLowerCase();
    String subtype = extension == 'png' ? 'png' : extension == 'webp' ? 'webp' : 'jpeg';
    
    final file = File(filePath);
    final filename = file.uri.pathSegments.last;
    
    final formData = FormData.fromMap({
      'photos': await MultipartFile.fromFile(
        filePath,
        filename: filename,
        contentType: MediaType('image', subtype),
      ),
      if (order != null) 'order': order.toString(),
    });
    
    final response = await _dio.post('/profiles/me/photos', data: formData);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> uploadPhotos(List<String> filePaths) async {
    final formData = FormData();
    
    for (int i = 0; i < filePaths.length; i++) {
      String filePath = filePaths[i];
      String extension = filePath.split('.').last.toLowerCase();
      
      String subtype = extension == 'png' ? 'png' : extension == 'webp' ? 'webp' : 'jpeg';
      final file = File(filePath);
      final filename = file.uri.pathSegments.last;
      
      formData.files.add(MapEntry(
        'photos',
        await MultipartFile.fromFile(
          filePath,
          filename: filename,
          contentType: MediaType('image', subtype),
        ),
      ));
    }

    final response = await _dio.post('/profiles/me/photos', data: formData);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updatePhotoOrder(
      String photoId, int newOrder) async {
    final response = await _dio.put('/profiles/me/photos/$photoId/order', data: jsonEncode({'newOrder': newOrder}),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> deletePhoto(String photoId) async {
    final response = await _dio.delete('/profiles/me/photos/$photoId');

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> setPrimaryPhoto(String photoId) async {
    final response = await _dio.put('/profiles/me/photos/$photoId/primary');

    return _handleResponse(response);
  }

  // Media file endpoints (audio/video)
  static Future<Map<String, dynamic>> uploadMediaFile(
    String filePath, {
    required String type,
    int? order,
  }) async {
    String extension = filePath.split('.').last.toLowerCase();

    String mainType = type == 'audio' ? 'audio' : 'video';
    String subtype;
    if (type == 'audio') {
      subtype = extension == 'mp3' ? 'mpeg' : extension == 'm4a' ? 'mp4' : extension;
    } else {
      subtype = extension == 'mov' ? 'quicktime' : extension == 'mkv' ? 'x-matroska' : extension;
    }

    final file = File(filePath);
    final filename = file.uri.pathSegments.last;

    final formData = FormData.fromMap({
      'mediaFile': await MultipartFile.fromFile(
        filePath,
        filename: filename,
        contentType: MediaType(mainType, subtype),
      ),
      'type': type,
      if (order != null) 'order': order.toString(),
    });

    final response = await _dio.post('/profiles/me/media', data: formData);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> deleteMediaFile(String mediaId) async {
    final response = await _dio.delete('/profiles/me/media/$mediaId');

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateMediaFileOrder(
    String mediaId,
    int newOrder,
  ) async {
    final response = await _dio.put('/profiles/me/media/$mediaId/order', data: jsonEncode({'newOrder': newOrder}),
    );

    return _handleResponse(response);
  }

  // Matching endpoints
  static Future<Map<String, dynamic>> getDailySelection() async {
    final response = await _makeRequest(
      _dio.get('/matching/daily-selection'),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> chooseProfile(
    String profileId, {
    String choice = 'like',
  }) async {
    final response = await _dio.post('/matching/choose/$profileId', data: jsonEncode({
        'choice': choice,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getMatches(
      {int? page, int? limit, String? status}) async {
    final queryParams = <String, String>{};
    if (page != null) queryParams['page'] = page.toString();
    if (limit != null) queryParams['limit'] = limit.toString();
    if (status != null) queryParams['status'] = status;

    final uri = Uri.parse('/matching/matches').replace(queryParameters: queryParams).toString();
    final response = await _dio.get(uri);

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getMatchDetails(String matchId) async {
    final response = await _dio.get('/matching/matches/$matchId');

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> deleteMatch(String matchId) async {
    final response = await _dio.delete('/matching/matches/$matchId');

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getCompatibility(String profileId) async {
    final response = await _dio.get('/matching/compatibility/$profileId');

    return _handleResponse(response);
  }

  // Premium feature: Who liked me
  static Future<Map<String, dynamic>> getWhoLikedMe() async {
    final response = await _makeRequest(
      _dio.get('/matching/who-liked-me'),
    );

    return _handleResponse(response);
  }

  // Chat endpoints
  static Future<Map<String, dynamic>> getConversations() async {
    final response = await _makeRequest(
      _dio.get('/chat'),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getConversationDetails(
      String chatId) async {
    final response = await _makeRequest(
      _dio.get('/chat/$chatId'),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getChatByMatchId(String matchId) async {
    final response = await _makeRequest(
      _dio.get('/chat/match/$matchId'),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getMessages(String chatId,
      {int? page, int? limit, String? before}) async {
    final queryParams = <String, String>{};
    if (page != null) queryParams['page'] = page.toString();
    if (limit != null) queryParams['limit'] = limit.toString();
    if (before != null) queryParams['before'] = before;

    final uri = Uri.parse('/chat/$chatId/messages').replace(queryParameters: queryParams).toString();
    final response = await _makeRequest(
      _dio.get(uri),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> sendMessage(String chatId,
      {required String type, required String content}) async {
    final response = await _makeRequest(
      _dio.post('/chat/$chatId/messages', data: jsonEncode({
          'type': type,
          'content': content,
        }),
      ),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> acceptMatch(String matchId,
      {required bool accept}) async {
    final response = await _makeRequest(
      _dio.post('/chat/accept/$matchId', data: jsonEncode({
          'accept': accept,
        }),
      ),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> markMessagesAsRead(String chatId) async {
    final response = await _makeRequest(
      _dio.put('/chat/$chatId/messages/read'),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> deleteMessage(String messageId) async {
    final response = await _makeRequest(
      _dio.delete('/chat/messages/$messageId'),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> expireChat(String chatId) async {
    final response = await _makeRequest(
      _dio.put('/chat/$chatId/expire'),
    );

    return _handleResponse(response);
  }



  // Subscription endpoints
  static Future<Map<String, dynamic>> getSubscriptionPlans() async {
    final response = await _dio.get('/subscriptions/plans');

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getCurrentSubscription() async {
    final response = await _dio.get('/subscriptions/me');

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> purchaseSubscription({
    required String plan,
    required String platform,
    required String receiptData,
  }) async {
    final response = await _dio.post('/subscriptions/purchase', data: jsonEncode({
        'plan': plan,
        'platform': platform,
        'receiptData': receiptData,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> verifyReceipt({
    required String receiptData,
    required String platform,
  }) async {
    final response = await _dio.post('/subscriptions/verify-receipt', data: jsonEncode({
        'receiptData': receiptData,
        'platform': platform,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> cancelSubscription() async {
    final response = await _dio.put('/subscriptions/cancel');

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> restoreSubscription() async {
    final response = await _dio.post('/subscriptions/restore');

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getSubscriptionUsage() async {
    final response = await _dio.get('/subscriptions/usage');

    return _handleResponse(response);
  }

  // Notification endpoints
  static Future<Map<String, dynamic>> getNotifications({
    int? page,
    int? limit,
    String? type,
    bool? read,
  }) async {
    final queryParams = <String, String>{};
    if (page != null) queryParams['page'] = page.toString();
    if (limit != null) queryParams['limit'] = limit.toString();
    if (type != null) queryParams['type'] = type;
    if (read != null) queryParams['read'] = read.toString();

    final uri = Uri.parse('/notifications').replace(queryParameters: queryParams).toString();
    final response = await _dio.get(uri);

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> markNotificationAsRead(
      String notificationId) async {
    final response = await _dio.put('/notifications/$notificationId/read');

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> markAllNotificationsAsRead() async {
    final response = await _dio.put('/notifications/read-all');

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> deleteNotification(
      String notificationId) async {
    final response = await _dio.delete('/notifications/$notificationId');

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getNotificationSettings() async {
    final response = await _dio.get('/notifications/settings');

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateNotificationSettings(
      Map<String, dynamic> settings) async {
    final response = await _dio.put('/notifications/settings', data: jsonEncode(settings),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> sendTestNotification({
    required String title,
    required String body,
    required String type,
  }) async {
    final response = await _dio.post('/notifications/test', data: jsonEncode({
        'title': title,
        'body': body,
        'type': type,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> triggerDailySelectionNotifications({
    List<String>? targetUsers,
    String? customMessage,
  }) async {
    final response = await _dio.post('/notifications/trigger-daily-selection', data: jsonEncode({
        if (targetUsers != null) 'targetUsers': targetUsers,
        if (customMessage != null) 'customMessage': customMessage,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> sendGroupNotification({
    required List<String> userIds,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final response = await _dio.post('/notifications/send-group', data: jsonEncode({
        'userIds': userIds,
        'type': type,
        'title': title,
        'body': body,
        if (data != null) 'data': data,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> registerPushToken({
    required String token,
    required String platform,
    String? appVersion,
    String? deviceId,
  }) async {
    final response = await _dio.post('/users/me/push-tokens', data: jsonEncode({
        'token': token,
        'platform': platform,
        if (appVersion != null) 'appVersion': appVersion,
        if (deviceId != null) 'deviceId': deviceId,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> removePushToken({
    required String token,
  }) async {
    final response = await _dio.delete('/users/me/push-tokens', data: jsonEncode({
        'token': token,
      }),
    );

    return _handleResponse(response);
  }

  // Legacy method for backward compatibility
  @Deprecated('Use registerPushToken instead')
  static Future<Map<String, dynamic>> registerDeviceToken(
      Map<String, String> deviceInfo) async {
    return registerPushToken(
      token: deviceInfo['deviceToken'] ?? deviceInfo['token']!,
      platform: deviceInfo['platform']!,
      appVersion: deviceInfo['appVersion'],
      deviceId: deviceInfo['deviceId'],
    );
  }

  // Admin endpoints
  static Future<Map<String, dynamic>> adminLogin({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/admin/auth/login', data: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getAdminUsers({
    int? page,
    int? limit,
    String? status,
    String? search,
  }) async {
    final queryParams = <String, String>{};
    if (page != null) queryParams['page'] = page.toString();
    if (limit != null) queryParams['limit'] = limit.toString();
    if (status != null) queryParams['status'] = status;
    if (search != null) queryParams['search'] = search;

    final uri =
        Uri.parse('/admin/users').replace(queryParameters: queryParams).toString();
    final response = await _dio.get(uri);

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getAdminUserDetails(String userId) async {
    final response = await _dio.get('/admin/users/$userId');

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateUserStatus(
      String userId, String status) async {
    final response = await _dio.put('/admin/users/$userId/status', data: jsonEncode({'status': status}),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getAdminReports({
    int? page,
    int? limit,
    String? status,
    String? type,
  }) async {
    final queryParams = <String, String>{};
    if (page != null) queryParams['page'] = page.toString();
    if (limit != null) queryParams['limit'] = limit.toString();
    if (status != null) queryParams['status'] = status;
    if (type != null) queryParams['type'] = type;

    final uri = Uri.parse('/admin/reports').replace(queryParameters: queryParams).toString();
    final response = await _dio.get(uri);

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateReportStatus(
      String reportId, String status, String resolution) async {
    final response = await _dio.put('/admin/reports/$reportId', data: jsonEncode({
        'status': status,
        'resolution': resolution,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getAdminAnalytics() async {
    final response = await _dio.get('/admin/analytics');

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> broadcastNotification({
    required String title,
    required String body,
    required String type,
  }) async {
    final response = await _dio.post('/admin/notifications/broadcast', data: jsonEncode({
        'title': title,
        'body': body,
        'type': type,
      }),
    );

    return _handleResponse(response);
  }

  // GDPR Compliance endpoints
  static Future<Map<String, dynamic>> submitGdprConsent({
    required bool dataProcessing,
    bool? marketing,
    bool? analytics,
  }) async {
    final response = await _dio.post('/users/consent', data: jsonEncode({
        'dataProcessing': dataProcessing,
        if (marketing != null) 'marketing': marketing,
        if (analytics != null) 'analytics': analytics,
        'consentedAt': DateTime.now().toIso8601String(),
      }),
    );

    return _handleResponse(response);
  }

  // Feedback endpoints
  static Future<Map<String, dynamic>> submitFeedback({
    required String type,
    required String subject,
    required String message,
    int? rating,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await _makeRequest(
      _dio.post('/feedback', data: jsonEncode({
          'type': type,
          'subject': subject,
          'message': message,
          if (rating != null) 'rating': rating,
          if (metadata != null) 'metadata': metadata,
        }),
      ),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getPrivacyPolicy({
    String? version,
    String format = 'json',
  }) async {
    final queryParams = <String, String>{};
    if (version != null) queryParams['version'] = version;
    queryParams['format'] = format;

    final uri = Uri.parse('/legal/privacy-policy').replace(queryParameters: queryParams).toString();
    final response = await _dio.get(uri);

    return _handleResponse(response);
  }

  static Future<dynamic> exportUserData({String format = 'json'}) async {
    final queryParams = <String, String>{'format': format};
    
    final uri = Uri.parse('/users/me/export-data').replace(queryParameters: queryParams).toString();
    final response = await _dio.get(uri);

    // For file downloads, we might need to handle differently
    if (format == 'pdf') {
      if ((response.statusCode ?? 500) >= 200 && (response.statusCode ?? 500) < 300) {
        return (response.data as List<int>); // Return raw bytes for PDF
      } else {
        throw ApiException(
          statusCode: response.statusCode ?? 500,
          message: 'Failed to export data as PDF',
          code: 'EXPORT_ERROR',
        );
      }
    }

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updatePrivacySettings({
    required bool analytics,
    required bool marketing,
    required bool functionalCookies,
    int? dataRetention,
  }) async {
    final response = await _dio.put('/users/me/privacy-settings', data: jsonEncode({
        'analytics': analytics,
        'marketing': marketing,
        'functionalCookies': functionalCookies,
        if (dataRetention != null) 'dataRetention': dataRetention,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getPrivacySettings() async {
    final response = await _dio.get('/users/me/privacy-settings');

    return _handleResponse(response);
  }

  // Request data export
  static Future<Map<String, dynamic>> requestDataExport() async {
    final response = await _dio.post('/users/me/data-export');

    return _handleResponse(response);
  }

  // Get data export status
  static Future<Map<String, dynamic>> getDataExportStatus(String requestId) async {
    final response = await _dio.get('/users/me/data-export/$requestId');

    return _handleResponse(response);
  }

  // Download data export
  static Future<dynamic> downloadDataExport(String requestId) async {
    final response = await _dio.get('/users/me/data-export/$requestId/download');

    if ((response.statusCode ?? 500) >= 200 && (response.statusCode ?? 500) < 300) {
      return (response.data as List<int>); // Return raw bytes for file download
    } else {
      throw ApiException(
        statusCode: response.statusCode ?? 500,
        message: 'Failed to download data export',
        code: 'DOWNLOAD_ERROR',
      );
    }
  }

  // Enhanced delete account with GDPR compliance and grace period
  static Future<Map<String, dynamic>> deleteAccountWithGdpr({
    required String password,
    String? reason,
    bool immediateDelete = false,
  }) async {
    final response = await _dio.delete('/users/me', data: jsonEncode({
        'password': password,
        if (reason != null) 'reason': reason,
        'immediateDelete': immediateDelete,
      }),
    );

    return _handleResponse(response);
  }

  // Cancel account deletion
  static Future<Map<String, dynamic>> cancelAccountDeletion() async {
    final response = await _dio.post('/users/me/cancel-deletion');

    return _handleResponse(response);
  }

  // Get account deletion status
  static Future<Map<String, dynamic>> getAccountDeletionStatus() async {
    final response = await _dio.get('/users/me/deletion-status');

    return _handleResponse(response);
  }

    static dynamic _handleResponse(Response response) {
    var rawData = response.data;
    if (rawData is String && rawData.isNotEmpty) {
      try {
        rawData = jsonDecode(rawData);
      } catch (_) {}
    }
    
    if ((response.statusCode ?? 500) >= 200 && (response.statusCode ?? 500) < 300) {
      return rawData;
    } else {
      String message = 'API Error';
      String code = 'ERROR';
      dynamic errors;
      RateLimitInfo? rateLimitInfo;
      
      if (rawData is Map) {
         message = rawData['message'] ?? message;
         code = rawData['code'] ?? code;
         errors = rawData['errors'];
         
         if (response.statusCode == 429 && rawData['retryAfter'] != null) {
           rateLimitInfo = RateLimitInfo(retryAfterSeconds: rawData['retryAfter'] as int?);
         }
      }
      
      if (rateLimitInfo == null) {
         final headerMap = <String, String>{};
         response.headers.forEach((key, value) {
            headerMap[key.toLowerCase()] = value.join(',');
         });
         final rli = RateLimitInfo.fromHeaders(headerMap);
         if (rli.hasData) rateLimitInfo = rli;
      }
      
      throw ApiException(
        statusCode: response.statusCode ?? 500,
        message: message,
        code: code,
        errors: errors,
        rateLimitInfo: rateLimitInfo
      );
    }
  }


  static String _getDefaultErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad Request - Invalid input data';
      case 401:
        return 'Unauthorized - Please log in again';
      case 403:
        return 'Forbidden - Insufficient permissions';
      case 404:
        return 'Not Found - Resource does not exist';
      case 409:
        return 'Conflict - Resource already exists';
      case 422:
        return 'Unprocessable Entity - Validation failed';
      case 429:
        return 'Too Many Requests - Please try again later';
      case 500:
        return 'Internal Server Error - Please try again later';
      case 502:
        return 'Bad Gateway - Service temporarily unavailable';
      case 503:
        return 'Service Unavailable - Please try again later';
      default:
        return 'Unknown error occurred';
    }
  }

  // Wrapper methods for MatchingServiceApi
  static Future<Map<String, dynamic>> calculateCompatibilityV2({
    required String userId,
    required List<String> candidateIds,
    required Map<String, dynamic> personalityAnswers,
    required Map<String, dynamic> preferences,
    Map<String, dynamic>? userLocation,
    bool includeAdvancedScoring = true,
  }) {
    return MatchingServiceApi.calculateCompatibilityV2(
      userId: userId,
      candidateIds: candidateIds,
      personalityAnswers: personalityAnswers,
      preferences: preferences,
      userLocation: userLocation,
      includeAdvancedScoring: includeAdvancedScoring,
    );
  }

  static Future<Map<String, dynamic>> getHistory({
    int page = 1,
    int limit = 20,
    String? startDate,
    String? endDate,
  }) {
    return MatchingServiceApi.getHistory(
      page: page,
      limit: limit,
      startDate: startDate,
      endDate: endDate,
    );
  }

  // Email notification endpoints
  static Future<Map<String, dynamic>> getEmailHistory({
    int? page,
    int? limit,
    String? type,
    String? status,
  }) async {
    final queryParams = <String, String>{};
    if (page != null) queryParams['page'] = page.toString();
    if (limit != null) queryParams['limit'] = limit.toString();
    if (type != null) queryParams['type'] = type;
    if (status != null) queryParams['status'] = status;

    final uri = Uri.parse('/users/me/email-history').replace(queryParameters: queryParams).toString();
    final response = await _makeRequest(
      _dio.get(uri),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getEmailDetails(String emailId) async {
    final response = await _makeRequest(
      _dio.get('/users/me/email-history/$emailId'),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> retryEmail(String emailId) async {
    final response = await _makeRequest(
      _dio.post('/users/me/email-history/$emailId/retry'),
    );

    return _handleResponse(response);
  }
}

// External Matching Service API
class MatchingServiceApi {
  static String get baseUrl => AppConfig.isDevelopment
      ? AppConfig.devMatchingServiceBaseUrl
      : AppConfig.matchingServiceBaseUrl;
  static String get apiKey => AppConfig.matchingServiceApiKey;

  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: AppConfig.defaultTimeout,
    receiveTimeout: AppConfig.defaultTimeout,
    headers: {
      'Content-Type': 'application/json',
      'X-API-Key': AppConfig.matchingServiceApiKey,
    },
  ));


  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-API-Key': apiKey,
      };

  // Helper method to handle HTTP requests with timeout and error handling
    static Future<Response> _makeRequest(
    Future<Response> request, [
    Duration? timeout,
  ]) async {
    try {
      return await request;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        throw ApiException(
          statusCode: 0,
          message: 'Request timeout - Please check your internet connection and try again',
          code: 'TIMEOUT_ERROR',
        );
      }
      if (e.response != null) {
        return e.response!; // Let _handleResponse manage the error parsing from response body
      }
      throw ApiException(
        statusCode: 0,
        message: 'Network error - Unable to connect to server',
        code: 'NETWORK_ERROR',
      );
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Network error - Unable to connect to server',
        code: 'NETWORK_ERROR',
      );
    }
  }


    static dynamic _handleResponse(Response response) {
    var rawData = response.data;
    if (rawData is String && rawData.isNotEmpty) {
      try {
        rawData = jsonDecode(rawData);
      } catch (_) {}
    }
    
    if ((response.statusCode ?? 500) >= 200 && (response.statusCode ?? 500) < 300) {
      return rawData;
    } else {
      String message = 'API Error';
      String code = 'ERROR';
      dynamic errors;
      RateLimitInfo? rateLimitInfo;
      
      if (rawData is Map) {
         message = rawData['message'] ?? message;
         code = rawData['code'] ?? code;
         errors = rawData['errors'];
         
         if (response.statusCode == 429 && rawData['retryAfter'] != null) {
           rateLimitInfo = RateLimitInfo(retryAfterSeconds: rawData['retryAfter'] as int?);
         }
      }
      
      if (rateLimitInfo == null) {
         final headerMap = <String, String>{};
         response.headers.forEach((key, value) {
            headerMap[key.toLowerCase()] = value.join(',');
         });
         final rli = RateLimitInfo.fromHeaders(headerMap);
         if (rli.hasData) rateLimitInfo = rli;
      }
      
      throw ApiException(
        statusCode: response.statusCode ?? 500,
        message: message,
        code: code,
        errors: errors,
        rateLimitInfo: rateLimitInfo
      );
    }
  }


  static Future<Map<String, dynamic>> calculateCompatibility({
    required Map<String, dynamic> user1Profile,
    required Map<String, dynamic> user2Profile,
  }) async {
    final response = await _dio.post('/matching-service/calculate-compatibility', data: jsonEncode({
        'user1Profile': user1Profile,
        'user2Profile': user2Profile,
      }),
    );

    return _handleMatchingResponse(response);
  }

  static Future<Map<String, dynamic>> generateDailySelection({
    required String userId,
    required Map<String, dynamic> userProfile,
    required List<Map<String, dynamic>> availableProfiles,
    int selectionSize = 5,
  }) async {
    final response = await _dio.post('/matching-service/generate-daily-selection', data: jsonEncode({
        'userId': userId,
        'userProfile': userProfile,
        'availableProfiles': availableProfiles,
        'selectionSize': selectionSize,
      }),
    );

    return _handleMatchingResponse(response);
  }

  static Future<Map<String, dynamic>> batchCompatibility({
    required Map<String, dynamic> baseProfile,
    required List<Map<String, dynamic>> profilesToCompare,
  }) async {
    final response = await _dio.post('/matching-service/batch-compatibility', data: jsonEncode({
        'baseProfile': baseProfile,
        'profilesToCompare': profilesToCompare,
      }),
    );

    return _handleMatchingResponse(response);
  }

  static Future<Map<String, dynamic>> calculateCompatibilityV2({
    required String userId,
    required List<String> candidateIds,
    required Map<String, dynamic> personalityAnswers,
    required Map<String, dynamic> preferences,
    Map<String, dynamic>? userLocation,
    bool includeAdvancedScoring = true,
  }) async {
    final response = await _dio.post('/matching/calculate-compatibility-v2', data: jsonEncode({
        'userId': userId,
        'candidateIds': candidateIds,
        'personalityAnswers': personalityAnswers,
        'preferences': preferences,
        if (userLocation != null) 'userLocation': userLocation,
        'includeAdvancedScoring': includeAdvancedScoring,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getAlgorithmStats() async {
    final response = await _dio.get('/matching-service/algorithm/stats');

    return _handleMatchingResponse(response);
  }

  // Matches API methods

  static Future<Map<String, dynamic>> getMatchDetails(String matchId) async {
    final response = await _makeRequest(
      _dio.get('/matching/matches/$matchId'),
    );

    return _handleResponse(response);
  }

  // History API methods
  static Future<Map<String, dynamic>> getHistory({
    int page = 1,
    int limit = 20,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;

    final uri = Uri.parse('/matching/history').replace(queryParameters: queryParams).toString();

    final response = await _makeRequest(
      _dio.get(uri),
    );

    return _handleResponse(response);
  }

  // Reports API methods
  static Future<Map<String, dynamic>> submitReport({
    required String targetUserId,
    required ReportType type,
    required String reason,
    String? messageId,
    String? chatId,
    List<String>? evidence,
  }) async {
    final body = {
      'targetUserId': targetUserId,
      'type': _reportTypeToString(type),
      'reason': reason,
      if (messageId != null) 'messageId': messageId,
      if (chatId != null) 'chatId': chatId,
      if (evidence != null) 'evidence': evidence,
    };

    final response = await _makeRequest(
      _dio.post('/reports', data: jsonEncode(body),
      ),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getMyReports({
    int page = 1,
    int limit = 20,
    ReportStatus? status,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    
    if (status != null) queryParams['status'] = _reportStatusToString(status);

    final uri = Uri.parse('/reports/me').replace(queryParameters: queryParams).toString();

    final response = await _makeRequest(
      _dio.get(uri),
    );

    return _handleResponse(response);
  }

  // Helper methods for report enums
  static String _reportTypeToString(ReportType type) {
    switch (type) {
      case ReportType.inappropriateContent:
        return 'inappropriate_content';
      case ReportType.harassment:
        return 'harassment';
      case ReportType.fakeProfile:
        return 'fake_profile';
      case ReportType.spam:
        return 'spam';
      case ReportType.other:
        return 'other';
    }
  }

  static String _reportStatusToString(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return 'pending';
      case ReportStatus.reviewed:
        return 'reviewed';
      case ReportStatus.resolved:
        return 'resolved';
      case ReportStatus.dismissed:
        return 'dismissed';
    }
  }

  static Map<String, dynamic> _handleMatchingResponse(Response response) {
    dynamic rawData = response.data;
    if (rawData is String && rawData.isNotEmpty) {
      try { rawData = jsonDecode(rawData); } catch (_) {}
    }
    final Map<String, dynamic> data = rawData is Map ? Map<String, dynamic>.from(rawData) : {};

    if ((response.statusCode ?? 500) >= 200 && (response.statusCode ?? 500) < 300) {
      return data;
    } else {
      RateLimitInfo? rateLimitInfo;
      
      if (response.statusCode == 429 && data['retryAfter'] != null) {
        rateLimitInfo = RateLimitInfo(
          retryAfterSeconds: data['retryAfter'] as int?,
        );
      }
      
      if (rateLimitInfo == null) {
        final headerMap = <String, String>{};
        response.headers.forEach((key, value) {
          headerMap[key.toLowerCase()] = value.join(',');
        });
        final rateLimitFromHeaders = RateLimitInfo.fromHeaders(headerMap);
        if (rateLimitFromHeaders.hasData) {
          rateLimitInfo = rateLimitFromHeaders;
        }
      }
      
      throw ApiException(
        statusCode: response.statusCode ?? 500,
        message: data['message'] ?? 'Matching service error occurred',
        code: data['code'],
        errors: data['errors'],
        rateLimitInfo: rateLimitInfo,
      );
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? code;
  final dynamic errors; // Can be Map<String, dynamic> or List<dynamic>
  final RateLimitInfo? rateLimitInfo;

  ApiException({
    required this.statusCode,
    required this.message,
    this.code,
    this.errors,
    this.rateLimitInfo,
  });

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';

  /// Get formatted error messages as a list of strings
  List<String> get errorMessages {
    if (errors == null) return [];
    
    if (errors is List) {
      return (errors as List).map((e) => e.toString()).toList();
    } else if (errors is Map<String, dynamic>) {
      final result = <String>[];
      (errors as Map<String, dynamic>).forEach((key, value) {
        if (value is List) {
          result.addAll((value as List).map((e) => '$key: $e'));
        } else {
          result.add('$key: $value');
        }
      });
      return result;
    }
    
    return [errors.toString()];
  }

  /// Get a single formatted error message
  String get errorMessage {
    final messages = errorMessages;
    if (messages.isEmpty) return message;
    return messages.join(', ');
  }

  bool get isAuthError => statusCode == 401;
  bool get isValidationError => statusCode == 400 || statusCode == 422;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode >= 500;
  bool get isNetworkError => statusCode == 0;
  bool get isRateLimitError => statusCode == 429;
}

/// Contains rate limiting information from API response headers
class RateLimitInfo {
  final int? limit;
  final int? remaining;
  final DateTime? resetTime;
  final int? retryAfterSeconds;

  RateLimitInfo({
    this.limit,
    this.remaining,
    this.resetTime,
    this.retryAfterSeconds,
  });

  factory RateLimitInfo.fromHeaders(Map<String, String> headers) {
    // Parse X-RateLimit-Limit header
    final limit = headers['x-ratelimit-limit'] != null
        ? int.tryParse(headers['x-ratelimit-limit']!)
        : null;

    // Parse X-RateLimit-Remaining header
    final remaining = headers['x-ratelimit-remaining'] != null
        ? int.tryParse(headers['x-ratelimit-remaining']!)
        : null;

    // Parse X-RateLimit-Reset header (Unix timestamp in seconds)
    DateTime? resetTime;
    final resetHeader = headers['x-ratelimit-reset'];
    if (resetHeader != null) {
      final resetTimestamp = int.tryParse(resetHeader);
      if (resetTimestamp != null) {
        resetTime = DateTime.fromMillisecondsSinceEpoch(
          resetTimestamp * 1000,
        );
      }
    }

    // Parse Retry-After header (seconds)
    final retryAfterSeconds = headers['retry-after'] != null
        ? int.tryParse(headers['retry-after']!)
        : null;

    return RateLimitInfo(
      limit: limit,
      remaining: remaining,
      resetTime: resetTime,
      retryAfterSeconds: retryAfterSeconds,
    );
  }

  bool get hasData => limit != null || remaining != null || resetTime != null || retryAfterSeconds != null;

  bool get isNearLimit => remaining != null && limit != null && remaining! < (limit! * 0.2);

  String getRetryMessage() {
    if (retryAfterSeconds != null) {
      final minutes = retryAfterSeconds! ~/ 60;
      final seconds = retryAfterSeconds! % 60;
      if (minutes > 0) {
        return 'Réessayez dans $minutes minute${minutes > 1 ? 's' : ''} ${seconds > 0 ? 'et $seconds seconde${seconds > 1 ? 's' : ''}' : ''}';
      }
      return 'Réessayez dans $seconds seconde${seconds > 1 ? 's' : ''}';
    }
    
    if (resetTime != null) {
      final now = DateTime.now();
      final diff = resetTime!.difference(now);
      if (diff.isNegative) {
        return 'Vous pouvez réessayer maintenant';
      }
      final minutes = diff.inMinutes;
      final seconds = diff.inSeconds % 60;
      if (minutes > 0) {
        return 'Réessayez dans $minutes minute${minutes > 1 ? 's' : ''} ${seconds > 0 ? 'et $seconds seconde${seconds > 1 ? 's' : ''}' : ''}';
      }
      return 'Réessayez dans $seconds seconde${seconds > 1 ? 's' : ''}';
    }
    
    return 'Veuillez réessayer plus tard';
  }
}
