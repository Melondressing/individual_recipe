import 'package:flutter_test/flutter_test.dart';
import 'package:individual_recipe/models/recipe.dart';
import 'package:individual_recipe/services/recipe_filter_service.dart';

void main() {
  test('Recipe JSON round-trip keeps core fields', () {
    final now = DateTime(2026, 4, 25).millisecondsSinceEpoch;
    final recipe = Recipe(
      id: 'test_recipe',
      name: 'Test Recipe',
      type: 'recipe',
      categories: const ['Korean', '한식'],
      tags: const ['quick'],
      ingredients: const ['rice', 'egg'],
      steps: const ['cook rice', 'fry egg'],
      notes: const ['test note'],
      images: const [],
      effortLevel: 2,
      cookCount: 3,
      isFavorite: true,
      isDraft: false,
      createdAt: now,
      updatedAt: now,
      lastUsedAt: now,
    );

    final restored = Recipe.fromJson(recipe.toJson());

    expect(restored.id, recipe.id);
    expect(restored.name, recipe.name);
    expect(restored.categories, recipe.categories);
    expect(restored.ingredients, recipe.ingredients);
    expect(restored.cookCount, recipe.cookCount);
    expect(restored.isFavorite, isTrue);
  });

  test('Category counts are calculated from searched recipes, not selected filter', () {
    final now = DateTime(2026, 4, 25).millisecondsSinceEpoch;
    final recipes = [
      Recipe(id: 'k1', name: '불고기', categories: const ['한식'], createdAt: now, updatedAt: now),
      Recipe(id: 'c1', name: '마파두부', categories: const ['중식'], createdAt: now, updatedAt: now),
      Recipe(id: 'i1', name: 'Carbonara', categories: const ['Italian', 'Pasta'], createdAt: now, updatedAt: now),
      Recipe(id: 's1', name: '불고기 소스', type: 'sauce', categories: const ['한식', '소스'], createdAt: now, updatedAt: now),
    ];

    final searched = RecipeFilterService.search(recipes, '');
    final counts = RecipeFilterService.countByCuisine(searched);
    final koreanOnly = RecipeFilterService.filterByCuisine(searched, RecipeFilterService.korean);

    expect(koreanOnly.length, 2);
    expect(counts[RecipeFilterService.all], 4);
    expect(counts[RecipeFilterService.korean], 2);
    expect(counts[RecipeFilterService.chinese], 1);
    expect(counts[RecipeFilterService.italian], 1);
    expect(counts[RecipeFilterService.sauce], 1);
  });

  test('Search matches multiple tokens using AND semantics', () {
    final now = DateTime(2026, 4, 25).millisecondsSinceEpoch;
    final recipes = [
      Recipe(
        id: 'r1',
        name: '불고기 소스',
        categories: const ['한식', '소스'],
        ingredients: const ['soy sauce', 'sugar', 'garlic'],
        createdAt: now,
        updatedAt: now,
      ),
      Recipe(
        id: 'r2',
        name: '김치찌개',
        categories: const ['한식'],
        ingredients: const ['kimchi', 'pork'],
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final results = RecipeFilterService.search(recipes, 'soy garlic');
    expect(results.map((r) => r.id), ['r1']);
  });
  test('Recipe automatically infers cuisine and cooking methods from existing packs', () {
    final now = DateTime(2026, 4, 25).millisecondsSinceEpoch;
    final recipe = Recipe(
      id: 'dakgalbi',
      name: '닭갈비',
      categories: const ['한식', '메인'],
      steps: const ['팬에서 닭고기와 야채를 볶는다', '양념을 넣고 마무리한다'],
      createdAt: now,
      updatedAt: now,
    );

    expect(recipe.cuisine, 'korean');
    expect(recipe.cookingMethods, contains('볶기'));
  });

}
