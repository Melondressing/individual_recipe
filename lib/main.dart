import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/recipe_provider.dart';
import 'providers/alias_provider.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _colorPalette = 'A'; // Default: Option A
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadThemePreferences();
  }

  Future<void> _loadThemePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _colorPalette = prefs.getString('colorPalette') ?? 'A';
      final themeModeString = prefs.getString('themeMode') ?? 'light';
      _themeMode = themeModeString == 'dark' ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _setColorPalette(String palette) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('colorPalette', palette);
    setState(() => _colorPalette = palette);
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode == ThemeMode.dark ? 'dark' : 'light');
    setState(() => _themeMode = mode);
  }

  // Color Palettes
  ColorScheme _buildLightColorScheme(String palette) {
    switch (palette) {
      case 'B': // Cool Neutral (Teal-blue)
        return const ColorScheme.light(
          primary: Color(0xFF2C3E50), // Dark slate blue
          onPrimary: Colors.white,
          secondary: Color(0xFF546E7A), // Medium slate blue
          onSecondary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
          surfaceContainerHighest: Color(0xFFF5F5F5),
          primaryContainer: Color(0xFFECEFF1),
          onPrimaryContainer: Color(0xFF2C3E50),
          error: Color(0xFFD32F2F),
        );
      case 'C': // Teal/Green
        return const ColorScheme.light(
          primary: Color(0xFF1B5E4F), // Deep teal
          onPrimary: Colors.white,
          secondary: Color(0xFF2E8B82), // Medium teal
          onSecondary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
          surfaceContainerHighest: Color(0xFFF1F5F4),
          primaryContainer: Color(0xFFD4E8E4),
          onPrimaryContainer: Color(0xFF1B5E4F),
          error: Color(0xFFD32F2F),
        );
      case 'A': // Warm Monochrome (Default)
      default:
        return const ColorScheme.light(
          primary: Color(0xFF6B4C3A), // Deep brown
          onPrimary: Colors.white,
          secondary: Color(0xFF8B6F47), // Warm brown
          onSecondary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
          surfaceContainerHighest: Color(0xFFF5F4F0),
          primaryContainer: Color(0xFFE8DDD0),
          onPrimaryContainer: Color(0xFF6B4C3A),
          error: Color(0xFFD32F2F),
        );
    }
  }

  ColorScheme _buildDarkColorScheme(String palette) {
    switch (palette) {
      case 'B': // Cool Neutral (Dark)
        return const ColorScheme.dark(
          primary: Color(0xFF5DADE2), // Light blue
          onPrimary: Colors.black,
          secondary: Color(0xFF7BA3C0), // Medium light blue
          onSecondary: Colors.black,
          surface: Color(0xFF121212),
          onSurface: Color(0xFFFFFFFF),
          surfaceContainerHighest: Color(0xFF2C2C2C),
          primaryContainer: Color(0xFF1F3A47),
          onPrimaryContainer: Color(0xFF5DADE2),
          error: Color(0xFFEF5350),
        );
      case 'C': // Teal/Green (Dark)
        return const ColorScheme.dark(
          primary: Color(0xFF4DB8A8), // Light teal
          onPrimary: Colors.black,
          secondary: Color(0xFF66A899), // Medium light teal
          onSecondary: Colors.black,
          surface: Color(0xFF121212),
          onSurface: Color(0xFFFFFFFF),
          surfaceContainerHighest: Color(0xFF2C2C2C),
          primaryContainer: Color(0xFF1B3F38),
          onPrimaryContainer: Color(0xFF4DB8A8),
          error: Color(0xFFEF5350),
        );
      case 'A': // Warm (Dark)
      default:
        return const ColorScheme.dark(
          primary: Color(0xFFD4A574), // Light terracotta
          onPrimary: Colors.black,
          secondary: Color(0xFFC9A876), // Light warm brown
          onSecondary: Colors.black,
          surface: Color(0xFF121212),
          onSurface: Color(0xFFFFFFFF),
          surfaceContainerHighest: Color(0xFF2C2C2C),
          primaryContainer: Color(0xFF3E3028),
          onPrimaryContainer: Color(0xFFD4A574),
          error: Color(0xFFEF5350),
        );
    }
  }

  ThemeData _buildLightTheme(String palette) {
    final colorScheme = _buildLightColorScheme(palette);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.white,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w300,
          letterSpacing: -0.5,
          fontSize: 57,
          height: 1.2,
        ),
        titleLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          fontSize: 22,
          height: 1.4,
        ),
        titleMedium: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
          fontSize: 16,
          height: 1.4,
        ),
        bodyLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          fontSize: 16,
          height: 1.5,
          color: Colors.black,
        ),
        bodyMedium: GoogleFonts.inter(
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          fontSize: 14,
          height: 1.4,
          color: Color(0xFF757575),
        ),
        labelSmall: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          fontSize: 12,
          height: 1.3,
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: colorScheme.primary,
        toolbarHeight: 64,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colorScheme.primary.withOpacity(0.12), width: 1),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      dividerColor: colorScheme.primary.withOpacity(0.12),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.primary.withOpacity(0.05),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.primary.withOpacity(0.1),
        selectedColor: colorScheme.primary,
        labelStyle: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  ThemeData _buildDarkTheme(String palette) {
    final colorScheme = _buildDarkColorScheme(palette);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF121212),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w300,
          letterSpacing: -0.5,
          fontSize: 57,
          height: 1.2,
          color: Colors.white,
        ),
        titleLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          fontSize: 22,
          height: 1.4,
          color: Colors.white,
        ),
        titleMedium: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
          fontSize: 16,
          height: 1.4,
          color: Colors.white,
        ),
        bodyLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          fontSize: 16,
          height: 1.5,
          color: Colors.white,
        ),
        bodyMedium: GoogleFonts.inter(
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          fontSize: 14,
          height: 1.4,
          color: Color(0xFFBDBDBD),
        ),
        labelSmall: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          fontSize: 12,
          height: 1.3,
          color: Colors.white,
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF1F1F1F),
        foregroundColor: colorScheme.primary,
        toolbarHeight: 64,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        color: const Color(0xFF1F1F1F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colorScheme.primary.withOpacity(0.2), width: 1),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.black,
        elevation: 4,
      ),
      dividerColor: colorScheme.primary.withOpacity(0.2),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.primary.withOpacity(0.08),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.primary.withOpacity(0.15),
        selectedColor: colorScheme.primary,
        labelStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RecipeProvider()..loadAllData()),
        ChangeNotifierProvider(create: (_) => AliasProvider()..loadAliases()),
      ],
      child: MaterialApp(
        title: 'Individual Recipe',
        debugShowCheckedModeBanner: false,
        theme: _buildLightTheme(_colorPalette),
        darkTheme: _buildDarkTheme(_colorPalette),
        themeMode: _themeMode,
        home: MainScreen(
          onThemeModeChanged: _setThemeMode,
          onColorPaletteChanged: _setColorPalette,
          currentColorPalette: _colorPalette,
          currentThemeMode: _themeMode,
        ),
      ),
    );
  }
}
