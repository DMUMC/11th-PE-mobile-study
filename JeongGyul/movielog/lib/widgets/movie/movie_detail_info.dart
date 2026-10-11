import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../models/movie.dart';

class MovieDetailInfo extends StatelessWidget {
  const MovieDetailInfo({super.key, required this.movie});
  final Movie movie;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(movie.title, style: textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            '${movie.year} · ${movie.tags.take(2).join('/')} · ${movie.durationMinutes}분',
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              RatingBarIndicator(
                rating: movie.averageRating,
                itemCount: 5,
                itemSize: 24,
                itemBuilder: (context, index) =>
                    Icon(Icons.star, color: colors.primary),
              ),
              Text(
                '${movie.averageRating.toStringAsFixed(1)} (${movie.ratingCount})',
                style: textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in movie.tags)
                Chip(
                  label: Text(tag),
                  backgroundColor: colors.surfaceContainerHighest,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
