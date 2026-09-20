import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class FavoriteGenreChip extends StatelessWidget {
  const FavoriteGenreChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x2,
        vertical: AppSpacing.x1,
      ),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        label,
        style: textTheme.labelSmall?.copyWith(color: colors.onPrimaryContainer),
      ),
    );
  }
}
