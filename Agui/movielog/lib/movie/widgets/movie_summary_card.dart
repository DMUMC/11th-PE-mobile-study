import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/tmdb_movie_dto.dart';
import '../../theme/app_colors.dart';
import '../../widgets/tmdb_poster_image.dart';

class MovieSummaryCard extends StatelessWidget {
  const MovieSummaryCard({
    super.key,
    required this.movie,
    this.genreNames = const [],
  });

  final TmdbMovieDto movie;
  final List<String> genreNames;

  @override
  Widget build(BuildContext context) {
    final year = movie.releaseDate?.split('-').first;
    final metadata = [
      if (year != null && year.isNotEmpty) year,
      ...genreNames,
    ].join(' · ');
    return Material(
      color: const Color(0xFFFEFCF9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFD9D3E1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/movies/${movie.id}', extra: movie),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: TmdbPosterImage(
                    posterPath: movie.posterPath,
                    width: 76,
                    height: 120,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (metadata.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          metadata,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.gray,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        '평점 ${movie.voteAverage.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
