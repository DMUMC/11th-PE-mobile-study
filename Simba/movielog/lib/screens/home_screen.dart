import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/movie_format.dart';
import '../view_models/movie_home_view_model.dart';
import '../widgets/tmdb_poster_image.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MovieLog', style: AppTextStyles.appBarTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('지금 인기 있는 영화', style: AppTextStyles.sectionTitle),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: _PopularMovieItem.height,
            // 인기 영역만 상태 변화에 맞춰 다시 그린다.
            child: Consumer<MovieHomeViewModel>(
              builder: (context, viewModel, child) {
                return switch (viewModel.status) {
                  MovieHomeLoadStatus.idle ||
                  MovieHomeLoadStatus.loading => const Center(
                    child: CircularProgressIndicator(color: AppColors.violet),
                  ),
                  MovieHomeLoadStatus.error => _HomeMessage(
                    message: viewModel.message ?? '인기 영화를 불러오지 못했어요.',
                    onRetry: () =>
                        context.read<MovieHomeViewModel>().loadPopular(),
                  ),
                  MovieHomeLoadStatus.empty => const _HomeMessage(
                    message: '인기 영화가 아직 없어요.',
                  ),
                  MovieHomeLoadStatus.success => _PopularMovieList(
                    movies: viewModel.popularMovies,
                  ),
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PopularMovieList extends StatelessWidget {
  const _PopularMovieList({required this.movies});

  final List<TmdbMovieDto> movies;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: movies.length,
      separatorBuilder: (context, index) => const SizedBox(width: 16),
      itemBuilder: (context, index) {
        final movie = movies[index];
        return _PopularMovieItem(
          key: ValueKey(movie.id),
          movie: movie,
          // TMDB id를 경로로, DTO는 extra로 전달한다.
          onTap: () => context.push('/home/movies/${movie.id}', extra: movie),
        );
      },
    );
  }
}

class _PopularMovieItem extends StatelessWidget {
  const _PopularMovieItem({super.key, required this.movie, required this.onTap});

  static const posterWidth = 175.0;
  static const posterHeight = 265.0;
  static const height = posterHeight + 56;

  final TmdbMovieDto movie;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final year = releaseYearOf(movie.releaseDate);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: posterWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: TmdbPosterImage(
                posterPath: movie.posterPath,
                width: posterWidth,
                height: posterHeight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              movie.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              [?year, '★ ${fivePointScoreOf(movie.voteAverage)}'].join(' · '),
              style: const TextStyle(color: AppColors.gray, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeMessage extends StatelessWidget {
  const _HomeMessage({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: const TextStyle(color: AppColors.gray)),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.violet),
              onPressed: onRetry,
              child: const Text('다시 시도'),
            ),
          ],
        ],
      ),
    );
  }
}
