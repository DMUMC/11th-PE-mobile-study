import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class MyRatingCard extends StatelessWidget {
  const MyRatingCard({
    super.key,
    required this.title,
    required this.score,
    required this.comment,
  });

  final String title;
  final int score;
  final String comment;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 160),
      padding: const EdgeInsets.all(AppSpacing.x2),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        border: Border.all(
          color: colors.secondary.withValues(alpha: 0.32),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Container(
              width: 80,
              height: 124,
              decoration: BoxDecoration(
                color: colors.secondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.x2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.x1),
                Text(
                  '별점 $score / 5',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.x1),
                Text(
                  comment,
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    height: 1.5,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
