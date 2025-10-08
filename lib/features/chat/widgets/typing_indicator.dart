import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Widget that displays a typing indicator with animated dots
class TypingIndicator extends StatefulWidget {
  final String userName;
  
  const TypingIndicator({
    super.key,
    required this.userName,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.accentCream.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${widget.userName} écrit',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
          ),
          const SizedBox(width: AppSpacing.xs),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  final delay = index * 0.3;
                  final value = (_controller.value - delay).clamp(0.0, 1.0);
                  final opacity = (Curves.easeInOut.transform(value) * 2 - 1).abs();
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Opacity(
                      opacity: 0.3 + (opacity * 0.7),
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}
