import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'inbox_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeModeChanged;
  final Function(String) onColorPaletteChanged;
  final String currentColorPalette;
  final ThemeMode currentThemeMode;

  const MainScreen({
    super.key,
    required this.onThemeModeChanged,
    required this.onColorPaletteChanged,
    required this.currentColorPalette,
    required this.currentThemeMode,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onOpenSearch: () => setState(() => _currentIndex = 1)),
      const SearchScreen(),
      const InboxScreen(),
      SettingsScreen(
        onThemeModeChanged: widget.onThemeModeChanged,
        onColorPaletteChanged: widget.onColorPaletteChanged,
        currentColorPalette: widget.currentColorPalette,
        currentThemeMode: widget.currentThemeMode,
      ),
    ];

    return Scaffold(
      body: SafeArea(child: screens[_currentIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.inbox_outlined),
            selectedIcon: Icon(Icons.inbox),
            label: 'Inbox',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
