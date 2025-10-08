import 'package:flutter/material.dart';

/// Represents different types of transactional emails
enum EmailType {
  welcome,
  dataExport,
  accountDeleted,
  subscriptionConfirmed,
  passwordReset,
  other,
}

/// Represents the delivery status of an email
enum EmailStatus {
  pending,
  sent,
  delivered,
  failed,
  bounced,
}

/// Model for transactional email notifications
class EmailNotification {
  final String id;
  final String userId;
  final EmailType type;
  final String recipient;
  final String subject;
  final EmailStatus status;
  final DateTime createdAt;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;
  final bool canRetry;

  EmailNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.recipient,
    required this.subject,
    required this.status,
    required this.createdAt,
    this.sentAt,
    this.deliveredAt,
    this.errorMessage,
    this.metadata,
    this.canRetry = false,
  });

  factory EmailNotification.fromJson(Map<String, dynamic> json) {
    return EmailNotification(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: _parseEmailType(json['type'] as String),
      recipient: json['recipient'] as String,
      subject: json['subject'] as String,
      status: _parseEmailStatus(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      sentAt: json['sentAt'] != null 
          ? DateTime.parse(json['sentAt'] as String)
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'] as String)
          : null,
      errorMessage: json['errorMessage'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      canRetry: json['canRetry'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': _emailTypeToString(type),
      'recipient': recipient,
      'subject': subject,
      'status': _emailStatusToString(status),
      'createdAt': createdAt.toIso8601String(),
      'sentAt': sentAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'errorMessage': errorMessage,
      'metadata': metadata,
      'canRetry': canRetry,
    };
  }

  static EmailType _parseEmailType(String type) {
    switch (type.toLowerCase()) {
      case 'welcome':
        return EmailType.welcome;
      case 'data_export':
      case 'dataexport':
        return EmailType.dataExport;
      case 'account_deleted':
      case 'accountdeleted':
        return EmailType.accountDeleted;
      case 'subscription_confirmed':
      case 'subscriptionconfirmed':
        return EmailType.subscriptionConfirmed;
      case 'password_reset':
      case 'passwordreset':
        return EmailType.passwordReset;
      default:
        return EmailType.other;
    }
  }

  static String _emailTypeToString(EmailType type) {
    switch (type) {
      case EmailType.welcome:
        return 'welcome';
      case EmailType.dataExport:
        return 'data_export';
      case EmailType.accountDeleted:
        return 'account_deleted';
      case EmailType.subscriptionConfirmed:
        return 'subscription_confirmed';
      case EmailType.passwordReset:
        return 'password_reset';
      case EmailType.other:
        return 'other';
    }
  }

  static EmailStatus _parseEmailStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return EmailStatus.pending;
      case 'sent':
        return EmailStatus.sent;
      case 'delivered':
        return EmailStatus.delivered;
      case 'failed':
        return EmailStatus.failed;
      case 'bounced':
        return EmailStatus.bounced;
      default:
        return EmailStatus.pending;
    }
  }

  static String _emailStatusToString(EmailStatus status) {
    switch (status) {
      case EmailStatus.pending:
        return 'pending';
      case EmailStatus.sent:
        return 'sent';
      case EmailStatus.delivered:
        return 'delivered';
      case EmailStatus.failed:
        return 'failed';
      case EmailStatus.bounced:
        return 'bounced';
    }
  }

  String get typeName {
    switch (type) {
      case EmailType.welcome:
        return 'Welcome Email';
      case EmailType.dataExport:
        return 'Data Export Ready';
      case EmailType.accountDeleted:
        return 'Account Deleted';
      case EmailType.subscriptionConfirmed:
        return 'Subscription Confirmed';
      case EmailType.passwordReset:
        return 'Password Reset';
      case EmailType.other:
        return 'Other';
    }
  }

  String get statusName {
    switch (status) {
      case EmailStatus.pending:
        return 'Pending';
      case EmailStatus.sent:
        return 'Sent';
      case EmailStatus.delivered:
        return 'Delivered';
      case EmailStatus.failed:
        return 'Failed';
      case EmailStatus.bounced:
        return 'Bounced';
    }
  }

  Color get statusColor {
    switch (status) {
      case EmailStatus.pending:
        return Colors.orange;
      case EmailStatus.sent:
        return Colors.blue;
      case EmailStatus.delivered:
        return Colors.green;
      case EmailStatus.failed:
        return Colors.red;
      case EmailStatus.bounced:
        return Colors.red.shade700;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case EmailStatus.pending:
        return Icons.schedule;
      case EmailStatus.sent:
        return Icons.send;
      case EmailStatus.delivered:
        return Icons.check_circle;
      case EmailStatus.failed:
        return Icons.error;
      case EmailStatus.bounced:
        return Icons.cancel;
    }
  }

  IconData get typeIcon {
    switch (type) {
      case EmailType.welcome:
        return Icons.waving_hand;
      case EmailType.dataExport:
        return Icons.download;
      case EmailType.accountDeleted:
        return Icons.delete_forever;
      case EmailType.subscriptionConfirmed:
        return Icons.card_membership;
      case EmailType.passwordReset:
        return Icons.lock_reset;
      case EmailType.other:
        return Icons.email;
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  bool get hasError => status == EmailStatus.failed || status == EmailStatus.bounced;
  bool get isSuccessful => status == EmailStatus.delivered;
  bool get isPending => status == EmailStatus.pending || status == EmailStatus.sent;

  EmailNotification copyWith({
    String? id,
    String? userId,
    EmailType? type,
    String? recipient,
    String? subject,
    EmailStatus? status,
    DateTime? createdAt,
    DateTime? sentAt,
    DateTime? deliveredAt,
    String? errorMessage,
    Map<String, dynamic>? metadata,
    bool? canRetry,
  }) {
    return EmailNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      recipient: recipient ?? this.recipient,
      subject: subject ?? this.subject,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      sentAt: sentAt ?? this.sentAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata ?? this.metadata,
      canRetry: canRetry ?? this.canRetry,
    );
  }
}
