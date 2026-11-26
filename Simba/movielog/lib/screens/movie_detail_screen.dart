import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';

import '../utils/movie_format.dart';
import '../view_models/movie_detail_view_model.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/tmdb_poster_image.dart';

/// 영화 상세. 영화 DTO와 평점 등록 상태는 [MovieDetailViewModel]이 가진다.
/// (MovieDetailLoader가 extra 또는 TMDB 재조회로 DTO를 준비한다)
class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool _isFavorite = false;

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

  Future<void> _openRatingDialog() async {
    final viewModel = context.read<MovieDetailViewModel>();
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 저장 중 바깥 탭으로 닫히는 것도 막는다.
      builder: (_) => RatingDialog(
        onSubmit: (score, comment) async {
          await viewModel.createRating(score: score, comment: comment);
          if (viewModel.submitStatus != SubmitStatus.success) {
            // Dialog가 닫히지 않고 서버 message(400/404/409)를 보여준다.
            throw SubmitFailure(viewModel.submitMessage ?? '저장에 실패했습니다.');
          }
        },
      ),
    );

    // 저장과 Snackbar는 다른 비동기 경계라 await 뒤에 mounted를 다시 확인한다.
    if (!mounted || saved != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('평점을 등록했습니다. 마이페이지의 "내가 등록한 평점"에서 확인할 수 있습니다.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MovieDetailViewModel>();
    final movie = viewModel.movie;

    final year = releaseYearOf(movie.releaseDate);
    final score = movie.voteAverage / 2;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.share), onPressed: () {})],
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
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
                      onPressed: _openRatingDialog,
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
            ],
          ),
        ),
      ),
    );
  }
}
