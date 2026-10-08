import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import '../models/recipe.dart';
import 'recipe_edit_screen.dart';
import 'recipe_detail_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _saveQuickText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();
    if (lines.isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final recipe = Recipe(
      id: 'recipe_${DateTime.now().millisecondsSinceEpoch}',
      name: lines.first, // 첫 줄을 임시 제목으로
      isDraft: true,
      notes: lines.length > 1 ? lines.sublist(1) : [],
      createdAt: now,
      updatedAt: now,
    );

    final provider = context.read<RecipeProvider>();
    await provider.createRecipe(recipe);

    if (mounted) {
      _textController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to Inbox')),
      );
    }
  }

  Future<void> _checkClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null && clipboardData!.text!.isNotEmpty) {
      if (mounted) {
        _showClipboardDialog(clipboardData.text!);
      }
    }
  }

  void _showClipboardDialog(String clipboardText) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clipboard Detected'),
          content: Text(
            'Save clipboard content to Inbox?\n\n${clipboardText.substring(0, clipboardText.length > 100 ? 100 : clipboardText.length)}...',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                _textController.text = clipboardText;
                await _saveQuickText();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        actions: [
          IconButton(
            icon: const Icon(Icons.content_paste),
            tooltip: 'Check Clipboard',
            onPressed: _checkClipboard,
          ),
        ],
      ),
      body: Column(
        children: [
          // 빠른 입력 영역
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Save',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: 'Paste recipe text or notes here...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _textController.clear(),
                      child: const Text('Clear'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _saveQuickText,
                      icon: const Icon(Icons.save),
                      label: const Text('Save to Inbox'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Draft 레시피 목록
          Expanded(
            child: Consumer<RecipeProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final drafts = provider.draftRecipes;

                if (drafts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No drafts yet',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Paste recipe text above to get started',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.loadAllData(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: drafts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final recipe = drafts[index];
                      final daysSinceCreated = DateTime.now()
                          .difference(DateTime.fromMillisecondsSinceEpoch(recipe.createdAt))
                          .inDays;
                      final needsOrganizing = daysSinceCreated >= 7;

                      return Card(
                        color: needsOrganizing
                            ? Colors.amber.shade50
                            : null,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RecipeDetailScreen(
                                  recipeId: recipe.id,
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        recipe.name,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (needsOrganizing)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${daysSinceCreated}d old',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (recipe.notes.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    recipe.notes.first,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => RecipeEditScreen(
                                              recipe: recipe,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.edit, size: 18),
                                      label: const Text('Organize'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
