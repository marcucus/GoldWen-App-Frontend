import 'package:flutter/material.dart';

class Chat {
  final String id;
  final String? matchName;
  final String? lastMessage;
  final int unreadCount;
  final DateTime? lastActivity;

  Chat({
    required this.id,
    this.matchName,
    this.lastMessage,
    this.unreadCount = 0,
    this.lastActivity,
  });
}

class ChatProvider with ChangeNotifier {
  Map<String, List<Map<String, dynamic>>> _chatMessages = {};
  Map<String, DateTime> _chatExpiryTimes = {};
  List<Chat> _chats = [];
  bool _isLoading = false;

  Map<String, List<Map<String, dynamic>>> get chatMessages => _chatMessages;
  Map<String, DateTime> get chatExpiryTimes => _chatExpiryTimes;
  List<Chat> get chats => _chats;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> getChatMessages(String chatId) {
    return _chatMessages[chatId] ?? [];
  }

  DateTime? getChatExpiryTime(String chatId) {
    return _chatExpiryTimes[chatId];
  }

  bool isChatExpired(String chatId) {
    final expiryTime = _chatExpiryTimes[chatId];
    if (expiryTime == null) return false;
    return DateTime.now().isAfter(expiryTime);
  }

  Duration? getRemainingTime(String chatId) {
    final expiryTime = _chatExpiryTimes[chatId];
    if (expiryTime == null) return null;
    
    final now = DateTime.now();
    if (now.isAfter(expiryTime)) return Duration.zero;
    
    return expiryTime.difference(now);
  }

  Duration? getChatRemainingTime(String chatId) {
    return getRemainingTime(chatId);
  }

  Future<void> loadChats() async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Implement API call to load chats
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock data
      _chats = [
        Chat(
          id: 'chat1',
          matchName: 'Alice',
          lastMessage: 'Hello! How are you?',
          unreadCount: 2,
          lastActivity: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
        Chat(
          id: 'chat2',
          matchName: 'Bob',
          lastMessage: 'Nice to meet you!',
          unreadCount: 0,
          lastActivity: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ];
      
      // Set expiry times for chats
      for (final chat in _chats) {
        _chatExpiryTimes[chat.id] = DateTime.now().add(const Duration(hours: 24));
      }
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createChat(String chatId, String otherUserId) async {
    try {
      // TODO: Implement API call to create chat
      await Future.delayed(const Duration(seconds: 1));
      
      _chatMessages[chatId] = [];
      _chatExpiryTimes[chatId] = DateTime.now().add(const Duration(hours: 24));
      
      // Add to chats list
      _chats.add(Chat(
        id: chatId,
        matchName: 'New Match',
        lastMessage: 'New match!',
        unreadCount: 0,
        lastActivity: DateTime.now(),
      ));
      
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> sendMessage(String chatId, String message) async {
    if (isChatExpired(chatId)) return;

    try {
      // TODO: Implement API call to send message
      await Future.delayed(const Duration(milliseconds: 500));
      
      final messageData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'text': message,
        'senderId': 'current_user', // TODO: Get from auth provider
        'timestamp': DateTime.now(),
        'isFromCurrentUser': true,
      };

      _chatMessages[chatId] = [...(_chatMessages[chatId] ?? []), messageData];
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> loadChatMessages(String chatId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Implement API call to load messages
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock data
      if (!_chatMessages.containsKey(chatId)) {
        _chatMessages[chatId] = [
          {
            'id': '1',
            'text': 'Hi! Great to match with you!',
            'senderId': 'other_user',
            'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
            'isFromCurrentUser': false,
          },
          {
            'id': '2',
            'text': 'Hello! Nice to meet you too!',
            'senderId': 'current_user',
            'timestamp': DateTime.now().subtract(const Duration(hours: 1)),
            'isFromCurrentUser': true,
          },
        ];
        _chatExpiryTimes[chatId] = DateTime.now().add(const Duration(hours: 22));
      }
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearExpiredChats() {
    final now = DateTime.now();
    final expiredChatIds = _chatExpiryTimes.entries
        .where((entry) => now.isAfter(entry.value))
        .map((entry) => entry.key)
        .toList();

    for (final chatId in expiredChatIds) {
      _chatMessages.remove(chatId);
      _chatExpiryTimes.remove(chatId);
      _chats.removeWhere((chat) => chat.id == chatId);
    }

    if (expiredChatIds.isNotEmpty) {
      notifyListeners();
    }
  }
}