import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class MyRatingCard extends StatelessWidget {
  const MyRatingCard({
    super.key,
    required this.title,
    required this.score,
    required this.comment,
    this.createdAt,
    this.posterUrl,
  });

  final String title;
  final int score;
  final String? comment;
  final DateTime? createdAt;
  final String? posterUrl;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final localDate = createdAt?.toLocal();
    final placeholder = Container(
      color: colors.secondary.withValues(alpha: 0.3),
    );

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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 80,
                height: 124,
                child: posterUrl == null
                    ? placeholder
                    : Image.network(
                        posterUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, error, stackTrace) => placeholder,
                        loadingBuilder: (_, child, progress) =>
                            progress == null ? child : placeholder,
                      ),
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
                if (comment?.trim().isNotEmpty ?? false) ...[
                  const SizedBox(height: AppSpacing.x1),
                  Text(
                    comment!,
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      height: 1.5,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
                if (localDate != null) ...[
                  const SizedBox(height: AppSpacing.x1),
                  Text(
                    '등록일 ${localDate.year}.${localDate.month.toString().padLeft(2, '0')}.${localDate.day.toString().padLeft(2, '0')}',
                    style: textTheme.labelSmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
