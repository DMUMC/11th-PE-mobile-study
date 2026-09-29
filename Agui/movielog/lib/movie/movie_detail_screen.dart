import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/movie/data/mock_movies.dart';
import 'package:movielog/movie/data/movie_rating_store.dart';
import 'package:movielog/movie/model/movie.dart';
import 'package:movielog/movie/widgets/movie_rating_dialog.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/theme/app_text_style.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movieId});

  final String movieId;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool _isFavorite = false;

  int get _currentMovieId => int.tryParse(widget.movieId) ?? -1;
  double? get _myRating => MovieRatingStore.ratingFor(_currentMovieId);

  static const _starlightSynopsis = [
    '바쁜 현대 사회 속에서 서로의 존재를 잊고 살아가던 두 남녀가 우연한 계기로 작은 천문대에서 만나게 됩니다. 매일 밤 별을 관측하며 서로의 상처를 치유하고, 잊고 있던 꿈과 사랑을 다시 깨닫게 되는 따뜻한 이야기입니다.',
    '과거의 아픔으로 인해 사람에게 마음을 열지 못하던 여주인공은, 별자리처럼 변함없는 모습으로 자신을 기다려주는 남주인공을 통해 서서히 마음의 문을 열게 됩니다. 하지만 두 사람 앞에 놓인 현실적인 장벽들은 그들의 관계를 시험하게 되는데...',
    '별이 쏟아지는 밤하늘 아래, 그들이 나눈 조용한 약속들은 과연 영원할 수 있을까요? 눈부신 영상미와 감성적인 OST가 어우러져 깊은 여운을 남기는 올 겨울 최고의 로맨스 영화.',
  ];

  @override
  Widget build(BuildContext context) {
    final movie = findMovieById(int.tryParse(widget.movieId));

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 64,
        centerTitle: true,
        leading: IconButton(
          tooltip: '뒤로 가기',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/movies');
            }
          },
          icon: SvgPicture.asset(
            'assets/icons/arrow_back.svg',
            width: 24,
            colorFilter: const ColorFilter.mode(
              AppColors.primary600,
              BlendMode.srcIn,
            ),
          ),
        ),
        title: const Text(
          'Cinema Archive',
          style: TextStyle(
            color: AppColors.primary600,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: '공유',
            onPressed: movie == null ? null : () => _copyMovieLink(movie),
            icon: SvgPicture.asset(
              'assets/icons/share.svg',
              width: 24,
              colorFilter: const ColorFilter.mode(
                AppColors.onSurface,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: movie == null
          ? const Center(child: Text('영화를 찾을 수 없습니다.'))
          : _DetailBody(movie: movie, synopsis: _starlightSynopsis),
      bottomNavigationBar: movie == null ? null : _buildActionBar(movie),
    );
  }

  Widget _buildActionBar(Movie movie) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: AppColors.surfaceBase,
          border: Border(top: BorderSide(color: AppColors.surfaceContainer)),
        ),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _isFavorite = !_isFavorite),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary600,
                    side: const BorderSide(color: AppColors.primary600),
                    shape: const StadiumBorder(),
                  ),
                  icon: _isFavorite
                      ? const Icon(Icons.bookmark, size: 18)
                      : SvgPicture.asset(
                          'assets/icons/bookmark.svg',
                          width: 18,
                          height: 18,
                          colorFilter: const ColorFilter.mode(
                            AppColors.primary600,
                            BlendMode.srcIn,
                          ),
                        ),
                  label: Text(_isFavorite ? '즐겨찾기 완료' : '즐겨찾기'),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: _showRatingDialog,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary500,
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.rate_review_outlined, size: 18),
                  label: const Text('평점 남기기'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyMovieLink(Movie movie) {
    unawaited(Clipboard.setData(ClipboardData(text: '/movies/${movie.id}')));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('영화 링크를 복사했습니다.')));
  }

  Future<void> _showRatingDialog() async {
    final rating = await showDialog<double>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => MovieRatingDialog(
        initialRating: _myRating ?? 3.5,
        hasExistingRating: _myRating != null,
      ),
    );

    if (rating == null || !mounted) return;
    MovieRatingStore.save(_currentMovieId, rating);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('평점 ${rating.toStringAsFixed(1)}점을 저장했습니다.')),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.movie, required this.synopsis});

  final Movie movie;
  final List<String> synopsis;

  @override
  Widget build(BuildContext context) {
    final isStarlight = movie.id == 10 || movie.id == 6;
    final backdrop = isStarlight
        ? 'assets/images/posters/hero_under_the_starlight.jpg'
        : movie.posterAsset;
    final metadata = isStarlight
        ? '2024 · 로맨스/드라마 · 124분'
        : '${movie.year} · ${movie.genre}';
    final rating = isStarlight ? 4.5 : movie.rating;

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(backdrop, height: 584, fit: BoxFit.cover),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(movie.title, style: AppTextStyles.headlineMediumBold),
                    const SizedBox(height: 2),
                    Text(
                      metadata,
                      style: AppTextStyles.bodyMediumRegular.copyWith(
                        color: AppColors.secondary500,
                      ),
                    ),
                    if (rating != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          for (var index = 0; index < 5; index++)
                            const Icon(
                              Icons.star_rounded,
                              color: AppColors.primary600,
                              size: 20,
                            ),
                          const SizedBox(width: 8),
                          Text(
                            isStarlight
                                ? '4.5 (1,245)'
                                : rating.toStringAsFixed(1),
                            style: AppTextStyles.bodyMediumRegular.copyWith(
                              color: AppColors.secondary500,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          (isStarlight ? ['로맨스', '드라마', '감동적인'] : [movie.genre])
                              .map(
                                (tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainer,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text(
                                    tag,
                                    style: AppTextStyles.labelSmallMedium
                                        .copyWith(color: AppColors.onSurface),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.surfaceContainer),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('시놉시스', style: AppTextStyles.headlineMediumBold),
                    const SizedBox(height: 8),
                    if (isStarlight)
                      for (final paragraph in synopsis) ...[
                        Text(
                          paragraph,
                          style: AppTextStyles.bodyMediumRegular.copyWith(
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ]
                    else
                      const Text(
                        '영화 소개가 준비 중입니다.',
                        style: AppTextStyles.bodyMediumRegular,
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
}
