import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:movielog/theme/app_colors.dart';

/// MovieLog 평점 선택 Dialog와 평점 입력에 사용하는 별점 위젯입니다.
class MovieRatingInput extends StatelessWidget {
  const MovieRatingInput({
    required this.rating,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final double rating;
  final ValueChanged<double> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return RatingBar.builder(
      initialRating: rating,
      minRating: 0.5,
      allowHalfRating: true,
      itemCount: 5,
      itemSize: 38,
      itemPadding: const EdgeInsets.symmetric(horizontal: 3),
      unratedColor: AppColors.neutral400,
      glow: false,
      ignoreGestures: !enabled,
      itemBuilder: (context, index) =>
          const Icon(Icons.star_rounded, color: AppColors.primary600),
      onRatingUpdate: onChanged,
    );
  }
}
