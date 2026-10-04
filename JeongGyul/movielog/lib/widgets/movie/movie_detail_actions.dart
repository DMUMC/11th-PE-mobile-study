import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MovieDetailActions extends StatelessWidget {
  const MovieDetailActions({
    super.key,
    required this.isFavorite,
    required this.onFavorite,
    required this.onRating,
  });
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onRating;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border(
        top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onFavorite,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  shape: const StadiumBorder(),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                icon: SizedBox.square(
                  dimension: 20,
                  child: SvgPicture.asset(
                    isFavorite
                        ? 'assets/icons/bookmark_filled.svg'
                        : 'assets/icons/bookmark.svg',
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).colorScheme.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                label: const Text('즐겨찾기'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onRating,
                style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
                icon: const Icon(Icons.rate_review_outlined, size: 20),
                label: const Text('평점 남기기'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
