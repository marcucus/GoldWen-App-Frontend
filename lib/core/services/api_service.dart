import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/app_config.dart';
import '../models/models.dart';

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
    
    if (AppConfig.isDevelopment) {
      print('Submitting personality answers: $answers');
      print('Request body: ${jsonEncode({'answers': answers})}');
    }
    
    final response = await http.post(
      Uri.parse('$baseUrl/profiles/me/personality-answers'),
      headers: _headers,
      body: jsonEncode({
        'answers': answers
      }), // Wrap answers in object as expected by DTO
    );

    return _handleResponse(response);
  }

  static Future<List<dynamic>> getPersonalityQuestions() async {
    final response = await _makeRequest(
      http.get(
        Uri.parse(
            '$baseUrl/profiles/personality-questions'), // Corrected endpoint - was /profiles/questions
        headers: _headers,
      ),
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
      http.get(
        Uri.parse('$baseUrl/profiles/prompts'),
        headers: _headers,
      ),
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
    final response = await http.post(
      Uri.parse('$baseUrl/profiles/me/prompt-answers'),
      headers: _headers,
      body: jsonEncode(
          {'answers': answers}), // Wrap in answers object as expected by DTO
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateProfileStatus({
    bool? isVisible,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/profiles/me/status'),
      headers: _headers,
      body: jsonEncode({
        if (isVisible != null) 'isVisible': isVisible,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getProfileCompletion() async {
    final response = await _makeRequest(
      http.get(
        Uri.parse('$baseUrl/profiles/completion'),
        headers: _headers,
      ),
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
    
    String extension = filePath.split('.').last.toLowerCase();
    
    // Determine media type based on file extension
    String subtype;
    switch (extension) {
      case 'png':
        subtype = 'png';
        break;
      case 'webp':
        subtype = 'webp';
        break;
      case 'jpg':
      case 'jpeg':
      default:
        subtype = 'jpeg';
        break;
    }
    
    // Read file as bytes to ensure proper MIME type handling
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final filename = file.uri.pathSegments.last;
    
    final multipartFile = http.MultipartFile.fromBytes(
      'photos',
      bytes,
      filename: filename,
      contentType: MediaType('image', subtype),
    );
    
    request.files.add(multipartFile);
    
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
      String filePath = filePaths[i];
      String extension = filePath.split('.').last.toLowerCase();
      
      // Determine media type based on file extension
      String subtype;
      String mimeType;
      switch (extension) {
        case 'png':
          subtype = 'png';
          mimeType = 'image/png';
          break;
        case 'webp':
          subtype = 'webp';
          mimeType = 'image/webp';
          break;
        case 'jpg':
        case 'jpeg':
        default:
          subtype = 'jpeg';
          mimeType = 'image/jpeg';
          break;
      }
      
      // Read file as bytes to ensure proper MIME type handling
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final filename = file.uri.pathSegments.last;
      
      print('Adding file: $filename with MIME type: $mimeType');
      
      // Create multipart file with explicit MIME type
      final multipartFile = http.MultipartFile.fromBytes(
        'photos',
        bytes,
        filename: filename,
        contentType: MediaType('image', subtype),
      );
      
      request.files.add(multipartFile);
    }
    
    // Debug: Log the request headers and content type
    print('Request headers: ${request.headers}');
    print('Files being uploaded: ${request.files.length}');
    for (var file in request.files) {
      print('File field: ${file.field}, filename: ${file.filename}, contentType: ${file.contentType}');
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

  // Media file endpoints (audio/video)
  static Future<Map<String, dynamic>> uploadMediaFile(
    String filePath, {
    required String type,
    int? order,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/profiles/me/media'),
    );
    request.headers.addAll(_headers);

    String extension = filePath.split('.').last.toLowerCase();

    // Determine media type based on file extension
    String mainType;
    String subtype;

    if (type == 'audio') {
      mainType = 'audio';
      switch (extension) {
        case 'mp3':
          subtype = 'mpeg';
          break;
        case 'wav':
          subtype = 'wav';
          break;
        case 'm4a':
          subtype = 'mp4';
          break;
        case 'aac':
          subtype = 'aac';
          break;
        case 'ogg':
          subtype = 'ogg';
          break;
        default:
          subtype = 'mpeg';
          break;
      }
    } else {
      // video
      mainType = 'video';
      switch (extension) {
        case 'mp4':
          subtype = 'mp4';
          break;
        case 'mov':
          subtype = 'quicktime';
          break;
        case 'avi':
          subtype = 'x-msvideo';
          break;
        case 'mkv':
          subtype = 'x-matroska';
          break;
        case 'webm':
          subtype = 'webm';
          break;
        default:
          subtype = 'mp4';
          break;
      }
    }

    // Read file as bytes
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final filename = file.uri.pathSegments.last;

    final multipartFile = http.MultipartFile.fromBytes(
      'mediaFile',
      bytes,
      filename: filename,
      contentType: MediaType(mainType, subtype),
    );

    request.files.add(multipartFile);
    request.fields['type'] = type;

    if (order != null) {
      request.fields['order'] = order.toString();
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> deleteMediaFile(String mediaId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/profiles/me/media/$mediaId'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateMediaFileOrder(
    String mediaId,
    int newOrder,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/profiles/me/media/$mediaId/order'),
      headers: _headers,
      body: jsonEncode({'newOrder': newOrder}),
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

  static Future<Map<String, dynamic>> chooseProfile(
    String profileId, {
    String choice = 'like',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/matching/choose/$profileId'),
      headers: _headers,
      body: jsonEncode({
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

  // Premium feature: Who liked me
  static Future<Map<String, dynamic>> getWhoLikedMe() async {
    final response = await _makeRequest(
      http.get(
        Uri.parse('$baseUrl/matching/who-liked-me'),
        headers: _headers,
      ),
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

  static Future<Map<String, dynamic>> getNotificationSettings() async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications/settings'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateNotificationSettings(
      Map<String, dynamic> settings) async {
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

  static Future<Map<String, dynamic>> triggerDailySelectionNotifications({
    List<String>? targetUsers,
    String? customMessage,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/notifications/trigger-daily-selection'),
      headers: _headers,
      body: jsonEncode({
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
    final response = await http.post(
      Uri.parse('$baseUrl/notifications/send-group'),
      headers: _headers,
      body: jsonEncode({
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
    final response = await http.post(
      Uri.parse('$baseUrl/users/me/push-tokens'),
      headers: _headers,
      body: jsonEncode({
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
    final response = await http.delete(
      Uri.parse('$baseUrl/users/me/push-tokens'),
      headers: _headers,
      body: jsonEncode({
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

  // Feedback endpoints
  static Future<Map<String, dynamic>> submitFeedback({
    required String type,
    required String subject,
    required String message,
    int? rating,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await _makeRequest(
      http.post(
        Uri.parse('$baseUrl/feedback'),
        headers: _headers,
        body: jsonEncode({
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

  // Request data export
  static Future<Map<String, dynamic>> requestDataExport() async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/me/data-export'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  // Get data export status
  static Future<Map<String, dynamic>> getDataExportStatus(String requestId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me/data-export/$requestId'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  // Download data export
  static Future<dynamic> downloadDataExport(String requestId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me/data-export/$requestId/download'),
      headers: _headers,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes; // Return raw bytes for file download
    } else {
      throw ApiException(
        statusCode: response.statusCode,
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
    final response = await http.delete(
      Uri.parse('$baseUrl/users/me'),
      headers: _headers,
      body: jsonEncode({
        'password': password,
        if (reason != null) 'reason': reason,
        'immediateDelete': immediateDelete,
      }),
    );

    return _handleResponse(response);
  }

  // Cancel account deletion
  static Future<Map<String, dynamic>> cancelAccountDeletion() async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/me/cancel-deletion'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  // Get account deletion status
  static Future<Map<String, dynamic>> getAccountDeletionStatus() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me/deletion-status'),
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
          print('Data type: ${decoded.runtimeType}');
          if (decoded is Map<String, dynamic>) {
            print('Map keys: ${decoded.keys.toList()}');
          }
        }
        return decoded; // Peut être Map ou List
      } else {
        // Si erreur, essaye d'extraire le message d'un Map, sinon retourne le body brut
        String message;
        String? code;
        Map<String, dynamic>? errors;
        RateLimitInfo? rateLimitInfo;
        
        if (decoded is Map<String, dynamic>) {
          message = decoded['message'] ??
              _getDefaultErrorMessage(response.statusCode);
          code = decoded['code'];
          errors = decoded['errors'];
          
          // Extract retry information from response body if available
          if (response.statusCode == 429 && decoded['retryAfter'] != null) {
            rateLimitInfo = RateLimitInfo(
              retryAfterSeconds: decoded['retryAfter'] as int?,
            );
          }
        } else {
          message = _getDefaultErrorMessage(response.statusCode);
          code = null;
          errors = null;
        }
        
        // Extract rate limit info from headers
        if (rateLimitInfo == null) {
          final headerMap = <String, String>{};
          response.headers.forEach((key, value) {
            headerMap[key.toLowerCase()] = value;
          });
          final rateLimitFromHeaders = RateLimitInfo.fromHeaders(headerMap);
          if (rateLimitFromHeaders.hasData) {
            rateLimitInfo = rateLimitFromHeaders;
          }
        }
        
        throw ApiException(
          statusCode: response.statusCode,
          message: message,
          code: code,
          errors: errors,
          rateLimitInfo: rateLimitInfo,
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

    final uri = Uri.parse('$baseUrl/users/me/email-history')
        .replace(queryParameters: queryParams);
    final response = await _makeRequest(
      http.get(uri, headers: _headers),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getEmailDetails(String emailId) async {
    final response = await _makeRequest(
      http.get(
        Uri.parse('$baseUrl/users/me/email-history/$emailId'),
        headers: _headers,
      ),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> retryEmail(String emailId) async {
    final response = await _makeRequest(
      http.post(
        Uri.parse('$baseUrl/users/me/email-history/$emailId/retry'),
        headers: _headers,
      ),
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

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-API-Key': apiKey,
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

  static dynamic _handleResponse(http.Response response) {
    try {
      if (AppConfig.isDevelopment) {
        print('Matching API Response Status: ${response.statusCode}');
        print('Matching API Response Body: ${response.body}');
      }

      final decoded = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (AppConfig.isDevelopment) {
          print('Matching API Response successful, returning data: $decoded');
        }
        return decoded;
      } else {
        String message;
        String? code;
        RateLimitInfo? rateLimitInfo;
        
        if (decoded is Map<String, dynamic>) {
          message = decoded['message'] ?? 'Unknown error';
          code = decoded['code'];
          
          // Extract retry information from response body if available
          if (response.statusCode == 429 && decoded['retryAfter'] != null) {
            rateLimitInfo = RateLimitInfo(
              retryAfterSeconds: decoded['retryAfter'] as int?,
            );
          }
        } else {
          message = response.body;
        }
        
        // Extract rate limit info from headers
        if (rateLimitInfo == null) {
          final headerMap = <String, String>{};
          response.headers.forEach((key, value) {
            headerMap[key.toLowerCase()] = value;
          });
          final rateLimitFromHeaders = RateLimitInfo.fromHeaders(headerMap);
          if (rateLimitFromHeaders.hasData) {
            rateLimitInfo = rateLimitFromHeaders;
          }
        }

        throw ApiException(
          statusCode: response.statusCode,
          message: message,
          code: code,
          rateLimitInfo: rateLimitInfo,
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Invalid response format',
        code: 'INVALID_RESPONSE',
      );
    }
  }

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

  static Future<Map<String, dynamic>> calculateCompatibilityV2({
    required String userId,
    required List<String> candidateIds,
    required Map<String, dynamic> personalityAnswers,
    required Map<String, dynamic> preferences,
    Map<String, dynamic>? userLocation,
    bool includeAdvancedScoring = true,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/matching/calculate-compatibility-v2'),
      headers: _headers,
      body: jsonEncode({
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
    final response = await http.get(
      Uri.parse('$baseUrl/matching-service/algorithm/stats'),
      headers: _headers,
    );

    return _handleMatchingResponse(response);
  }

  // Matches API methods

  static Future<Map<String, dynamic>> getMatchDetails(String matchId) async {
    final response = await _makeRequest(
      http.get(
        Uri.parse('$baseUrl/matching/matches/$matchId'),
        headers: _headers,
      ),
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

    final uri = Uri.parse('$baseUrl/matching/history').replace(
      queryParameters: queryParams,
    );

    final response = await _makeRequest(
      http.get(uri, headers: _headers),
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
      http.post(
        Uri.parse('$baseUrl/reports'),
        headers: _headers,
        body: jsonEncode(body),
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

    final uri = Uri.parse('$baseUrl/reports/me').replace(
      queryParameters: queryParams,
    );

    final response = await _makeRequest(
      http.get(uri, headers: _headers),
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

  static Map<String, dynamic> _handleMatchingResponse(http.Response response) {
    final Map<String, dynamic> data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      RateLimitInfo? rateLimitInfo;
      
      // Extract retry information from response body if available
      if (response.statusCode == 429 && data['retryAfter'] != null) {
        rateLimitInfo = RateLimitInfo(
          retryAfterSeconds: data['retryAfter'] as int?,
        );
      }
      
      // Extract rate limit info from headers
      if (rateLimitInfo == null) {
        final headerMap = <String, String>{};
        response.headers.forEach((key, value) {
          headerMap[key.toLowerCase()] = value;
        });
        final rateLimitFromHeaders = RateLimitInfo.fromHeaders(headerMap);
        if (rateLimitFromHeaders.hasData) {
          rateLimitInfo = rateLimitFromHeaders;
        }
      }
      
      throw ApiException(
        statusCode: response.statusCode,
        message: data['message'] ?? 'Matching service error occurred',
        code: data['code'],
        rateLimitInfo: rateLimitInfo,
      );
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? code;
  final Map<String, dynamic>? errors;
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
