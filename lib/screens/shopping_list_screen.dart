import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/shopping_list_item.dart';
import '../providers/shopping_list_provider.dart';
import '../theme/app_theme.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final TextEditingController _inputController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _addItem() {
    final provider = context.read<ShoppingListProvider>();
    provider.addItem(_inputController.text);
    _inputController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('장보기 목록'),
        actions: [
          Consumer<ShoppingListProvider>(
            builder: (context, provider, _) {
              if (provider.checkedItems.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: '구매 완료 항목 삭제',
                onPressed: provider.clearChecked,
              );
            },
          ),
        ],
      ),
      body: Consumer<ShoppingListProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        decoration: const InputDecoration(
                          hintText: '예: 양파 2개',
                          isDense: true,
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _addItem(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _addItem,
                      child: const Text('추가'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: provider.items.isEmpty
                    ? _buildEmptyState(context)
                    : _buildList(context, provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            Text(
              '장보기 목록이 비어 있습니다',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '위에 직접 추가하거나, 레시피 상세 화면의 재료에서 추가해보세요.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, ShoppingListProvider provider) {
    final unchecked = provider.uncheckedItems;
    final checked = provider.checkedItems;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final item in unchecked) _ShoppingListTile(item: item),
        if (checked.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              '구매 완료 (${checked.length})',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          for (final item in checked) _ShoppingListTile(item: item),
        ],
      ],
    );
  }
}

class _ShoppingListTile extends StatelessWidget {
  final ShoppingListItem item;

  const _ShoppingListTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ShoppingListProvider>();
    final mutedColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.5);

    return CheckboxListTile(
      value: item.isChecked,
      onChanged: (_) => provider.toggleChecked(item),
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(
        item.name,
        style: item.isChecked
            ? TextStyle(color: mutedColor, decoration: TextDecoration.lineThrough)
            : null,
      ),
      subtitle: item.recipeName != null
          ? Text(
              item.recipeName!,
              style: TextStyle(color: mutedColor, fontSize: 12),
            )
          : null,
      secondary: IconButton(
        icon: Icon(Icons.close, size: 20, color: mutedColor),
        tooltip: '삭제',
        onPressed: () => provider.deleteItem(item.id),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.chipRadius)),
    );
  }
}
