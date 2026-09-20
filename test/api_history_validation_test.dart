import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/core/services/api_service.dart';
import 'package:goldwen_app/core/models/models.dart';
import 'support/api_adapter.dart';

void main() {
  late List<RequestOptions> requests;
  setUp(() {
    requests = [];
    ApiService.clearToken();
    ApiService.onSessionExpired = null;
    ApiService.onTokensRefreshed = null;
    ApiService.setToken('access');
    ApiService.configureTestAdapter(() => ApiAdapter((request) {
      requests.add(request);
      return (200, {'data': []});
    }));
  });
  tearDown(ApiService.clearToken);

  test('history and reports use the main API with JWT and pagination', () async {
    await ApiService.getHistory(page: 2, limit: 10, startDate: '2026-09-01');
    await ApiService.getMyReports(status: ReportStatus.pending);
    expect(requests[0].uri.path, '/api/v1/matching/history');
    expect(requests[0].uri.queryParameters, {'page': '2', 'limit': '10', 'startDate': '2026-09-01'});
    expect(requests[1].uri.path, '/api/v1/reports/me');
    expect(requests[1].uri.queryParameters['status'], 'pending');
    for (final request in requests) {
      expect(request.headers['Authorization'], 'Bearer access');
      expect(request.headers.containsKey('X-API-Key'), isFalse);
      expect(request.uri.host, Uri.parse(ApiService.baseUrl).host);
    }
  });

  test('report submission serializes the backend contract', () async {
    // Le contrat réel (CreateReportDto côté backend) est `targetType` +
    // `targetId` + `reason` (l'enum ReportType) + `description` (texte
    // libre) ; `targetUserId`/`type`/`chatId` n'existent pas dans ce DTO, et
    // `ValidationPipe` a `forbidNonWhitelisted: true` — les envoyer faisait
    // rejeter (400) tout signalement avant ce correctif. `chatId` ici n'a
    // plus d'usage côté fil (le backend retrouve chatId lui-même à partir du
    // message quand targetType == 'message').
    await ApiService.submitReport(targetUserId: 'user-2', type: ReportType.harassment, reason: 'Messages insistants', chatId: 'chat-1');
    expect(requests.single.method, 'POST');
    expect(requests.single.uri.path, '/api/v1/reports');
    expect(jsonDecode(requests.single.data as String), {
      'targetType': 'user', 'targetId': 'user-2', 'reason': 'harassment', 'description': 'Messages insistants',
    });
  });

  test('message report submission targets the message id, not the user id',
      () async {
    await ApiService.submitReport(
      targetUserId: 'user-2',
      type: ReportType.inappropriateContent,
      reason: 'Contenu déplacé',
      messageId: 'message-9',
      chatId: 'chat-1',
      decryptedMessageContent: 'texte déchiffré du message signalé',
    );
    expect(jsonDecode(requests.single.data as String), {
      'targetType': 'message',
      'targetId': 'message-9',
      'reason': 'inappropriate_content',
      'description': 'Contenu déplacé',
      'decryptedMessageContent': 'texte déchiffré du message signalé',
    });
  });

  test('concurrent 401 responses share one refresh and replay with new JWT', () async {
    ApiService.setRefreshToken('refresh');
    var refreshCount = 0;
    var persisted = 0;
    ApiService.onTokensRefreshed = (access, refresh) {
      expect(access, 'new-access');
      expect(refresh, 'new-refresh');
      persisted++;
    };
    ApiService.configureTestAdapter(() => ApiAdapter((request) {
      requests.add(request);
      if (request.uri.path.endsWith('/auth/refresh')) {
        refreshCount++;
        expect(jsonDecode(request.data as String), {'refreshToken': 'refresh'});
        expect(request.headers.containsKey('Authorization'), isFalse);
        return (200, {'data': {'accessToken': 'new-access', 'refreshToken': 'new-refresh'}});
      }
      if (request.headers['Authorization'] != 'Bearer new-access') {
        return (401, {'message': 'Expired'});
      }
      return (200, {'data': []});
    }));
    await Future.wait([ApiService.getHistory(), ApiService.getMyReports()]);
    expect(refreshCount, 1);
    expect(persisted, 1);
    expect(ApiService.token, 'new-access');
    expect(ApiService.refreshToken, 'new-refresh');
  });

  test('failed refresh clears the session and signals logout once', () async {
    ApiService.setRefreshToken('expired-refresh');
    var expired = 0;
    ApiService.onSessionExpired = () => expired++;
    ApiService.configureTestAdapter(() => ApiAdapter((_) => (401, {'message': 'Unauthorized'})));
    await expectLater(ApiService.getHistory(), throwsA(isA<ApiException>()));
    expect(ApiService.token, isNull);
    expect(ApiService.refreshToken, isNull);
    expect(expired, 1);
  });
}
