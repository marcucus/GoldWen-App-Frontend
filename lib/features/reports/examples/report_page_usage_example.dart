import 'package:flutter/material.dart';
import '../pages/report_page.dart';

/// Example showing how to use the ReportPage
/// 
/// The ReportPage can be used to report either a user profile or a message.
/// It implements:
/// - Report form with 4 categories (Inappropriate Content, Harassment, Spam, Other)
/// - Optional description field (max 500 characters)
/// - Local duplicate prevention using SharedPreferences
/// - Backend duplicate prevention handling
/// - Success/error feedback
/// 
/// Usage examples:

class ReportPageExample {
  /// Example 1: Report a user profile from their detail page
  static void reportUserProfile(
    BuildContext context, {
    required String userId,
    required String userName,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportPage(
          targetUserId: userId,
          targetUserName: userName,
        ),
      ),
    );
  }

  /// Example 2: Report a message from chat
  static void reportMessage(
    BuildContext context, {
    required String userId,
    required String userName,
    required String messageId,
    String? chatId,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportPage(
          targetUserId: userId,
          targetUserName: userName,
          messageId: messageId,
          chatId: chatId,
        ),
      ),
    );
  }

  /// Example 3: Report with result handling
  static Future<void> reportWithResultHandling(
    BuildContext context, {
    required String userId,
    required String userName,
  }) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ReportPage(
          targetUserId: userId,
          targetUserName: userName,
        ),
      ),
    );

    // Result is true if report was successfully submitted
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Merci pour votre signalement'),
        ),
      );
    }
  }

  /// Example 4: Show report option in a bottom sheet menu
  static void showReportOption(
    BuildContext context, {
    required String userId,
    required String userName,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.report, color: Colors.red),
              title: const Text('Signaler ce profil'),
              onTap: () {
                Navigator.pop(context);
                reportUserProfile(
                  context,
                  userId: userId,
                  userName: userName,
                );
              },
            ),
            // Add other menu items here
          ],
        ),
      ),
    );
  }
}

/// Integration with existing ReportDialog
/// 
/// If you prefer to use the existing ReportDialog (dialog style) instead of
/// the new ReportPage (full page), you can still use it:
/// 
/// ```dart
/// import '../../matching/widgets/report_dialog.dart';
/// 
/// showDialog(
///   context: context,
///   builder: (context) => ReportDialog(
///     targetUserId: userId,
///     targetUserName: userName,
///     messageId: messageId, // optional
///     chatId: chatId,       // optional
///   ),
/// );
/// ```
/// 
/// Key differences:
/// - ReportDialog: Quick modal dialog, good for in-context reporting
/// - ReportPage: Full page with more space, better for detailed reporting
