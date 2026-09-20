import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/local_notification_service.dart';
import '../../../core/models/models.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/e2e_message_crypto_service.dart';
import '../../../core/services/e2e_key_service.dart';

class ChatProvider with ChangeNotifier {
  List<Conversation> _conversations = [];
  final Map<String, List<ChatMessage>> _chatMessages = {};
  final Map<String, TypingStatus> _typingStatuses = {};
  final Map<String, OnlineStatus> _onlineStatuses = {};
  bool _isLoading = false;
  String? _error;
  WebSocketService? _webSocketService;
  bool _isWebSocketConnected = false;
  String? _currentUserId;
  String? _connectedToken;
  Timer? _typingTimer;
  String? _currentTypingChatId;
  final Map<String, Timer?> _expirationCheckTimers = {};
  final LocalNotificationService _notificationService =
      LocalNotificationService();

  List<Conversation> get conversations => _conversations;
  Map<String, List<ChatMessage>> get chatMessages => _chatMessages;
  Map<String, TypingStatus> get typingStatuses => _typingStatuses;
  Map<String, OnlineStatus> get onlineStatuses => _onlineStatuses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isWebSocketConnected => _isWebSocketConnected;

  /// Get only active (non-expired) conversations
  List<Conversation> get activeConversations {
    return _conversations.where((conv) => !conv.isExpired).toList();
  }

  /// Get only archived (expired) conversations
  List<Conversation> get archivedConversations {
    return _conversations.where((conv) => conv.isExpired).toList();
  }

  ChatProvider() {
    _initializeWebSocket();
  }

  void setCurrentUserId(String userId) {
    _currentUserId = userId;
  }

  /// Keeps the real-time connection aligned with the authenticated session.
  /// MultiProvider calls this whenever AuthProvider changes; repeated rebuilds
  /// with the same credentials are intentionally no-ops.
  void updateSession(String? token, String? userId) {
    if (token == null || userId == null) {
      _connectedToken = null;
      _currentUserId = null;
      _webSocketService?.disconnect();
      _isWebSocketConnected = false;
      return;
    }
    if (_connectedToken == token && _currentUserId == userId) return;
    _connectedToken = token;
    _currentUserId = userId;
    unawaited(initializeWebSocket(token));
    // AV-15 / V106 : s'assure que la clé publique X25519 de cet appareil est
    // bien connue du serveur dès qu'une session authentifiée est active,
    // pour que les autres participants puissent chiffrer leurs messages vers
    // cet utilisateur. Best-effort, voir E2eKeyService.ensurePublicKeyUploaded.
    unawaited(E2eKeyService.instance.ensurePublicKeyUploaded());
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

  OnlineStatus? getOnlineStatus(String userId) {
    return _onlineStatuses[userId];
  }

  bool isUserTyping(String chatId, String userId) {
    final status = getTypingStatus(chatId);
    return status?.userId == userId &&
        status?.isTyping == true &&
        status!.isRecent;
  }

  bool isUserOnline(String userId) {
    final status = getOnlineStatus(userId);
    return status?.isOnline ?? false;
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
      _webSocketService!.onlineStatusStream.listen(_handleOnlineStatusUpdate);
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
        debugPrint('ChatProvider: Starting to load conversations...');
      }

      final response = await ApiService.getConversations();

      final conversationsData =
          response['data'] ?? response['conversations'] ?? [];

      if (AppConfig.isDevelopment) {
        debugPrint(
            'ChatProvider: Processing ${(conversationsData as List).length} conversations');
      }

      _conversations = [];

      // Parse conversations one by one to handle individual parsing errors
      for (final conversationJson in (conversationsData as List)) {
        try {
          final conversation =
              Conversation.fromJson(conversationJson as Map<String, dynamic>);
          _conversations.add(conversation);
        } catch (e) {
          // Log parsing error but continue with other conversations
          if (AppConfig.isDevelopment) {
            debugPrint('Error parsing conversation: $e');
          }
          // Skip this conversation and continue with others
        }
      }

      if (AppConfig.isDevelopment) {
        debugPrint(
            'ChatProvider: Successfully parsed ${_conversations.length} conversations');
      }

      // Schedule expiration notifications for all active conversations
      scheduleAllExpirationNotifications();

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

  Future<void> loadChatMessages(String chatId,
      {int page = 1, int limit = 50}) async {
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
          final message =
              ChatMessage.fromJson(messageJson as Map<String, dynamic>);
          newMessages.add(message);
        } catch (e) {
          // Log parsing error but continue with other messages
          if (AppConfig.isDevelopment) {
            debugPrint('Error parsing message: $e');
          }
          // Skip this message and continue with others
        }
      }

      // AV-15 / V106 : déchiffrement de bout en bout. La clé publique de
      // l'autre participant est la même pour toute la conversation, quel que
      // soit l'expéditeur d'un message donné (ECDH est symétrique) — pas
      // besoin de la connaître par message. Si la conversation n'est pas
      // encore en cache (accès direct au chat sans être passé par la liste),
      // on va la chercher : sans ça on ne pourrait pas distinguer un message
      // en clair (ancien) d'un ciphertext qu'on affiche par erreur tel quel.
      final peerPublicKey = await _peerPublicKeyFor(chatId);
      final decryptedNewMessages = await Future.wait(
        newMessages.map((m) => _decryptIfNeeded(m, peerPublicKey)),
      );

      if (page == 1) {
        _chatMessages[chatId] = decryptedNewMessages;
      } else {
        _chatMessages[chatId] = [
          ...(_chatMessages[chatId] ?? []),
          ...decryptedNewMessages
        ];
      }

      // Join the chat room for real-time updates
      _webSocketService?.joinChat(chatId);

      // Schedule expiration notification for this chat
      _scheduleExpirationNotification(chatId);

      _error = null;
      notifyListeners();
    } catch (e) {
      _handleError(e, 'Failed to load messages');
    } finally {
      if (page == 1) _setLoaded();
    }
  }

  Future<void> sendMessage(String chatId, String message,
      {String type = 'text'}) async {
    if (isChatExpired(chatId)) {
      _error = 'Cannot send message to expired chat';
      notifyListeners();
      return;
    }

    try {
      // Check if this is the first message in the conversation
      final isFirstMessage = (_chatMessages[chatId]?.isEmpty ?? true);

      // Optimistically add message to UI. `decryptedContent` carries the
      // plaintext the user just typed so it displays immediately, while the
      // wire payload (see below) is what actually gets encrypted and sent —
      // the two are deliberately different here (AV-15 / V106).
      final tempMessage = ChatMessage(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: chatId,
        senderId:
            _currentUserId ?? 'current_user', // Use set user ID or fallback
        type: type,
        content: message,
        decryptedContent: message,
        isRead: false,
        createdAt: DateTime.now(),
      );

      _chatMessages[chatId] = [...(_chatMessages[chatId] ?? []), tempMessage];
      notifyListeners();

      // AV-15 / V106 : le contenu réellement envoyé sur le fil (Socket.IO ou
      // REST) est chiffré de bout en bout quand la clé de l'interlocuteur est
      // connue ; seul ce blob opaque atteint le serveur.
      final wireContent =
          type == 'text' ? await _encryptForChat(chatId, message) : message;

      // Socket.IO persists and broadcasts the message. REST is a fallback
      // only: doing both used to create two database rows per message.
      final Map<String, dynamic> sentMessageData;
      if (_isWebSocketConnected && _webSocketService != null) {
        sentMessageData = await _webSocketService!
            .sendMessage(chatId, wireContent, type: type);
      } else {
        final response = await ApiService.sendMessage(chatId,
            type: type, content: wireContent);
        sentMessageData = Map<String, dynamic>.from(
          (response['data'] ?? response) as Map,
        );
      }
      // `sentMessageData['content']` is the ciphertext echoed back by the
      // server ; we already know the plaintext we just encrypted, no need to
      // decrypt what we ourselves just produced.
      final sentMessage =
          ChatMessage.fromJson(sentMessageData).copyWith(decryptedContent: message);

      // Track analytics
      if (isFirstMessage) {
        await AnalyticsService.trackFirstMessageSent(chatId);
      }
      await AnalyticsService.trackMessageSent(chatId,
          messageLength: message.length);

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

  Future<void> markMessagesAsRead(String chatId) async {
    try {
      await ApiService.markMessagesAsRead(chatId);

      // Update local message status
      final messages = _chatMessages[chatId] ?? [];
      final updatedMessages = messages.map((message) {
        if (!message.isRead) {
          return message.copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
        }
        return message;
      }).toList();

      _chatMessages[chatId] = updatedMessages;
      notifyListeners();

      // Send read receipt via WebSocket
      // Note: markMessagesAsRead method needs to be implemented in WebSocketService
      // _webSocketService?.markMessagesAsRead(chatId);
    } catch (e) {
      // Read receipts are not critical, so don't show error to user
    }
  }

  Future<String?> getChatIdFromMatch(String matchId) async {
    try {
      final response = await ApiService.getChatByMatchId(matchId);
      final chatData = response['data'] ?? response;

      if (chatData != null && chatData['id'] != null) {
        return chatData['id'] as String;
      }
      return null;
    } catch (e) {
      // Chat may not exist yet, which is normal
      return null;
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await ApiService.deleteMessage(messageId);

      // Remove message from all chats (since we only have the messageId)
      for (final chatId in _chatMessages.keys) {
        final messages = _chatMessages[chatId] ?? [];
        messages.removeWhere((m) => m.id == messageId);
        _chatMessages[chatId] = messages;
      }

      notifyListeners();
    } catch (e) {
      _handleError(e, 'Failed to delete message');
    }
  }

  void startTyping(String chatId) {
    // Cancel existing timer if user is typing again
    _typingTimer?.cancel();

    // Send typing start event only if this is a new chat or different from current
    if (_currentTypingChatId != chatId) {
      _webSocketService?.sendTyping(chatId);
      _currentTypingChatId = chatId;
    }

    // Set timeout to auto-stop typing after 3 seconds
    _typingTimer = Timer(const Duration(seconds: 3), () {
      stopTyping(chatId);
    });
  }

  void stopTyping(String chatId) {
    _typingTimer?.cancel();
    _webSocketService?.sendStoppedTyping(chatId);
    _currentTypingChatId = null;
  }

  void leaveChatRoom(String chatId) {
    _webSocketService?.leaveChat(chatId);
  }

  /// Clé publique (base64) de l'autre participant d'une conversation,
  /// nécessaire au chiffrement/déchiffrement E2E (AV-15 / V106). Utilise le
  /// cache `_conversations` s'il est déjà chargé ; sinon va chercher les
  /// détails de la conversation une fois (ex: ouverture directe d'un chat
  /// via une notification, sans être passé par la liste des conversations).
  Future<String?> _peerPublicKeyFor(String chatId) async {
    final cached = getConversation(chatId);
    if (cached != null) {
      return cached.otherParticipantPublicKey;
    }
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
      return conversation.otherParticipantPublicKey;
    } catch (_) {
      // Pas de clé trouvable : le message restera affiché tel quel s'il est
      // en clair, ou signalé "illisible" s'il s'avère être du ciphertext
      // (voir _decryptIfNeeded) — jamais de ciphertext brut affiché en clair.
      return null;
    }
  }

  /// Déchiffre [message] si c'est un message texte et qu'on a la clé
  /// publique de l'interlocuteur. Ne modifie jamais `content` (valeur brute
  /// telle que reçue du serveur) : le résultat va dans `decryptedContent`
  /// (succès) ou `decryptionFailed` (échec), pour que l'UI affiche l'un ou
  /// l'autre via `ChatMessage.displayContent` — jamais le ciphertext tel
  /// quel. Un message sans clé disponible reste affiché tel quel : c'est le
  /// cas normal d'un message envoyé avant que le chiffrement soit possible
  /// pour cette paire (voir E2eMessageCryptoService, limite assumée).
  Future<ChatMessage> _decryptIfNeeded(
    ChatMessage message,
    String? peerPublicKey,
  ) async {
    if (!message.isTextMessage ||
        peerPublicKey == null ||
        peerPublicKey.isEmpty) {
      return message;
    }
    final plainText = await E2eMessageCryptoService.instance.decryptMessage(
      content: message.content,
      peerPublicKeyBase64: peerPublicKey,
    );
    if (plainText != null) {
      return message.copyWith(decryptedContent: plainText);
    }
    // Ambigu par nature : soit un vrai échec de déchiffrement (clé qui a
    // changé, corruption), soit un message en clair envoyé avant l'E2E pour
    // cette conversation. On ne peut pas distinguer les deux de façon fiable
    // sans marqueur de version en base ; on assume l'échec plutôt que
    // d'afficher silencieusement une valeur qui pourrait être du
    // ciphertext — cohérent avec la doc de E2eMessageCryptoService.decryptMessage.
    return message.copyWith(decryptionFailed: true);
  }

  /// Chiffre [plainText] pour la conversation [chatId] si l'interlocuteur a
  /// déjà une clé publique connue ; sinon renvoie le texte en clair tel quel
  /// (dégradation assumée : ce message précis ne pourra pas être chiffré,
  /// voir E2eKeyService). N'échoue jamais : un problème de chiffrement ne
  /// doit pas empêcher l'envoi du message.
  Future<String> _encryptForChat(String chatId, String plainText) async {
    final peerPublicKey = await _peerPublicKeyFor(chatId);
    if (peerPublicKey == null || peerPublicKey.isEmpty) {
      return plainText;
    }
    try {
      return await E2eMessageCryptoService.instance.encryptMessage(
        plainText: plainText,
        peerPublicKeyBase64: peerPublicKey,
      );
    } catch (_) {
      return plainText;
    }
  }

  // WebSocket event handlers
  void _handleNewMessage(Map<String, dynamic> data) {
    try {
      final message = ChatMessage.fromJson(data['message']);
      final chatId = message.conversationId;

      // The gateway broadcasts `new_message` to every socket in the room,
      // including the sender's own — our own messages are already added
      // optimistically and reconciled from the REST response in
      // sendMessage(), so skip that echo (and any event we've already
      // recorded) rather than duplicating the bubble.
      final messages = _chatMessages[chatId] ?? [];
      final isOwnMessage =
          _currentUserId != null && message.senderId == _currentUserId;
      final alreadyKnown = messages.any((m) => m.id == message.id);
      if (isOwnMessage || alreadyKnown) {
        return;
      }

      // AV-15 / V106 : `content` reçu ici est le ciphertext (ou du texte en
      // clair pour un message pré-E2E) — déchiffrement asynchrone avant
      // d'ajouter le message à l'écran, jamais d'affichage du ciphertext brut
      // le temps de l'attente.
      unawaited(_peerPublicKeyFor(chatId).then((peerPublicKey) async {
        final decrypted = await _decryptIfNeeded(message, peerPublicKey);
        final current = _chatMessages[chatId] ?? [];
        if (current.any((m) => m.id == decrypted.id)) {
          return; // reçu deux fois pendant le déchiffrement (rare)
        }
        current.add(decrypted);
        _chatMessages[chatId] = current;

        // Update conversation's last message
        final convIndex = _conversations.indexWhere((c) => c.id == chatId);
        if (convIndex != -1) {
          _conversations[convIndex] = _conversations[convIndex].copyWith(
            lastMessage: decrypted,
            unreadCount: _conversations[convIndex].unreadCount + 1,
            updatedAt: DateTime.now(),
          );
        }

        notifyListeners();
      }));
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

  void _handleOnlineStatusUpdate(Map<String, dynamic> data) {
    try {
      final onlineStatus = OnlineStatus.fromJson(data);
      _onlineStatuses[onlineStatus.userId] = onlineStatus;
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

      // Track chat expiration
      final messageCount = _chatMessages[chatId]?.length ?? 0;
      AnalyticsService.trackChatExpired(chatId, messageCount);

      // Add system message before marking as expired
      _addSystemMessage(chatId, 'Cette conversation a expiré');

      // Mark conversation as expired instead of removing
      final conversationIndex =
          _conversations.indexWhere((c) => c.id == chatId);
      if (conversationIndex != -1) {
        // Keep the conversation but mark it as expired through the model
        // The Conversation model already has isExpired getter
      }

      _typingStatuses.remove(chatId);

      notifyListeners();
    } catch (e) {
      // Handle error silently
    }
  }

  void _addSystemMessage(String chatId, String content) {
    final systemMessage = ChatMessage(
      id: 'system_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: chatId,
      senderId: 'system',
      type: 'system',
      content: content,
      isRead: true,
      createdAt: DateTime.now(),
    );

    if (_chatMessages[chatId] == null) {
      _chatMessages[chatId] = [];
    }
    _chatMessages[chatId]!.add(systemMessage);
  }

  void _handleConnectionUpdate(bool isConnected) {
    _isWebSocketConnected = isConnected;
    notifyListeners();
  }

  void clearExpiredChats() {
    final now = DateTime.now();
    final expiredConversations = _conversations
        .where((conv) => conv.expiresAt != null && now.isAfter(conv.expiresAt!))
        .toList();

    for (final conversation in expiredConversations) {
      // Add system message before marking as expired
      _addSystemMessage(conversation.id, 'Cette conversation a expiré');

      // Remove typing status but keep messages for reference
      _typingStatuses.remove(conversation.id);

      // Cancel any pending expiration notifications
      _cancelExpirationNotification(conversation.id);
    }

    if (expiredConversations.isNotEmpty) {
      notifyListeners();
    }
  }

  /// Schedule a notification 2 hours before chat expiration
  void _scheduleExpirationNotification(String chatId) {
    final conversation = getConversation(chatId);
    if (conversation?.expiresAt == null) return;

    final now = DateTime.now();
    final expiresAt = conversation!.expiresAt!;
    final notificationTime = expiresAt.subtract(const Duration(hours: 2));

    // Don't schedule if notification time has already passed
    if (notificationTime.isBefore(now)) return;

    // Don't schedule if less than 2 hours remain
    if (expiresAt.difference(now).inHours < 2) return;

    // Cancel any existing timer for this chat
    _cancelExpirationNotification(chatId);

    // Schedule the notification
    final delay = notificationTime.difference(now);
    _expirationCheckTimers[chatId] = Timer(delay, () {
      final partnerName =
          conversation.otherParticipant?.firstName ?? 'votre contact';
      _notificationService.showChatExpiringNotification(
        partnerName: partnerName,
        hoursLeft: 2,
      );
    });
  }

  /// Cancel expiration notification for a specific chat
  void _cancelExpirationNotification(String chatId) {
    _expirationCheckTimers[chatId]?.cancel();
    _expirationCheckTimers.remove(chatId);
  }

  /// Check and schedule expiration notifications for all active conversations
  void scheduleAllExpirationNotifications() {
    for (final conversation in _conversations) {
      if (!conversation.isExpired && conversation.expiresAt != null) {
        _scheduleExpirationNotification(conversation.id);
      }
    }
  }

  // Utility methods
  void _setLoading() {
    _isLoading = true;
    _error = null;
    if (AppConfig.isDevelopment) {
      debugPrint('ChatProvider: Setting loading state to true');
    }
    notifyListeners();
  }

  void _setLoaded() {
    _isLoading = false;
    if (AppConfig.isDevelopment) {
      debugPrint('ChatProvider: Setting loading state to false');
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
      debugPrint('ChatProvider: Error occurred - $_error');
      debugPrint('Original error: $error');
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _webSocketService?.dispose();
    // Cancel all expiration notification timers
    for (final timer in _expirationCheckTimers.values) {
      timer?.cancel();
    }
    _expirationCheckTimers.clear();
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
