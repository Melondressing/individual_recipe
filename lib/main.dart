import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/recipe_provider.dart';
import 'providers/alias_provider.dart';
import 'providers/shopping_list_provider.dart';
import 'screens/main_screen.dart';
import 'theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RecipeProvider()..loadAllData()),
        ChangeNotifierProvider(create: (_) => AliasProvider()..loadAliases()),
        ChangeNotifierProvider(create: (_) => ShoppingListProvider()..loadItems()),
      ],
      child: MaterialApp(
        title: 'Individual Recipe',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(_colorPalette),
        darkTheme: AppTheme.dark(_colorPalette),
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
