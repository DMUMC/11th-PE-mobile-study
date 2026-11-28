import 'package:movielog/data/models/rating_request.dart';
import 'package:flutter/material.dart';
import 'package:movielog/movie/widgets/movie_rating_input.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/widgets/movielog_button.dart';

import '../../view_models/movie_detail_view_model.dart';

class MovieRatingDialog extends StatefulWidget {
  const MovieRatingDialog({
    this.initialScore = 0,
    this.initialComment,
    this.showAddToFavorite = false,
    required this.onSubmit,
    super.key,
  });

  final int initialScore;
  final String? initialComment;
  final bool showAddToFavorite;
  final Future<void> Function(int score, String? comment, bool addToFavorites)
  onSubmit;

  @override
  State<MovieRatingDialog> createState() => _MovieRatingDialogState();
}

class _MovieRatingDialogState extends State<MovieRatingDialog> {
  bool _isSubmitting = false;
  bool _addToFavorites = false;
  String? _errorText;
  late int _score = widget.initialScore;
  late final _commentController = TextEditingController(
    text: widget.initialComment ?? '',
  );

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting,
      child: Dialog(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 338),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '평점을 남겨주세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 20,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: MovieRatingInput(
                    rating: _score.toDouble(),
                    enabled: !_isSubmitting,
                    onChanged: (rating) =>
                        setState(() => _score = validateServerScore(rating)),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  '코멘트 (선택, 최대 500자)',
                  style: TextStyle(fontSize: 12, height: 1.5),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _commentController,
                  enabled: !_isSubmitting,
                  minLines: 4,
                  maxLines: 4,
                  maxLength: 500,
                  style: const TextStyle(fontSize: 12, height: 1.5),
                  decoration: InputDecoration(
                    hintText: '이 영화의 인상적인 장면은..',
                    hintStyle: const TextStyle(color: AppColors.gray),
                    fillColor: const Color(0xFFFAF8FF),
                    filled: true,
                    counterText: '',
                    contentPadding: const EdgeInsets.all(12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.surfaceHighest,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary500),
                    ),
                  ),
                ),
                if (widget.showAddToFavorite) ...[
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: _addToFavorites,
                    onChanged: _isSubmitting
                        ? null
                        : (value) =>
                              setState(() => _addToFavorites = value ?? false),
                    title: const Text(
                      '즐겨찾기에도 추가',
                      style: TextStyle(fontSize: 14),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeColor: AppColors.primary,
                  ),
                ],
                if (_errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(_errorText!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: MovieLogButton(
                        label: '취소',
                        backgroundColor: AppColors.primary100,
                        foregroundColor: AppColors.primary600,
                        borderRadius: 100,
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(false),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: MovieLogButton(
                        label: '확인',
                        borderRadius: 100,
                        isLoading: _isSubmitting,
                        onPressed: _score > 0 && !_isSubmitting
                            ? _confirm
                            : null,
                      ),
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

  Future<void> _confirm() async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    final comment = _commentController.text.trim();
    try {
      await widget.onSubmit(
        _score,
        comment.isEmpty ? null : comment,
        widget.showAddToFavorite && _addToFavorites,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      if (error is RatingSubmissionException && error.closeDialog) {
        Navigator.of(context).pop(error);
        return;
      }
      setState(() {
        _isSubmitting = false;
        _errorText = error.toString();
      });
    }
  }
}
