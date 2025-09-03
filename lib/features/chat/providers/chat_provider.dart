import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/models/models.dart';
import '../../../core/config/app_config.dart';

class ChatProvider with ChangeNotifier {
  List<Conversation> _conversations = [];
  Map<String, List<ChatMessage>> _chatMessages = {};
  Map<String, TypingStatus> _typingStatuses = {};
  bool _isLoading = false;
  String? _error;
  WebSocketService? _webSocketService;
  bool _isWebSocketConnected = false;
  String? _currentUserId;

  List<Conversation> get conversations => _conversations;
  Map<String, List<ChatMessage>> get chatMessages => _chatMessages;
  Map<String, TypingStatus> get typingStatuses => _typingStatuses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isWebSocketConnected => _isWebSocketConnected;

  ChatProvider() {
    _initializeWebSocket();
  }

  void setCurrentUserId(String userId) {
    _currentUserId = userId;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  List<ChatMessage> getChatMessages(String chatId) {
    return _chatMessages[chatId] ?? [];
  }

  Conversation? getConversation(String chatId) {
    try {
      return _conversations.firstWhere((conv) => conv.id == chatId);
    } catch (e) {
      return null;
    }
  }

  bool isChatExpired(String chatId) {
    final conversation = getConversation(chatId);
    return conversation?.isExpired ?? false;
  }

  Duration? getRemainingTime(String chatId) {
    final conversation = getConversation(chatId);
    if (conversation?.expiresAt == null) return null;
    
    final now = DateTime.now();
    if (now.isAfter(conversation!.expiresAt!)) return Duration.zero;
    
    return conversation.expiresAt!.difference(now);
  }

  TypingStatus? getTypingStatus(String chatId) {
    final status = _typingStatuses[chatId];
    if (status?.isRecent == true) return status;
    return null;
  }

  bool isUserTyping(String chatId, String userId) {
    final status = getTypingStatus(chatId);
    return status?.userId == userId && status?.isTyping == true;
  }

  Future<void> initializeWebSocket(String token) async {
    try {
      _webSocketService = WebSocketService();
      _webSocketService!.setToken(token);
      
      // Listen to WebSocket events
      _webSocketService!.messageStream.listen(_handleNewMessage);
      _webSocketService!.typingStream.listen(_handleTypingUpdate);
      _webSocketService!.readReceiptStream.listen(_handleReadReceipt);
      _webSocketService!.chatExpiredStream.listen(_handleChatExpired);
      _webSocketService!.connectionStream.listen(_handleConnectionUpdate);
      
      await _webSocketService!.connect();
    } catch (e) {
      _error = 'Failed to connect to chat service';
      notifyListeners();
    }
  }

  void _initializeWebSocket() {
    // This will be called when token is available
    // For now, just set up the structure
  }

  Future<void> loadConversations() async {
    _setLoading();

    try {
      if (AppConfig.isDevelopment) {
        print('ChatProvider: Starting to load conversations...');
      }
      
      final response = await ApiService.getConversations();
      
      if (AppConfig.isDevelopment) {
        print('ChatProvider: Received response: $response');
      }
      
      final conversationsData = response['data'] ?? response['conversations'] ?? [];
      
      if (AppConfig.isDevelopment) {
        print('ChatProvider: Processing ${(conversationsData as List).length} conversations');
      }
      
      _conversations = [];
      
      // Parse conversations one by one to handle individual parsing errors
      for (final conversationJson in (conversationsData as List)) {
        try {
          final conversation = Conversation.fromJson(conversationJson as Map<String, dynamic>);
          _conversations.add(conversation);
        } catch (e) {
          // Log parsing error but continue with other conversations
          if (AppConfig.isDevelopment) {
            print('Error parsing conversation: $e');
            print('Conversation data: $conversationJson');
          }
          // Skip this conversation and continue with others
        }
      }
      
      if (AppConfig.isDevelopment) {
        print('ChatProvider: Successfully parsed ${_conversations.length} conversations');
      }
      
      _error = null;
    } catch (e) {
      _handleError(e, 'Failed to load conversations');
    } finally {
      _setLoaded();
    }
  }

  Future<void> loadConversationDetails(String chatId) async {
    try {
      final response = await ApiService.getConversationDetails(chatId);
      final conversationData = response['data'] ?? response;
      
      final conversation = Conversation.fromJson(conversationData);
      final index = _conversations.indexWhere((c) => c.id == chatId);
      
      if (index != -1) {
        _conversations[index] = conversation;
      } else {
        _conversations.add(conversation);
      }
      
      notifyListeners();
    } catch (e) {
      _handleError(e, 'Failed to load conversation details');
    }
  }

  Future<void> loadChatMessages(String chatId, {int page = 1, int limit = 50}) async {
    if (page == 1) _setLoading();

    try {
      final response = await ApiService.getMessages(
        chatId,
        page: page,
        limit: limit,
      );
      
      final messagesData = response['data'] ?? response['messages'] ?? [];
      final newMessages = <ChatMessage>[];
      
      // Parse messages one by one to handle individual parsing errors
      for (final messageJson in (messagesData as List)) {
        try {
          final message = ChatMessage.fromJson(messageJson as Map<String, dynamic>);
          newMessages.add(message);
        } catch (e) {
          // Log parsing error but continue with other messages
          if (AppConfig.isDevelopment) {
            print('Error parsing message: $e');
            print('Message data: $messageJson');
          }
          // Skip this message and continue with others
        }
      }

      if (page == 1) {
        _chatMessages[chatId] = newMessages;
      } else {
        _chatMessages[chatId] = [...(_chatMessages[chatId] ?? []), ...newMessages];
      }
      
      // Join the chat room for real-time updates
      _webSocketService?.joinChat(chatId);
      
      _error = null;
      notifyListeners();
    } catch (e) {
      _handleError(e, 'Failed to load messages');
    } finally {
      if (page == 1) _setLoaded();
    }
  }

  Future<void> sendMessage(String chatId, String message, {String type = 'text'}) async {
    if (isChatExpired(chatId)) {
      _error = 'Cannot send message to expired chat';
      notifyListeners();
      return;
    }

    try {
      // Optimistically add message to UI
      final tempMessage = ChatMessage(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: chatId,
        senderId: _currentUserId ?? 'current_user', // Use set user ID or fallback
        type: type,
        content: message,
        isRead: false,
        createdAt: DateTime.now(),
      );

      _chatMessages[chatId] = [...(_chatMessages[chatId] ?? []), tempMessage];
      notifyListeners();

      // Send via WebSocket for real-time delivery
      if (_isWebSocketConnected) {
        _webSocketService?.sendMessage(chatId, message, type: type);
      }

      // Also send via REST API for persistence
      final response = await ApiService.sendMessage(chatId, type: type, content: message);
      final sentMessageData = response['data'] ?? response;
      final sentMessage = ChatMessage.fromJson(sentMessageData);

      // Replace temp message with real message
      final messages = _chatMessages[chatId] ?? [];
      final tempIndex = messages.indexWhere((m) => m.id == tempMessage.id);
      if (tempIndex != -1) {
        messages[tempIndex] = sentMessage;
        _chatMessages[chatId] = messages;
      }

      // Update conversation's last message
      final convIndex = _conversations.indexWhere((c) => c.id == chatId);
      if (convIndex != -1) {
        _conversations[convIndex] = _conversations[convIndex].copyWith(
          lastMessage: sentMessage,
          updatedAt: DateTime.now(),
        );
      }

      _error = null;
      notifyListeners();
    } catch (e) {
      // Remove the temp message on error
      final messages = _chatMessages[chatId] ?? [];
      messages.removeWhere((m) => m.id.startsWith('temp_'));
      _chatMessages[chatId] = messages;
      
      _handleError(e, 'Failed to send message');
    }
  }

  Future<void> markMessageAsRead(String chatId, String messageId) async {
    try {
      await ApiService.markMessageAsRead(chatId, messageId);
      
      // Update local message status
      final messages = _chatMessages[chatId] ?? [];
      final messageIndex = messages.indexWhere((m) => m.id == messageId);
      if (messageIndex != -1) {
        messages[messageIndex] = messages[messageIndex].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
        _chatMessages[chatId] = messages;
        notifyListeners();
      }

      // Send read receipt via WebSocket
      _webSocketService?.markMessageAsRead(chatId, messageId);
    } catch (e) {
      // Read receipts are not critical, so don't show error to user
    }
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await ApiService.deleteMessage(chatId, messageId);
      
      // Remove message from local list
      final messages = _chatMessages[chatId] ?? [];
      messages.removeWhere((m) => m.id == messageId);
      _chatMessages[chatId] = messages;
      
      notifyListeners();
    } catch (e) {
      _handleError(e, 'Failed to delete message');
    }
  }

  void startTyping(String chatId) {
    _webSocketService?.sendTyping(chatId);
  }

  void stopTyping(String chatId) {
    _webSocketService?.sendStoppedTyping(chatId);
  }

  void leaveChatRoom(String chatId) {
    _webSocketService?.leaveChat(chatId);
  }

  // WebSocket event handlers
  void _handleNewMessage(Map<String, dynamic> data) {
    try {
      final message = ChatMessage.fromJson(data['message']);
      final chatId = message.conversationId;
      
      final messages = _chatMessages[chatId] ?? [];
      messages.add(message);
      _chatMessages[chatId] = messages;
      
      // Update conversation's last message
      final convIndex = _conversations.indexWhere((c) => c.id == chatId);
      if (convIndex != -1) {
        _conversations[convIndex] = _conversations[convIndex].copyWith(
          lastMessage: message,
          unreadCount: _conversations[convIndex].unreadCount + 1,
          updatedAt: DateTime.now(),
        );
      }
      
      notifyListeners();
    } catch (e) {
      // Handle error silently
    }
  }

  void _handleTypingUpdate(Map<String, dynamic> data) {
    try {
      final typingStatus = TypingStatus.fromJson(data);
      _typingStatuses[typingStatus.conversationId] = typingStatus;
      notifyListeners();
    } catch (e) {
      // Handle error silently
    }
  }

  void _handleReadReceipt(Map<String, dynamic> data) {
    try {
      final chatId = data['chatId'] as String;
      final messageId = data['messageId'] as String;
      
      final messages = _chatMessages[chatId] ?? [];
      final messageIndex = messages.indexWhere((m) => m.id == messageId);
      if (messageIndex != -1) {
        messages[messageIndex] = messages[messageIndex].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
        _chatMessages[chatId] = messages;
        notifyListeners();
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _handleChatExpired(Map<String, dynamic> data) {
    try {
      final chatId = data['chatId'] as String;
      
      // Remove from conversations or mark as expired
      _conversations.removeWhere((c) => c.id == chatId);
      _chatMessages.remove(chatId);
      _typingStatuses.remove(chatId);
      
      notifyListeners();
    } catch (e) {
      // Handle error silently
    }
  }

  void _handleConnectionUpdate(bool isConnected) {
    _isWebSocketConnected = isConnected;
    notifyListeners();
  }

  void clearExpiredChats() {
    final now = DateTime.now();
    final expiredChatIds = _conversations
        .where((conv) => conv.expiresAt != null && now.isAfter(conv.expiresAt!))
        .map((conv) => conv.id)
        .toList();

    for (final chatId in expiredChatIds) {
      _chatMessages.remove(chatId);
      _typingStatuses.remove(chatId);
    }
    
    _conversations.removeWhere((conv) => expiredChatIds.contains(conv.id));

    if (expiredChatIds.isNotEmpty) {
      notifyListeners();
    }
  }

  // Utility methods
  void _setLoading() {
    _isLoading = true;
    _error = null;
    if (AppConfig.isDevelopment) {
      print('ChatProvider: Setting loading state to true');
    }
    notifyListeners();
  }

  void _setLoaded() {
    _isLoading = false;
    if (AppConfig.isDevelopment) {
      print('ChatProvider: Setting loading state to false');
    }
    notifyListeners();
  }

  void _handleError(dynamic error, String fallbackMessage) {
    _isLoading = false;
    
    if (error is ApiException) {
      _error = error.message;
    } else {
      _error = fallbackMessage;
    }
    
    if (AppConfig.isDevelopment) {
      print('ChatProvider: Error occurred - $_error');
      print('Original error: $error');
    }
    
    notifyListeners();
  }

  @override
  void dispose() {
    _webSocketService?.dispose();
    super.dispose();
  }
}

// Extension to add copyWith method to Conversation
extension ConversationExtension on Conversation {
  Conversation copyWith({
    String? id,
    String? matchId,
    List<String>? participantIds,
    ChatMessage? lastMessage,
    int? unreadCount,
    String? status,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Profile? otherParticipant,
  }) {
    return Conversation(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      participantIds: participantIds ?? this.participantIds,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      status: status ?? this.status,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      otherParticipant: otherParticipant ?? this.otherParticipant,
    );
  }
}

// Extension to add copyWith method to ChatMessage
extension ChatMessageExtension on ChatMessage {
  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? type,
    String? content,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    User? sender,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      sender: sender ?? this.sender,
    );
  }
}