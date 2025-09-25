import 'user.dart';
import 'profile.dart';

class Conversation {
  final String id;
  final String matchId;
  final List<String> participantIds;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final String status;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Profile? otherParticipant;

  Conversation({
    required this.id,
    required this.matchId,
    required this.participantIds,
    this.lastMessage,
    required this.unreadCount,
    required this.status,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    this.otherParticipant,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      matchId: json['matchId'] as String,
      participantIds: (json['participantIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      lastMessage: json['lastMessage'] != null
          ? ChatMessage.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
      status: json['status'] as String,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      otherParticipant: json['otherParticipant'] != null
          ? Profile.fromJson(json['otherParticipant'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matchId': matchId,
      'participantIds': participantIds,
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'status': status,
      'expiresAt': expiresAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'otherParticipant': otherParticipant?.toJson(),
    };
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get hasUnreadMessages => unreadCount > 0;

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

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String type;
  final String content;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final User? sender;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.type,
    required this.content,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.sender,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      type: json['type'] as String,
      content: json['content'] as String,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
      sender: json['sender'] != null
          ? User.fromJson(json['sender'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'type': type,
      'content': content,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'sender': sender?.toJson(),
    };
  }

  bool get isTextMessage => type == 'text';
  bool get isImageMessage => type == 'image';
  bool get isSystemMessage => type == 'system';

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

class TypingStatus {
  final String userId;
  final String conversationId;
  final bool isTyping;
  final DateTime timestamp;

  TypingStatus({
    required this.userId,
    required this.conversationId,
    required this.isTyping,
    required this.timestamp,
  });

  factory TypingStatus.fromJson(Map<String, dynamic> json) {
    return TypingStatus(
      userId: json['userId'] as String,
      conversationId: json['conversationId'] as String,
      isTyping: json['isTyping'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'conversationId': conversationId,
      'isTyping': isTyping,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  bool get isRecent {
    final now = DateTime.now();
    return now.difference(timestamp).inSeconds < 5;
  }
}