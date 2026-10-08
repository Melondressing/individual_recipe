import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ingredient_alias.dart';
import '../providers/alias_provider.dart';

class AliasManagementScreen extends StatefulWidget {
  const AliasManagementScreen({super.key});

  @override
  State<AliasManagementScreen> createState() => _AliasManagementScreenState();
}

class _AliasManagementScreenState extends State<AliasManagementScreen> {
  void _showAliasDialog({IngredientAlias? alias}) {
    final provider = context.read<AliasProvider>();
    final aliasController = TextEditingController(text: alias?.alias ?? '');
    final canonicalController = TextEditingController(text: alias?.canonical ?? '');

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(alias == null ? 'Add Alias' : 'Edit Alias'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: aliasController,
                decoration: const InputDecoration(
                  labelText: 'Alias (actual word used)',
                  hintText: 'e.g., 미림',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: canonicalController,
                decoration: const InputDecoration(
                  labelText: 'Canonical (standard term)',
                  hintText: 'e.g., 맛술',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final aliasText = aliasController.text.trim();
                final canonicalText = canonicalController.text.trim();
                if (aliasText.isEmpty || canonicalText.isEmpty) return;

                final nextAlias = IngredientAlias(
                  id: alias?.id ?? 'alias_${DateTime.now().millisecondsSinceEpoch}',
                  alias: aliasText,
                  canonical: canonicalText,
                );

                if (alias == null) {
                  await provider.createAlias(nextAlias);
                } else {
                  await provider.updateAlias(nextAlias);
                }

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ).whenComplete(() {
      aliasController.dispose();
      canonicalController.dispose();
    });
  }

  void _deleteAlias(IngredientAlias alias) {
    final provider = context.read<AliasProvider>();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Alias'),
          content: Text('Delete "${alias.alias}" → "${alias.canonical}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await provider.deleteAlias(alias.id);
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ingredient Aliases')),
      body: Consumer<AliasProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.aliases.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.list_alt, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No aliases yet',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add aliases to improve search',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.aliases.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final alias = provider.aliases[index];
              return ListTile(
                title: Text(alias.alias),
                subtitle: Text('→ ${alias.canonical}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showAliasDialog(alias: alias),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteAlias(alias),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAliasDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
