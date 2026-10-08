import 'package:flutter/material.dart';
import '../models/recipe.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;
  final bool showCookCount;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    this.showCookCount = false,
  });

  IconData _getEffortIcon() {
    switch (recipe.effortLevel) {
      case 1:
        return Icons.looks_one;
      case 2:
        return Icons.looks_two;
      case 3:
        return Icons.looks_3;
      case 4:
        return Icons.looks_4;
      case 5:
        return Icons.looks_5;
      default:
        return Icons.looks_3;
    }
  }

  Color _getEffortColor(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    switch (recipe.effortLevel) {
      case 1:
        return primary.withOpacity(0.3);
      case 2:
        return primary.withOpacity(0.45);
      case 3:
        return primary.withOpacity(0.6);
      case 4:
        return primary.withOpacity(0.8);
      case 5:
        return primary;
      default:
        return primary.withOpacity(0.6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
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
                  if (recipe.isFavorite)
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Icon(
                    _getEffortIcon(),
                    color: _getEffortColor(context),
                    size: 20,
                  ),
                ],
              ),
              if (recipe.description.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  recipe.description,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ] else if (recipe.ingredients.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  recipe.ingredients.take(2).join(', '),
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  if (recipe.categories.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        recipe.categories.first,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  if (recipe.cookingMethods.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        recipe.cookingMethods.take(2).join(' · '),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else
                    const Spacer(),
                  if (recipe.hasTiming) ...[
                    Icon(Icons.timer_outlined, size: 15, color: Theme.of(context).colorScheme.primary.withOpacity(0.6)),
                    const SizedBox(width: 3),
                    Text(
                      '${recipe.totalMinutes}m',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (showCookCount && recipe.cookCount > 0)
                    Row(
                      children: [
                        Icon(
                          Icons.restaurant,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.cookCount}x',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                          ),
                        ),
                      ],
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
