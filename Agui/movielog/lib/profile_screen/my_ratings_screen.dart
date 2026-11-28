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
import 'widgets/loading_overlay.dart';

class MyRatingsScreen extends StatefulWidget {
  const MyRatingsScreen({
    super.key,
    this.onEdit,
    this.onDelete,
    this.onEnterEdit,
    this.isDeletingSelected = false,
  });

  final ValueChanged<RatingDto>? onEdit;
  final ValueChanged<RatingDto>? onDelete;
  final VoidCallback? onEnterEdit;
  final bool isDeletingSelected;

  @override
  State<MyRatingsScreen> createState() => _MyRatingsScreenState();
}

class _MyRatingsScreenState extends State<MyRatingsScreen> {
  bool _isSelecting = false;
  final Set<int> _selectedRatingIds = {};

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final viewModel = context.watch<MyRatingsViewModel>();

    final visibleIds = viewModel.ratings
        .map((entry) => entry.rating.ratingId)
        .toSet();
    final selectedIds = _selectedRatingIds.intersection(visibleIds);

    final isDeleting =
        widget.isDeletingSelected || viewModel.isDeletingSelected;

    return PopScope(
      canPop: !isDeleting,
      child: LoadingOverlay(
        isLoading: isDeleting,
        child: Scaffold(
          appBar: AppBar(
            toolbarHeight: AppComponentHeight.appBar,
            centerTitle: true,
            leading: IconButton(
              tooltip: '뒤로 가기',
              onPressed: isDeleting ? null : () => context.pop(),
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
          bottomNavigationBar: _isSelecting
              ? SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: selectedIds.isEmpty || isDeleting
                            ? null
                            : () =>
                                  _confirmDeleteSelected(context, selectedIds),
                        style: FilledButton.styleFrom(
                          shape: const StadiumBorder(),
                        ),
                        child: Text('선택한 ${selectedIds.length}개 삭제'),
                      ),
                    ),
                  ),
                )
              : null,
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
                  const Text('현재 로그인 세션에서 등록한 평점만 표시됩니다.'),
                  Row(
                    children: [
                      if (_isSelecting)
                        Text(
                          '${selectedIds.length}개 선택됨',
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      const Spacer(),
                      TextButton(
                        onPressed:
                            _isSelecting ||
                                viewModel.status == MyRatingsLoadStatus.success
                            ? () {
                                setState(() {
                                  _isSelecting = !_isSelecting;
                                  _selectedRatingIds.clear();
                                });
                                if (_isSelecting) widget.onEnterEdit?.call();
                              }
                            : null,
                        style: TextButton.styleFrom(
                          foregroundColor: colors.primary,
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          minimumSize: const Size(64, 40),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(_isSelecting ? '취소' : '편집'),
                      ),
                    ],
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
                        message:
                            '현재 로그인 세션에서 등록한 평점이 없습니다.\n기존 평점은 불러올 수 없습니다.',
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
                        if (_isSelecting)
                          _SelectableRatingCard(
                            rating: entry.rating,
                            title:
                                entry.movie?.title ??
                                '영화 #${entry.rating.movieId}',
                            selected: selectedIds.contains(
                              entry.rating.ratingId,
                            ),
                            onChanged: (selected) => setState(() {
                              if (selected) {
                                _selectedRatingIds.add(entry.rating.ratingId);
                              } else {
                                _selectedRatingIds.remove(
                                  entry.rating.ratingId,
                                );
                              }
                            }),
                          )
                        else
                          MyRatingCard(
                            key: ValueKey(entry.rating.ratingId),
                            title:
                                entry.movie?.title ??
                                '영화 #${entry.rating.movieId}',
                            score: entry.rating.score,
                            comment: entry.rating.comment,
                            onEdit: () {
                              if (widget.onEdit != null) {
                                widget.onEdit!(entry.rating);
                              } else {
                                _editRating(context, entry.rating);
                              }
                            },
                            onDelete: () =>
                                _confirmDelete(context, entry.rating),
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
        ),
      ),
    );
  }

  Future<void> _confirmDeleteSelected(
    BuildContext context,
    Set<int> selectedIds,
  ) async {
    final viewModel = context.read<MyRatingsViewModel>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('선택한 평점을 삭제할까요?'),
        content: const Text('삭제한 평점은 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (!context.mounted || confirmed != true) return;
    final failed = await viewModel.deleteSelectedRatings(Set.of(selectedIds));
    if (!context.mounted) return;
    setState(() {
      _selectedRatingIds.removeAll(selectedIds.difference(failed));
      if (failed.isEmpty) _isSelecting = false;
    });
    final message = failed.isNotEmpty
        ? '${failed.length}개 항목을 삭제하지 못했습니다. 선택된 항목을 다시 확인해 주세요.'
        : viewModel.refreshWarning ?? '선택한 평점을 삭제했습니다.';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
    widget.onDelete?.call(rating);
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
        onSubmit: (score, comment, _) => viewModel.updateRating(
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

class _SelectableRatingCard extends StatelessWidget {
  const _SelectableRatingCard({
    required this.rating,
    required this.title,
    required this.selected,
    required this.onChanged,
  });
  final RatingDto rating;
  final String title;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.secondary.withValues(alpha: 0.32)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onChanged(!selected),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 128),
          child: Row(
            children: [
              Checkbox(
                value: selected,
                onChanged: (value) => onChanged(value ?? false),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$title · 별점 ${rating.score}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (rating.comment?.trim().isNotEmpty ?? false) ...[
                        const SizedBox(height: 8),
                        Text(
                          rating.comment!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
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
