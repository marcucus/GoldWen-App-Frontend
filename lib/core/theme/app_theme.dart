import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary Palette - Sophisticated Gold Theme
  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color primary = primaryGold; // Alias for primaryGold
  static const Color primaryGoldDark = Color(0xFFB8941F);
  static const Color primaryGoldLight = Color(0xFFE8C547);
  
  // Secondary Palette
  static const Color secondaryBeige = Color(0xFFF5F5DC);
  static const Color accentCream = Color(0xFFFAF0E6);
  static const Color accentPeach = Color(0xFFFFE5D1);
  
  // Neutral Palette
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color textMuted = Color(0xFF9E9E9E); // Alias for textTertiary
  static const Color backgroundWhite = Color(0xFFFFFFF8);
  static const Color backgroundGrey = Color(0xFFF8F9FA);
  static const Color backgroundLight = Color(0xFFFFFFF8); // Alias for backgroundWhite
  static const Color backgroundCream = Color(0xFFFAF0E6); // Cream background for history page
  static const Color dividerLight = Color(0xFFE8E8E8);
  static const Color border = Color(0xFFE8E8E8); // Alias for dividerLight
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textLight = Color(0xFFFFFFFF);
  
  // Semantic Colors
  static const Color errorRed = Color(0xFFE57373);
  static const Color error = errorRed; // Alias for errorRed
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color success = successGreen; // Alias for successGreen
  static const Color warningAmber = Color(0xFFFFC107);
  static const Color warningOrange = Color(0xFFF57C00); // Additional warning color
  static const Color infoBlue = Color(0xFF2196F3);
  
  // Modern Gradient Colors
  static const Color gradientStart = Color(0xFF8B6914);
  static const Color gradientMiddle = Color(0xFFD4AF37);
  static const Color gradientEnd = Color(0xFFF5E6B8);
  static const Color cardOverlay = Color(0xFFFFFFFF);
  
  // Glass Morphism Colors
  static const Color glassBackground = Color(0x40FFFFFF);
  static const Color glassBorder = Color(0x80FFFFFF);
  
  // Shadow Colors
  static const Color shadowLight = Color(0x10000000);
  static const Color shadowMedium = Color(0x20000000);
  static const Color shadowDark = Color(0x30000000);
  static const Color shadowColor = Color(0x20000000); // General shadow color
  
  // Border Colors
  static const Color borderColor = Color(0xFFE8E8E8);
  static const Color borderLight = Color(0xFFF0F0F0);

  // Background Colors variations
  static const Color backgroundDark = Color(0xFF1A1A1A);

  // High Contrast Colors (WCAG AAA compliant)
  static const Color highContrastPrimary = Color(0xFF8B6914);
  static const Color highContrastText = Color(0xFF000000);
  static const Color highContrastBackground = Color(0xFFFFFFFF);
  static const Color highContrastSecondary = Color(0xFF4A4A4A);
  static const Color highContrastBorder = Color(0xFF000000);
  
  // Premium Gradients
  static LinearGradient get primaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientMiddle, gradientEnd],
    stops: [0.0, 0.5, 1.0],
  );
  
  static LinearGradient get cardGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      cardOverlay.withOpacity(0.95),
      cardOverlay.withOpacity(0.85),
    ],
  );
  
  static LinearGradient get premiumGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryGoldLight, primaryGold, primaryGoldDark],
    stops: [0.0, 0.5, 1.0],
  );
  
  static LinearGradient get subtleGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      backgroundWhite,
      backgroundGrey.withOpacity(0.5),
    ],
  );
  
  // Glass Morphism Effect
  static BoxDecoration get glassDecoration => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        glassBackground,
        glassBackground.withOpacity(0.3),
      ],
    ),
    border: Border.all(
      color: glassBorder,
      width: 1,
    ),
    borderRadius: BorderRadius.circular(20),
  );

  /// Get color with proper contrast ratio for accessibility
  static Color getAccessibleColor(Color backgroundColor, {bool highContrast = false}) {
    if (highContrast) {
      return _isLight(backgroundColor) ? highContrastText : highContrastBackground;
    }
    return _isLight(backgroundColor) ? textDark : textLight;
  }

  /// Check if color is light (for contrast calculations)
  static bool _isLight(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5;
  }

  /// Get high contrast version of primary colors
  static Color getHighContrastPrimary(bool enabled) {
    return enabled ? highContrastPrimary : primaryGold;
  }

  /// Get high contrast text color
  static Color getHighContrastText(bool enabled) {
    return enabled ? highContrastText : textDark;
  }

  /// Get high contrast background color
  static Color getHighContrastBackground(bool enabled) {
    return enabled ? highContrastBackground : backgroundWhite;
  }
}

class AppTheme {
  static ThemeData lightTheme({
    bool highContrast = false,
    double textScaleFactor = 1.0,
  }) {
    final primaryColor = AppColors.getHighContrastPrimary(highContrast);
    final textColor = AppColors.getHighContrastText(highContrast);
    final backgroundColor = AppColors.getHighContrastBackground(highContrast);
    
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: highContrast ? AppColors.highContrastSecondary : AppColors.secondaryBeige,
        surface: backgroundColor,
        onSurface: textColor,
      ),

      // Typography with accessibility scaling
      textTheme: _buildTextTheme(highContrast, textScaleFactor, textColor),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20 * textScaleFactor,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        centerTitle: true,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: AppColors.getAccessibleColor(primaryColor, highContrast: highContrast),
          textStyle: GoogleFonts.lato(
            fontSize: 16 * textScaleFactor,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: highContrast ? const BorderSide(color: AppColors.highContrastBorder, width: 2) : BorderSide.none,
          ),
          elevation: 2,
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: GoogleFonts.lato(
            fontSize: 14 * textScaleFactor,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

      // Input Decoration Theme with enhanced contrast
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: highContrast ? AppColors.highContrastBackground : AppColors.accentCream,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: highContrast ? 
              const BorderSide(color: AppColors.highContrastBorder, width: 2) : 
              BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: highContrast ? AppColors.highContrastBorder : AppColors.dividerLight,
            width: highContrast ? 2 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: primaryColor,
            width: highContrast ? 3 : 2,
          ),
        ),
        labelStyle: GoogleFonts.lato(
          color: highContrast ? AppColors.highContrastText : AppColors.textSecondary,
          fontSize: 14 * textScaleFactor,
        ),
        hintStyle: GoogleFonts.lato(
          color: highContrast ? AppColors.highContrastSecondary : AppColors.textSecondary,
          fontSize: 14 * textScaleFactor,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // Card Theme with enhanced borders for high contrast
      cardTheme: CardThemeData(
        color: backgroundColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: highContrast ? 
              const BorderSide(color: AppColors.highContrastBorder, width: 1) : 
              BorderSide.none,
        ),
        margin: const EdgeInsets.all(8),
      ),

      // Divider Theme with enhanced visibility
      dividerTheme: DividerThemeData(
        color: highContrast ? AppColors.highContrastBorder : AppColors.dividerLight,
        thickness: highContrast ? 2 : 1,
        space: 20,
      ),
    );
  }

  static TextTheme _buildTextTheme(bool highContrast, double textScaleFactor, Color textColor) {
    final secondaryColor = highContrast ? AppColors.highContrastSecondary : AppColors.textSecondary;
    
    return TextTheme(
      // Headlines use Playfair Display (Serif)
      headlineLarge: GoogleFonts.playfairDisplay(
        fontSize: 32 * textScaleFactor,
        fontWeight: FontWeight.bold,
        color: textColor,
        height: 1.2,
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        fontSize: 28 * textScaleFactor,
        fontWeight: FontWeight.bold,
        color: textColor,
        height: 1.3,
      ),
      headlineSmall: GoogleFonts.playfairDisplay(
        fontSize: 24 * textScaleFactor,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: 1.3,
      ),

      // Body text uses Lato (Sans-Serif)
      bodyLarge: GoogleFonts.lato(
        fontSize: 16 * textScaleFactor,
        fontWeight: FontWeight.normal,
        color: textColor,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.lato(
        fontSize: 14 * textScaleFactor,
        fontWeight: FontWeight.normal,
        color: textColor,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.lato(
        fontSize: 12 * textScaleFactor,
        fontWeight: FontWeight.normal,
        color: secondaryColor,
        height: 1.4,
      ),

      // Labels with enhanced contrast
      labelLarge: GoogleFonts.lato(
        fontSize: 14 * textScaleFactor,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: 1.4,
      ),
      labelMedium: GoogleFonts.lato(
        fontSize: 12 * textScaleFactor,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
        height: 1.4,
      ),
    );
  }
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppBorderRadius {
  static const double small = 8.0;
  static const double medium = 12.0;
  static const double large = 16.0;
  static const double xLarge = 24.0;
}

// Alias for AppBorderRadius with shorter property names
class AppRadius {
  static const double xs = 4.0;
  static const double sm = AppBorderRadius.small;
  static const double md = AppBorderRadius.medium;
  static const double lg = AppBorderRadius.large;
  static const double xl = AppBorderRadius.xLarge;
}

class AppAnimations {
  // Duration constants with accessibility support
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);
  
  // Curve constants
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve bounceIn = Curves.bounceIn;
  static const Curve bounceOut = Curves.bounceOut;
  static const Curve elasticOut = Curves.elasticOut;
  static const Curve decelerate = Curves.decelerate;
  
  // Common animation values
  static const double scaleSmall = 0.95;
  static const double scaleMedium = 0.9;
  static const double scaleLarge = 0.8;
  
  // Slide animation offsets
  static const Offset slideInFromBottom = Offset(0, 1);
  static const Offset slideInFromTop = Offset(0, -1);
  static const Offset slideInFromLeft = Offset(-1, 0);
  static const Offset slideInFromRight = Offset(1, 0);

  /// Get duration based on accessibility settings
  static Duration getDuration(Duration defaultDuration, {bool reducedMotion = false}) {
    return reducedMotion ? Duration.zero : defaultDuration;
  }

  /// Get curve based on accessibility settings
  static Curve getCurve(Curve defaultCurve, {bool reducedMotion = false}) {
    return reducedMotion ? Curves.linear : defaultCurve;
  }
}

class AppShadows {
  static List<BoxShadow> soft({bool highContrast = false}) => [
    BoxShadow(
      color: highContrast ? AppColors.highContrastBorder.withOpacity(0.3) : AppColors.shadowLight,
      blurRadius: highContrast ? 2 : 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> medium({bool highContrast = false}) => [
    BoxShadow(
      color: highContrast ? AppColors.highContrastBorder.withOpacity(0.5) : AppColors.shadowMedium,
      blurRadius: highContrast ? 4 : 12,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> strong({bool highContrast = false}) => [
    BoxShadow(
      color: highContrast ? AppColors.highContrastBorder.withOpacity(0.7) : AppColors.shadowDark,
      blurRadius: highContrast ? 6 : 16,
      offset: const Offset(0, 6),
    ),
  ];
  
  static List<BoxShadow> floating({bool highContrast = false}) => [
    BoxShadow(
      color: highContrast ? AppColors.highContrastBorder.withOpacity(0.5) : AppColors.shadowMedium,
      blurRadius: highContrast ? 8 : 20,
      offset: const Offset(0, 8),
    ),
  ];
}

class AppDecorations {
  static BoxDecoration modernCard({bool highContrast = false}) => BoxDecoration(
    color: highContrast ? AppColors.highContrastBackground : AppColors.cardOverlay,
    borderRadius: BorderRadius.circular(AppBorderRadius.large),
    boxShadow: AppShadows.soft(highContrast: highContrast),
    border: highContrast ? 
        Border.all(color: AppColors.highContrastBorder, width: 1) : 
        null,
  );
  
  static BoxDecoration premiumCard({bool highContrast = false}) => BoxDecoration(
    gradient: highContrast ? null : AppColors.cardGradient,
    color: highContrast ? AppColors.highContrastBackground : null,
    borderRadius: BorderRadius.circular(AppBorderRadius.xLarge),
    boxShadow: AppShadows.medium(highContrast: highContrast),
    border: Border.all(
      color: highContrast ? 
          AppColors.highContrastBorder : 
          AppColors.primaryGold.withOpacity(0.3),
      width: highContrast ? 2 : 1,
    ),
  );
  
  static BoxDecoration floatingCard({bool highContrast = false}) => BoxDecoration(
    color: highContrast ? AppColors.highContrastBackground : AppColors.cardOverlay,
    borderRadius: BorderRadius.circular(AppBorderRadius.xLarge),
    boxShadow: AppShadows.floating(highContrast: highContrast),
    border: highContrast ? 
        Border.all(color: AppColors.highContrastBorder, width: 1) : 
        null,
  );
}

/// Extension for accessibility-aware theming
extension AccessibleTheme on ThemeData {
  /// Check if high contrast is enabled
  bool get isHighContrast => 
      colorScheme.primary == AppColors.highContrastPrimary;

  /// Get accessible text color for background
  Color getAccessibleTextColor(Color backgroundColor) =>
      AppColors.getAccessibleColor(backgroundColor, highContrast: isHighContrast);

  /// Get focus color with proper contrast
  Color get accessibleFocusColor =>
      isHighContrast ? AppColors.highContrastPrimary : colorScheme.primary;
}
