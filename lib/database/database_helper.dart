import '../models/recipe.dart';
import '../models/ingredient_alias.dart';
import '../models/cooking_log.dart';
import '../models/review.dart';
import 'database_helper_platform_stub.dart'
    if (dart.library.html) 'web_database_helper.dart'
    if (dart.library.io) 'database_helper_mobile.dart';

/// Cross-platform database facade.
///
/// The concrete backend is selected at compile time:
/// - Web: browser LocalStorage
/// - Android/iOS: SQLite via sqflite
///
/// Do not import `dart:html` or `dart:io` from UI files. Keep platform-only
/// APIs inside the backend files selected by conditional import.
class DatabaseHelper {
  static DatabaseHelper? _instance;
  static DatabaseHelper get instance {
    _instance ??= DatabaseHelper._init();
    return _instance!;
  }

  final dynamic _db;

  DatabaseHelper._init() : _db = createDatabaseBackend();

  // ==================== Recipe CRUD ====================

  Future<String> createRecipe(Recipe recipe) async {
    return await _db.createRecipe(recipe);
  }

  Future<Recipe?> getRecipe(String id) async {
    return await _db.getRecipe(id);
  }

  Future<List<Recipe>> getAllRecipes() async {
    return await _db.getAllRecipes();
  }

  Future<List<Recipe>> getDraftRecipes() async {
    return await _db.getDraftRecipes();
  }

  Future<List<Recipe>> getFavoriteRecipes() async {
    return await _db.getFavoriteRecipes();
  }

  Future<List<Recipe>> getRecentlyUsedRecipes({int limit = 10}) async {
    return await _db.getRecentlyUsedRecipes(limit: limit);
  }

  Future<List<Recipe>> getTopCookedRecipes({int limit = 3}) async {
    return await _db.getTopCookedRecipes(limit: limit);
  }

  Future<int> updateRecipe(Recipe recipe) async {
    return await _db.updateRecipe(recipe);
  }

  Future<int> deleteRecipe(String id) async {
    return await _db.deleteRecipe(id);
  }

  Future<void> markRecipeAsUsed(String recipeId) async {
    return await _db.markRecipeAsUsed(recipeId);
  }

  // ==================== Search ====================

  Future<List<Recipe>> searchRecipes(String query) async {
    return await _db.searchRecipes(query);
  }

  // ==================== Ingredient Alias CRUD ====================

  Future<String> createIngredientAlias(IngredientAlias alias) async {
    return await _db.createIngredientAlias(alias);
  }

  Future<List<IngredientAlias>> getAllIngredientAliases() async {
    return await _db.getAllIngredientAliases();
  }

  Future<int> updateIngredientAlias(IngredientAlias alias) async {
    return await _db.updateIngredientAlias(alias);
  }

  Future<int> deleteIngredientAlias(String id) async {
    return await _db.deleteIngredientAlias(id);
  }

  // ==================== Cooking Log CRUD ====================

  Future<String> createCookingLog(CookingLog log) async {
    return await _db.createCookingLog(log);
  }

  Future<List<CookingLog>> getAllCookingLogs() async {
    return await _db.getAllCookingLogs();
  }

  Future<List<CookingLog>> getCookingLogsByRecipe(String recipeId) async {
    return await _db.getCookingLogsByRecipe(recipeId);
  }

  Future<int> deleteCookingLog(String id) async {
    return await _db.deleteCookingLog(id);
  }

  // ==================== Review CRUD ====================

  Future<String> createReview(Review review) async {
    return await _db.createReview(review);
  }

  Future<List<Review>> getReviewsByRecipe(String recipeId) async {
    return await _db.getReviewsByRecipe(recipeId);
  }

  Future<int> deleteReview(String id) async {
    return await _db.deleteReview(id);
  }

  // ==================== Backup / Restore / Reset ====================

  Future<Map<String, dynamic>> exportData() async {
    return await _db.exportData();
  }

  Future<void> importData(Map<String, dynamic> data) async {
    return await _db.importData(data);
  }

  Future<void> clearAll() async {
    return await _db.clearAll();
  }

  Future<void> close() async {
    return await _db.close();
  }
}
