import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../utils/movie_format.dart';
import '../widgets/tmdb_poster_image.dart';

/// 평점 Dialog가 돌려주는 값. `movieId`는 TMDB 영화 id이며
/// 이후 MovieLog 평점 API(CreateRatingRequest.movieId)로 그대로 전달한다.
typedef MovieRatingInput = ({int movieId, double score});

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movieId, this.movie});

  /// 경로(`/movies/:movieId`)로 전달된 TMDB 영화 id
  final int? movieId;

  /// 목록에서 extra로 전달한 영화 DTO
  final TmdbMovieDto? movie;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool _isFavorite = false;
  double? _userRating;

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFavorite ? '즐겨찾기에 추가되었습니다.' : '즐겨찾기에서 제거되었습니다.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openRatingDialog(TmdbMovieDto movie) async {
    final result = await showDialog<MovieRatingInput>(
      context: context,
      builder: (context) => _RatingCustomDialog(
        movieId: movie.id,
        initialRating: _userRating ?? 0.0,
      ),
    );

    if (result == null || !mounted) return;
    setState(() {
      _userRating = result.score;
    });
    // 평점 API가 연결되면 result.movieId(TMDB id)를 그대로 movieId로 보낸다.
    debugPrint('[Rating] movieId=${result.movieId} score=${result.score}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('별점 ${result.score.toStringAsFixed(1)}점을 등록했습니다.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;

    if (movie == null || movie.id != widget.movieId) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('영화를 찾을 수 없습니다.')),
      );
    }

    final year = releaseYearOf(movie.releaseDate);
    final score = movie.voteAverage / 2;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 포스터 배너
            TmdbPosterImage(
              posterPath: movie.posterPath,
              width: double.infinity,
              height: 380,
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // release_date가 없으면 출시 연도를 표시하지 않는다.
                  if (year != null) ...[
                    const SizedBox(height: 6),
                    Text(year, style: const TextStyle(color: Colors.grey)),
                  ],
                  const SizedBox(height: 12),
                  // 읽기 전용 평점 (TMDB 10점 만점 → 5점 만점)
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: score,
                        itemBuilder: (context, _) =>
                            const Icon(Icons.star, color: Colors.amber),
                        itemCount: 5,
                        itemSize: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        fivePointScoreOf(movie.voteAverage),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  const Text(
                    '시놉시스',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (movie.overview.trim().isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          '줄거리 정보가 없어요.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    Text(movie.overview, style: const TextStyle(height: 1.6)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
      // 하단 액션 버튼 바
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _toggleFavorite,
                  icon: Icon(
                    _isFavorite ? Icons.bookmark : Icons.bookmark_border,
                  ),
                  label: const Text('즐겨찾기'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openRatingDialog(movie),
                  icon: const Icon(Icons.rate_review_outlined),
                  label: const Text('평점 남기기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 평점 입력 및 다시 선택하기 커스텀 Dialog
class _RatingCustomDialog extends StatefulWidget {
  const _RatingCustomDialog({
    required this.movieId,
    required this.initialRating,
  });

  /// 평점을 남길 TMDB 영화 id
  final int movieId;
  final double initialRating;

  @override
  State<_RatingCustomDialog> createState() => _RatingCustomDialogState();
}

class _RatingCustomDialogState extends State<_RatingCustomDialog> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '영화는 어떠셨나요?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            RatingBar.builder(
              initialRating: _currentRating,
              minRating: 0.5,
              allowHalfRating: true,
              itemCount: 5,
              itemSize: 36,
              itemBuilder: (context, _) =>
                  const Icon(Icons.star, color: Colors.deepPurpleAccent),
              onRatingUpdate: (rating) {
                setState(() {
                  _currentRating = rating;
                });
              },
            ),
            const SizedBox(height: 12),
            // 다시 선택하기 (초기화) 버튼
            TextButton(
              onPressed: () {
                setState(() {
                  _currentRating = 0.0;
                });
              },
              child: const Text(
                '다시 선택하기',
                style: TextStyle(color: Colors.deepPurple),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop<MovieRatingInput>(
                  context,
                  (movieId: widget.movieId, score: _currentRating),
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
