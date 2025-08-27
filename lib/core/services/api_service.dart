import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api/v1';
  
  late final Dio _dio;
  String? _authToken;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Add interceptors for debugging in development
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ));
    }

    // Add auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Token expired, clear it
          _authToken = null;
        }
        handler.next(error);
      },
    ));
  }

  void setAuthToken(String? token) {
    _authToken = token;
  }

  String? get authToken => _authToken;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  ApiException _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          'Connexion timeout. Vérifiez votre connexion internet.',
          type: ApiExceptionType.timeout,
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 
                       e.response?.data?['error'] ?? 
                       'Erreur serveur';
        return ApiException(
          message,
          statusCode: statusCode,
          type: _getExceptionType(statusCode),
        );
      case DioExceptionType.cancel:
        return ApiException(
          'Requête annulée',
          type: ApiExceptionType.cancelled,
        );
      default:
        return ApiException(
          'Erreur réseau. Vérifiez votre connexion.',
          type: ApiExceptionType.network,
        );
    }
  }

  ApiExceptionType _getExceptionType(int? statusCode) {
    switch (statusCode) {
      case 400:
        return ApiExceptionType.badRequest;
      case 401:
        return ApiExceptionType.unauthorized;
      case 403:
        return ApiExceptionType.forbidden;
      case 404:
        return ApiExceptionType.notFound;
      case 422:
        return ApiExceptionType.validation;
      case 500:
        return ApiExceptionType.serverError;
      default:
        return ApiExceptionType.unknown;
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final ApiExceptionType type;

  ApiException(
    this.message, {
    this.statusCode,
    required this.type,
  });

  @override
  String toString() => 'ApiException: $message';
}

enum ApiExceptionType {
  timeout,
  network,
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  validation,
  serverError,
  cancelled,
  unknown,
}