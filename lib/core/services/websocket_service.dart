import 'dart:async';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/app_config.dart';
import 'notification_manager.dart';

/// Real-time chat transport.
///
/// The backend chat gateway (`ChatGateway`, `main-api/src/modules/chat`) is
/// a Socket.IO server on namespace `/chat`, authenticated via the handshake
/// (`auth.token`) — not a raw WebSocket. This client must speak the same
/// protocol: a `socket_io_client` connection to `<mainApiOrigin>/chat`,
/// using the backend's own event names and payload shapes (`conversationId`,
/// not `chatId`, on the wire) rather than the ad-hoc `{type: ...}` JSON
/// envelope a raw WebSocket would need.
class WebSocketService {
  /// The Socket.IO connection URL: the main API's origin (scheme + host +
  /// port, no `/api/v1`), with `/chat` as the namespace. Socket.IO's own
  /// handshake still happens over HTTP(S) on this same origin, so this uses
  /// http(s), not ws(s) — the ws(s) values in AppConfig were written for a
  /// raw WebSocket and are converted here.
  static String get _namespaceUrl {
    final base = AppConfig.isDevelopment
        ? AppConfig.devWebSocketBaseUrl
        : AppConfig.webSocketBaseUrl;
    return base
        .replaceFirst('wss://', 'https://')
        .replaceFirst('ws://', 'http://');
  }

  /// Public alias for tests / diagnostics — the actual Socket.IO connect
  /// call uses [_namespaceUrl] internally.
  static String get baseUrl => _namespaceUrl;

  io.Socket? _socket;
  String? _token;
  bool _isConnected = false;
  BuildContext? _context; // Add context for notification management

  // Exponential backoff state. The socket.io client has its own built-in
  // reconnection, but it's disabled (`disableReconnection`) so this existing
  // backoff — the one the rest of the app already relies on — stays in
  // control end to end.
  static const Duration _initialReconnectDelay = Duration(seconds: 1);
  static const Duration _maxReconnectDelay = Duration(seconds: 30);
  Duration _currentReconnectDelay = _initialReconnectDelay;
  int _reconnectAttempt = 0;
  Timer? _reconnectTimer;
  bool _disposed = false;

  // Stream controllers for different event types
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _typingController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _readReceiptController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _chatExpiredController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _onlineStatusController =
      StreamController.broadcast();
  final StreamController<bool> _connectionController =
      StreamController.broadcast();

  // Public streams
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;
  Stream<Map<String, dynamic>> get readReceiptStream =>
      _readReceiptController.stream;
  Stream<Map<String, dynamic>> get chatExpiredStream =>
      _chatExpiredController.stream;
  Stream<Map<String, dynamic>> get onlineStatusStream =>
      _onlineStatusController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isConnected => _isConnected;

  void setToken(String token) {
    _token = token;
  }

  void setContext(BuildContext context) {
    _context = context;
  }

  Future<void> connect() async {
    if (_token == null) {
      throw Exception('Token must be set before connecting');
    }

    try {
      _socket?.dispose();

      final socket = io.io(
        _namespaceUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .enableForceNew()
            .disableAutoConnect()
            .disableReconnection() // handled ourselves, see _scheduleReconnect
            .setAuth({'token': _token})
            .build(),
      );
      _socket = socket;

      socket.onConnect((_) {
        debugPrint('WebSocket (Socket.IO /chat) connected');
        _isConnected = true;
        // Reset backoff on successful connection.
        _currentReconnectDelay = _initialReconnectDelay;
        _reconnectAttempt = 0;
        _connectionController.add(true);
      });

      socket.on('new_message', (data) => _handleNewMessage(_asMap(data)));
      socket.on('message_read', (data) => _handleReadReceipt(_asMap(data)));
      socket.on('user_typing', (data) => _handleTyping(_asMap(data), true));
      socket.on(
          'user_stopped_typing', (data) => _handleTyping(_asMap(data), false));
      socket.on('user_presence_changed', (data) => _handlePresence(_asMap(data)));
      socket.on('chat_expired', (data) => _handleChatExpired(_asMap(data)));
      socket.on('chat_expiring', (data) => _handleChatExpiring(_asMap(data)));
      socket.on('error', (data) {
        debugPrint('WebSocket (Socket.IO /chat) server error: $data');
      });

      socket.onDisconnect((reason) {
        debugPrint('WebSocket (Socket.IO /chat) disconnected: $reason');
        _isConnected = false;
        _connectionController.add(false);
        _scheduleReconnect();
      });

      socket.onConnectError((error) {
        debugPrint('WebSocket (Socket.IO /chat) connect error: $error');
        _isConnected = false;
        _connectionController.add(false);
        _scheduleReconnect();
      });

      socket.connect();
    } catch (e) {
      _isConnected = false;
      _connectionController.add(false);
      throw Exception('Failed to connect to WebSocket: $e');
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _connectionController.add(false);
  }

  /// Schedules a reconnection attempt using unlimited exponential backoff.
  /// Delay starts at 1 s, doubles on each attempt, and is capped at 30 s.
  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _reconnectAttempt++;
    debugPrint(
      'WebSocket reconnect attempt #$_reconnectAttempt '
      'in ${_currentReconnectDelay.inSeconds}s',
    );
    _reconnectTimer = Timer(_currentReconnectDelay, () async {
      // Double the delay for the next attempt, capped at the maximum.
      _currentReconnectDelay = Duration(
        milliseconds: (_currentReconnectDelay.inMilliseconds * 2)
            .clamp(0, _maxReconnectDelay.inMilliseconds),
      );
      try {
        await connect();
      } catch (_) {
        // connect() failed synchronously; the onDisconnect/onConnectError
        // handlers on the previous socket will already have triggered the
        // next scheduled reconnect, but guard against that not happening.
        _scheduleReconnect();
      }
    });
  }

  // The backend emits `new_message` as a flat payload
  // ({messageId, conversationId, senderId, content, type, timestamp}); the
  // rest of the app expects a `{message: ChatMessage-shaped}` envelope.
  void _handleNewMessage(Map<String, dynamic> data) {
    try {
      _messageController.add({
        'message': {
          'id': data['messageId'],
          'conversationId': data['conversationId'],
          'senderId': data['senderId'],
          'type': data['type'] ?? 'text',
          'content': data['content'],
          'isRead': false,
          'createdAt': data['timestamp'] ??
              DateTime.now().toIso8601String(),
        },
      });
    } catch (e) {
      debugPrint('Error handling new_message: $e');
    }
  }

  void _handleTyping(Map<String, dynamic> data, bool isTyping) {
    try {
      _typingController.add({
        'userId': data['userId'],
        'conversationId': data['conversationId'],
        'isTyping': isTyping,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error handling typing event: $e');
    }
  }

  void _handlePresence(Map<String, dynamic> data) {
    try {
      final isOnline = data['isOnline'] as bool? ?? false;
      _onlineStatusController.add({
        'userId': data['userId'],
        'isOnline': isOnline,
        'lastSeenAt': isOnline ? null : data['timestamp'],
      });
    } catch (e) {
      debugPrint('Error handling presence event: $e');
    }
  }

  void _handleReadReceipt(Map<String, dynamic> data) {
    try {
      _readReceiptController.add({
        'chatId': data['conversationId'],
        'messageId': data['messageId'],
        'readBy': data['readBy'],
        'readAt': data['readAt'],
      });
    } catch (e) {
      debugPrint('Error handling message_read: $e');
    }
  }

  void _handleChatExpired(Map<String, dynamic> data) {
    try {
      _chatExpiredController.add({
        'chatId': data['conversationId'],
      });
      _handleChatExpiredNotification(data);
    } catch (e) {
      debugPrint('Error handling chat_expired: $e');
    }
  }

  void _handleChatExpiring(Map<String, dynamic> data) {
    // No stream consumer today (the app doesn't yet show a countdown
    // warning ahead of the chat_expired system message) — surface it as a
    // local notification only, best-effort, using only the fields the
    // gateway actually sends (no partner name at the socket layer).
    if (_context == null) return;
    try {
      final expiresAtRaw = data['expiresAt'] as String?;
      final expiresAt =
          expiresAtRaw != null ? DateTime.tryParse(expiresAtRaw) : null;
      final hoursLeft = expiresAt != null
          ? expiresAt.difference(DateTime.now()).inHours.clamp(0, 24)
          : null;

      NotificationManager().showNotificationIfAllowed(
        context: _context!,
        type: 'system',
        title: 'Conversation bientôt expirée',
        body: hoursLeft != null
            ? 'Il vous reste environ ${hoursLeft}h pour échanger.'
            : 'Cette conversation va bientôt expirer.',
        payload: 'chat_expiring',
      );
    } catch (e) {
      debugPrint('Failed to show chat expiring notification: $e');
    }
  }

  void _handleChatExpiredNotification(Map<String, dynamic> data) {
    if (_context == null) return;

    try {
      NotificationManager().showNotificationIfAllowed(
        context: _context!,
        type: 'system',
        title: 'Conversation expirée',
        body: 'Cette conversation a expiré.',
        payload: 'chat_expired',
      );
    } catch (e) {
      debugPrint('Failed to show chat expired notification: $e');
    }
  }

  // Send events to server. Field names match what ChatGateway's
  // @SubscribeMessage handlers destructure (`conversationId`, not `chatId`).
  void sendMessage(String chatId, String content, {String type = 'text'}) {
    if (!_isConnected || _socket == null) {
      throw Exception('WebSocket not connected');
    }

    _socket!.emit('send_message', {
      'conversationId': chatId,
      'content': content,
      'type': type,
    });
  }

  void sendTyping(String chatId) {
    if (!_isConnected || _socket == null) {
      return; // Typing events are not critical
    }

    _socket!.emit('start_typing', {'conversationId': chatId});
  }

  void sendStoppedTyping(String chatId) {
    if (!_isConnected || _socket == null) {
      return; // Typing events are not critical
    }

    _socket!.emit('stop_typing', {'conversationId': chatId});
  }

  void markMessageAsRead(String chatId, String messageId) {
    if (!_isConnected || _socket == null) {
      return;
    }

    _socket!.emit('read_message', {
      'conversationId': chatId,
      'messageId': messageId,
    });
  }

  void joinChat(String chatId) {
    if (!_isConnected || _socket == null) {
      return;
    }

    _socket!.emit('join_chat', {'conversationId': chatId});
  }

  void leaveChat(String chatId) {
    if (!_isConnected || _socket == null) {
      return;
    }

    _socket!.emit('leave_chat', {'conversationId': chatId});
  }

  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    disconnect();
    _messageController.close();
    _typingController.close();
    _readReceiptController.close();
    _chatExpiredController.close();
    _onlineStatusController.close();
    _connectionController.close();
  }
}
