import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/recipe.dart';
import '../models/shopping_list_item.dart';

class ShoppingListProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<ShoppingListItem> _items = [];
  bool _isLoading = false;
  String? _error;

  List<ShoppingListItem> get items => _items;
  List<ShoppingListItem> get uncheckedItems => _items.where((item) => !item.isChecked).toList();
  List<ShoppingListItem> get checkedItems => _items.where((item) => item.isChecked).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _db.getAllShoppingListItems();
    } catch (e) {
      _error = 'Failed to load shopping list: $e';
      if (kDebugMode) debugPrint('Error loading shopping list: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addItem(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    try {
      final item = ShoppingListItem(
        id: 'shopping_${DateTime.now().millisecondsSinceEpoch}',
        name: trimmed,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      await _db.createShoppingListItem(item);
      await loadItems();
    } catch (e) {
      _error = 'Failed to add item: $e';
      notifyListeners();
    }
  }

  /// 레시피의 재료를 한 번에 장보기 목록에 추가한다.
  Future<void> addIngredientsFromRecipe(Recipe recipe) async {
    if (recipe.ingredients.isEmpty) return;

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      for (var i = 0; i < recipe.ingredients.length; i++) {
        final item = ShoppingListItem(
          id: 'shopping_${now}_$i',
          name: recipe.ingredients[i],
          recipeId: recipe.id,
          recipeName: recipe.name,
          createdAt: now,
        );
        await _db.createShoppingListItem(item);
      }
      await loadItems();
    } catch (e) {
      _error = 'Failed to add ingredients: $e';
      notifyListeners();
    }
  }

  Future<void> toggleChecked(ShoppingListItem item) async {
    try {
      await _db.updateShoppingListItem(item.copyWith(isChecked: !item.isChecked));
      await loadItems();
    } catch (e) {
      _error = 'Failed to update item: $e';
      notifyListeners();
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await _db.deleteShoppingListItem(id);
      await loadItems();
    } catch (e) {
      _error = 'Failed to delete item: $e';
      notifyListeners();
    }
  }

  Future<void> clearChecked() async {
    try {
      await _db.clearCheckedShoppingListItems();
      await loadItems();
    } catch (e) {
      _error = 'Failed to clear checked items: $e';
      notifyListeners();
    }
  }

  Future<void> clearAll() async {
    try {
      await _db.clearAllShoppingListItems();
      await loadItems();
    } catch (e) {
      _error = 'Failed to clear shopping list: $e';
      notifyListeners();
    }
  }
}
