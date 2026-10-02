import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../theme/app_colors.dart';

class MovieRatingInput extends StatefulWidget {
  const MovieRatingInput({required this.movieTitle, super.key});

  final String movieTitle;

  @override
  State<MovieRatingInput> createState() => _MovieRatingInputState();
}

class _MovieRatingInputState extends State<MovieRatingInput> {
  double _rating = 3.5;

  @override
  Widget build(BuildContext context) {
    final hasRating = _rating > 0;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '영화는 어떠셨나요?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            KeyedSubtree(
              key: const Key('ratingInput'),
              child: RatingBar.builder(
                initialRating: _rating,
                minRating: 0.5,
                allowHalfRating: true,
                itemCount: 5,
                itemSize: 42,
                unratedColor: const Color(0xFFE2DFE8),
                itemBuilder: (_, _) =>
                    const Icon(Icons.star_rounded, color: AppColors.primary),
                onRatingUpdate: (rating) => setState(() => _rating = rating),
              ),
            ),
            const SizedBox(height: 8),
            if (hasRating)
              TextButton(
                key: const Key('resetRatingButton'),
                onPressed: () => setState(() => _rating = 0),
                child: const Text('다시 선택하기'),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  '별을 눌러 평점을 선택해주세요',
                  style: TextStyle(color: AppColors.onSurfaceVariant),
                ),
              ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: hasRating
                    ? () => Navigator.pop(context, _rating)
                    : null,
                child: const Text('확인'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
