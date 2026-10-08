import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/cooking_log.dart';
import '../models/ingredient_alias.dart';
import '../models/recipe.dart';
import '../models/review.dart';

dynamic createDatabaseBackend() => MobileDatabaseHelper.instance;

class MobileDatabaseHelper {
  static MobileDatabaseHelper? _instance;
  static MobileDatabaseHelper get instance {
    _instance ??= MobileDatabaseHelper._init();
    return _instance!;
  }

  static Database? _database;

  MobileDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('individual_recipe.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE recipes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT DEFAULT '',
        type TEXT NOT NULL DEFAULT 'recipe',
        cuisine TEXT DEFAULT 'other',
        categories TEXT,
        tags TEXT,
        cookingMethods TEXT,
        ingredients TEXT,
        steps TEXT,
        notes TEXT,
        images TEXT,
        prepMinutes INTEGER DEFAULT 0,
        cookMinutes INTEGER DEFAULT 0,
        servings INTEGER DEFAULT 0,
        effortLevel INTEGER DEFAULT 2,
        cookCount INTEGER DEFAULT 0,
        isFavorite INTEGER DEFAULT 0,
        isDraft INTEGER DEFAULT 0,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        lastUsedAt INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE ingredient_aliases (
        id TEXT PRIMARY KEY,
        alias TEXT NOT NULL,
        canonical TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE usage_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipeId TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');

    await _createCookingLogsTable(db);
    await _createReviewsTable(db);
    await _createIndexes(db);

    await db.execute('''
      CREATE TABLE meta (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    await db.insert('meta', {'key': 'schemaVersion', 'value': '5'});
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createCookingLogsTable(db);
    }
    if (oldVersion < 4) {
      await _createReviewsTable(db);
    }
    if (oldVersion < 5) {
      await _upgradeRecipesToV5(db);
    }
    if (oldVersion < 3) {
      await _createIndexes(db);
    }
    await _createIndexes(db);
    await db.insert(
      'meta',
      {'key': 'schemaVersion', 'value': '5'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _createCookingLogsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cooking_logs (
        id TEXT PRIMARY KEY,
        recipeId TEXT NOT NULL,
        recipeName TEXT NOT NULL,
        cookedAt INTEGER NOT NULL,
        images TEXT,
        notes TEXT,
        rating INTEGER DEFAULT 0,
        tags TEXT
      )
    ''');
  }

  Future<void> _createReviewsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reviews (
        id TEXT PRIMARY KEY,
        recipeId TEXT NOT NULL,
        recipeName TEXT NOT NULL,
        userName TEXT NOT NULL,
        text TEXT NOT NULL,
        rating INTEGER DEFAULT 0,
        photoUrls TEXT,
        createdAt INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _upgradeRecipesToV5(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(recipes)');
    final existing = columns.map((column) => column['name'] as String).toSet();

    Future<void> addColumn(String name, String definition) async {
      if (!existing.contains(name)) {
        await db.execute('ALTER TABLE recipes ADD COLUMN $name $definition');
      }
    }

    await addColumn('description', "TEXT DEFAULT ''");
    await addColumn('cuisine', "TEXT DEFAULT 'other'");
    await addColumn('cookingMethods', 'TEXT');
    await addColumn('prepMinutes', 'INTEGER DEFAULT 0');
    await addColumn('cookMinutes', 'INTEGER DEFAULT 0');
    await addColumn('servings', 'INTEGER DEFAULT 0');
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute('CREATE INDEX IF NOT EXISTS idx_recipes_updatedAt ON recipes(updatedAt DESC)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_recipes_lastUsedAt ON recipes(lastUsedAt DESC)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_recipes_cookCount ON recipes(cookCount DESC)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_cooking_logs_recipeId ON cooking_logs(recipeId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_cooking_logs_cookedAt ON cooking_logs(cookedAt DESC)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_reviews_recipeId ON reviews(recipeId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_reviews_createdAt ON reviews(createdAt DESC)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_aliases_canonical ON ingredient_aliases(canonical)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_aliases_alias ON ingredient_aliases(alias)');
  }

  Future<String> createRecipe(Recipe recipe) async {
    final db = await database;
    await db.insert('recipes', recipe.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return recipe.id;
  }

  Future<Recipe?> getRecipe(String id) async {
    final db = await database;
    final maps = await db.query('recipes', where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? Recipe.fromMap(maps.first) : null;
  }

  Future<List<Recipe>> getAllRecipes() async {
    final db = await database;
    final maps = await db.query('recipes', orderBy: 'updatedAt DESC');
    return maps.map((map) => Recipe.fromMap(map)).toList();
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
    final db = await database;
    return db.update('recipes', recipe.toMap(), where: 'id = ?', whereArgs: [recipe.id]);
  }

  Future<int> deleteRecipe(String id) async {
    final db = await database;
    await db.delete('usage_log', where: 'recipeId = ?', whereArgs: [id]);
    await db.delete('cooking_logs', where: 'recipeId = ?', whereArgs: [id]);
    await db.delete('reviews', where: 'recipeId = ?', whereArgs: [id]);
    return db.delete('recipes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markRecipeAsUsed(String recipeId) async {
    final db = await database;
    final recipe = await getRecipe(recipeId);
    if (recipe == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      await txn.update(
        'recipes',
        {
          'cookCount': recipe.cookCount + 1,
          'updatedAt': now,
          'lastUsedAt': now,
        },
        where: 'id = ?',
        whereArgs: [recipeId],
      );
      await txn.insert('usage_log', {'recipeId': recipeId, 'timestamp': now});
    });
  }

  Future<List<Recipe>> searchRecipes(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final db = await database;
    final expandedQueries = await _expandSearchQuery(trimmed);
    final whereConditions = <String>[];
    final whereArgs = <String>[];

    for (final q in expandedQueries) {
      whereConditions.add(
        '(LOWER(name) LIKE ? OR LOWER(description) LIKE ? OR LOWER(type) LIKE ? OR LOWER(cuisine) LIKE ? OR LOWER(ingredients) LIKE ? OR LOWER(steps) LIKE ? OR LOWER(tags) LIKE ? OR LOWER(categories) LIKE ? OR LOWER(cookingMethods) LIKE ? OR LOWER(notes) LIKE ?)',
      );
      final likePattern = '%${q.toLowerCase()}%';
      whereArgs.addAll([
        likePattern,
        likePattern,
        likePattern,
        likePattern,
        likePattern,
        likePattern,
        likePattern,
        likePattern,
        likePattern,
        likePattern,
      ]);
    }

    final maps = await db.query(
      'recipes',
      where: whereConditions.join(' OR '),
      whereArgs: whereArgs,
      orderBy: 'updatedAt DESC',
    );

    return maps.map((map) => Recipe.fromMap(map)).toList();
  }

  Future<List<String>> _expandSearchQuery(String query) async {
    final db = await database;
    final queries = <String>{query.toLowerCase()};

    final aliasMaps = await db.query(
      'ingredient_aliases',
      where: 'LOWER(alias) = ? OR LOWER(canonical) = ?',
      whereArgs: [query.toLowerCase(), query.toLowerCase()],
    );

    for (final map in aliasMaps) {
      final canonical = map['canonical'] as String;
      queries.add(canonical.toLowerCase());
      final relatedMaps = await db.query(
        'ingredient_aliases',
        where: 'LOWER(canonical) = ?',
        whereArgs: [canonical.toLowerCase()],
      );
      for (final related in relatedMaps) {
        queries.add((related['alias'] as String).toLowerCase());
      }
    }

    return queries.toList();
  }

  Future<String> createIngredientAlias(IngredientAlias alias) async {
    final db = await database;
    await db.insert(
      'ingredient_aliases',
      alias.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return alias.id;
  }

  Future<List<IngredientAlias>> getAllIngredientAliases() async {
    final db = await database;
    final maps = await db.query('ingredient_aliases', orderBy: 'canonical ASC, alias ASC');
    return maps.map((map) => IngredientAlias.fromMap(map)).toList();
  }

  Future<int> updateIngredientAlias(IngredientAlias alias) async {
    final db = await database;
    return db.update(
      'ingredient_aliases',
      alias.toMap(),
      where: 'id = ?',
      whereArgs: [alias.id],
    );
  }

  Future<int> deleteIngredientAlias(String id) async {
    final db = await database;
    return db.delete('ingredient_aliases', where: 'id = ?', whereArgs: [id]);
  }

  Future<String> createCookingLog(CookingLog log) async {
    final db = await database;
    await db.insert('cooking_logs', log.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return log.id;
  }

  Future<List<CookingLog>> getAllCookingLogs() async {
    final db = await database;
    final maps = await db.query('cooking_logs', orderBy: 'cookedAt DESC');
    return maps.map((map) => CookingLog.fromMap(map)).toList();
  }

  Future<List<CookingLog>> getCookingLogsByRecipe(String recipeId) async {
    final db = await database;
    final maps = await db.query(
      'cooking_logs',
      where: 'recipeId = ?',
      whereArgs: [recipeId],
      orderBy: 'cookedAt DESC',
    );
    return maps.map((map) => CookingLog.fromMap(map)).toList();
  }

  Future<int> deleteCookingLog(String id) async {
    final db = await database;
    return db.delete('cooking_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<String> createReview(Review review) async {
    final db = await database;
    await db.insert('reviews', review.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return review.id;
  }

  Future<List<Review>> getReviewsByRecipe(String recipeId) async {
    final db = await database;
    final maps = await db.query(
      'reviews',
      where: 'recipeId = ?',
      whereArgs: [recipeId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Review.fromMap(map)).toList();
  }

  Future<List<Review>> getAllReviews() async {
    final db = await database;
    final maps = await db.query('reviews', orderBy: 'createdAt DESC');
    return maps.map((map) => Review.fromMap(map)).toList();
  }

  Future<int> deleteReview(String id) async {
    final db = await database;
    return db.delete('reviews', where: 'id = ?', whereArgs: [id]);
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
    final db = await database;

    await db.transaction((txn) async {
      if (data['recipes'] != null) {
        for (final recipeJson in data['recipes'] as List) {
          final recipe = Recipe.fromJson(recipeJson as Map<String, dynamic>);
          await txn.insert('recipes', recipe.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      if (data['ingredientAliases'] != null) {
        for (final aliasJson in data['ingredientAliases'] as List) {
          final alias = IngredientAlias.fromJson(aliasJson as Map<String, dynamic>);
          await txn.insert('ingredient_aliases', alias.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      if (data['cookingLogs'] != null) {
        for (final logJson in data['cookingLogs'] as List) {
          final log = CookingLog.fromJson(logJson as Map<String, dynamic>);
          await txn.insert('cooking_logs', log.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      if (data['reviews'] != null) {
        for (final reviewJson in data['reviews'] as List) {
          final review = Review.fromJson(reviewJson as Map<String, dynamic>);
          await txn.insert('reviews', review.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('usage_log');
      await txn.delete('cooking_logs');
      await txn.delete('reviews');
      await txn.delete('ingredient_aliases');
      await txn.delete('recipes');
      await txn.insert(
        'meta',
        {'key': 'schemaVersion', 'value': '5'},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
