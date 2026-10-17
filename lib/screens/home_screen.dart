import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import '../widgets/recipe_card.dart';
import 'cooking_logs_screen.dart';
import 'inbox_screen.dart';
import 'ingredient_stats_screen.dart';
import 'recipe_edit_screen.dart';
import 'recipe_detail_screen.dart';
import 'recipe_pack_import_screen.dart';
import 'shopping_list_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onOpenSearch;

  const HomeScreen({super.key, this.onOpenSearch});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Individual Recipe')),
      body: Consumer<RecipeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadAllData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 환영 메시지
                  Text(
                    '나만의 레시피 보관함',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '총 ${provider.allRecipes.length}개의 레시피와 조리 기록을 한 곳에 모아두세요',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),

                  _buildOverview(context, provider),

                  const SizedBox(height: 18),

                  _buildQuickActions(context),

                  if (provider.allRecipes.isEmpty) ...[
                    const SizedBox(height: 18),
                    _buildEmptyStarter(context),
                  ],

                  const SizedBox(height: 26),

                  // 즐겨찾기
                  _buildSection(
                    context,
                    title: '즐겨찾기',
                    icon: Icons.star,
                    iconColor: Colors.amber,
                    emptyMessage: '즐겨찾기한 레시피가 없습니다',
                    recipes: provider.favoriteRecipes,
                  ),

                  const SizedBox(height: 24),

                  // 최근 사용한 레시피
                  _buildSection(
                    context,
                    title: '최근 요리',
                    icon: Icons.history,
                    iconColor: Theme.of(context).colorScheme.secondary,
                    emptyMessage: '아직 조리한 레시피가 없습니다',
                    recipes: provider.recentRecipes,
                  ),

                  const SizedBox(height: 24),

                  // 숙련도 리포트 (TOP 3)
                  _buildTopCookedSection(context, provider),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openRecipeEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('새 레시피'),
      ),
    );
  }

  Widget _buildOverview(BuildContext context, RecipeProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? 4 : 2;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: columns == 4 ? 1.4 : 1.55,
          children: [
            _StatTile(
              icon: Icons.menu_book_outlined,
              label: '전체',
              value: '${provider.allRecipes.length}',
            ),
            _StatTile(
              icon: Icons.star_border,
              label: '즐겨찾기',
              value: '${provider.favoriteRecipes.length}',
            ),
            _StatTile(
              icon: Icons.history,
              label: '최근 요리',
              value: '${provider.recentRecipes.length}',
            ),
            _StatTile(
              icon: Icons.edit_note,
              label: '정리 필요',
              value: '${provider.draftRecipes.length}',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InboxScreen()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ActionChip(
          avatar: const Icon(Icons.search, size: 18),
          label: const Text('검색'),
          onPressed: widget.onOpenSearch,
        ),
        ActionChip(
          avatar: const Icon(Icons.collections_bookmark_outlined, size: 18),
          label: const Text('레시피팩'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RecipePackImportScreen()),
            );
          },
        ),
        ActionChip(
          avatar: const Icon(Icons.restaurant_menu, size: 18),
          label: const Text('조리 기록'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CookingLogsScreen()),
            );
          },
        ),
        ActionChip(
          avatar: const Icon(Icons.shopping_cart_outlined, size: 18),
          label: const Text('장보기 목록'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ShoppingListScreen()),
            );
          },
        ),
        ActionChip(
          avatar: const Icon(Icons.bar_chart, size: 18),
          label: const Text('재료 통계'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const IngredientStatsScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyStarter(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '첫 레시피를 추가해볼까요?',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            '개인 레시피를 직접 만들거나, 준비된 레시피팩을 가져와 바로 시작할 수 있습니다.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _openRecipeEditor(context),
            icon: const Icon(Icons.add),
            label: const Text('레시피 만들기'),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required String emptyMessage,
    required List recipes,
  }) {
    final mutedColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              '${recipes.length}개',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: mutedColor),
            ),
          ],
        ),
        const SizedBox(height: 12),
        recipes.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  emptyMessage,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: mutedColor),
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recipes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return RecipeCard(
                    recipe: recipes[index],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RecipeDetailScreen(recipeId: recipes[index].id),
                        ),
                      );
                    },
                  );
                },
              ),
      ],
    );
  }

  Widget _buildTopCookedSection(BuildContext context, RecipeProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.emoji_events, size: 20, color: Colors.amber.shade700),
            const SizedBox(width: 8),
            Text(
              '많이 만든 레시피',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        provider.topCookedRecipes.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '레시피를 만들어보면 자주 만든 순서로 보여드려요',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.topCookedRecipes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final recipe = provider.topCookedRecipes[index];
                  return RecipeCard(
                    recipe: recipe,
                    showCookCount: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RecipeDetailScreen(recipeId: recipe.id),
                        ),
                      );
                    },
                  );
                },
              ),
      ],
    );
  }

  void _openRecipeEditor(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RecipeEditScreen()),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.primaryContainer.withOpacity(0.5),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 20, color: colorScheme.primary),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
