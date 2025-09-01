import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';

class ArtDecoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool showGradient;

  const ArtDecoCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.showGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Container(
          margin: margin ?? const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: showGradient
                ? (themeProvider.isDarkMode 
                    ? AppColors.darkGoldGradient 
                    : AppColors.goldGradient)
                : null,
            color: showGradient 
                ? null 
                : (themeProvider.isDarkMode 
                    ? AppColors.backgroundDarkSecondary 
                    : AppColors.backgroundWhite),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (themeProvider.isDarkMode 
                    ? AppColors.primaryGoldDark 
                    : AppColors.primaryGold).withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: (themeProvider.isDarkMode 
                  ? AppColors.primaryGoldDark 
                  : AppColors.primaryGold).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Padding(
                padding: padding ?? const EdgeInsets.all(16),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

class ArtDecoPattern extends StatelessWidget {
  final double size;
  final Color? color;

  const ArtDecoPattern({
    super.key,
    this.size = 100,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final patternColor = color ?? 
            (themeProvider.isDarkMode 
                ? AppColors.primaryGoldDark.withOpacity(0.1)
                : AppColors.primaryGold.withOpacity(0.1));

        return CustomPaint(
          size: Size(size, size),
          painter: ArtDecoPainter(color: patternColor),
        );
      },
    );
  }
}

class ArtDecoPainter extends CustomPainter {
  final Color color;

  ArtDecoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Art Deco fan pattern
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * (3.14159 / 180);
      final startX = center.dx + (radius * 0.3) * (i % 2 == 0 ? 1 : 0.7);
      final startY = center.dy + (radius * 0.3) * (i % 2 == 0 ? 1 : 0.7);
      
      canvas.drawLine(
        center,
        Offset(
          center.dx + radius * 0.8 * (angle < 3.14159 ? 1 : -1),
          center.dy + radius * 0.8 * (angle < 1.57 || angle > 4.71 ? -1 : 1),
        ),
        paint,
      );
    }

    // Concentric circles
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, radius * (i / 4), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}