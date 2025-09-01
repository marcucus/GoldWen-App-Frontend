import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

class AppLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final bool useTransparentVersion;

  const AppLogo({
    super.key,
    this.width,
    this.height,
    this.useTransparentVersion = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        String logoPath;
        
        if (useTransparentVersion) {
          // Use the transparent logo for in-app display
          logoPath = 'assets/images/logo_sans_fond.png';
        } else {
          // Use theme-appropriate logo
          logoPath = themeProvider.currentLogoAsset;
        }

        return Image.asset(
          logoPath,
          width: width,
          height: height,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to base logo if theme-specific logo fails
            return Image.asset(
              'assets/images/logo_base.png',
              width: width,
              height: height,
              fit: BoxFit.contain,
            );
          },
        );
      },
    );
  }
}

class AppLogoIcon extends StatelessWidget {
  final double size;

  const AppLogoIcon({
    super.key,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return AppLogo(
      width: size,
      height: size,
      useTransparentVersion: true,
    );
  }
}