import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goldwen_app/core/theme/app_theme.dart';
import 'package:goldwen_app/features/matching/pages/history_page.dart';
import 'package:goldwen_app/features/matching/providers/matching_provider.dart';
import 'package:goldwen_app/core/models/models.dart';

void main() {
  runApp(const HistoryDemoApp());
}

class HistoryDemoApp extends StatelessWidget {
  const HistoryDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MockMatchingProvider(),
      child: MaterialApp(
        title: 'History Demo',
        theme: AppTheme.lightTheme(),
        home: const HistoryPage(),
      ),
    );
  }
}

class MockMatchingProvider extends MatchingProvider {
  @override
  List<HistoryItem> get historyItems => _generateMockHistory();

  @override
  bool get hasMoreHistory => false;

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  List<HistoryItem> _generateMockHistory() {
    return [
      HistoryItem(
        date: '2024-01-15',
        choices: [
          HistoryChoice(
            targetUserId: 'user-1',
            targetUser: {
              'name': 'Sophie Martin',
              'photos': ['https://via.placeholder.com/300x300/D4AF37/FFFFFF?text=SM']
            },
            choice: 'like',
            chosenAt: DateTime.parse('2024-01-15T14:30:00Z'),
            isMatch: true,
          ),
          HistoryChoice(
            targetUserId: 'user-2',
            targetUser: {
              'name': 'Marc Dubois',
              'photos': ['https://via.placeholder.com/300x300/B8941F/FFFFFF?text=MD']
            },
            choice: 'pass',
            chosenAt: DateTime.parse('2024-01-15T15:45:00Z'),
            isMatch: false,
          ),
        ],
      ),
      HistoryItem(
        date: '2024-01-14',
        choices: [
          HistoryChoice(
            targetUserId: 'user-3',
            targetUser: {
              'name': 'Emma Laurent',
              'photos': ['https://via.placeholder.com/300x300/E8C547/FFFFFF?text=EL']
            },
            choice: 'like',
            chosenAt: DateTime.parse('2024-01-14T13:20:00Z'),
            isMatch: false,
          ),
        ],
      ),
      HistoryItem(
        date: '2024-01-13',
        choices: [
          HistoryChoice(
            targetUserId: 'user-4',
            targetUser: {
              'name': 'Julien Moreau',
              'photos': ['https://via.placeholder.com/300x300/F5E6B8/1A1A1A?text=JM']
            },
            choice: 'like',
            chosenAt: DateTime.parse('2024-01-13T16:10:00Z'),
            isMatch: true,
          ),
          HistoryChoice(
            targetUserId: 'user-5',
            targetUser: {
              'name': 'Claire Petit',
              'photos': ['https://via.placeholder.com/300x300/FAF0E6/1A1A1A?text=CP']
            },
            choice: 'like',
            chosenAt: DateTime.parse('2024-01-13T17:30:00Z'),
            isMatch: false,
          ),
        ],
      ),
    ];
  }

  @override
  Future<void> loadHistory({
    int page = 1,
    int limit = 20,
    String? startDate,
    String? endDate,
    bool refresh = false,
  }) async {
    // Mock implementation - no actual API call
    notifyListeners();
  }
}