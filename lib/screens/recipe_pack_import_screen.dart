import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/database_helper.dart';
import '../models/recipe_pack.dart';
import '../providers/alias_provider.dart';
import '../providers/recipe_provider.dart';
import '../theme/app_theme.dart';

class RecipePackImportScreen extends StatefulWidget {
  const RecipePackImportScreen({super.key});

  @override
  State<RecipePackImportScreen> createState() => _RecipePackImportScreenState();
}

class _RecipePackImportScreenState extends State<RecipePackImportScreen> {
  final Set<String> _selectedPacks = {};
  bool _isImporting = false;

  Future<void> _importSelected() async {
    if (_selectedPacks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one recipe pack')),
      );
      return;
    }

    final recipeProvider = context.read<RecipeProvider>();
    final aliasProvider = context.read<AliasProvider>();
    final selectedPackIds = List<String>.from(_selectedPacks);

    setState(() => _isImporting = true);

    try {
      final db = DatabaseHelper.instance;
      int totalRecipes = 0;
      int totalAliases = 0;

      if (kDebugMode) {
        debugPrint('📦 [Import] Starting import of ${selectedPackIds.length} packs...');
      }

      for (final packId in selectedPackIds) {
        final pack = RecipePacks.allPacks.firstWhere((p) => p.id == packId);

        if (kDebugMode) {
          debugPrint('📦 [Import] Importing pack: ${pack.name} (${pack.recipes.length} recipes, ${pack.aliases.length} aliases)');
        }

        for (final recipe in pack.recipes) {
          await db.createRecipe(recipe);
          totalRecipes++;
        }

        for (final alias in pack.aliases) {
          await db.createIngredientAlias(alias);
          totalAliases++;
        }
      }

      await recipeProvider.loadAllData();
      await aliasProvider.loadAliases();

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported $totalRecipes recipes and $totalAliases aliases'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Import] Import failed: $e');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  void _togglePack(String id, bool selected) {
    setState(() {
      if (selected) {
        _selectedPacks.add(id);
      } else {
        _selectedPacks.remove(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Packs'),
        actions: [
          if (!_isImporting)
            TextButton(
              onPressed: _importSelected,
              child: Text(
                'Import',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _isImporting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Importing recipes...'),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: RecipePacks.allPacks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final pack = RecipePacks.allPacks[index];
                final isSelected = _selectedPacks.contains(pack.id);
                final colorScheme = Theme.of(context).colorScheme;
                final onSelectedColor = colorScheme.onPrimary;
                final onSurfaceColor = colorScheme.onSurface;

                return Card(
                  elevation: 0,
                  color: isSelected ? colorScheme.primary : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    side: BorderSide(
                      color: isSelected ? colorScheme.primary : colorScheme.primary.withValues(alpha: 0.12),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: () => _togglePack(pack.id, !isSelected),
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: isSelected,
                                onChanged: (value) => _togglePack(pack.id, value ?? false),
                                activeColor: colorScheme.primary,
                                checkColor: onSelectedColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  pack.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? onSelectedColor : onSurfaceColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 56),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pack.description,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isSelected
                                        ? onSelectedColor.withValues(alpha: 0.8)
                                        : onSurfaceColor.withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    _buildInfoChip(context, '${pack.recipes.length} recipes', isSelected),
                                    if (pack.aliases.isNotEmpty)
                                      _buildInfoChip(context, '${pack.aliases.length} aliases', isSelected),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildInfoChip(BuildContext context, String label, bool isSelected) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.onPrimary.withValues(alpha: 0.2)
            : colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.chipRadius),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? colorScheme.onPrimary : colorScheme.primary,
        ),
      ),
    );
  }
}
