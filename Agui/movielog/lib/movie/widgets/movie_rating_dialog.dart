import 'package:flutter/material.dart';
import 'package:movielog/movie/widgets/movie_rating_input.dart';
import 'package:movielog/theme/app_colors.dart';

class MovieRatingDialog extends StatefulWidget {
  const MovieRatingDialog({
    required this.initialRating,
    this.hasExistingRating = false,
    super.key,
  });

  final double initialRating;
  final bool hasExistingRating;

  @override
  State<MovieRatingDialog> createState() => _MovieRatingDialogState();
}

class _MovieRatingDialogState extends State<MovieRatingDialog> {
  late double _rating = widget.initialRating;
  late bool _isEditing = !widget.hasExistingRating;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceBase,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '영화는 어떠셨나요?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.onSurface,
                fontSize: 20,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            MovieRatingInput(
              rating: _rating,
              enabled: _isEditing,
              onChanged: (rating) => setState(() => _rating = rating),
            ),
            if (widget.hasExistingRating && !_isEditing) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() => _isEditing = true),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary600,
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('다시 선택하기'),
              ),
            ],
            SizedBox(height: widget.hasExistingRating && !_isEditing ? 12 : 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_rating),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('확인'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
