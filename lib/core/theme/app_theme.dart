import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary Palette - Sophisticated Gold Theme
  static const Color primaryGold = Color(0xFFD4AF37);
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
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: AppColors.primaryGold,
      scaffoldBackgroundColor: AppColors.backgroundWhite,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryGold,
        brightness: Brightness.light,
        primary: AppColors.primaryGold,
        secondary: AppColors.secondaryBeige,
        surface: AppColors.backgroundWhite,
        onSurface: AppColors.textDark,
      ),

      // Typography
      textTheme: TextTheme(
        // Headlines use Playfair Display (Serif)
        headlineLarge: GoogleFonts.playfairDisplay(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
          height: 1.2,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
          height: 1.3,
        ),
        headlineSmall: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
          height: 1.3,
        ),

        // Body text uses Lato (Sans-Serif)
        bodyLarge: GoogleFonts.lato(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.textDark,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.lato(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.textDark,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.lato(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondary,
          height: 1.4,
        ),

        // Labels
        labelLarge: GoogleFonts.lato(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
          height: 1.4,
        ),
        labelMedium: GoogleFonts.lato(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
          height: 1.4,
        ),
      ),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        centerTitle: true,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGold,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryGold,
          textStyle: GoogleFonts.lato(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.accentCream,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.dividerLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryGold, width: 2),
        ),
        labelStyle: GoogleFonts.lato(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.lato(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.backgroundWhite,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(8),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerLight,
        thickness: 1,
        space: 20,
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

class AppAnimations {
  // Duration constants
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
}

class AppShadows {
  static List<BoxShadow> get soft => [
    BoxShadow(
      color: AppColors.shadowLight,
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get medium => [
    BoxShadow(
      color: AppColors.shadowMedium,
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get strong => [
    BoxShadow(
      color: AppColors.shadowDark,
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];
  
  static List<BoxShadow> get floating => [
    BoxShadow(
      color: AppColors.shadowMedium,
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}

class AppDecorations {
  static BoxDecoration get modernCard => BoxDecoration(
    color: AppColors.cardOverlay,
    borderRadius: BorderRadius.circular(AppBorderRadius.large),
    boxShadow: AppShadows.soft,
  );
  
  static BoxDecoration get premiumCard => BoxDecoration(
    gradient: AppColors.cardGradient,
    borderRadius: BorderRadius.circular(AppBorderRadius.xLarge),
    boxShadow: AppShadows.medium,
    border: Border.all(
      color: AppColors.primaryGold.withOpacity(0.3),
      width: 1,
    ),
  );
  
  static BoxDecoration get floatingCard => BoxDecoration(
    color: AppColors.cardOverlay,
    borderRadius: BorderRadius.circular(AppBorderRadius.xLarge),
    boxShadow: AppShadows.floating,
  );
}
