import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../theme/app_colors.dart';

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
  Widget build(BuildContext context) => KeyedSubtree(
    key: const Key('ratingInput'),
    child: RatingBar.builder(
      initialRating: rating,
      minRating: 1,
      allowHalfRating: false,
      ignoreGestures: !enabled,
      itemCount: 5,
      itemSize: 40,
      unratedColor: const Color(0xFFE2DFE8),
      itemBuilder: (_, _) =>
          const Icon(Icons.star_rounded, color: AppColors.primary),
      onRatingUpdate: onChanged,
    ),
  );
}
