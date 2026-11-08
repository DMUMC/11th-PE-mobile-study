import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';

import '../data/models/rating_with_movie.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/my_ratings_view_model.dart';
import '../widgets/movielog_button.dart';
import '../widgets/tmdb_poster_image.dart';

/// 마이페이지 → 내가 등록한 평점.
/// root Navigator 위에 열리므로 하단 NavigationBar가 없다.
class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('내가 등록한 평점', style: AppTextStyles.appBarTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Consumer<MyRatingsViewModel>(
          builder: (context, viewModel, child) {
            return switch (viewModel.status) {
              MyRatingsLoadStatus.idle ||
              MyRatingsLoadStatus.loading => const Center(
                child: CircularProgressIndicator(color: AppColors.violet),
              ),
              MyRatingsLoadStatus.empty => _StateMessage(
                icon: Icons.star_outline,
                message: '아직 등록된 평점이 없어요.',
                memberId: viewModel.memberId,
              ),
              MyRatingsLoadStatus.error => _StateMessage(
                icon: Icons.error_outline,
                message: viewModel.message ?? '평점을 불러오지 못했습니다.',
                memberId: viewModel.memberId,
                onRetry: viewModel.load,
              ),
              MyRatingsLoadStatus.success => _RatingList(viewModel: viewModel),
            };
          },
        ),
      ),
    );
  }
}

/// 이 화면이 로그인 사용자가 아닌 학습용 샘플 데이터라는 안내
class _SampleNotice extends StatelessWidget {
  const _SampleNotice({required this.memberId});

  final int memberId;

  @override
  Widget build(BuildContext context) {
    return Text(
      '학습용 memberId $memberId의 공개 평점을 조회합니다.',
      style: AppTextStyles.labelSmall,
    );
  }
}

class _RatingList extends StatelessWidget {
  const _RatingList({required this.viewModel});

  final MyRatingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final message = viewModel.message;

    return RefreshIndicator(
      color: AppColors.violet,
      onRefresh: viewModel.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Row(
            children: [
              const Text('평점 기록', style: AppTextStyles.sectionTitle),
              const SizedBox(width: 8),
              Text(
                '${viewModel.ratings.length}',
                style: AppTextStyles.sectionTitle.copyWith(
                  color: AppColors.violet,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _SampleNotice(memberId: viewModel.memberId),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(message, style: AppTextStyles.labelSmall),
          ],
          const SizedBox(height: 12),
          for (final entry in viewModel.ratings)
            _RatingCard(key: ValueKey(entry.rating.ratingId), entry: entry),
        ],
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({super.key, required this.entry});

  final RatingWithMovie entry;

  @override
  Widget build(BuildContext context) {
    final rating = entry.rating;
    final movie = entry.movie;
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
            // movie가 null이면 posterPath도 null → placeholder
            child: TmdbPosterImage(
              posterPath: movie?.posterPath,
              width: 64,
              height: 96,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie?.title ?? '영화 정보를 불러오지 못했어요',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: movie == null ? AppColors.gray : AppColors.black,
                  ),
                ),
                const SizedBox(height: 6),
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
                // comment가 null이면 표시하지 않는다.
                if (comment != null && comment.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(comment, style: AppTextStyles.bodyMedium),
                ],
                const SizedBox(height: 6),
                Text(
                  '${_formatDate(rating.createdAt.toLocal())} · movieId ${rating.movieId}',
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

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.message,
    required this.memberId,
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final int memberId;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.gray),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.black, height: 1.5),
            ),
            const SizedBox(height: 4),
            _SampleNotice(memberId: memberId),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              // 고정 너비 버튼: 문구 길이와 관계없이 항상 96px
              MovieLogButton(label: '다시 시도', width: 96, onPressed: onRetry),
            ],
          ],
        ),
      ),
    );
  }
}
