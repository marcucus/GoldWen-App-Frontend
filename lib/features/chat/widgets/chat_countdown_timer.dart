import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ChatCountdownTimer extends StatefulWidget {
  final DateTime expiresAt;
  final VoidCallback? onExpired;

  const ChatCountdownTimer({
    super.key,
    required this.expiresAt,
    this.onExpired,
  });

  @override
  State<ChatCountdownTimer> createState() => _ChatCountdownTimerState();
}

class _ChatCountdownTimerState extends State<ChatCountdownTimer> {
  Timer? _timer;
  Duration? _remaining;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final now = DateTime.now();
    if (now.isBefore(widget.expiresAt)) {
      setState(() {
        _remaining = widget.expiresAt.difference(now);
        _isExpired = false;
      });
    } else {
      setState(() {
        _remaining = Duration.zero;
        _isExpired = true;
      });
      _timer?.cancel();
      widget.onExpired?.call();
    }
  }

  Color get _timerColor {
    if (_isExpired) return AppColors.errorRed;
    
    final totalHours = 24.0;
    final remainingHours = (_remaining?.inMinutes ?? 0) / 60.0;
    final percentage = remainingHours / totalHours;
    
    if (percentage > 0.5) return AppColors.primaryGold;
    if (percentage > 0.25) return AppColors.warningOrange;
    return AppColors.errorRed;
  }

  String get _displayText {
    if (_isExpired) return 'Conversation expirée';
    if (_remaining == null) return '00:00:00';
    
    final hours = _remaining!.inHours;
    final minutes = _remaining!.inMinutes.remainder(60);
    final seconds = _remaining!.inSeconds.remainder(60);
    
    return '${hours.toString().padLeft(2, '0')}:'
           '${minutes.toString().padLeft(2, '0')}:'
           '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _timerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _timerColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isExpired ? Icons.timer_off : Icons.timer,
            color: _timerColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            _displayText,
            style: TextStyle(
              color: _timerColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Lato',
            ),
          ),
        ],
      ),
    );
  }
}