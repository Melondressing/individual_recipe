import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/recipe.dart';

class RecipeProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Recipe> _allRecipes = [];
  List<Recipe> _draftRecipes = [];
  List<Recipe> _favoriteRecipes = [];
  List<Recipe> _recentRecipes = [];
  List<Recipe> _topCookedRecipes = [];
  List<Recipe> _searchResults = [];

  bool _isLoading = false;
  String? _error;

  List<Recipe> get allRecipes => List.unmodifiable(_allRecipes);
  List<Recipe> get draftRecipes => List.unmodifiable(_draftRecipes);
  List<Recipe> get favoriteRecipes => List.unmodifiable(_favoriteRecipes);
  List<Recipe> get recentRecipes => List.unmodifiable(_recentRecipes);
  List<Recipe> get topCookedRecipes => List.unmodifiable(_topCookedRecipes);
  List<Recipe> get searchResults => List.unmodifiable(_searchResults);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAllData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final recipes = await _db.getAllRecipes();
      _applyRecipeCache(recipes);

      if (kDebugMode) {
        debugPrint(
          '📚 [Provider] Loaded data: ${_allRecipes.length} total, '
          '${_draftRecipes.length} drafts, ${_favoriteRecipes.length} favorites, '
          '${_recentRecipes.length} recent, ${_topCookedRecipes.length} top cooked',
        );
      }
    } catch (e) {
      _error = 'Failed to load recipes: $e';
      if (kDebugMode) debugPrint('❌ [Provider] Error loading data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyRecipeCache(List<Recipe> recipes) {
    _allRecipes = List<Recipe>.from(recipes)..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    _draftRecipes = _allRecipes.where((recipe) => recipe.isDraft).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _favoriteRecipes = _allRecipes.where((recipe) => recipe.isFavorite).toList()
      ..sort((a, b) {
        final aTime = a.lastUsedAt > 0 ? a.lastUsedAt : a.updatedAt;
        final bTime = b.lastUsedAt > 0 ? b.lastUsedAt : b.updatedAt;
        return bTime.compareTo(aTime);
      });

    _recentRecipes = _allRecipes.where((recipe) => recipe.lastUsedAt > 0).toList()
      ..sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
    _recentRecipes = _recentRecipes.take(10).toList();

    _topCookedRecipes = _allRecipes.where((recipe) => recipe.cookCount > 0).toList()
      ..sort((a, b) => b.cookCount.compareTo(a.cookCount));
    _topCookedRecipes = _topCookedRecipes.take(3).toList();
  }

  Future<void> createRecipe(Recipe recipe) async {
    try {
      await _db.createRecipe(recipe);
      await loadAllData();
    } catch (e) {
      _error = 'Failed to create recipe: $e';
      notifyListeners();
    }
  }

  Future<void> updateRecipe(Recipe recipe) async {
    try {
      await _db.updateRecipe(recipe);
      await loadAllData();
    } catch (e) {
      _error = 'Failed to update recipe: $e';
      notifyListeners();
    }
  }

  Future<void> deleteRecipe(String id) async {
    try {
      await _db.deleteRecipe(id);
      await loadAllData();
    } catch (e) {
      _error = 'Failed to delete recipe: $e';
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(Recipe recipe) async {
    try {
      final updated = recipe.copyWith(
        isFavorite: !recipe.isFavorite,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await _db.updateRecipe(updated);
      await loadAllData();
    } catch (e) {
      _error = 'Failed to toggle favorite: $e';
      notifyListeners();
    }
  }

  Future<void> markAsUsed(String recipeId) async {
    try {
      await _db.markRecipeAsUsed(recipeId);
      await loadAllData();
    } catch (e) {
      _error = 'Failed to mark recipe as used: $e';
      notifyListeners();
    }
  }

  Future<void> searchRecipes(String query) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _searchResults = await _db.searchRecipes(query);
    } catch (e) {
      _error = 'Search failed: $e';
      _searchResults = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }

  Future<Recipe?> getRecipe(String id) async {
    try {
      final cached = _allRecipes.where((recipe) => recipe.id == id);
      if (cached.isNotEmpty) return cached.first;
      return await _db.getRecipe(id);
    } catch (e) {
      _error = 'Failed to get recipe: $e';
      notifyListeners();
      return null;
    }
  }
}
