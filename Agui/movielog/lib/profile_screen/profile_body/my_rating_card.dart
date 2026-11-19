import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class MyRatingCard extends StatelessWidget {
  const MyRatingCard({
    super.key,
    required this.title,
    required this.score,
    required this.comment,
    this.createdAt,
    this.posterUrl,
    this.onEdit,
    this.onDelete,
  });

  final String title;
  final int score;
  final String? comment;
  final DateTime? createdAt;
  final String? posterUrl;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: AppColors.secondary300.withValues(alpha: 0.7),
    );
    return Container(
      constraints: const BoxConstraints(minHeight: 156),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(
          color: AppColors.secondary300.withValues(alpha: 0.6),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ExcludeSemantics(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '별점 $score / 5',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: AppColors.primary600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (comment?.trim().isNotEmpty ?? false) ...[
                  const SizedBox(height: 8),
                  Text(
                    comment!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: AppColors.gray,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RatingAction(
                label: '수정',
                background: AppColors.primary100,
                foreground: AppColors.primary600,
                onPressed: onEdit,
              ),
              const SizedBox(height: 8),
              _RatingAction(
                label: '삭제',
                background: const Color(0xFFFFF4F2),
                foreground: AppColors.errorBorder,
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RatingAction extends StatelessWidget {
  const _RatingAction({
    required this.label,
    required this.background,
    required this.foreground,
    this.onPressed,
  });
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 62,
    height: 36,
    child: TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: background,
        disabledForegroundColor: foreground,
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    ),
  );
}
