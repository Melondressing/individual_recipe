import 'package:flutter/material.dart';

/// Shows a recipe's effort level (1-5) as filled dots plus a plain-language
/// label, instead of a bare number that has no meaning without a legend.
class DifficultyBadge extends StatelessWidget {
  final int effortLevel;
  final bool showLabel;

  const DifficultyBadge({
    super.key,
    required this.effortLevel,
    this.showLabel = true,
  });

  static const _labels = {
    1: '매우 쉬움',
    2: '쉬움',
    3: '보통',
    4: '어려움',
    5: '매우 어려움',
  };

  String get _label => _labels[effortLevel.clamp(1, 5)]!;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final level = effortLevel.clamp(1, 5);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: showLabel ? 9 : 6, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              final filled = i < level;
              return Container(
                width: 5,
                height: 5,
                margin: EdgeInsets.only(right: i == 4 ? 0 : 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onPrimaryContainer.withOpacity(0.25),
                ),
              );
            }),
          ),
          if (showLabel) ...[
            const SizedBox(width: 6),
            Text(
              _label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
