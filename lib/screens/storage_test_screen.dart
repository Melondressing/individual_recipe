import 'dart:convert';

import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/recipe.dart';

class StorageTestScreen extends StatefulWidget {
  const StorageTestScreen({super.key});

  @override
  State<StorageTestScreen> createState() => _StorageTestScreenState();
}

class _StorageTestScreenState extends State<StorageTestScreen> {
  String _testResult = '';
  bool _isRunning = false;

  Future<void> _runTest() async {
    setState(() {
      _isRunning = true;
      _testResult = 'Running storage facade test...\n\n';
    });

    try {
      final db = DatabaseHelper.instance;
      final before = await db.exportData();
      final beforeRecipeCount = (before['recipes'] as List?)?.length ?? 0;
      final beforeAliasCount = (before['ingredientAliases'] as List?)?.length ?? 0;
      final beforeLogCount = (before['cookingLogs'] as List?)?.length ?? 0;
      final beforeReviewCount = (before['reviews'] as List?)?.length ?? 0;

      _testResult += 'Initial export OK\n';
      _testResult += '- recipes: $beforeRecipeCount\n';
      _testResult += '- aliases: $beforeAliasCount\n';
      _testResult += '- cooking logs: $beforeLogCount\n';
      _testResult += '- reviews: $beforeReviewCount\n\n';

      final now = DateTime.now().millisecondsSinceEpoch;
      final testRecipe = Recipe(
        id: 'storage_test_$now',
        name: 'Storage Test Recipe',
        type: 'recipe',
        categories: const ['test'],
        tags: const ['temporary'],
        ingredients: const ['water 100ml'],
        steps: const ['Add water', 'Finish test'],
        notes: const ['This recipe is created and deleted by the storage test.'],
        createdAt: now,
        updatedAt: now,
      );

      await db.createRecipe(testRecipe);
      _testResult += 'Create recipe OK\n';

      final loaded = await db.getRecipe(testRecipe.id);
      if (loaded == null || loaded.name != testRecipe.name) {
        throw StateError('Read-back validation failed.');
      }
      _testResult += 'Read recipe OK\n';

      final searchResults = await db.searchRecipes('Storage Test');
      if (!searchResults.any((recipe) => recipe.id == testRecipe.id)) {
        throw StateError('Search validation failed.');
      }
      _testResult += 'Search recipe OK\n';

      await db.deleteRecipe(testRecipe.id);
      final deleted = await db.getRecipe(testRecipe.id);
      if (deleted != null) {
        throw StateError('Delete validation failed.');
      }
      _testResult += 'Delete recipe OK\n\n';

      final after = await db.exportData();
      final encoded = const JsonEncoder.withIndent('  ').convert(after);
      _testResult += 'Final export OK\n';
      _testResult += 'Backup JSON size: ${encoded.length} chars\n\n';
      _testResult += 'ALL TESTS PASSED';
    } catch (e) {
      _testResult += '\nERROR: $e\n';
    } finally {
      if (mounted) {
        setState(() => _isRunning = false);
      }
    }
  }

  Future<void> _checkData() async {
    setState(() {
      _isRunning = true;
      _testResult = 'Checking current data...\n\n';
    });

    try {
      final data = await DatabaseHelper.instance.exportData();
      final recipes = data['recipes'] as List? ?? [];
      final aliases = data['ingredientAliases'] as List? ?? [];
      final logs = data['cookingLogs'] as List? ?? [];
      final reviews = data['reviews'] as List? ?? [];

      _testResult += 'recipes: ${recipes.length}\n';
      _testResult += 'aliases: ${aliases.length}\n';
      _testResult += 'cooking logs: ${logs.length}\n';
      _testResult += 'reviews: ${reviews.length}\n\n';

      if (recipes.isEmpty) {
        _testResult += 'No recipes found. Import a recipe pack from Settings > Recipe Packs.\n';
      } else {
        _testResult += 'First recipes:\n';
        for (var i = 0; i < recipes.length && i < 10; i++) {
          final recipe = recipes[i] as Map<String, dynamic>;
          _testResult += '${i + 1}. ${recipe['name']}\n';
        }
        if (recipes.length > 10) {
          _testResult += '... and ${recipes.length - 10} more\n';
        }
      }
    } catch (e) {
      _testResult += 'ERROR: $e\n';
    } finally {
      if (mounted) setState(() => _isRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Test'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Storage Facade Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Runs create/read/search/delete checks without clearing your saved data.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRunning ? null : _runTest,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Run Test'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRunning ? null : _checkData,
                    icon: const Icon(Icons.restaurant),
                    label: const Text('Check Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.black),
              ),
              child: Text(
                _testResult.isEmpty ? 'Click "Run Test" to start' : _testResult,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
