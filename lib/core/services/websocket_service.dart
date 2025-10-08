import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter/material.dart';
import '../config/app_config.dart';
import 'notification_manager.dart';

class WebSocketService {
  static String get baseUrl => AppConfig.isDevelopment 
      ? AppConfig.devWebSocketBaseUrl 
      : AppConfig.webSocketBaseUrl;
  
  WebSocketChannel? _channel;
  String? _token;
  bool _isConnected = false;
  BuildContext? _context; // Add context for notification management
  
  // Stream controllers for different event types
  final StreamController<Map<String, dynamic>> _messageController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _typingController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _readReceiptController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _chatExpiredController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _onlineStatusController = StreamController.broadcast();
  final StreamController<bool> _connectionController = StreamController.broadcast();

  // Public streams
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;
  Stream<Map<String, dynamic>> get readReceiptStream => _readReceiptController.stream;
  Stream<Map<String, dynamic>> get chatExpiredStream => _chatExpiredController.stream;
  Stream<Map<String, dynamic>> get onlineStatusStream => _onlineStatusController.stream;
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
      final uri = Uri.parse('$baseUrl?token=$_token');
      _channel = IOWebSocketChannel.connect(uri);
      
      _isConnected = true;
      _connectionController.add(true);
      
      // Listen to incoming messages
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
      );
    } catch (e) {
      _isConnected = false;
      _connectionController.add(false);
      throw Exception('Failed to connect to WebSocket: $e');
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
    _connectionController.add(false);
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final eventType = data['type'] as String?;

      switch (eventType) {
        case 'new_message':
          _messageController.add(data);
          _handleNewMessageNotification(data);
          break;
        case 'message_read':
          _readReceiptController.add(data);
          break;
        case 'user_typing':
        case 'user_stopped_typing':
          _typingController.add(data);
          break;
        case 'user_online':
        case 'user_offline':
          _onlineStatusController.add(data);
          break;
        case 'chat_expired':
          _chatExpiredController.add(data);
          _handleChatExpiringNotification(data);
          break;
        case 'chat_expiring_soon':
          _handleChatExpiringSoonNotification(data);
          break;
        default:
          print('Unknown WebSocket event type: $eventType');
      }
    } catch (e) {
      print('Error handling WebSocket message: $e');
    }
  }

  void _handleNewMessageNotification(Map<String, dynamic> data) {
    if (_context == null) return;
    
    try {
      final senderName = data['senderName'] as String?;
      final isFromCurrentUser = data['isFromCurrentUser'] as bool? ?? false;
      
      // Only show notification if message is not from current user
      if (!isFromCurrentUser && senderName != null) {
        NotificationManager().showNewMessageNotification(_context!, senderName);
      }
    } catch (e) {
      print('Failed to show new message notification: $e');
    }
  }

  void _handleChatExpiringNotification(Map<String, dynamic> data) {
    if (_context == null) return;
    
    try {
      final partnerName = data['partnerName'] as String?;
      if (partnerName != null) {
        NotificationManager().showNotificationIfAllowed(
          context: _context!,
          type: 'system',
          title: 'Conversation expirée',
          body: 'Votre conversation avec $partnerName a expiré',
          payload: 'chat_expired',
        );
      }
    } catch (e) {
      print('Failed to show chat expired notification: $e');
    }
  }

  void _handleChatExpiringSoonNotification(Map<String, dynamic> data) {
    if (_context == null) return;
    
    try {
      final partnerName = data['partnerName'] as String?;
      final hoursLeft = data['hoursLeft'] as int?;
      
      if (partnerName != null && hoursLeft != null) {
        NotificationManager().showChatExpiringNotification(
          _context!, 
          partnerName, 
          hoursLeft
        );
      }
    } catch (e) {
      print('Failed to show chat expiring soon notification: $e');
    }
  }

  void _handleError(error) {
    print('WebSocket error: $error');
    _isConnected = false;
    _connectionController.add(false);
  }

  void _handleDisconnection() {
    print('WebSocket disconnected');
    _isConnected = false;
    _connectionController.add(false);
  }

  // Send events to server
  void sendMessage(String chatId, String content, {String type = 'text'}) {
    if (!_isConnected || _channel == null) {
      throw Exception('WebSocket not connected');
    }

    final data = {
      'type': 'send_message',
      'chatId': chatId,
      'content': content,
      'messageType': type,
    };

    _channel!.sink.add(jsonEncode(data));
  }

  void sendTyping(String chatId) {
    if (!_isConnected || _channel == null) {
      return; // Typing events are not critical
    }

    final data = {
      'type': 'typing',
      'chatId': chatId,
    };

    _channel!.sink.add(jsonEncode(data));
  }

  void sendStoppedTyping(String chatId) {
    if (!_isConnected || _channel == null) {
      return; // Typing events are not critical
    }

    final data = {
      'type': 'stopped_typing',
      'chatId': chatId,
    };

    _channel!.sink.add(jsonEncode(data));
  }

  void markMessageAsRead(String chatId, String messageId) {
    if (!_isConnected || _channel == null) {
      return;
    }

    final data = {
      'type': 'mark_read',
      'chatId': chatId,
      'messageId': messageId,
    };

    _channel!.sink.add(jsonEncode(data));
  }

  void joinChat(String chatId) {
    if (!_isConnected || _channel == null) {
      return;
    }

    final data = {
      'type': 'join_chat',
      'chatId': chatId,
    };

    _channel!.sink.add(jsonEncode(data));
  }

  void leaveChat(String chatId) {
    if (!_isConnected || _channel == null) {
      return;
    }

    final data = {
      'type': 'leave_chat',
      'chatId': chatId,
    };

    _channel!.sink.add(jsonEncode(data));
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _typingController.close();
    _readReceiptController.close();
    _chatExpiredController.close();
    _onlineStatusController.close();
    _connectionController.close();
  }
}