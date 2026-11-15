import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:movielog/movie/widgets/movie_rating_dialog.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/theme/app_text_style.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key});
  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool _isFavorite = false;
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MovieDetailViewModel>();
    final movie = viewModel.movie;
    return Scaffold(
      appBar: AppBar(
        title: const Text('영화 상세'),
        actions: [
          IconButton(
            tooltip: '공유',
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: '/movies/${movie.id}'));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('영화 링크를 복사했습니다.')));
            },
          ),
        ],
        leading: IconButton(
          tooltip: '뒤로 가기',
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/movies'),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (movie.posterUrl != null)
                  Image.network(
                    movie.posterUrl!,
                    height: 480,
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, stack) => const SizedBox(
                      height: 240,
                      child: Icon(Icons.movie_outlined, size: 64),
                    ),
                  )
                else
                  const SizedBox(
                    height: 240,
                    child: Icon(Icons.movie_outlined, size: 64),
                  ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
                        style: AppTextStyles.headlineMediumBold,
                      ),
                      if (movie.releaseDate.isNotEmpty)
                        Text(
                          movie.releaseDate,
                          style: AppTextStyles.bodyMediumRegular,
                        ),
                      const SizedBox(height: 24),
                      const Text(
                        '시놉시스',
                        style: AppTextStyles.headlineMediumBold,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        movie.overview.isEmpty
                            ? '영화 소개가 준비 중입니다.'
                            : movie.overview,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (viewModel.memberId == null)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('평점 등록을 위해 먼저 회원가입을 완료해 주세요.'),
                ),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() => _isFavorite = !_isFavorite);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _isFavorite
                                    ? '즐겨찾기에 추가했습니다.'
                                    : '즐겨찾기에서 삭제했습니다.',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.bookmark_outline),
                        label: Text(_isFavorite ? '즐겨찾기 완료' : '즐겨찾기'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: viewModel.memberId == null
                            ? null
                            : () => _showRatingDialog(context, viewModel),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary500,
                          shape: const StadiumBorder(),
                        ),
                        icon: const Icon(Icons.rate_review_outlined),
                        label: const Text('평점 남기기'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRatingDialog(
    BuildContext context,
    MovieDetailViewModel viewModel,
  ) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => MovieRatingDialog(
        onSubmit: (score, comment) async {
          try {
            await viewModel.createRating(score: score, comment: comment);
          } on RatingSubmissionException catch (error) {
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(error.message)));
            }
            rethrow;
          }
        },
      ),
    );
    if (!context.mounted || saved != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('평점을 등록했습니다. 마이페이지의 "내가 등록한 평점"에서 확인할 수 있습니다.'),
      ),
    );
  }
}
