import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import '../models/recipe.dart';
import '../models/review.dart';
import '../database/database_helper.dart';
import 'recipe_edit_screen.dart';
import 'cooking_mode_screen.dart';
import 'cooking_logs_screen.dart';
import 'review_write_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String recipeId;

  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  Recipe? _recipe;
  bool _isLoading = true;
  List<Review> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadRecipe();
  }

  Future<void> _loadRecipe() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final provider = context.read<RecipeProvider>();
    final recipe = await provider.getRecipe(widget.recipeId);
    final reviews = await DatabaseHelper.instance.getReviewsByRecipe(widget.recipeId);
    if (!mounted) return;
    setState(() {
      _recipe = recipe;
      _reviews = reviews;
      _isLoading = false;
    });
  }

  Future<void> _toggleFavorite() async {
    final recipe = _recipe;
    if (recipe == null) return;
    await context.read<RecipeProvider>().toggleFavorite(recipe);
    await _loadRecipe();
  }

  void _deleteRecipe() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Recipe'),
          content: Text('Delete "${_recipe?.name}"? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                final provider = this.context.read<RecipeProvider>();
                await provider.deleteRecipe(widget.recipeId);
                if (!mounted) return;
                Navigator.pop(this.context); // Close detail screen
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _startCooking() {
    if (_recipe == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CookingModeScreen(recipe: _recipe!),
      ),
    ).then((_) => _loadRecipe()); // Reload after cooking
  }

  void _viewCookingLogs() {
    if (_recipe == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CookingLogsScreen(recipeId: _recipe!.id),
      ),
    );
  }

  Future<void> _writeReview() async {
    final recipe = _recipe;
    if (recipe == null) return;

    final review = await Navigator.push<Review>(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewWriteScreen(
          recipeId: recipe.id,
          recipeName: recipe.name,
        ),
      ),
    );

    if (!mounted || review == null) return;
    await DatabaseHelper.instance.createReview(review);
    if (!mounted) return;
    setState(() => _reviews.insert(0, review));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('리뷰가 저장되었습니다')),
    );
  }

  void _showReviewDetail(Review review) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // 핸들
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 16),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 사용자 정보 및 별점
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.blue[100],
                                child: Text(
                                  review.userName[0].toUpperCase(),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      review.userName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      _formatDate(review.createdAt),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: List.generate(5, (index) {
                                  return Icon(
                                    index < review.rating ? Icons.star : Icons.star_border,
                                    color: Colors.amber,
                                    size: 20,
                                  );
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // 리뷰 텍스트
                          Text(
                            review.text,
                            style: const TextStyle(fontSize: 16, height: 1.5),
                          ),
                          const SizedBox(height: 20),
                          
                          // 사진들 (추후 서버 구현 시)
                          if (review.photoUrls.isNotEmpty) ...[
                            const Text(
                              '사진',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: review.photoUrls.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.image, size: 48),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays > 30) {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}일 전';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}시간 전';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_recipe == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Recipe not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_recipe!.name),
        actions: [
          IconButton(
            onPressed: _viewCookingLogs,
            icon: const Icon(Icons.history),
            tooltip: '조리 기록',
          ),
          IconButton(
            icon: Icon(_recipe!.isFavorite ? Icons.star : Icons.star_border),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecipeEditScreen(recipe: _recipe),
                ),
              ).then((_) => _loadRecipe());
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteRecipe,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 기본 정보
            _buildInfoChips(),

            if (_recipe!.description.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  _recipe!.description,
                  style: const TextStyle(height: 1.45),
                ),
              ),
            ],

            if (_recipe!.cookingMethods.isNotEmpty || _recipe!.hasTiming || _recipe!.hasServings) ...[
              const SizedBox(height: 16),
              _buildMethodSummary(),
            ],

            const SizedBox(height: 24),

            // 재료
            if (_recipe!.ingredients.isNotEmpty) ...[
              _buildSectionTitle('Ingredients'),
              const SizedBox(height: 8),
              ..._recipe!.ingredients.map((ingredient) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 16)),
                    Expanded(child: Text(ingredient)),
                  ],
                ),
              )),
              const SizedBox(height: 24),
            ],
            
            // 단계
            if (_recipe!.steps.isNotEmpty) ...[
              _buildSectionTitle('Steps'),
              const SizedBox(height: 8),
              ...List.generate(_recipe!.steps.length, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(_recipe!.steps[index]),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],
            
            // 노트
            if (_recipe!.notes.isNotEmpty) ...[
              _buildSectionTitle('Notes'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _recipe!.notes.map((note) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(note),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // 리뷰 섹션
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle('리뷰 (${_reviews.length})'),
                TextButton.icon(
                  onPressed: _writeReview,
                  icon: const Icon(Icons.edit),
                  label: const Text('리뷰 작성'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (_reviews.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        '아직 리뷰가 없습니다',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _writeReview,
                        child: const Text('첫 리뷰를 작성해보세요'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...(_reviews.take(3).map((review) => _buildReviewPreview(review))),
            
            if (_reviews.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: TextButton(
                    onPressed: () {
                      // 전체 리뷰 목록 화면으로 이동 (추후 구현)
                    },
                    child: Text('모든 리뷰 보기 (${_reviews.length})'),
                  ),
                ),
              ),
            
            const SizedBox(height: 80), // Bottom navigation bar를 위한 공간
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _viewCookingLogs,
                  icon: const Icon(Icons.history),
                  label: const Text('조리 기록'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _recipe!.steps.isEmpty ? null : _startCooking,
                  icon: const Icon(Icons.restaurant_menu),
                  label: const Text('Start Cooking'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildMethodSummary() {
    final items = <Widget>[];

    if (_recipe!.cookingMethods.isNotEmpty) {
      items.add(_summaryTile(Icons.restaurant_menu, 'Method', _recipe!.methodLabel));
    }
    if (_recipe!.hasTiming) {
      items.add(_summaryTile(Icons.timer_outlined, 'Time', _recipe!.timingLabel));
    }
    if (_recipe!.hasServings) {
      items.add(_summaryTile(Icons.people_outline, 'Yield', _recipe!.servingsLabel));
    }

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: item,
            ),
          )
          .toList(),
    );
  }

  Widget _summaryTile(IconData icon, String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildInfoChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Chip(
          label: Text('Type: ${_recipe!.type}'),
          avatar: const Icon(Icons.category, size: 18),
        ),
        Chip(
          label: Text('Cuisine: ${_recipe!.cuisine}'),
          avatar: const Icon(Icons.public, size: 18),
        ),
        if (_recipe!.categories.isNotEmpty)
          ...(_recipe!.categories.map((cat) => Chip(
            label: Text(cat),
            avatar: const Icon(Icons.local_dining, size: 18),
          ))),
        if (_recipe!.tags.isNotEmpty)
          ...(_recipe!.tags.map((tag) => Chip(
            label: Text(tag),
            avatar: const Icon(Icons.label, size: 18),
          ))),
        if (_recipe!.cookingMethods.isNotEmpty)
          ...(_recipe!.cookingMethods.map((method) => Chip(
            label: Text(method),
            avatar: const Icon(Icons.restaurant_menu, size: 18),
          ))),
        if (_recipe!.hasTiming)
          Chip(
            label: Text(_recipe!.timingLabel),
            avatar: const Icon(Icons.timer_outlined, size: 18),
          ),
        if (_recipe!.hasServings)
          Chip(
            label: Text(_recipe!.servingsLabel),
            avatar: const Icon(Icons.people_outline, size: 18),
          ),
        Chip(
          label: Text('Difficulty: ${_recipe!.effortLevel == 1 ? "Very Simple" : _recipe!.effortLevel == 2 ? "Simple" : _recipe!.effortLevel == 3 ? "Moderate" : _recipe!.effortLevel == 4 ? "Complex" : "Very Complex"} (${_recipe!.effortLevel}/5)'),
          avatar: const Icon(Icons.trending_up, size: 18),
        ),
        if (_recipe!.cookCount > 0)
          Chip(
            label: Text('Cooked ${_recipe!.cookCount}x'),
            avatar: const Icon(Icons.restaurant, size: 18),
          ),
      ],
    );
  }

  Widget _buildReviewPreview(Review review) {
    return InkWell(
      onTap: () => _showReviewDetail(review),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    review.userName[0].toUpperCase(),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _formatDate(review.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < review.rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              review.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            if (review.photoUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.photoUrls.length > 3 ? 3 : review.photoUrls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return Container(
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(Icons.image, size: 24),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
