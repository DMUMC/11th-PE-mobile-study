import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_movies.dart';
import '../theme/app_colors.dart';
import '../widgets/movie/movie_detail_info.dart';
import '../widgets/movie/movie_detail_actions.dart';
import '../widgets/movie/rating_dialog.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movieId});
  final int? movieId;
  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool _isFavorite = false;
  double _rating = 0;

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFavorite ? '즐겨찾기에 추가했습니다.' : '즐겨찾기에서 삭제했습니다.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showRatingDialog() async {
    final rating = await showDialog<double>(
      context: context,
      builder: (context) => RatingDialog(initialRating: _rating),
    );
    // Dialog가 닫힌 뒤에도 상세 화면이 남아 있을 때만 상태를 갱신합니다.
    if (!mounted || rating == null) return;
    setState(() => _rating = rating);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${rating.toStringAsFixed(1)}점의 평점을 남겼습니다.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/movies');
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = findMovieById(widget.movieId);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cinema Archive',
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontSize: 22, color: AppColors.primary600),
        ),
        leading: IconButton(
          tooltip: '뒤로가기',
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back, color: AppColors.primary500),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.all(16),
            child: Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: movie == null
          ? const Center(child: Text('영화를 찾을 수 없습니다.'))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: 2 / 3,
                    child: Image.asset(
                      movie.heroAsset ?? movie.posterAsset,
                      fit: BoxFit.cover,
                    ),
                  ),
                  MovieDetailInfo(movie: movie),
                  const Divider(height: 24),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '시놉시스',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontSize: 20),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          movie.synopsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                height: 1.7,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: movie == null
          ? null
          : MovieDetailActions(
              isFavorite: _isFavorite,
              onFavorite: _toggleFavorite,
              onRating: _showRatingDialog,
            ),
    );
  }
}
