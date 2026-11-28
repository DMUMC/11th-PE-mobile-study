import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/rating_dto.dart';
import '../data/models/rating_with_movie.dart';
import '../data/services/rating_api_service.dart';
import '../view_models/my_ratings_view_model.dart';
import '../widgets/movielog_button.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/tmdb_poster_image.dart';

class MyRatingsSignUpRequiredScreen extends StatelessWidget {
  const MyRatingsSignUpRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(centerTitle: true, title: const Text('내가 등록한 평점')),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('학습용 회원가입이 필요합니다.'),
          const SizedBox(height: 16),
          MovieLogButton(
            label: '회원가입',
            onPressed: () => context.push('/signup'),
          ),
        ],
      ),
    ),
  );
}

class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  Future<void> _edit(
    BuildContext context,
    MyRatingsViewModel model,
    RatingDto rating,
  ) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RatingDialog(
        initialScore: rating.score,
        initialComment: rating.comment,
        onSubmit: (score, comment) => model.updateRating(
          ratingId: rating.ratingId,
          score: score,
          comment: comment,
        ),
      ),
    );
    if (saved == true && context.mounted) _showMessage(context, '평점을 수정했습니다.');
  }

  Future<void> _delete(
    BuildContext context,
    MyRatingsViewModel model,
    int ratingId,
  ) async {
    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _DeleteRatingDialog(onConfirm: () => model.deleteRating(ratingId)),
    );
    if (deleted == true && context.mounted) {
      _showMessage(context, '평점을 삭제했습니다.');
    }
  }

  Future<void> _deleteSelected(
    BuildContext context,
    MyRatingsViewModel model,
  ) async {
    final count = model.selectedCount;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('선택한 $count개 평점을 삭제할까요?'),
        content: const Text('삭제한 평점은 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          MovieLogButton(
            label: '삭제',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirmed != true ||
        !context.mounted ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }

    final failed = await model.deleteSelectedRatings();
    if (!context.mounted) return;
    _showMessage(context, switch (failed) {
      0 => '$count개 평점을 삭제했습니다.',
      _ when failed == count => '$failed개 평점을 삭제하지 못했습니다. 선택된 항목을 확인해 주세요.',
      _ => '${count - failed}개를 삭제했고 $failed개를 삭제하지 못했습니다. 선택된 항목을 확인해 주세요.',
    });
  }

  void _showMessage(BuildContext context, String message) {
    if (ModalRoute.of(context)?.isCurrent != true) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<MyRatingsViewModel>();
    return PopScope(
      canPop: !model.isWriting,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Scaffold(
            appBar: AppBar(centerTitle: true, title: const Text('내가 등록한 평점')),
            body: SafeArea(child: _buildBody(context, model)),
            bottomNavigationBar:
                model.isSelecting && model.status == MyRatingsLoadStatus.success
                ? SafeArea(
                    minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: MovieLogButton(
                      label: '선택한 ${model.selectedCount}개 삭제',
                      onPressed: model.selectedCount == 0 || model.isWriting
                          ? null
                          : () => _deleteSelected(context, model),
                    ),
                  )
                : null,
          ),
          if (model.isDeletingSelected) ...[
            const ModalBarrier(dismissible: false, color: Colors.black45),
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                semanticsLabel: '평점 삭제 중',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    MyRatingsViewModel model,
  ) => switch (model.status) {
    MyRatingsLoadStatus.idle || MyRatingsLoadStatus.loading
        when !model.isDeletingSelected =>
      const Center(child: CircularProgressIndicator()),
    MyRatingsLoadStatus.empty => const Center(child: Text('등록된 평점이 없습니다.')),
    MyRatingsLoadStatus.error => Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(model.message ?? '', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            MovieLogButton(label: '다시 시도', width: 96, onPressed: model.load),
          ],
        ),
      ),
    ),
    _ => Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  model.isSelecting
                      ? '${model.selectedCount}개 선택'
                      : '학습용 회원 ${model.memberId}의 평점',
                ),
              ),
              TextButton(
                onPressed: model.isWriting ? null : model.toggleSelectionMode,
                child: Text(model.isSelecting ? '취소' : '편집'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            itemCount: model.ratings.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final entry = model.ratings[index];
              final rating = entry.rating;
              final id = rating.ratingId;
              return _RatingCard(
                key: ValueKey(id),
                entry: entry,
                actions: model.isSelecting
                    ? Checkbox(
                        key: ValueKey('selectRating-$id'),
                        semanticLabel:
                            '${entry.movie?.title ?? '영화 #${rating.movieId}'} 평점 선택',
                        value: model.isSelected(id),
                        onChanged: model.isWriting
                            ? null
                            : (_) => model.toggleSelection(id),
                      )
                    : Column(
                        children: [
                          IconButton(
                            key: ValueKey('editRating-$id'),
                            tooltip: '평점 수정',
                            onPressed: model.isWriting
                                ? null
                                : () => _edit(context, model, rating),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            key: ValueKey('deleteRating-$id'),
                            tooltip: '평점 삭제',
                            onPressed: model.isWriting
                                ? null
                                : () => _delete(context, model, id),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
              );
            },
          ),
        ),
      ],
    ),
  };
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.entry, required this.actions, super.key});
  final RatingWithMovie entry;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    final rating = entry.rating;
    final date = MaterialLocalizations.of(context)
        .formatCompactDate(rating.createdAt.toLocal());
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TmdbPosterImage(
                posterPath: entry.movie?.posterPath,
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
                    entry.movie?.title ?? '영화 #${rating.movieId}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text('★ ${rating.score} / 5'),
                  if (rating.comment case final comment?) Text(comment),
                  Text('등록일 $date'),
                ],
              ),
            ),
            actions,
          ],
        ),
      ),
    );
  }
}

class _DeleteRatingDialog extends StatefulWidget {
  const _DeleteRatingDialog({required this.onConfirm});
  final Future<void> Function() onConfirm;

  @override
  State<_DeleteRatingDialog> createState() => _DeleteRatingDialogState();
}

class _DeleteRatingDialogState extends State<_DeleteRatingDialog> {
  bool _deleting = false;
  String? _errorText;

  Future<void> _confirm() async {
    if (_deleting) return;
    setState(() {
      _deleting = true;
      _errorText = null;
    });
    try {
      await widget.onConfirm();
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _deleting = false;
        _errorText = writeRatingErrorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_deleting,
    child: AlertDialog(
      title: const Text('평점을 삭제할까요?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('삭제한 평점은 복구할 수 없습니다.'),
          if (_errorText case final message?) ...[
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _deleting ? null : () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        MovieLogButton(label: '삭제', isLoading: _deleting, onPressed: _confirm),
      ],
    ),
  );
}
