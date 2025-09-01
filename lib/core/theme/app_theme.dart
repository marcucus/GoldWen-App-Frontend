import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Art Deco Gold Palette - Light Theme
  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color primaryGoldLight = Color(0xFFE6C547);
  static const Color secondaryBeige = Color(0xFFF5F5DC);
  static const Color accentCream = Color(0xFFFAF0E6);
  static const Color textDark = Color(0xFF2C2C2C);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color backgroundWhite = Color(0xFFFFFFF8);
  static const Color dividerLight = Color(0xFFE8E8E8);
  static const Color errorRed = Color(0xFFE57373);
  static const Color successGreen = Color(0xFF81C784);

  // Art Deco Dark Palette - Dark Theme
  static const Color primaryGoldDark = Color(0xFFB8941F);
  static const Color backgroundDark = Color(0xFF1A1A1A);
  static const Color backgroundDarkSecondary = Color(0xFF2D2D2D);
  static const Color accentDarkCream = Color(0xFF3A3A3A);
  static const Color textLight = Color(0xFFF5F5F5);
  static const Color textSecondaryDark = Color(0xFFB8B8B8);
  static const Color dividerDark = Color(0xFF404040);
  
  // Art Deco Accent Colors (consistent across themes)
  static const Color artDecoCopper = Color(0xFFB87333);
  static const Color artDecoBronze = Color(0xFFCD7F32);
  static const Color artDecoSilver = Color(0xFFC0C0C0);
  
  // Art Deco Gradients
  static const LinearGradient goldGradient = LinearGradient(
    colors: [primaryGold, primaryGoldLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient darkGoldGradient = LinearGradient(
    colors: [primaryGoldDark, artDecoBronze],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
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
      textTheme: _buildTextTheme(false),

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

      // Button Themes
      elevatedButtonTheme: _buildElevatedButtonTheme(false),
      textButtonTheme: _buildTextButtonTheme(false),

      // Input Decoration Theme
      inputDecorationTheme: _buildInputDecorationTheme(false),

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

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: AppColors.primaryGoldDark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryGoldDark,
        brightness: Brightness.dark,
        primary: AppColors.primaryGoldDark,
        secondary: AppColors.backgroundDarkSecondary,
        surface: AppColors.backgroundDark,
        onSurface: AppColors.textLight,
      ),

      // Typography
      textTheme: _buildTextTheme(true),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textLight,
        ),
        centerTitle: true,
      ),

      // Button Themes
      elevatedButtonTheme: _buildElevatedButtonTheme(true),
      textButtonTheme: _buildTextButtonTheme(true),

      // Input Decoration Theme
      inputDecorationTheme: _buildInputDecorationTheme(true),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.backgroundDarkSecondary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(8),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerDark,
        thickness: 1,
        space: 20,
      ),
    );
  }

  static TextTheme _buildTextTheme(bool isDark) {
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return TextTheme(
      // Headlines use Playfair Display (Serif) - Art Deco style
      headlineLarge: GoogleFonts.playfairDisplay(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textColor,
        height: 1.2,
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textColor,
        height: 1.3,
      ),
      headlineSmall: GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: 1.3,
      ),

      // Body text uses Lato (Sans-Serif)
      bodyLarge: GoogleFonts.lato(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: textColor,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.lato(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: textColor,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.lato(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: secondaryTextColor,
        height: 1.4,
      ),

      // Labels
      labelLarge: GoogleFonts.lato(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: 1.4,
      ),
      labelMedium: GoogleFonts.lato(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: secondaryTextColor,
        height: 1.4,
      ),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme(bool isDark) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? AppColors.primaryGoldDark : AppColors.primaryGold,
        foregroundColor: isDark ? AppColors.backgroundDark : Colors.white,
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
    );
  }

  static TextButtonThemeData _buildTextButtonTheme(bool isDark) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: isDark ? AppColors.primaryGoldDark : AppColors.primaryGold,
        textStyle: GoogleFonts.lato(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme(bool isDark) {
    final fillColor = isDark ? AppColors.accentDarkCream : AppColors.accentCream;
    final borderColor = isDark ? AppColors.dividerDark : AppColors.dividerLight;
    final focusColor = isDark ? AppColors.primaryGoldDark : AppColors.primaryGold;
    final textColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: focusColor, width: 2),
      ),
      labelStyle: GoogleFonts.lato(
        color: textColor,
        fontSize: 14,
      ),
      hintStyle: GoogleFonts.lato(
        color: textColor,
        fontSize: 14,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
