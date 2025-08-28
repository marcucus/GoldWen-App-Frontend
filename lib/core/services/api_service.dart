import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api/v1';
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

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
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
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
    final response = await http.post(
      Uri.parse('$baseUrl/auth/social-login'),
      headers: _headers,
      body: jsonEncode({
        'socialId': socialId,
        'provider': provider,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
      }),
    );

    return _handleResponse(response);
  }

  // Profile endpoints
  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/profiles/me'),
      headers: _headers,
      body: jsonEncode(profileData),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> submitPersonalityAnswers(List<Map<String, dynamic>> answers) async {
    final response = await http.post(
      Uri.parse('$baseUrl/profiles/me/personality-answers'),
      headers: _headers,
      body: jsonEncode({'answers': answers}),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getPersonalityQuestions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/profiles/questions'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> submitPromptAnswers(List<Map<String, dynamic>> answers) async {
    final response = await http.post(
      Uri.parse('$baseUrl/profiles/me/prompt-answers'),
      headers: _headers,
      body: jsonEncode({'answers': answers}),
    );

    return _handleResponse(response);
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final Map<String, dynamic> data = jsonDecode(response.body);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: data['message'] ?? 'Unknown error occurred',
        code: data['code'],
      );
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? code;

  ApiException({
    required this.statusCode,
    required this.message,
    this.code,
  });

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}