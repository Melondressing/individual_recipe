# Rebuild Notes — Individual Recipe v1.1.0+4

## Applied changes

1. Removed Firebase dependency direction from the project.
2. Kept the app identity as Individual Recipe.
3. Added `RecipeFilterService` for search, category matching, grouping, sorting, and count calculation.
4. Fixed category chip count logic so choosing one cuisine no longer makes other cuisine counts fall to zero.
5. Rebuilt `SearchScreen` to use the service instead of embedding filtering logic inside the widget.
6. Fixed duplicate/invalid widget properties found in `SearchScreen`, `SettingsScreen`, and `RecipeEditScreen`.
7. Rebuilt `RecipeEditScreen` with safer save-state handling, suggested category chips, cuisine selection, cooking-method chips, description, prep/cook time, and servings.
8. Rebuilt `CookingModeScreen` with empty-step protection and safer async navigation.
9. Added persistent Review storage:
   - Web LocalStorage key: `flutter.individual_recipe.reviews`
   - Mobile SQLite table: `reviews`
   - Included reviews in JSON export/import/reset
10. Upgraded mobile DB schema to version 5, added indexes, and added structured recipe clarity columns.
11. Added legacy Web LocalStorage migration from previous `recipe_keeper` keys to `individual_recipe` keys.
12. Improved `RecipeProvider` so it loads recipes once and derives secondary lists in memory.
13. Updated test coverage for recipe serialization, category-count filtering behavior, and automatic cuisine/method inference.
14. Recipe cards and detail screens now display description, cuisine, cooking methods, time, and yield when available.

## Test commands

```bash
flutter clean
rm -f pubspec.lock
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

## Expected `flutter pub get` result

Firebase packages should not appear. If packages like `firebase_core`, `cloud_firestore`, or `_flutterfire_internals` appear, the old folder is being used.

## Known limits

This is still an offline-first testable build. Cloudflare hosting will serve the app, but user data remains browser-local unless a Cloudflare backend is added later.
