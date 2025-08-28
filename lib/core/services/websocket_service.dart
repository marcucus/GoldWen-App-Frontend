import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../config/app_config.dart';

class WebSocketService {
  static String get baseUrl => AppConfig.isDevelopment 
      ? AppConfig.devWebSocketBaseUrl 
      : AppConfig.webSocketBaseUrl;
  
  WebSocketChannel? _channel;
  String? _token;
  bool _isConnected = false;
  
  // Stream controllers for different event types
  final StreamController<Map<String, dynamic>> _messageController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _typingController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _readReceiptController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _chatExpiredController = StreamController.broadcast();
  final StreamController<bool> _connectionController = StreamController.broadcast();

  // Public streams
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;
  Stream<Map<String, dynamic>> get readReceiptStream => _readReceiptController.stream;
  Stream<Map<String, dynamic>> get chatExpiredStream => _chatExpiredController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isConnected => _isConnected;

  void setToken(String token) {
    _token = token;
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
          break;
        case 'message_read':
          _readReceiptController.add(data);
          break;
        case 'user_typing':
        case 'user_stopped_typing':
          _typingController.add(data);
          break;
        case 'chat_expired':
          _chatExpiredController.add(data);
          break;
        default:
          print('Unknown WebSocket event type: $eventType');
      }
    } catch (e) {
      print('Error handling WebSocket message: $e');
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
    _connectionController.close();
  }
}