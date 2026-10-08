// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/foundation.dart';

import '../models/cooking_log.dart';
import '../models/ingredient_alias.dart';
import '../models/recipe.dart';
import '../models/review.dart';

dynamic createDatabaseBackend() => WebDatabaseHelper.instance;

class WebDatabaseHelper {
  static WebDatabaseHelper? _instance;
  static WebDatabaseHelper get instance {
    _instance ??= WebDatabaseHelper._init();
    return _instance!;
  }

  WebDatabaseHelper._init() {
    _migrateLegacyKeysIfNeeded();
    if (kDebugMode) debugPrint('🌐 [Web DB] Initialized with LocalStorage');
  }

  static const String _recipesKey = 'flutter.individual_recipe.recipes';
  static const String _aliasesKey = 'flutter.individual_recipe.aliases';
  static const String _usageLogKey = 'flutter.individual_recipe.usage_log';
  static const String _cookingLogsKey = 'flutter.individual_recipe.cooking_logs';
  static const String _reviewsKey = 'flutter.individual_recipe.reviews';

  static const String _legacyRecipesKey = 'flutter.recipe_keeper.recipes';
  static const String _legacyAliasesKey = 'flutter.recipe_keeper.aliases';
  static const String _legacyUsageLogKey = 'flutter.recipe_keeper.usage_log';
  static const String _legacyCookingLogsKey = 'flutter.recipe_keeper.cooking_logs';
  static const String _legacyReviewsKey = 'flutter.recipe_keeper.reviews';

  html.Storage get _storage => html.window.localStorage;

  void _migrateLegacyKeysIfNeeded() {
    _copyLegacyValue(_legacyRecipesKey, _recipesKey);
    _copyLegacyValue(_legacyAliasesKey, _aliasesKey);
    _copyLegacyValue(_legacyUsageLogKey, _usageLogKey);
    _copyLegacyValue(_legacyCookingLogsKey, _cookingLogsKey);
    _copyLegacyValue(_legacyReviewsKey, _reviewsKey);
  }

  void _copyLegacyValue(String legacyKey, String newKey) {
    final current = _storage[newKey];
    final legacy = _storage[legacyKey];
    if ((current == null || current.isEmpty) && legacy != null && legacy.isNotEmpty) {
      _storage[newKey] = legacy;
      if (kDebugMode) debugPrint('🔁 [Web DB] Migrated $legacyKey → $newKey');
    }
  }

  List<T> _readList<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final raw = _storage[key];
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = json.decode(raw);
      if (decoded is! List) return [];
      return decoded.map((item) => fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Web DB] Failed to read $key: $e');
      return [];
    }
  }

  void _writeList<T>(String key, List<T> items, Map<String, dynamic> Function(T) toJson) {
    _storage[key] = json.encode(items.map(toJson).toList());
  }

  Future<String> createRecipe(Recipe recipe) async {
    final recipes = await getAllRecipes();
    final index = recipes.indexWhere((r) => r.id == recipe.id);
    if (index >= 0) {
      recipes[index] = recipe;
    } else {
      recipes.add(recipe);
    }
    _writeList<Recipe>(_recipesKey, recipes, (recipe) => recipe.toJson());
    return recipe.id;
  }

  Future<Recipe?> getRecipe(String id) async {
    final recipes = await getAllRecipes();
    final matches = recipes.where((recipe) => recipe.id == id);
    return matches.isEmpty ? null : matches.first;
  }

  Future<List<Recipe>> getAllRecipes() async {
    final recipes = _readList<Recipe>(_recipesKey, Recipe.fromJson)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return recipes;
  }

  Future<List<Recipe>> getDraftRecipes() async {
    final recipes = await getAllRecipes();
    return recipes.where((recipe) => recipe.isDraft).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<Recipe>> getFavoriteRecipes() async {
    final recipes = await getAllRecipes();
    return recipes.where((recipe) => recipe.isFavorite).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<List<Recipe>> getRecentlyUsedRecipes({int limit = 10}) async {
    final recipes = await getAllRecipes();
    final used = recipes.where((recipe) => recipe.lastUsedAt > 0).toList()
      ..sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
    return used.take(limit).toList();
  }

  Future<List<Recipe>> getTopCookedRecipes({int limit = 3}) async {
    final recipes = await getAllRecipes();
    final cooked = recipes.where((recipe) => recipe.cookCount > 0).toList()
      ..sort((a, b) => b.cookCount.compareTo(a.cookCount));
    return cooked.take(limit).toList();
  }

  Future<int> updateRecipe(Recipe recipe) async {
    final recipes = await getAllRecipes();
    final index = recipes.indexWhere((r) => r.id == recipe.id);
    if (index < 0) return 0;
    recipes[index] = recipe;
    _writeList<Recipe>(_recipesKey, recipes, (recipe) => recipe.toJson());
    return 1;
  }

  Future<int> deleteRecipe(String id) async {
    final recipes = await getAllRecipes();
    final originalLength = recipes.length;
    recipes.removeWhere((recipe) => recipe.id == id);
    _writeList<Recipe>(_recipesKey, recipes, (recipe) => recipe.toJson());

    final logs = await getAllCookingLogs();
    logs.removeWhere((log) => log.recipeId == id);
    _writeList<CookingLog>(_cookingLogsKey, logs, (log) => log.toJson());

    final reviews = await getAllReviews();
    reviews.removeWhere((review) => review.recipeId == id);
    _writeList<Review>(_reviewsKey, reviews, (review) => review.toJson());

    return recipes.length == originalLength ? 0 : 1;
  }

  Future<void> markRecipeAsUsed(String recipeId) async {
    final recipe = await getRecipe(recipeId);
    if (recipe == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    await updateRecipe(
      recipe.copyWith(
        cookCount: recipe.cookCount + 1,
        updatedAt: now,
        lastUsedAt: now,
      ),
    );

    final rawLog = _storage[_usageLogKey] ?? '[]';
    final decodedLog = json.decode(rawLog);
    final log = decodedLog is List ? decodedLog : <dynamic>[];
    log.add({'recipeId': recipeId, 'timestamp': now});
    _storage[_usageLogKey] = json.encode(log);
  }

  Future<List<Recipe>> searchRecipes(String query) async {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return [];

    final recipes = await getAllRecipes();
    final expandedQueries = await _expandSearchQuery(trimmed);

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
      return expandedQueries.any(text.contains);
    }).toList();
  }

  Future<List<String>> _expandSearchQuery(String query) async {
    final queries = <String>{query.toLowerCase()};
    final aliases = await getAllIngredientAliases();

    for (final alias in aliases) {
      final aliasLower = alias.alias.toLowerCase();
      final canonicalLower = alias.canonical.toLowerCase();

      if (aliasLower == query || canonicalLower == query) {
        queries.add(aliasLower);
        queries.add(canonicalLower);
        for (final related in aliases.where((a) => a.canonical.toLowerCase() == canonicalLower)) {
          queries.add(related.alias.toLowerCase());
        }
      }
    }

    return queries.toList();
  }

  Future<String> createIngredientAlias(IngredientAlias alias) async {
    final aliases = await getAllIngredientAliases();
    final index = aliases.indexWhere((a) => a.id == alias.id);
    if (index >= 0) {
      aliases[index] = alias;
    } else {
      aliases.add(alias);
    }
    _writeList<IngredientAlias>(_aliasesKey, aliases, (alias) => alias.toJson());
    return alias.id;
  }

  Future<List<IngredientAlias>> getAllIngredientAliases() async {
    final aliases = _readList<IngredientAlias>(_aliasesKey, IngredientAlias.fromJson)
      ..sort((a, b) {
        final byCanonical = a.canonical.compareTo(b.canonical);
        return byCanonical != 0 ? byCanonical : a.alias.compareTo(b.alias);
      });
    return aliases;
  }

  Future<int> updateIngredientAlias(IngredientAlias alias) async {
    final aliases = await getAllIngredientAliases();
    final index = aliases.indexWhere((a) => a.id == alias.id);
    if (index < 0) return 0;
    aliases[index] = alias;
    _writeList<IngredientAlias>(_aliasesKey, aliases, (alias) => alias.toJson());
    return 1;
  }

  Future<int> deleteIngredientAlias(String id) async {
    final aliases = await getAllIngredientAliases();
    final originalLength = aliases.length;
    aliases.removeWhere((alias) => alias.id == id);
    _writeList<IngredientAlias>(_aliasesKey, aliases, (alias) => alias.toJson());
    return aliases.length == originalLength ? 0 : 1;
  }

  Future<String> createCookingLog(CookingLog log) async {
    final logs = await getAllCookingLogs();
    final index = logs.indexWhere((l) => l.id == log.id);
    if (index >= 0) {
      logs[index] = log;
    } else {
      logs.add(log);
    }
    logs.sort((a, b) => b.cookedAt.compareTo(a.cookedAt));
    _writeList<CookingLog>(_cookingLogsKey, logs, (log) => log.toJson());
    return log.id;
  }

  Future<List<CookingLog>> getAllCookingLogs() async {
    final logs = _readList<CookingLog>(_cookingLogsKey, CookingLog.fromJson)
      ..sort((a, b) => b.cookedAt.compareTo(a.cookedAt));
    return logs;
  }

  Future<List<CookingLog>> getCookingLogsByRecipe(String recipeId) async {
    final logs = await getAllCookingLogs();
    return logs.where((log) => log.recipeId == recipeId).toList();
  }

  Future<int> deleteCookingLog(String id) async {
    final logs = await getAllCookingLogs();
    final originalLength = logs.length;
    logs.removeWhere((log) => log.id == id);
    _writeList<CookingLog>(_cookingLogsKey, logs, (log) => log.toJson());
    return logs.length == originalLength ? 0 : 1;
  }

  Future<String> createReview(Review review) async {
    final reviews = await getAllReviews();
    final index = reviews.indexWhere((r) => r.id == review.id);
    if (index >= 0) {
      reviews[index] = review;
    } else {
      reviews.add(review);
    }
    reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _writeList<Review>(_reviewsKey, reviews, (review) => review.toJson());
    return review.id;
  }

  Future<List<Review>> getAllReviews() async {
    final reviews = _readList<Review>(_reviewsKey, Review.fromJson)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return reviews;
  }

  Future<List<Review>> getReviewsByRecipe(String recipeId) async {
    final reviews = await getAllReviews();
    return reviews.where((review) => review.recipeId == recipeId).toList();
  }

  Future<int> deleteReview(String id) async {
    final reviews = await getAllReviews();
    final originalLength = reviews.length;
    reviews.removeWhere((review) => review.id == id);
    _writeList<Review>(_reviewsKey, reviews, (review) => review.toJson());
    return reviews.length == originalLength ? 0 : 1;
  }

  Future<Map<String, dynamic>> exportData() async {
    final recipes = await getAllRecipes();
    final aliases = await getAllIngredientAliases();
    final cookingLogs = await getAllCookingLogs();
    final reviews = await getAllReviews();

    return {
      'meta': {
        'version': '1.1.0',
        'schemaVersion': 5,
        'exportedAt': DateTime.now().millisecondsSinceEpoch,
      },
      'recipes': recipes.map((r) => r.toJson()).toList(),
      'ingredientAliases': aliases.map((a) => a.toJson()).toList(),
      'cookingLogs': cookingLogs.map((l) => l.toJson()).toList(),
      'reviews': reviews.map((r) => r.toJson()).toList(),
    };
  }

  Future<void> importData(Map<String, dynamic> data) async {
    if (data['recipes'] != null) {
      final recipes = await getAllRecipes();
      for (final item in data['recipes'] as List) {
        final recipe = Recipe.fromJson(item as Map<String, dynamic>);
        recipes.removeWhere((r) => r.id == recipe.id);
        recipes.add(recipe);
      }
      _writeList<Recipe>(_recipesKey, recipes, (recipe) => recipe.toJson());
    }

    if (data['ingredientAliases'] != null) {
      final aliases = await getAllIngredientAliases();
      for (final item in data['ingredientAliases'] as List) {
        final alias = IngredientAlias.fromJson(item as Map<String, dynamic>);
        aliases.removeWhere((a) => a.id == alias.id);
        aliases.add(alias);
      }
      _writeList<IngredientAlias>(_aliasesKey, aliases, (alias) => alias.toJson());
    }

    if (data['cookingLogs'] != null) {
      final logs = await getAllCookingLogs();
      for (final item in data['cookingLogs'] as List) {
        final log = CookingLog.fromJson(item as Map<String, dynamic>);
        logs.removeWhere((l) => l.id == log.id);
        logs.add(log);
      }
      _writeList<CookingLog>(_cookingLogsKey, logs, (log) => log.toJson());
    }

    if (data['reviews'] != null) {
      final reviews = await getAllReviews();
      for (final item in data['reviews'] as List) {
        final review = Review.fromJson(item as Map<String, dynamic>);
        reviews.removeWhere((r) => r.id == review.id);
        reviews.add(review);
      }
      _writeList<Review>(_reviewsKey, reviews, (review) => review.toJson());
    }
  }

  Future<void> clearAll() async {
    _storage.remove(_recipesKey);
    _storage.remove(_aliasesKey);
    _storage.remove(_usageLogKey);
    _storage.remove(_cookingLogsKey);
    _storage.remove(_reviewsKey);
    if (kDebugMode) debugPrint('🗑️ [Web DB] All data cleared');
  }

  Future<void> close() async {
    // No-op for web.
  }
}
