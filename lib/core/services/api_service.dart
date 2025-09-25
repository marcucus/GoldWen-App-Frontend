import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ApiService {
  static String get baseUrl => AppConfig.isDevelopment
      ? AppConfig.devMainApiBaseUrl
      : AppConfig.mainApiBaseUrl;
  static String? _token;

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
  static Future<http.Response> _makeRequest(
    Future<http.Response> request, [
    Duration? timeout,
  ]) async {
    try {
      return await request.timeout(timeout ?? AppConfig.defaultTimeout);
    } on TimeoutException catch (_) {
      throw ApiException(
        statusCode: 0,
        message:
            'Request timeout - Please check your internet connection and try again',
        code: 'TIMEOUT_ERROR',
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
      http.get(
        Uri.parse('$baseUrl/health'),
        headers: _headers,
      ),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getWelcome() async {
    final response = await http.get(
      Uri.parse('${baseUrl.replaceAll('/api/v1', '')}/'),
      headers: _headers,
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
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers,
      body: jsonEncode({
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
      http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers,
        body: jsonEncode({
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
      http.post(
        Uri.parse('$baseUrl/auth/social-login'),
        headers: _headers,
        body: jsonEncode({
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
    final response = await http.post(
      Uri.parse('$baseUrl/auth/logout'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  // Profile endpoints
  static Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> profileData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/profiles/me'),
      headers: _headers,
      body: jsonEncode(profileData),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> submitPersonalityAnswers(
      List<Map<String, dynamic>> answers) async {
    final response = await http.post(
      Uri.parse('$baseUrl/profiles/me/personality-answers'),
      headers: _headers,
      body: jsonEncode(answers), // Send as direct array, not wrapped
    );

    return _handleResponse(response);
  }

  static Future<List<dynamic>> getPersonalityQuestions() async {
    final response = await _makeRequest(
      http.get(
        Uri.parse(
            '$baseUrl/profiles/questions'), // Fixed endpoint to match API docs
        headers: _headers,
      ),
    );
    return _handleResponse(response) as List<dynamic>;
  }

  static Future<List<dynamic>> getPrompts() async {
    final response = await _makeRequest(
      http.get(
        Uri.parse('$baseUrl/profiles/prompts'),
        headers: _headers,
      ),
    );
    return _handleResponse(response) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> submitPromptAnswers(
      List<Map<String, dynamic>> answers) async {
    final response = await http.post(
      Uri.parse('$baseUrl/profiles/me/prompt-answers'),
      headers: _headers,
      body: jsonEncode(
          {'answers': answers}), // Wrap in answers object as expected by DTO
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateProfileStatus({
    String? status,
    bool? completed,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/profiles/me/status'),
      headers: _headers,
      body: jsonEncode({
        if (status != null) 'status': status,
        if (completed != null) 'completed': completed,
      }),
    );

    return _handleResponse(response);
  }

  // Authentication extensions
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: _headers,
      body: jsonEncode({'email': email}),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> resetPassword(
      String token, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: _headers,
      body: jsonEncode({
        'token': token,
        'newPassword': newPassword,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> changePassword(
      String currentPassword, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/change-password'),
      headers: _headers,
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> verifyEmail(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-email'),
      headers: _headers,
      body: jsonEncode({'token': token}),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  // User endpoints
  static Future<Map<String, dynamic>> getUserProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateUser(
      Map<String, dynamic> userData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/me'),
      headers: _headers,
      body: jsonEncode(userData),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateUserSettings(
      Map<String, dynamic> settings) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/me/settings'),
      headers: _headers,
      body: jsonEncode(settings),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getUserStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me/stats'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> deactivateAccount() async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/me/deactivate'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> deleteAccount() async {
    final response = await http.delete(
      Uri.parse('$baseUrl/users/me'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  // Enhanced Profile endpoints
  static Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/profiles/me'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getProfileById(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/profiles/$userId'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> uploadPhoto(String filePath,
      {int? order}) async {
    var request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl/profiles/me/photos'));
    request.headers.addAll(_headers);
    request.files.add(await http.MultipartFile.fromPath('photos', filePath));
    if (order != null) {
      request.fields['order'] = order.toString();
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> uploadPhotos(List<String> filePaths) async {
    var request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl/profiles/me/photos'));
    request.headers.addAll(_headers);
    
    for (int i = 0; i < filePaths.length; i++) {
      request.files.add(await http.MultipartFile.fromPath('photos', filePaths[i]));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updatePhotoOrder(
      String photoId, int newOrder) async {
    final response = await http.put(
      Uri.parse('$baseUrl/profiles/me/photos/$photoId/order'),
      headers: _headers,
      body: jsonEncode({'newOrder': newOrder}),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> deletePhoto(String photoId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/profiles/me/photos/$photoId'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> setPrimaryPhoto(String photoId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/profiles/me/photos/$photoId/primary'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  // Matching endpoints
  static Future<Map<String, dynamic>> getDailySelection() async {
    final response = await _makeRequest(
      http.get(
        Uri.parse('$baseUrl/matching/daily-selection'),
        headers: _headers,
      ),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> chooseProfile(String profileId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/matching/choose/$profileId'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getMatches(
      {int? page, int? limit, String? status}) async {
    final queryParams = <String, String>{};
    if (page != null) queryParams['page'] = page.toString();
    if (limit != null) queryParams['limit'] = limit.toString();
    if (status != null) queryParams['status'] = status;

    final uri = Uri.parse('$baseUrl/matching/matches')
        .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getMatchDetails(String matchId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/matching/matches/$matchId'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> deleteMatch(String matchId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/matching/matches/$matchId'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getCompatibility(String profileId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/matching/compatibility/$profileId'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  // Chat endpoints
  static Future<Map<String, dynamic>> getConversations() async {
    final response = await _makeRequest(
      http.get(
        Uri.parse('$baseUrl/chat'),
        headers: _headers,
      ),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getConversationDetails(
      String chatId) async {
    final response = await _makeRequest(
      http.get(
        Uri.parse('$baseUrl/chat/$chatId'),
        headers: _headers,
      ),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getChatByMatchId(String matchId) async {
    final response = await _makeRequest(
      http.get(
        Uri.parse('$baseUrl/chat/match/$matchId'),
        headers: _headers,
      ),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getMessages(String chatId,
      {int? page, int? limit, String? before}) async {
    final queryParams = <String, String>{};
    if (page != null) queryParams['page'] = page.toString();
    if (limit != null) queryParams['limit'] = limit.toString();
    if (before != null) queryParams['before'] = before;

    final uri = Uri.parse('$baseUrl/chat/$chatId/messages')
        .replace(queryParameters: queryParams);
    final response = await _makeRequest(
      http.get(uri, headers: _headers),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> sendMessage(String chatId,
      {required String type, required String content}) async {
    final response = await _makeRequest(
      http.post(
        Uri.parse('$baseUrl/chat/$chatId/messages'),
        headers: _headers,
        body: jsonEncode({
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
      http.post(
        Uri.parse('$baseUrl/chat/accept/$matchId'),
        headers: _headers,
        body: jsonEncode({
          'accept': accept,
        }),
      ),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> markMessagesAsRead(String chatId) async {
    final response = await _makeRequest(
      http.put(
        Uri.parse('$baseUrl/chat/$chatId/messages/read'),
        headers: _headers,
      ),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> deleteMessage(String messageId) async {
    final response = await _makeRequest(
      http.delete(
        Uri.parse('$baseUrl/chat/messages/$messageId'),
        headers: _headers,
      ),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> expireChat(String chatId) async {
    final response = await _makeRequest(
      http.put(
        Uri.parse('$baseUrl/chat/$chatId/expire'),
        headers: _headers,
      ),
    );

    return _handleResponse(response);
  }



  // Subscription endpoints
  static Future<Map<String, dynamic>> getSubscriptionPlans() async {
    final response = await http.get(
      Uri.parse('$baseUrl/subscriptions/plans'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getCurrentSubscription() async {
    final response = await http.get(
      Uri.parse('$baseUrl/subscriptions/me'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> purchaseSubscription({
    required String plan,
    required String platform,
    required String receiptData,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/subscriptions/purchase'),
      headers: _headers,
      body: jsonEncode({
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
    final response = await http.post(
      Uri.parse('$baseUrl/subscriptions/verify-receipt'),
      headers: _headers,
      body: jsonEncode({
        'receiptData': receiptData,
        'platform': platform,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> cancelSubscription() async {
    final response = await http.put(
      Uri.parse('$baseUrl/subscriptions/cancel'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> restoreSubscription() async {
    final response = await http.post(
      Uri.parse('$baseUrl/subscriptions/restore'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getSubscriptionUsage() async {
    final response = await http.get(
      Uri.parse('$baseUrl/subscriptions/usage'),
      headers: _headers,
    );

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

    final uri = Uri.parse('$baseUrl/notifications')
        .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> markNotificationAsRead(
      String notificationId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/notifications/$notificationId/read'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> markAllNotificationsAsRead() async {
    final response = await http.put(
      Uri.parse('$baseUrl/notifications/read-all'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> deleteNotification(
      String notificationId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/notifications/$notificationId'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateNotificationSettings(
      Map<String, bool> settings) async {
    final response = await http.put(
      Uri.parse('$baseUrl/notifications/settings'),
      headers: _headers,
      body: jsonEncode(settings),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> sendTestNotification({
    required String title,
    required String body,
    required String type,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/notifications/test'),
      headers: _headers,
      body: jsonEncode({
        'title': title,
        'body': body,
        'type': type,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> registerDeviceToken(
      Map<String, String> deviceInfo) async {
    final response = await http.post(
      Uri.parse('$baseUrl/notifications/register-device'),
      headers: _headers,
      body: jsonEncode(deviceInfo),
    );

    return _handleResponse(response);
  }

  // Admin endpoints
  static Future<Map<String, dynamic>> adminLogin({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/auth/login'),
      headers: _headers,
      body: jsonEncode({
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
        Uri.parse('$baseUrl/admin/users').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getAdminUserDetails(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/users/$userId'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateUserStatus(
      String userId, String status) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/users/$userId/status'),
      headers: _headers,
      body: jsonEncode({'status': status}),
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

    final uri = Uri.parse('$baseUrl/admin/reports')
        .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateReportStatus(
      String reportId, String status, String resolution) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/reports/$reportId'),
      headers: _headers,
      body: jsonEncode({
        'status': status,
        'resolution': resolution,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getAdminAnalytics() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/analytics'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> broadcastNotification({
    required String title,
    required String body,
    required String type,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/notifications/broadcast'),
      headers: _headers,
      body: jsonEncode({
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
    final response = await http.post(
      Uri.parse('$baseUrl/users/consent'),
      headers: _headers,
      body: jsonEncode({
        'dataProcessing': dataProcessing,
        if (marketing != null) 'marketing': marketing,
        if (analytics != null) 'analytics': analytics,
        'consentedAt': DateTime.now().toIso8601String(),
      }),
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

    final uri = Uri.parse('$baseUrl/legal/privacy-policy')
        .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);

    return _handleResponse(response);
  }

  static Future<dynamic> exportUserData({String format = 'json'}) async {
    final queryParams = <String, String>{'format': format};
    
    final uri = Uri.parse('$baseUrl/users/me/export-data')
        .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);

    // For file downloads, we might need to handle differently
    if (format == 'pdf') {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.bodyBytes; // Return raw bytes for PDF
      } else {
        throw ApiException(
          statusCode: response.statusCode,
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
    final response = await http.put(
      Uri.parse('$baseUrl/users/me/privacy-settings'),
      headers: _headers,
      body: jsonEncode({
        'analytics': analytics,
        'marketing': marketing,
        'functionalCookies': functionalCookies,
        if (dataRetention != null) 'dataRetention': dataRetention,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getPrivacySettings() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me/privacy-settings'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  // Enhanced delete account with GDPR compliance notice
  static Future<Map<String, dynamic>> deleteAccountWithGdpr() async {
    final response = await http.delete(
      Uri.parse('$baseUrl/users/me'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  static dynamic _handleResponse(http.Response response) {
    try {
      if (AppConfig.isDevelopment) {
        print('API Response Status: ${response.statusCode}');
        print('API Response Body: ${response.body}');
      }

      final decoded = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (AppConfig.isDevelopment) {
          print('API Response successful, returning data: $decoded');
        }
        return decoded; // Peut être Map ou List
      } else {
        // Si erreur, essaye d'extraire le message d'un Map, sinon retourne le body brut
        String message;
        String? code;
        Map<String, dynamic>? errors;
        if (decoded is Map<String, dynamic>) {
          message = decoded['message'] ??
              _getDefaultErrorMessage(response.statusCode);
          code = decoded['code'];
          errors = decoded['errors'];
        } else {
          message = _getDefaultErrorMessage(response.statusCode);
          code = null;
          errors = null;
        }
        throw ApiException(
          statusCode: response.statusCode,
          message: message,
          code: code,
          errors: errors,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to parse response: $e',
        code: 'PARSE_ERROR',
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
}

// External Matching Service API
class MatchingServiceApi {
  static String get baseUrl => AppConfig.isDevelopment
      ? AppConfig.devMatchingServiceBaseUrl
      : AppConfig.matchingServiceBaseUrl;
  static String get apiKey => AppConfig.matchingServiceApiKey;

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-API-Key': apiKey,
      };

  static Future<Map<String, dynamic>> calculateCompatibility({
    required Map<String, dynamic> user1Profile,
    required Map<String, dynamic> user2Profile,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/matching-service/calculate-compatibility'),
      headers: _headers,
      body: jsonEncode({
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
    final response = await http.post(
      Uri.parse('$baseUrl/matching-service/generate-daily-selection'),
      headers: _headers,
      body: jsonEncode({
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
    final response = await http.post(
      Uri.parse('$baseUrl/matching-service/batch-compatibility'),
      headers: _headers,
      body: jsonEncode({
        'baseProfile': baseProfile,
        'profilesToCompare': profilesToCompare,
      }),
    );

    return _handleMatchingResponse(response);
  }

  static Future<Map<String, dynamic>> getAlgorithmStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/matching-service/algorithm/stats'),
      headers: _headers,
    );

    return _handleMatchingResponse(response);
  }

  static Map<String, dynamic> _handleMatchingResponse(http.Response response) {
    final Map<String, dynamic> data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: data['message'] ?? 'Matching service error occurred',
        code: data['code'],
      );
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? code;
  final Map<String, dynamic>? errors;

  ApiException({
    required this.statusCode,
    required this.message,
    this.code,
    this.errors,
  });

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';

  bool get isAuthError => statusCode == 401;
  bool get isValidationError => statusCode == 400 || statusCode == 422;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode >= 500;
  bool get isNetworkError => statusCode == 0;
}
