import 'package:flutter/foundation.dart';
import '../models/ingredient_alias.dart';
import '../database/database_helper.dart';

class AliasProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  
  List<IngredientAlias> _aliases = [];
  bool _isLoading = false;
  String? _error;

  List<IngredientAlias> get aliases => _aliases;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAliases() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _aliases = await _db.getAllIngredientAliases();
    } catch (e) {
      _error = 'Failed to load aliases: $e';
      if (kDebugMode) {
        debugPrint('Error loading aliases: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createAlias(IngredientAlias alias) async {
    try {
      await _db.createIngredientAlias(alias);
      await loadAliases();
    } catch (e) {
      _error = 'Failed to create alias: $e';
      notifyListeners();
    }
  }

  Future<void> updateAlias(IngredientAlias alias) async {
    try {
      await _db.updateIngredientAlias(alias);
      await loadAliases();
    } catch (e) {
      _error = 'Failed to update alias: $e';
      notifyListeners();
    }
  }

  Future<void> deleteAlias(String id) async {
    try {
      await _db.deleteIngredientAlias(id);
      await loadAliases();
    } catch (e) {
      _error = 'Failed to delete alias: $e';
      notifyListeners();
    }
  }
}
