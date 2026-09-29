import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/home/movie_log_bottom_navigation_bar.dart';
import 'package:movielog/movie/data/mock_movies.dart';
import 'package:movielog/movie/model/movie.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/theme/app_text_style.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final featured = findMovieById(6)!;
    final popular = [
      (movie: findMovieById(7)!, rating: '9.6'),
      (movie: findMovieById(8)!, rating: '9.2'),
      (movie: findMovieById(9)!, rating: '8.9'),
      (movie: findMovieById(1)!, rating: '8.7'),
      (movie: findMovieById(4)!, rating: '8.5'),
    ];
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 64,
          centerTitle: false,
          titleSpacing: 16,
          title: const Text(
            'MovieLog',
            style: TextStyle(
              color: AppColors.primary600,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          actions: [
            IconButton(
              tooltip: '영화 검색',
              onPressed: () => context.go('/movies'),
              icon: SvgPicture.asset(
                'assets/icons/search.svg',
                width: 24,
                colorFilter: const ColorFilter.mode(
                  AppColors.onSurface,
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: AppColors.surfaceContainer),
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: ListView(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '오늘은 어떤\n영화를 볼까요?',
                  style: AppTextStyles.headlineLargeBold,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: _FeaturedMovieBanner(movie: featured),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    const Text(
                      '인기 영화',
                      style: AppTextStyles.headlineMediumBold,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.go('/movies'),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('전체보기'),
                          SizedBox(width: 2),
                          Icon(Icons.chevron_right, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 272,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: popular.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => _PopularMovieCard(
                    movie: popular[index].movie,
                    rating: popular[index].rating,
                    rank: index + 1,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        bottomNavigationBar: const MovieLogBottomNavigationBar(currentIndex: 0),
      ),
    );
  }
}

class _FeaturedMovieBanner extends StatelessWidget {
  const _FeaturedMovieBanner({required this.movie});
  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 356 / 534,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(movie.posterAsset, fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x12000000),
                    Color(0x20000000),
                    Color(0xE9000000),
                  ],
                  stops: [0.1, 0.52, 1],
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary500,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Text(
                      '추천 신작',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    movie.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '로맨스 · 드라마 · 120분',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: () => context.push('/movies/${movie.id}'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary500,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: SvgPicture.asset(
                        'assets/icons/info.svg',
                        width: 20,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                      label: const Text('상세보기'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PopularMovieCard extends StatelessWidget {
  const _PopularMovieCard({
    required this.movie,
    required this.rating,
    required this.rank,
  });
  final Movie movie;
  final String rating;
  final int rank;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.push('/movies/${movie.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    movie.posterAsset,
                    width: 140,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary600,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$rank',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
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
              style: AppTextStyles.bodyMediumBold,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/star.svg',
                  width: 16,
                  height: 16,
                  colorFilter: const ColorFilter.mode(
                    AppColors.tertiary500,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 4),
                Text(rating, style: AppTextStyles.labelSmallMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
