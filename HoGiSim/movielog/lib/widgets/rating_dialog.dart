import 'package:flutter/material.dart';

import '../data/models/rating_request.dart';
import '../data/services/rating_api_service.dart';
import 'movie_rating_input.dart';
import 'movielog_button.dart';

class RatingDialog extends StatefulWidget {
  const RatingDialog({
    required this.onSubmit,
    this.movieTitle,
    this.initialScore = 0,
    this.initialComment,
    super.key,
  });

  final String? movieTitle;
  final int initialScore;
  final String? initialComment;
  final Future<void> Function(int score, String? comment) onSubmit;

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  late int _score = widget.initialScore;
  late final _commentController = TextEditingController(
    text: widget.initialComment,
  );
  bool _submitting = false;
  String? _errorText;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || _score == 0) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _errorText = null;
    });
    final comment = _commentController.text.trim();

    try {
      await widget.onSubmit(_score, comment.isEmpty ? null : comment);
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorText = writeRatingErrorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_submitting,
    child: AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      scrollable: true,
      title: const Text('평점을 남겨주세요'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.movieTitle case final title?) ...[
            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
          ],
          FittedBox(
            fit: BoxFit.scaleDown,
            child: MovieRatingInput(
              rating: _score.toDouble(),
              enabled: !_submitting,
              onChanged: (value) => setState(() {
                _score = validateServerScore(value);
                _errorText = null;
              }),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('ratingCommentField'),
            controller: _commentController,
            enabled: !_submitting,
            maxLength: 500,
            maxLines: 3,
            onChanged: (_) {
              if (_errorText != null) setState(() => _errorText = null);
            },
            decoration: const InputDecoration(hintText: '코멘트를 남겨보세요 (선택)'),
          ),
          if (_errorText case final message?)
            Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        MovieLogButton(
          key: const Key('submitRatingButton'),
          label: '확인',
          isLoading: _submitting,
          onPressed: _score == 0 ? null : _submit,
        ),
      ],
    ),
  );
}
