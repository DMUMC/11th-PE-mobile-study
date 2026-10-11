import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/movie.dart';
import '../../theme/app_colors.dart';

class MovieCard extends StatelessWidget {
  const MovieCard({super.key, required this.movie, this.rank});
  final Movie movie;
  final int? rank;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/movies/${movie.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 2 / 3,
                  child: Image.asset(movie.posterAsset, fit: BoxFit.cover),
                ),
              ),
              Positioned(
                top: 8,
                left: rank != null ? 8 : null,
                right: rank == null ? 8 : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xB31D1B20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    rank?.toString() ??
                        '★ ${movie.averageRating.toStringAsFixed(1)}',
                    style: textTheme.labelSmall?.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            movie.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          if (rank == null)
            Text(
              '${movie.year} · ${movie.genre}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else
            Row(
              children: [
                const Icon(Icons.star, size: 16, color: AppColors.tertiary300),
                const SizedBox(width: 4),
                // 홈의 10점 표기는 같은 평균 평점(5점 기준)을 환산합니다.
                Text(
                  (movie.averageRating * 2).toStringAsFixed(1),
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
