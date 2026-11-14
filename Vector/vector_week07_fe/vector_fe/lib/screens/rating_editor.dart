import 'package:flutter/material.dart';

import '../services/member_api.dart';

Future<int?> showRatingEditor(
  BuildContext context, {
  required String movieTitle,
  required int movieId,
  int? initialScore,
  required Future<void> Function(int) save,
}) => showDialog<int>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _RatingEditor(
    movieTitle: movieTitle,
    movieId: movieId,
    initialScore: initialScore,
    save: save,
  ),
);

class _RatingEditor extends StatefulWidget {
  const _RatingEditor({
    required this.movieTitle,
    required this.movieId,
    required this.initialScore,
    required this.save,
  });
  final String movieTitle;
  final int movieId;
  final int? initialScore;
  final Future<void> Function(int) save;

  @override
  State<_RatingEditor> createState() => _RatingEditorState();
}

class _RatingEditorState extends State<_RatingEditor> {
  late int _score = widget.initialScore ?? 0;
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    if (_saving || _score == 0) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.save(_score);
      if (mounted) Navigator.pop(context, _score);
    } on MemberApiException catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: Text(widget.initialScore == null ? '평점 등록' : '평점 수정'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.movieTitle),
          Text(
            'TMDB ID ${widget.movieId} → MovieLog movieId ${widget.movieId}',
          ),
          FittedBox(
            child: Row(
              children: [
                for (var score = 1; score <= 5; score++)
                  IconButton(
                    tooltip: '$score점',
                    onPressed: _saving
                        ? null
                        : () => setState(() => _score = score),
                    icon: Icon(
                      score <= _score ? Icons.star : Icons.star_border,
                    ),
                  ),
              ],
            ),
          ),
          Text('별점 $_score / 5'),
          if (_error case final error?)
            Text(
              error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _saving || _score == 0 ? null : _save,
          child: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('저장'),
        ),
      ],
    ),
  );
}
