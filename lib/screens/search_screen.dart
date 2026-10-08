import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../services/recipe_filter_service.dart';
import '../widgets/recipe_card.dart';
import 'recipe_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCuisine = RecipeFilterService.all;
  String _sortBy = 'name';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openRecipe(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(recipeId: recipe.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('전체 레시피')),
      body: Consumer<RecipeProvider>(
        builder: (context, provider, child) {
          final query = _searchController.text.trim();
          final searched = RecipeFilterService.search(provider.allRecipes, query);
          final counts = RecipeFilterService.countByCuisine(searched);
          final filtered = RecipeFilterService.filterByCuisine(searched, _selectedCuisine);
          RecipeFilterService.sort(filtered, _sortBy);
          final grouped = RecipeFilterService.groupByPrimaryCuisine(filtered, _sortBy);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: '레시피, 재료, 태그, 조리법 검색...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _selectedCuisine = RecipeFilterService.all;
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              _CuisineFilterBar(
                selectedCuisine: _selectedCuisine,
                counts: counts,
                onSelected: (value) => setState(() => _selectedCuisine = value),
              ),
              const SizedBox(height: 8),
              _SortBar(
                selectedSort: _sortBy,
                onSelected: (value) => setState(() => _sortBy = value),
              ),
              const Divider(height: 24),
              Expanded(
                child: filtered.isEmpty
                    ? _EmptyState(
                        message: provider.allRecipes.isEmpty
                            ? '레시피가 없습니다. Settings > Recipe Packs에서 레시피를 먼저 가져오세요.'
                            : query.isEmpty
                                ? '선택한 카테고리에 레시피가 없습니다'
                                : '검색 결과가 없습니다',
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (_selectedCuisine == RecipeFilterService.all)
                            ...RecipeFilterService.cuisines
                                .where((cuisine) => cuisine != RecipeFilterService.all)
                                .map((cuisine) => _CuisineSection(
                                      title: RecipeFilterService.labelFor(cuisine),
                                      recipes: grouped[cuisine] ?? const <Recipe>[],
                                      onTapRecipe: _openRecipe,
                                    ))
                                .where((section) => section.recipes.isNotEmpty)
                          else
                            ...filtered.map((recipe) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: RecipeCard(
                                    recipe: recipe,
                                    onTap: () => _openRecipe(recipe),
                                  ),
                                )),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CuisineFilterBar extends StatelessWidget {
  final String selectedCuisine;
  final Map<String, int> counts;
  final ValueChanged<String> onSelected;

  const _CuisineFilterBar({
    required this.selectedCuisine,
    required this.counts,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final visibleCuisines = RecipeFilterService.cuisines
        .where((cuisine) => cuisine != RecipeFilterService.other || (counts[cuisine] ?? 0) > 0)
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final cuisine in visibleCuisines) ...[
              _CuisineChip(
                label: RecipeFilterService.labelFor(cuisine),
                value: cuisine,
                count: counts[cuisine] ?? 0,
                selected: selectedCuisine == cuisine,
                onSelected: onSelected,
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _CuisineChip extends StatelessWidget {
  final String label;
  final String value;
  final int count;
  final bool selected;
  final ValueChanged<String> onSelected;

  const _CuisineChip({
    required this.label,
    required this.value,
    required this.count,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(
        '$label ($count)',
        style: TextStyle(
          color: selected ? Colors.white : Colors.black,
          fontSize: 13,
        ),
      ),
      selected: selected,
      onSelected: (_) => onSelected(value),
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.black,
      checkmarkColor: Colors.white,
    );
  }
}

class _SortBar extends StatelessWidget {
  final String selectedSort;
  final ValueChanged<String> onSelected;

  const _SortBar({
    required this.selectedSort,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text('정렬: '),
          const SizedBox(width: 8),
          _SortChip(label: '이름순', value: 'name', selectedSort: selectedSort, onSelected: onSelected),
          const SizedBox(width: 8),
          _SortChip(label: '최근순', value: 'recent', selectedSort: selectedSort, onSelected: onSelected),
          const SizedBox(width: 8),
          _SortChip(label: '인기순', value: 'cookCount', selectedSort: selectedSort, onSelected: onSelected),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final String value;
  final String selectedSort;
  final ValueChanged<String> onSelected;

  const _SortChip({
    required this.label,
    required this.value,
    required this.selectedSort,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selectedSort == value,
      onSelected: (selected) {
        if (selected) onSelected(value);
      },
    );
  }
}

class _CuisineSection extends StatelessWidget {
  final String title;
  final List<Recipe> recipes;
  final ValueChanged<Recipe> onTapRecipe;

  const _CuisineSection({
    required this.title,
    required this.recipes,
    required this.onTapRecipe,
  });

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 8),
          child: Row(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${recipes.length}개',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        ...recipes.map((recipe) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RecipeCard(
                recipe: recipe,
                onTap: () => onTapRecipe(recipe),
              ),
            )),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
