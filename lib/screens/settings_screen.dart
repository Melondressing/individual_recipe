import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database_helper.dart';
import '../providers/alias_provider.dart';
import '../providers/recipe_provider.dart';
import 'alias_management_screen.dart';
import 'cooking_logs_screen.dart';
import 'recipe_pack_import_screen.dart';
import 'storage_test_screen.dart';

class SettingsScreen extends StatelessWidget {
  final Function(ThemeMode) onThemeModeChanged;
  final Function(String) onColorPaletteChanged;
  final String currentColorPalette;
  final ThemeMode currentThemeMode;

  const SettingsScreen({
    super.key,
    required this.onThemeModeChanged,
    required this.onColorPaletteChanged,
    required this.currentColorPalette,
    required this.currentThemeMode,
  });

  Future<void> _reloadProviders(BuildContext context) async {
    await context.read<RecipeProvider>().loadAllData();
    if (!context.mounted) return;
    await context.read<AliasProvider>().loadAliases();
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      final data = await DatabaseHelper.instance.exportData();
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      final filename = 'individual_recipe_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final bytes = Uint8List.fromList(utf8.encode(jsonString));

      await SharePlus.instance.share(
        ShareParams(
          subject: 'Individual Recipe Backup',
          text: 'Individual Recipe backup file',
          files: [
            XFile.fromData(
              bytes,
              name: filename,
              mimeType: 'application/json',
            ),
          ],
        ),
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export successful')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _importData(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final bytes = result.files.first.bytes;
      if (bytes == null) {
        throw StateError('The selected file could not be read.');
      }

      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Backup file must be a JSON object.');
      }

      await DatabaseHelper.instance.importData(decoded);
      if (!context.mounted) return;
      await _reloadProviders(context);
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Import successful')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset All Data'),
          content: const Text(
            'This will delete all recipes, aliases, and cooking logs. This action cannot be undone. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await DatabaseHelper.instance.clearAll();
                  if (!context.mounted) return;
                  await _reloadProviders(context);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All data has been reset')),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Reset failed: $e')),
                  );
                }
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _buildSectionHeader(context, 'Data Management'),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('조리 기록'),
            subtitle: const Text('전체 조리 기록 보기'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CookingLogsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.collections_bookmark),
            title: const Text('Recipe Packs'),
            subtitle: const Text('Import recipe collections by category'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RecipePackImportScreen()),
              );
            },
          ),
          if (kIsWeb)
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('Storage Test'),
              subtitle: const Text('Run a non-destructive storage check'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StorageTestScreen()),
                );
              },
            ),
          ListTile(
            leading: const Icon(Icons.file_upload),
            title: const Text('Export Backup'),
            subtitle: const Text('Save recipes, aliases, cooking logs, and reviews as JSON'),
            onTap: () => _exportData(context),
          ),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Import Backup'),
            subtitle: const Text('Restore from JSON file'),
            onTap: () => _importData(context),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Ingredient Aliases'),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('Manage Aliases'),
            subtitle: const Text('Edit ingredient search aliases'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AliasManagementScreen()),
              );
            },
          ),
          const Divider(),
          _buildSectionHeader(context, 'Appearance'),
          ListTile(
            title: const Text('Color Palette'),
            subtitle: const Text('Choose your preferred color theme'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: [
                _buildPaletteButton(context, 'A', 'Warm Brown', const Color(0xFF6B4C3A)),
                _buildPaletteButton(context, 'B', 'Cool Blue', const Color(0xFF2C3E50)),
                _buildPaletteButton(context, 'C', 'Teal Green', const Color(0xFF1B5E4F)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Choose light or dark theme'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildThemeButton(context, ThemeMode.light, 'Light', Icons.light_mode),
                _buildThemeButton(context, ThemeMode.dark, 'Dark', Icons.dark_mode),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          _buildSectionHeader(context, 'About'),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('Version'),
            subtitle: Text('1.1.0 Structured recipes'),
          ),
          const ListTile(
            leading: Icon(Icons.description),
            title: Text('About Individual Recipe'),
            subtitle: Text('Personal offline recipe manager'),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Danger Zone'),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Reset All Data', style: TextStyle(color: Colors.red)),
            subtitle: const Text('Delete everything permanently'),
            onTap: () => _showResetConfirmation(context),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPaletteButton(BuildContext context, String palette, String label, Color color) {
    final isSelected = currentColorPalette == palette;
    return GestureDetector(
      onTap: () => onColorPaletteChanged(palette),
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? color.withOpacity(0.1) : null,
        ),
        child: Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeButton(BuildContext context, ThemeMode mode, String label, IconData icon) {
    final isSelected = currentThemeMode == mode;
    return GestureDetector(
      onTap: () => onThemeModeChanged(mode),
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
