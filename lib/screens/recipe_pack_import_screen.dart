import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/database_helper.dart';
import '../models/recipe_pack.dart';
import '../providers/alias_provider.dart';
import '../providers/recipe_provider.dart';

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

                return Card(
                  elevation: 0,
                  color: isSelected ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(
                      color: isSelected ? Colors.black : const Color(0xFFE0E0E0),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: () => _togglePack(pack.id, !isSelected),
                    borderRadius: BorderRadius.circular(4),
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
                                activeColor: Colors.black,
                                checkColor: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  pack.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : Colors.black,
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
                                        ? Colors.white.withValues(alpha: 0.8)
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    _buildInfoChip('${pack.recipes.length} recipes', isSelected),
                                    if (pack.aliases.isNotEmpty)
                                      _buildInfoChip('${pack.aliases.length} aliases', isSelected),
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

  Widget _buildInfoChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : Colors.grey.shade700,
        ),
      ),
    );
  }
}
