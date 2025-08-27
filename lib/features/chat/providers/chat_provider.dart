import 'package:flutter/material.dart';

class ChatProvider with ChangeNotifier {
  Map<String, List<Map<String, dynamic>>> _chats = {};
  Map<String, DateTime> _chatExpiryTimes = {};
  bool _isLoading = false;

  Map<String, List<Map<String, dynamic>>> get chats => _chats;
  Map<String, DateTime> get chatExpiryTimes => _chatExpiryTimes;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> getChatMessages(String chatId) {
    return _chats[chatId] ?? [];
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

  Future<void> createChat(String chatId, String otherUserId) async {
    try {
      // TODO: Implement API call to create chat
      await Future.delayed(const Duration(seconds: 1));
      
      _chats[chatId] = [];
      _chatExpiryTimes[chatId] = DateTime.now().add(const Duration(hours: 24));
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

      _chats[chatId] = [...(_chats[chatId] ?? []), messageData];
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
      if (!_chats.containsKey(chatId)) {
        _chats[chatId] = [
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
      _chats.remove(chatId);
      _chatExpiryTimes.remove(chatId);
    }

    if (expiredChatIds.isNotEmpty) {
      notifyListeners();
    }
  }
}