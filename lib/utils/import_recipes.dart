import '../database/database_helper.dart';
import '../models/recipe_pack.dart';

/// Imports all bundled recipe packs into the currently selected database backend.
///
/// This utility intentionally avoids direct `dart:io`, `dart:html`, or SQLite
/// imports so the package can be analyzed for both web and mobile targets.
Future<void> importBundledRecipePacks() async {
  final db = DatabaseHelper.instance;

  for (final pack in RecipePacks.allPacks) {
    for (final recipe in pack.recipes) {
      await db.createRecipe(recipe);
    }
    for (final alias in pack.aliases) {
      await db.createIngredientAlias(alias);
    }
  }
}
