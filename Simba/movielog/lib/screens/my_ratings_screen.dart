import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';

import '../data/models/rating_dto.dart';
import '../data/models/rating_with_movie.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/my_ratings_view_model.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/movielog_button.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/tmdb_poster_image.dart';

/// 마이페이지 → 내가 등록한 평점. 조회·수정·삭제를 이 화면에서 한다.
/// root Navigator 위에 열리므로 하단 NavigationBar가 없다.
class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MyRatingsViewModel>(
      builder: (context, viewModel, child) {
        final selectedCount = viewModel.selectedRatingIds.length;
        // 다중 삭제 중에는 뒤로가기로 화면을 벗어날 수 없다.
        return PopScope(
          canPop: !viewModel.isDeletingSelected,
          child: Scaffold(
            appBar: AppBar(
              leading: BackButton(
                onPressed: viewModel.isDeletingSelected
                    ? null
                    : () => Navigator.maybePop(context),
              ),
              title: const Text('내가 등록한 평점', style: AppTextStyles.appBarTitle),
              centerTitle: true,
            ),
            body: SafeArea(
              child: LoadingOverlay(
                isLoading: viewModel.isDeletingSelected,
                child: _Body(viewModel: viewModel),
              ),
            ),
            bottomNavigationBar: viewModel.isEditMode
                ? SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: MovieLogButton(
                        label: '선택한 $selectedCount개 삭제',
                        width: double.infinity,
                        isLoading: viewModel.isDeletingSelected,
                        onPressed: selectedCount > 0
                            ? () => _onDeleteSelectedPressed(context)
                            : null,
                      ),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.viewModel});

  final MyRatingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return switch (viewModel.status) {
      MyRatingsLoadStatus.idle || MyRatingsLoadStatus.loading => const Center(
        child: CircularProgressIndicator(color: AppColors.violet),
      ),
      MyRatingsLoadStatus.empty => _StateMessage(
        icon: Icons.star_outline,
        message: '아직 등록된 평점이 없어요.',
        memberId: viewModel.memberId,
      ),
      MyRatingsLoadStatus.error => _StateMessage(
        icon: Icons.error_outline,
        // 저장 성공 뒤 GET만 실패했으면 그 사실을 따로 알리고 조회만 다시 시도한다.
        message:
            viewModel.refreshWarning ?? viewModel.message ?? '평점을 불러오지 못했습니다.',
        memberId: viewModel.memberId,
        onRetry: viewModel.load,
      ),
      MyRatingsLoadStatus.success => _RatingList(viewModel: viewModel),
    };
  }
}

class _SampleNotice extends StatelessWidget {
  const _SampleNotice({required this.memberId});

  final int memberId;

  @override
  Widget build(BuildContext context) {
    return Text(
      '학습용 memberId $memberId의 평점입니다. (로그인 인증 아님)',
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
    final isEditMode = viewModel.isEditMode;

    return RefreshIndicator(
      color: AppColors.violet,
      onRefresh: viewModel.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          // 편집 진입 / 선택 중 헤더
          SizedBox(
            height: 48,
            child: Row(
              children: [
                if (isEditMode)
                  Text(
                    '${viewModel.selectedRatingIds.length}개 선택',
                    style: AppTextStyles.sectionTitle.copyWith(
                      color: AppColors.violet,
                    ),
                  )
                else ...[
                  const Text('평점 기록', style: AppTextStyles.sectionTitle),
                  const SizedBox(width: 8),
                  Text(
                    '${viewModel.ratings.length}',
                    style: AppTextStyles.sectionTitle.copyWith(
                      color: AppColors.violet,
                    ),
                  ),
                ],
                const Spacer(),
                TextButton(
                  onPressed: viewModel.isDeletingSelected
                      ? null
                      : isEditMode
                      ? viewModel.exitEditMode
                      : viewModel.enterEditMode,
                  child: Text(isEditMode ? '취소' : '편집'),
                ),
              ],
            ),
          ),
          _SampleNotice(memberId: viewModel.memberId),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(message, style: AppTextStyles.labelSmall),
          ],
          const SizedBox(height: 12),
          for (final entry in viewModel.ratings)
            _RatingCard(
              key: ValueKey(entry.rating.ratingId),
              entry: entry,
              isEditMode: isEditMode,
              isSelected: viewModel.selectedRatingIds.contains(
                entry.rating.ratingId,
              ),
              onToggle: () => viewModel.toggleSelection(entry.rating.ratingId),
              onEdit: () => _onEditPressed(context, entry.rating),
              onDelete: () => _onDeletePressed(context, entry.rating),
            ),
        ],
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({
    super.key,
    required this.entry,
    required this.isEditMode,
    required this.isSelected,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final RatingWithMovie entry;
  final bool isEditMode;
  final bool isSelected;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final rating = entry.rating;
    final movie = entry.movie;
    final comment = rating.comment;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isSelected ? AppColors.lightViolet : AppColors.cardBg,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: isSelected ? AppColors.violet : AppColors.cardBorder,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isEditMode ? onToggle : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
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
                          color: movie == null
                              ? AppColors.gray
                              : AppColors.black,
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
                // 기본: 개별 수정·삭제 / 편집 모드: CheckBox
                if (isEditMode)
                  Checkbox(
                    value: isSelected,
                    activeColor: AppColors.violet,
                    onChanged: (_) => onToggle(),
                  )
                else
                  Column(
                    children: [
                      IconButton(
                        tooltip: '수정',
                        icon: const Icon(Icons.edit_outlined),
                        color: AppColors.violet,
                        onPressed: onEdit,
                      ),
                      IconButton(
                        tooltip: '삭제',
                        icon: const Icon(Icons.delete_outline),
                        color: const Color(0xFFD32F2F),
                        onPressed: onDelete,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
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

// ── 수정 ──
/// 등록과 같은 RatingDialog를 기존 별점·코멘트로 채워 연다.
Future<void> _onEditPressed(BuildContext context, RatingDto rating) async {
  final viewModel = context.read<MyRatingsViewModel>();
  await showDialog<bool>(
    context: context,
    barrierDismissible: false, // 저장 중 바깥 탭으로 닫히는 것도 막는다.
    builder: (_) => RatingDialog(
      title: '평점을 수정할까요?',
      initialScore: rating.score,
      initialComment: rating.comment, // null이면 빈 칸으로 시작
      onSubmit: (score, comment) => viewModel.updateRating(
        ratingId: rating.ratingId,
        score: score,
        comment: comment,
      ),
    ),
  );
  // 성공하면 updateRating 안에서 목록을 다시 읽는다. 실패는 Dialog 안에서 안내한다.
}

// ── 단일 삭제: 삭제하는 동안 Dialog를 유지한다 ──
Future<void> _onDeletePressed(BuildContext context, RatingDto rating) async {
  final viewModel = context.read<MyRatingsViewModel>();
  await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _DeleteRatingDialog(
      onConfirm: () => viewModel.deleteRating(rating.ratingId),
    ),
  );
}

class _DeleteRatingDialog extends StatefulWidget {
  const _DeleteRatingDialog({required this.onConfirm});

  final Future<void> Function() onConfirm;

  @override
  State<_DeleteRatingDialog> createState() => _DeleteRatingDialogState();
}

class _DeleteRatingDialogState extends State<_DeleteRatingDialog> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDeleting,
      child: AlertDialog(
        title: const Text('평점을 삭제할까요?'),
        content: const Text('삭제한 평점은 복구할 수 없습니다.'),
        actions: [
          MovieLogButton(
            label: '취소',
            // 취소하면 onConfirm을 부르지 않으므로 삭제 요청도 없다.
            onPressed: _isDeleting ? null : () => Navigator.pop(context, false),
          ),
          MovieLogButton(
            label: '삭제',
            isLoading: _isDeleting,
            onPressed: _isDeleting ? null : _onConfirm,
          ),
        ],
      ),
    );
  }

  Future<void> _onConfirm() async {
    setState(() => _isDeleting = true);
    try {
      await widget.onConfirm();
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      // 403(본인 평점 아님)과 404(없는 평점)를 서버 문구로 구분해 보여준다.
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(describeSubmitError(error))));
    }
  }
}

// ── 다중 삭제: 확인 Dialog는 바로 닫고, 화면 위 오버레이로 진행한다 ──
Future<void> _onDeleteSelectedPressed(BuildContext context) async {
  final viewModel = context.read<MyRatingsViewModel>();
  final count = viewModel.selectedRatingIds.length;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('선택한 $count개 평점을 삭제할까요?'),
      content: const Text('삭제한 평점은 복구할 수 없습니다.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('삭제', style: TextStyle(color: Color(0xFFD32F2F))),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  final failed = await viewModel.deleteSelectedRatings();
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        failed == 0
            ? '선택한 $count개 평점을 삭제했습니다.'
            : '${count - failed}개를 삭제했고, $failed개는 삭제하지 못했습니다. 남은 선택 항목을 확인해 주세요.',
      ),
    ),
  );
}
