import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../data/models/rating_dto.dart';
import '../movie/widgets/movie_rating_dialog.dart';
import '../view_models/my_ratings_view_model.dart';
import '../widgets/movielog_button.dart';
import 'profile_body/my_rating_card.dart';
import 'widgets/delete_rating_dialog.dart';

class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({
    super.key,
    this.onEdit,
    this.onDelete,
    this.onEnterEdit,
  });

  final ValueChanged<RatingDto>? onEdit;
  final ValueChanged<RatingDto>? onDelete;
  final VoidCallback? onEnterEdit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final viewModel = context.watch<MyRatingsViewModel>();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: AppComponentHeight.appBar,
        centerTitle: true,
        leading: IconButton(
          tooltip: '뒤로 가기',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, size: 24),
        ),
        title: Text(
          '내가 등록한 평점',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 20,
            height: 1.4,
            color: colors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: viewModel.load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              18,
              AppSpacing.x3,
              18,
              AppSpacing.x3,
            ),
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onEnterEdit,
                  style: TextButton.styleFrom(
                    foregroundColor: colors.primary,
                    disabledForegroundColor: colors.primary,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    minimumSize: const Size(64, 40),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('편집'),
                ),
              ),
              const SizedBox(height: AppSpacing.x1),
              ...switch (viewModel.status) {
                MyRatingsLoadStatus.idle || MyRatingsLoadStatus.loading => [
                  const _RatingsStatus(
                    indicator: CircularProgressIndicator(),
                    message: '평점을 불러오는 중입니다.',
                  ),
                ],
                MyRatingsLoadStatus.empty => [
                  _RatingsStatus(
                    indicator: Icon(
                      Icons.star_border,
                      size: 32,
                      color: colors.primary,
                    ),
                    message: '등록된 평점이 없습니다.',
                    onRetry: viewModel.load,
                  ),
                ],
                MyRatingsLoadStatus.error => [
                  _RatingsStatus(
                    indicator: Icon(
                      Icons.error_outline,
                      size: 32,
                      color: colors.error,
                    ),
                    message:
                        viewModel.refreshWarning ??
                        viewModel.message ??
                        '평점을 불러오지 못했습니다.',
                    onRetry: viewModel.load,
                  ),
                ],
                MyRatingsLoadStatus.success => [
                  if (viewModel.message != null) ...[
                    Text(
                      viewModel.message!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.x2),
                  ],
                  for (final entry in viewModel.ratings) ...[
                    MyRatingCard(
                      key: ValueKey(entry.rating.ratingId),
                      title:
                          entry.movie?.title ?? '영화 #${entry.rating.movieId}',
                      score: entry.rating.score,
                      comment: entry.rating.comment,
                      onEdit: () {
                        if (onEdit != null) {
                          onEdit!(entry.rating);
                        } else {
                          _editRating(context, entry.rating);
                        }
                      },
                      onDelete: () => _confirmDelete(context, entry.rating),
                      posterUrl: entry.movie?.posterUrl,
                    ),
                    const SizedBox(height: AppSpacing.x2),
                  ],
                ],
              },
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, RatingDto rating) async {
    final viewModel = context.read<MyRatingsViewModel>();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      barrierDismissible: false,
      builder: (_) => DeleteRatingDialog(
        onConfirm: () => viewModel.deleteRating(rating.ratingId),
      ),
    );
    if (!context.mounted || confirmed != true) return;
    onDelete?.call(rating);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(viewModel.refreshWarning ?? '평점을 삭제했습니다.')),
    );
  }

  Future<void> _editRating(BuildContext context, RatingDto rating) async {
    final viewModel = context.read<MyRatingsViewModel>();
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => MovieRatingDialog(
        initialScore: rating.score,
        initialComment: rating.comment,
        onSubmit: (score, comment) => viewModel.updateRating(
          ratingId: rating.ratingId,
          score: score,
          comment: comment,
        ),
      ),
    );
    if (!context.mounted || saved != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(viewModel.refreshWarning ?? '평점을 수정했습니다.')),
    );
  }
}

class _RatingsStatus extends StatelessWidget {
  const _RatingsStatus({
    required this.indicator,
    required this.message,
    this.onRetry,
  });

  final Widget indicator;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48),
    child: Column(
      children: [
        indicator,
        const SizedBox(height: AppSpacing.x2),
        Text(message, textAlign: TextAlign.center),
        if (onRetry != null) ...[
          const SizedBox(height: AppSpacing.x3),
          MovieLogButton(label: '다시 불러오기', onPressed: onRetry),
        ],
      ],
    ),
  );
}
