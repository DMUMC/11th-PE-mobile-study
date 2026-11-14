import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../models/movie.dart';
import '../services/member_api.dart';
import 'rating_editor.dart';
import '../widgets/movie_poster.dart';

class MovieDetailScreen extends StatelessWidget {
  const MovieDetailScreen({
    super.key,
    required this.movie,
    required this.store,
    this.memberApi,
    this.memberId,
  });
  final Movie movie;
  final MovieLogStore store;
  final MemberApi? memberApi;
  final int? memberId;

  Future<void> _rateServer(
    BuildContext context,
    int movieId,
    MemberApi api,
  ) async {
    final member = memberId;
    if (member == null) {
      context.push('/signup');
      return;
    }
    final score = await showRatingEditor(
      context,
      movieTitle: movie.title,
      movieId: movieId,
      save: (score) => api.createRating(member, movieId, score),
    );
    if (score == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
    try {
      final ratings = await api.fetchRatings(member);
      final saved = ratings
          .where((rating) => rating.movieId == movieId)
          .firstOrNull;
      if (saved == null) throw const MemberApiException('등록된 평점을 찾을 수 없습니다.');
      if (context.mounted) {
        messenger.showSnackBar(const SnackBar(content: Text('평점 저장 및 재조회 완료')));
      }
    } on MemberApiException catch (error) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('저장 성공 · 재조회 실패. 내 평점 목록을 확인해주세요. ${error.message}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final favorite = store.favorites.contains(movie.id);
      final tmdbId = int.tryParse(movie.id);
      final api = memberApi;
      final rating = tmdbId != null && api != null
          ? null
          : store.ratings[movie.id];
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Cinema Archive'),
          leading: IconButton(
            tooltip: '뒤로',
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/movies');
              }
            },
          ),
          actions: [
            IconButton(
              tooltip: '영화 정보 복사',
              icon: const Icon(Icons.share_outlined, color: Color(0xFF49454F)),
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(
                    text:
                        '${movie.title} · ${movie.metadata}\n${GoRouterState.of(context).uri}',
                  ),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('영화 정보를 복사했습니다.')),
                  );
                }
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: ListView(
          key: PageStorageKey('detail-${movie.id}'),
          children: [
            AspectRatio(
              aspectRatio: 2 / 3,
              child: MoviePoster(source: movie.image),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    movie.metadata,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF55515B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      for (var i = 1; i <= 5; i++)
                        Icon(
                          movie.rating >= i
                              ? Icons.star
                              : movie.rating > i - 1
                              ? Icons.star_half
                              : Icons.star_border,
                          size: 21,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      const SizedBox(width: 12),
                      Text(
                        movie.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (movie.id == 'starlight')
                        const Text(
                          ' (1,245)',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF55515B),
                          ),
                        ),
                    ],
                  ),
                  if (rating != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        '내 평점: $rating / 5',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children:
                        [...movie.genres, if (movie.id == 'starlight') '감동적인']
                            .map(
                              (genre) => Chip(
                                label: Text(
                                  genre,
                                  style: const TextStyle(
                                    color: Color(0xFF55515B),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '시놉시스',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    movie.synopsis,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.75,
                      color: Color(0xFF55515B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => store.toggleFavorite(movie.id),
                        icon: Icon(
                          favorite ? Icons.bookmark : Icons.bookmark_border,
                        ),
                        label: Text(favorite ? '즐겨찾기 완료' : '즐겨찾기'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (tmdbId != null && api != null) {
                            await _rateServer(context, tmdbId, api);
                            return;
                          }
                          final result = await showDialog<int>(
                            context: context,
                            builder: (_) =>
                                RatingDialog(initialRating: rating ?? 0),
                          );
                          if (result != null) store.rate(movie.id, result);
                        },
                        icon: const Icon(Icons.rate_review_outlined),
                        label: Text(
                          tmdbId != null && api != null || rating == null
                              ? '평점 남기기'
                              : '평점 수정',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class RatingDialog extends StatefulWidget {
  const RatingDialog({super.key, required this.initialRating});
  final int initialRating;
  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  late int draft = widget.initialRating;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('평점 남기기'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('이 영화는 어떠셨나요?'),
        const SizedBox(height: 16),
        FittedBox(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              5,
              (index) => IconButton(
                tooltip: '${index + 1}점',
                onPressed: () => setState(() => draft = index + 1),
                icon: Icon(
                  index < draft ? Icons.star : Icons.star_border,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          draft == 0 ? '별점을 선택해주세요' : '$draft / 5',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextButton.icon(
          onPressed: () => setState(() => draft = 0),
          icon: const Icon(Icons.refresh),
          label: const Text('평점 초기화'),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('취소'),
      ),
      ElevatedButton(
        onPressed: () => Navigator.pop(context, draft),
        child: const Text('저장'),
      ),
    ],
  );
}
