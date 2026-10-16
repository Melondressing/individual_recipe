import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ingredient_alias.dart';
import '../models/recipe.dart';
import '../providers/alias_provider.dart';
import '../providers/recipe_provider.dart';

class IngredientStatsScreen extends StatelessWidget {
  const IngredientStatsScreen({super.key});

  static final RegExp _parenthetical = RegExp(r'\([^)]*\)');
  static final RegExp _unitsAndNumbers = RegExp(
    r'[0-9]+(\.[0-9]+)?\s*(g|kg|ml|l|oz|lb|tbsp|tsp|cup|cups|개|컵|큰술|작은술|알|봉|팩|줌|쪽|장|마리|컵|대|통|모|스푼|티스푼|그램|리터)?',
    caseSensitive: false,
  );
  static final RegExp _extraWhitespace = RegExp(r'\s+');

  String _cleanIngredientName(String raw) {
    var text = raw.replaceAll(_parenthetical, '');
    text = text.replaceAll(_unitsAndNumbers, ' ');
    text = text.replaceAll(RegExp(r'[,.\-·/]'), ' ');
    text = text.replaceAll(_extraWhitespace, ' ').trim();
    return text;
  }

  String _canonicalize(String cleanedName, List<IngredientAlias> aliases) {
    final lower = cleanedName.toLowerCase();
    for (final alias in aliases) {
      if (alias.alias.toLowerCase() == lower) return alias.canonical;
    }
    return cleanedName;
  }

  Map<String, int> _computeFrequency(List<Recipe> recipes, List<IngredientAlias> aliases) {
    final frequency = <String, int>{};

    for (final recipe in recipes) {
      final seenInRecipe = <String>{};
      for (final rawIngredient in recipe.ingredients) {
        final cleaned = _cleanIngredientName(rawIngredient);
        if (cleaned.isEmpty) continue;
        final canonical = _canonicalize(cleaned, aliases);
        if (seenInRecipe.contains(canonical)) continue;
        seenInRecipe.add(canonical);
        frequency[canonical] = (frequency[canonical] ?? 0) + 1;
      }
    }

    return frequency;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('재료별 통계')),
      body: Consumer2<RecipeProvider, AliasProvider>(
        builder: (context, recipeProvider, aliasProvider, child) {
          if (recipeProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final recipes = recipeProvider.allRecipes;
          if (recipes.isEmpty) {
            return Center(
              child: Text(
                '통계를 보려면 레시피를 먼저 추가하세요',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }

          final frequency = _computeFrequency(recipes, aliasProvider.aliases);
          if (frequency.isEmpty) {
            return Center(
              child: Text(
                '분석할 재료 정보가 없습니다',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }

          final sorted = frequency.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final top = sorted.take(15).toList();
          final maxCount = top.first.value;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '전체 ${recipes.length}개 레시피 중 가장 많이 사용된 재료',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
              const SizedBox(height: 16),
              ...top.asMap().entries.map((entry) {
                final rank = entry.key + 1;
                final name = entry.value.key;
                final count = entry.value.value;
                final fraction = count / maxCount;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          '$rank',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: Theme.of(context).textTheme.bodyLarge,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '$count회',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: fraction,
                                minHeight: 8,
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary.withOpacity(0.08),
                                valueColor: AlwaysStoppedAnimation(
                                  Theme.of(context).colorScheme.primary.withOpacity(0.3 + 0.7 * fraction),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
