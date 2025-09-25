import 'package:flutter/material.dart';
import 'package:goldwen_app/features/chat/widgets/chat_countdown_timer.dart';
import 'package:goldwen_app/features/chat/widgets/match_acceptance_dialog.dart';
import 'package:goldwen_app/core/theme/app_theme.dart';

void main() {
  runApp(const ChatSystemDemoApp());
}

class ChatSystemDemoApp extends StatelessWidget {
  const ChatSystemDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat System Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryGold),
        useMaterial3: true,
      ),
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatelessWidget {
  const DemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat System - 24h Expiration & Match Acceptance'),
        backgroundColor: AppColors.primaryGold,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chat Countdown Timer Examples:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Active chat with 12 hours remaining
            Row(
              children: [
                const Text('Active (12h remaining): '),
                ChatCountdownTimer(
                  expiresAt: DateTime.now().add(const Duration(hours: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Warning chat with 3 hours remaining
            Row(
              children: [
                const Text('Warning (3h remaining): '),
                ChatCountdownTimer(
                  expiresAt: DateTime.now().add(const Duration(hours: 3)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Critical chat with 1 hour remaining
            Row(
              children: [
                const Text('Critical (1h remaining): '),
                ChatCountdownTimer(
                  expiresAt: DateTime.now().add(const Duration(hours: 1)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Expired chat
            Row(
              children: [
                const Text('Expired: '),
                ChatCountdownTimer(
                  expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Match acceptance dialog demo
            const Text(
              'Match Acceptance:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const MatchAcceptanceDialog(
                    matchId: 'demo-match-id',
                    otherUser: null, // Would normally have Profile object
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: Colors.white,
              ),
              child: const Text('Show Match Acceptance Dialog'),
            ),
            
            const SizedBox(height: 32),
            
            const Text(
              'Features Implemented:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            const Text('✅ API endpoints updated to match backend'),
            const Text('✅ 24-hour countdown timer with color coding'),
            const Text('✅ Match acceptance dialog with proper flow'),
            const Text('✅ Automatic chat expiration with system messages'),
            const Text('✅ Disabled message input for expired chats'),
            const Text('✅ Real-time WebSocket integration'),
            const Text('✅ Comprehensive error handling'),
          ],
        ),
      ),
    );
  }
}