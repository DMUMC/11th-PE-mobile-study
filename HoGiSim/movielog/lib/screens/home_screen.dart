import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../theme/app_colors.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_load_status.dart';
import '../widgets/movie_list_states.dart';
import '../widgets/tmdb_poster_image.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => CustomScrollView(
    key: const PageStorageKey('home-scroll'),
    slivers: [
      const SliverAppBar(
        floating: true,
        title: Text(
          'MovieLog',
          style: TextStyle(color: AppColors.primary, fontSize: 20),
        ),
      ),
      const SliverPadding(
        padding: EdgeInsets.fromLTRB(16, 10, 16, 20),
        sliver: SliverToBoxAdapter(
          child: Text(
            '오늘은 어떤\n영화를 볼까요?',
            style: TextStyle(
              fontSize: 27,
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      Consumer<MovieHomeViewModel>(
        builder: (context, vm, _) {
          switch (vm.status) {
            case MovieLoadStatus.idle:
            case MovieLoadStatus.loading:
              return const SliverFillRemaining(child: MovieLoadingView());
            case MovieLoadStatus.error:
              return SliverFillRemaining(
                child: MovieErrorView(
                  message: vm.message,
                  onRetry: vm.loadPopular,
                ),
              );
            case MovieLoadStatus.empty:
              return const SliverFillRemaining(child: MovieEmptyView());
            case MovieLoadStatus.success:
              final featured = vm.popularMovies.first;
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList.list(
                  children: [
                    _FeaturedMovie(movie: featured),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '인기 영화',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/movies'),
                          child: const Text('전체보기 ›'),
                        ),
                      ],
                    ),
                    SizedBox(
                      key: const Key('popularMovies'),
                      height: 240,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: vm.popularMovies.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final movie = vm.popularMovies[index];
                          return SizedBox(
                            width: 126,
                            child: InkWell(
                              key: ValueKey('popular-${movie.id}'),
                              onTap: () => context.push(
                                '/movies/${movie.id}',
                                extra: movie,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          child: TmdbPosterImage(
                                            posterPath: movie.posterPath,
                                          ),
                                        ),
                                        Positioned(
                                          top: 6,
                                          left: 8,
                                          child: Text(
                                            '${index + 1}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              shadows: [Shadow(blurRadius: 6)],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    movie.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '★ ${movie.voteAverage.toStringAsFixed(1)} / 10',
                                    style: const TextStyle(
                                      color: Color(0xFF9B7A16),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'This product uses the TMDB API but is not endorsed or certified by TMDB.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
          }
        },
      ),
    ],
  );
}

class _FeaturedMovie extends StatelessWidget {
  const _FeaturedMovie({required this.movie});
  final TmdbMovieDto movie;

  @override
  Widget build(BuildContext context) => GestureDetector(
    key: const Key('featuredMovieCard'),
    onTap: () => context.push('/movies/${movie.id}', extra: movie),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: .72,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'poster-${movie.id}',
              child: TmdbPosterImage(posterPath: movie.posterPath),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xE6000000)],
                  stops: [.42, 1],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '지금 인기 있는 영화',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    movie.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '★ ${movie.voteAverage.toStringAsFixed(1)} / 10',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: FilledButton.icon(
                      onPressed: () =>
                          context.push('/movies/${movie.id}', extra: movie),
                      icon: const Icon(Icons.info_outline, size: 17),
                      label: const Text('상세보기'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
