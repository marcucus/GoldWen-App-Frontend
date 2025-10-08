import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/moderation.dart';
import 'api_service.dart';

/// Service to interact with the moderation API
class ModerationService {
  /// Get moderation status for a specific resource
  /// 
  /// [resourceType] can be 'message', 'photo', or 'bio'
  /// [resourceId] is the unique identifier of the resource
  static Future<ModerationResult> getModerationStatus({
    required String resourceType,
    required String resourceId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/moderation/status/$resourceType/$resourceId'),
        headers: {
          'Content-Type': 'application/json',
          if (ApiService.token != null) 'Authorization': 'Bearer ${ApiService.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ModerationResult.fromJson(data);
      } else if (response.statusCode == 404) {
        // Resource not found or not moderated yet - return approved status
        return ModerationResult(
          status: ModerationStatus.approved,
          flags: [],
        );
      } else {
        throw Exception('Failed to get moderation status: ${response.statusCode}');
      }
    } catch (e) {
      // On error, return approved status to not block UI
      return ModerationResult(
        status: ModerationStatus.approved,
        flags: [],
      );
    }
  }

  /// Get moderation history for the current user
  /// 
  /// Returns a list of all moderation actions on user's content
  static Future<List<ModerationHistoryItem>> getModerationHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/moderation/history?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          if (ApiService.token != null) 'Authorization': 'Bearer ${ApiService.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final items = (data['data'] as List<dynamic>)
            .map((item) => ModerationHistoryItem.fromJson(item as Map<String, dynamic>))
            .toList();
        return items;
      } else {
        throw Exception('Failed to get moderation history: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  /// Appeal a moderation decision
  /// 
  /// [resourceType] can be 'message', 'photo', or 'bio'
  /// [resourceId] is the unique identifier of the resource
  /// [reason] is the appeal reason provided by the user
  static Future<bool> appealModerationDecision({
    required String resourceType,
    required String resourceId,
    required String reason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/moderation/appeal'),
        headers: {
          'Content-Type': 'application/json',
          if (ApiService.token != null) 'Authorization': 'Bearer ${ApiService.token}',
        },
        body: jsonEncode({
          'resourceType': resourceType,
          'resourceId': resourceId,
          'reason': reason,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}
