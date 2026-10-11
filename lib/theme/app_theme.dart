import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Single source of truth for theming.
///
/// Three color palettes ('A' Warm Brown, 'B' Cool Blue, 'C' Teal Green),
/// each with a light and dark [ColorScheme] built from a seed color so every
/// Material 3 component (nav bar indicator, switches, etc.) picks up a
/// harmonized color instead of Flutter's default purple. Buttons, cards,
/// inputs, chips, dialogs and snackbars all share the same radius/padding
/// tokens below so the app reads as one consistent, simple design.
class AppTheme {
  AppTheme._();

  static const double cardRadius = 14;
  static const double buttonRadius = 12;
  static const double inputRadius = 12;
  static const double chipRadius = 10;
  static const double dialogRadius = 20;

  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(vertical: 14, horizontal: 20);

  static const List<String> paletteIds = ['A', 'B', 'C'];

  static String paletteLabel(String id) {
    switch (id) {
      case 'B':
        return 'Cool Blue';
      case 'C':
        return 'Teal Green';
      case 'A':
      default:
        return 'Warm Brown';
    }
  }

  static Color paletteSwatch(String id) {
    switch (id) {
      case 'B':
        return const Color(0xFF2C3E50);
      case 'C':
        return const Color(0xFF1B5E4F);
      case 'A':
      default:
        return const Color(0xFF6B4C3A);
    }
  }

  static ColorScheme lightColorScheme(String palette) {
    switch (palette) {
      case 'B': // Cool Neutral (Teal-blue)
        return ColorScheme.fromSeed(
          seedColor: const Color(0xFF2C3E50),
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFF2C3E50),
          onPrimary: Colors.white,
          secondary: const Color(0xFF546E7A),
          onSecondary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
          surfaceContainerHighest: const Color(0xFFF5F5F5),
          primaryContainer: const Color(0xFFECEFF1),
          onPrimaryContainer: const Color(0xFF2C3E50),
          error: const Color(0xFFD32F2F),
        );
      case 'C': // Teal/Green
        return ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E4F),
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFF1B5E4F),
          onPrimary: Colors.white,
          secondary: const Color(0xFF2E8B82),
          onSecondary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
          surfaceContainerHighest: const Color(0xFFF1F5F4),
          primaryContainer: const Color(0xFFD4E8E4),
          onPrimaryContainer: const Color(0xFF1B5E4F),
          error: const Color(0xFFD32F2F),
        );
      case 'A': // Warm Monochrome (Default)
      default:
        return ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B4C3A),
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFF6B4C3A),
          onPrimary: Colors.white,
          secondary: const Color(0xFF8B6F47),
          onSecondary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
          surfaceContainerHighest: const Color(0xFFF5F4F0),
          primaryContainer: const Color(0xFFE8DDD0),
          onPrimaryContainer: const Color(0xFF6B4C3A),
          error: const Color(0xFFD32F2F),
        );
    }
  }

  static ColorScheme darkColorScheme(String palette) {
    switch (palette) {
      case 'B': // Cool Neutral (Dark)
        return ColorScheme.fromSeed(
          seedColor: const Color(0xFF5DADE2),
          brightness: Brightness.dark,
        ).copyWith(
          primary: const Color(0xFF5DADE2),
          onPrimary: Colors.black,
          secondary: const Color(0xFF7BA3C0),
          onSecondary: Colors.black,
          surface: const Color(0xFF121212),
          onSurface: Colors.white,
          surfaceContainerHighest: const Color(0xFF2C2C2C),
          primaryContainer: const Color(0xFF1F3A47),
          onPrimaryContainer: const Color(0xFF5DADE2),
          error: const Color(0xFFEF5350),
        );
      case 'C': // Teal/Green (Dark)
        return ColorScheme.fromSeed(
          seedColor: const Color(0xFF4DB8A8),
          brightness: Brightness.dark,
        ).copyWith(
          primary: const Color(0xFF4DB8A8),
          onPrimary: Colors.black,
          secondary: const Color(0xFF66A899),
          onSecondary: Colors.black,
          surface: const Color(0xFF121212),
          onSurface: Colors.white,
          surfaceContainerHighest: const Color(0xFF2C2C2C),
          primaryContainer: const Color(0xFF1B3F38),
          onPrimaryContainer: const Color(0xFF4DB8A8),
          error: const Color(0xFFEF5350),
        );
      case 'A': // Warm (Dark)
      default:
        return ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4A574),
          brightness: Brightness.dark,
        ).copyWith(
          primary: const Color(0xFFD4A574),
          onPrimary: Colors.black,
          secondary: const Color(0xFFC9A876),
          onSecondary: Colors.black,
          surface: const Color(0xFF121212),
          onSurface: Colors.white,
          surfaceContainerHighest: const Color(0xFF2C2C2C),
          primaryContainer: const Color(0xFF3E3028),
          onPrimaryContainer: const Color(0xFFD4A574),
          error: const Color(0xFFEF5350),
        );
    }
  }

  static ThemeData light(String palette) => _build(lightColorScheme(palette), Brightness.light);

  static ThemeData dark(String palette) => _build(darkColorScheme(palette), Brightness.dark);

  static ThemeData _build(ColorScheme colorScheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bodyColor = isDark ? Colors.white : Colors.black;
    final mutedColor = isDark ? const Color(0xFFBDBDBD) : const Color(0xFF757575);
    final surfaceColor = isDark ? const Color(0xFF1F1F1F) : Colors.white;
    final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(buttonRadius));

    final baseTextTheme = isDark
        ? GoogleFonts.interTextTheme(ThemeData.dark().textTheme)
        : GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w300,
          letterSpacing: -0.5,
          fontSize: 57,
          height: 1.2,
          color: bodyColor,
        ),
        titleLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          fontSize: 22,
          height: 1.4,
          color: bodyColor,
        ),
        titleMedium: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
          fontSize: 16,
          height: 1.4,
          color: bodyColor,
        ),
        bodyLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          fontSize: 16,
          height: 1.5,
          color: bodyColor,
        ),
        bodyMedium: GoogleFonts.inter(
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          fontSize: 14,
          height: 1.4,
          color: mutedColor,
        ),
        labelSmall: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          fontSize: 12,
          height: 1.3,
          color: bodyColor,
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: surfaceColor,
        foregroundColor: colorScheme.primary,
        toolbarHeight: 64,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: colorScheme.primary.withOpacity(isDark ? 0.2 : 0.12)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: buttonPadding,
          shape: buttonShape,
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: buttonPadding,
          shape: buttonShape,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: buttonPadding,
          shape: buttonShape,
          side: BorderSide(color: colorScheme.primary.withOpacity(0.5)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: buttonShape,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        indicatorColor: colorScheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
      ),
      dividerColor: colorScheme.primary.withOpacity(isDark ? 0.2 : 0.12),
      dialogTheme: DialogThemeData(
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(dialogRadius)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(inputRadius)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.primary.withOpacity(isDark ? 0.08 : 0.05),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.primary.withOpacity(isDark ? 0.15 : 0.1),
        selectedColor: colorScheme.primary,
        labelStyle: TextStyle(
          color: isDark ? Colors.white : colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(chipRadius)),
      ),
    );
  }
}
