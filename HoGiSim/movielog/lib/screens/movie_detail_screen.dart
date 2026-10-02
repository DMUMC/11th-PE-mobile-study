import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';

import '../models/movie.dart';
import '../theme/app_colors.dart';
import '../widgets/movie_rating_input.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({required this.movie, super.key});

  final Movie movie;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool _isFavorite = false;
  double? _myRating;

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(_isFavorite ? '즐겨찾기에 추가했습니다.' : '즐겨찾기에서 삭제했습니다.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _openRatingDialog() async {
    final rating = await showDialog<double>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => MovieRatingInput(movieTitle: widget.movie.title),
    );
    if (rating == null || !mounted) return;
    setState(() => _myRating = rating);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('평점 $rating점을 저장했습니다.')));
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('detailBackButton'),
          onPressed: context.pop,
          icon: const Icon(Icons.arrow_back),
        ),
        centerTitle: true,
        title: const Text(
          'Cinema Archive',
          style: TextStyle(color: AppColors.primary, fontSize: 20),
        ),
        actions: [
          IconButton(
            tooltip: '공유하기',
            onPressed: () {},
            icon: const Icon(Icons.share_outlined),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        children: [
          AspectRatio(
            aspectRatio: 0.67,
            child: Hero(
              tag: 'poster-${movie.id}',
              child: Image.asset(movie.posterAsset, fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${movie.year} · ${movie.genreLabel} · ${movie.runtime}분',
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                _RatingSummary(movie: movie),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  children: [
                    ...movie.genres.map((genre) => Chip(label: Text(genre))),
                    const Chip(label: Text('감동적인')),
                  ],
                ),
                const Divider(height: 38),
                const Text(
                  '시놉시스',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  movie.overview,
                  style: const TextStyle(fontSize: 15, height: 1.65),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('favoriteButton'),
                onPressed: _toggleFavorite,
                icon: Icon(
                  _isFavorite ? Icons.bookmark : Icons.bookmark_border,
                ),
                label: Text(_isFavorite ? '즐겨찾기됨' : '즐겨찾기'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                key: const Key('openRatingDialog'),
                onPressed: _openRatingDialog,
                icon: const Icon(Icons.rate_review_outlined),
                label: Text(_myRating == null ? '평점 남기기' : '$_myRating점'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingSummary extends StatelessWidget {
  const _RatingSummary({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        KeyedSubtree(
          key: const Key('averageRatingIndicator'),
          child: RatingBarIndicator(
            rating: movie.averageRating,
            itemCount: 5,
            itemSize: 18,
            itemBuilder: (_, _) =>
                const Icon(Icons.star_rounded, color: AppColors.primary),
            unratedColor: AppColors.outline,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${movie.averageRating.toStringAsFixed(1)} (${_formatCount(movie.reviewCount)})',
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    final value = count.toString();
    if (value.length <= 3) return value;
    return '${value.substring(0, value.length - 3)},${value.substring(value.length - 3)}';
  }
}

class MovieNotFoundScreen extends StatelessWidget {
  const MovieNotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: const Center(child: Text('영화를 찾을 수 없습니다.')),
    );
  }
}
