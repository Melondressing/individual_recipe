import '../models/ingredient_alias.dart';
import '../models/recipe.dart';

/// Pure filtering, grouping, counting and sorting logic for recipes.
///
/// Keeping this out of the screen prevents the selected tab from contaminating
/// category counts and makes the logic testable without building widgets.
class RecipeFilterService {
  static const String all = 'all';
  static const String korean = 'korean';
  static const String chinese = 'chinese';
  static const String italian = 'italian';
  static const String french = 'french';
  static const String sauce = 'sauce';
  static const String other = 'other';

  static const List<String> cuisines = [
    all,
    korean,
    chinese,
    italian,
    french,
    sauce,
    other,
  ];

  static String labelFor(String cuisine) {
    switch (cuisine) {
      case korean:
        return '🇰🇷 한식';
      case chinese:
        return '🇨🇳 중식';
      case italian:
        return '🇮🇹 이탈리아';
      case french:
        return '🇫🇷 프렌치';
      case sauce:
        return '🍯 소스';
      case other:
        return '기타';
      case all:
      default:
        return '전체';
    }
  }

  /// [aliases] lets a search term also match recipes written with a
  /// synonym (e.g. searching "맛술" also finds recipes that only say
  /// "미림", and vice versa) via Settings > Manage Aliases. Each token is
  /// matched against the recipe if the token itself OR any of its known
  /// synonyms is found; tokens are still combined with AND.
  static List<Recipe> search(
    List<Recipe> recipes,
    String query, {
    List<IngredientAlias> aliases = const [],
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final tokens = normalizedQuery
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList();

    if (tokens.isEmpty) return List<Recipe>.from(recipes);

    // An alias pair can itself be a multi-word phrase (e.g. "두반장" <->
    // "중국 매운 콩된장"). If the whole query matches one side of such a
    // pair, treat it as a single unit instead of AND-ing its words apart,
    // or the phrase would never match the token-by-token loop below.
    final wholeQuerySynonyms = _expandToken(normalizedQuery, aliases);
    final tokenSynonyms = wholeQuerySynonyms.length > 1
        ? [wholeQuerySynonyms]
        : tokens.map((token) => _expandToken(token, aliases)).toList();

    return recipes.where((recipe) {
      final text = [
        recipe.name,
        recipe.description,
        recipe.type,
        recipe.cuisine,
        ...recipe.categories,
        ...recipe.tags,
        ...recipe.cookingMethods,
        ...recipe.ingredients,
        ...recipe.steps,
        ...recipe.notes,
      ].join(' ').toLowerCase();

      // AND search across tokens: "pork sauce" needs both words.
      // Within one token's synonym set, any match (OR) counts.
      return tokenSynonyms.every((synonyms) => synonyms.any(text.contains));
    }).toList();
  }

  /// Returns the token plus every alias/canonical term that shares a
  /// mapping with it (the same lookup the alias table is built for).
  static Set<String> _expandToken(String token, List<IngredientAlias> aliases) {
    final matchedCanonicals = <String>{};
    for (final entry in aliases) {
      final alias = entry.alias.toLowerCase();
      final canonical = entry.canonical.toLowerCase();
      if (alias == token || canonical == token) {
        matchedCanonicals.add(canonical);
      }
    }

    if (matchedCanonicals.isEmpty) return {token};

    final expanded = <String>{token, ...matchedCanonicals};
    for (final entry in aliases) {
      if (matchedCanonicals.contains(entry.canonical.toLowerCase())) {
        expanded.add(entry.alias.toLowerCase());
      }
    }
    return expanded;
  }

  static bool matchesCuisine(Recipe recipe, String cuisine) {
    if (cuisine == all) return true;
    if (cuisine == other) return primaryCuisine(recipe) == other;

    final categories = recipe.categories.map((c) => c.toLowerCase()).toList();
    final type = recipe.type.toLowerCase();
    final recipeCuisine = recipe.cuisine.toLowerCase();
    final tags = recipe.tags.map((t) => t.toLowerCase()).toList();
    final methods = recipe.cookingMethods.map((m) => m.toLowerCase()).toList();
    final combined = [recipeCuisine, ...categories, ...tags, ...methods].join(' ');

    switch (cuisine) {
      case korean:
        return recipeCuisine == korean || combined.contains('한식') || combined.contains('korean') || combined.contains('korea');
      case chinese:
        return recipeCuisine == chinese || combined.contains('중식') || combined.contains('중국') || combined.contains('chinese') || combined.contains('china');
      case italian:
        return recipeCuisine == italian || combined.contains('이탈리아') || combined.contains('italian') || combined.contains('italy') || combined.contains('파스타') || combined.contains('pasta');
      case french:
        return recipeCuisine == french || combined.contains('프렌치') || combined.contains('french') || combined.contains('france') || combined.contains('bistro');
      case sauce:
        return recipeCuisine == sauce || type == 'sauce' || combined.contains('소스') || combined.contains('sauce') || combined.contains('드레싱') || combined.contains('dressing');
      default:
        return true;
    }
  }

  /// A single primary bucket for grouped display. A sauce can still be counted
  /// under the sauce chip, but group display should not duplicate the same card
  /// under multiple sections.
  static String primaryCuisine(Recipe recipe) {
    if (matchesCuisine(recipe, sauce)) return sauce;
    if (matchesCuisine(recipe, korean)) return korean;
    if (matchesCuisine(recipe, chinese)) return chinese;
    if (matchesCuisine(recipe, italian)) return italian;
    if (matchesCuisine(recipe, french)) return french;
    return other;
  }

  static List<Recipe> filterByCuisine(List<Recipe> recipes, String cuisine) {
    if (cuisine == all) return List<Recipe>.from(recipes);
    return recipes.where((recipe) => matchesCuisine(recipe, cuisine)).toList();
  }

  static Map<String, int> countByCuisine(List<Recipe> recipes) {
    return {
      all: recipes.length,
      korean: recipes.where((r) => matchesCuisine(r, korean)).length,
      chinese: recipes.where((r) => matchesCuisine(r, chinese)).length,
      italian: recipes.where((r) => matchesCuisine(r, italian)).length,
      french: recipes.where((r) => matchesCuisine(r, french)).length,
      sauce: recipes.where((r) => matchesCuisine(r, sauce)).length,
      other: recipes.where((r) => primaryCuisine(r) == other).length,
    };
  }

  static Map<String, List<Recipe>> groupByPrimaryCuisine(List<Recipe> recipes, String sortBy) {
    final grouped = <String, List<Recipe>>{
      korean: <Recipe>[],
      chinese: <Recipe>[],
      italian: <Recipe>[],
      french: <Recipe>[],
      sauce: <Recipe>[],
      other: <Recipe>[],
    };

    for (final recipe in recipes) {
      grouped[primaryCuisine(recipe)]!.add(recipe);
    }

    for (final group in grouped.values) {
      sort(group, sortBy);
    }

    return grouped;
  }

  static void sort(List<Recipe> recipes, String sortBy) {
    switch (sortBy) {
      case 'cookCount':
        recipes.sort((a, b) {
          final byCookCount = b.cookCount.compareTo(a.cookCount);
          return byCookCount != 0 ? byCookCount : a.name.compareTo(b.name);
        });
        break;
      case 'recent':
        recipes.sort((a, b) {
          final aTime = a.lastUsedAt > 0 ? a.lastUsedAt : a.updatedAt;
          final bTime = b.lastUsedAt > 0 ? b.lastUsedAt : b.updatedAt;
          final byTime = bTime.compareTo(aTime);
          return byTime != 0 ? byTime : a.name.compareTo(b.name);
        });
        break;
      case 'name':
      default:
        recipes.sort((a, b) => a.name.compareTo(b.name));
    }
  }
}
