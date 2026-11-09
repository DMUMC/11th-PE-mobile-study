import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/my_page_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/tmdb_poster_image.dart';
import 'profile_screen.dart';

/// 마이 탭. 기존 프로필 화면 구성에 MovieLog 서버의 "내가 남긴 평점"을 더한다.
class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '내 프로필'),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.violet,
          onRefresh: () => context.read<MyPageViewModel>().loadRatings(),
          child: const SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileHeader(
                  imagePath: 'assets/images/profile/profile_movielog.jpg',
                ),
                SizedBox(height: 24),
                ProfileStats(),
                SizedBox(height: 28),
                FavoriteGenres(),
                SizedBox(height: 28),
                _MyRatingsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MyRatingsSection extends StatelessWidget {
  const _MyRatingsSection();

  @override
  Widget build(BuildContext context) {
    // 평점 영역만 상태 변화에 맞춰 다시 그린다.
    return Consumer<MyPageViewModel>(
      builder: (context, viewModel, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('내가 남긴 평점', style: AppTextStyles.sectionTitle),
                const SizedBox(width: 8),
                if (viewModel.status == MyRatingsLoadStatus.success)
                  Text(
                    '${viewModel.ratings.length}',
                    style: AppTextStyles.sectionTitle.copyWith(
                      color: AppColors.violet,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'memberId ${viewModel.memberId} · MovieLog 서버',
              style: AppTextStyles.labelSmall,
            ),
            const SizedBox(height: 12),
            switch (viewModel.status) {
              MyRatingsLoadStatus.idle ||
              MyRatingsLoadStatus.loading => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.violet),
                ),
              ),
              MyRatingsLoadStatus.empty => const _RatingsMessage(
                message: '아직 남긴 평점이 없어요.',
              ),
              MyRatingsLoadStatus.error => _RatingsMessage(
                message: viewModel.message ?? '평점을 불러오지 못했어요.',
                onRetry: () => context.read<MyPageViewModel>().loadRatings(),
              ),
              MyRatingsLoadStatus.success => Column(
                children: [
                  for (final item in viewModel.ratings)
                    _RatingTile(key: ValueKey(item.rating.ratingId), item: item),
                ],
              ),
            },
          ],
        );
      },
    );
  }
}

class _RatingTile extends StatelessWidget {
  const _RatingTile({super.key, required this.item});

  final MyRatingItem item;

  @override
  Widget build(BuildContext context) {
    final rating = item.rating;
    final movie = item.movie;
    final createdAt = rating.createdAt;
    final comment = rating.comment;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TmdbPosterImage(
              posterPath: movie?.posterPath,
              width: 56,
              height: 84,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // TMDB 조회에 실패해도 movieId로 어떤 영화인지 표시한다.
                  movie?.title ?? '영화 #${rating.movieId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    RatingBarIndicator(
                      rating: rating.score.toDouble(),
                      itemCount: 5,
                      itemSize: 16,
                      itemBuilder: (context, _) =>
                          const Icon(Icons.star, color: Colors.amber),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${rating.score}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                if (comment != null && comment.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(comment, style: AppTextStyles.bodyMedium),
                ],
                const SizedBox(height: 6),
                Text(
                  [
                    'movieId ${rating.movieId}',
                    if (createdAt != null) _formatDate(createdAt),
                  ].join(' · '),
                  style: AppTextStyles.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${date.year}.${twoDigits(date.month)}.${twoDigits(date.day)}';
  }
}

class _RatingsMessage extends StatelessWidget {
  const _RatingsMessage({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.gray, height: 1.5),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.violet,
                ),
                onPressed: onRetry,
                child: const Text('다시 시도'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
