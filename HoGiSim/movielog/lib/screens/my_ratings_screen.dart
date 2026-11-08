import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/rating_with_movie.dart';
import '../widgets/movielog_button.dart';
import '../widgets/tmdb_poster_image.dart';
import '../view_models/my_ratings_view_model.dart';

class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<MyRatingsViewModel>();
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('내가 등록한 평점')),
      body: SafeArea(
        child: switch (model.status) {
          MyRatingsLoadStatus.idle || MyRatingsLoadStatus.loading =>
            const Center(child: CircularProgressIndicator()),
          MyRatingsLoadStatus.empty => const Center(
            child: Text('등록된 평점이 없습니다.'),
          ),
          MyRatingsLoadStatus.error => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(model.message!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  MovieLogButton(
                    label: '다시 시도',
                    width: 96,
                    onPressed: model.load,
                  ),
                ],
              ),
            ),
          ),
          MyRatingsLoadStatus.success => ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: model.ratings.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) => index == 0
                ? const Text('학습용 회원 $sampleMemberId의 평점')
                : _RatingCard(entry: model.ratings[index - 1]),
          ),
        },
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.entry});
  final RatingWithMovie entry;

  @override
  Widget build(BuildContext context) {
    final rating = entry.rating;
    final date = MaterialLocalizations.of(context)
        .formatCompactDate(rating.createdAt.toLocal());
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TmdbPosterImage(
                posterPath: entry.movie?.posterPath,
                width: 64,
                height: 96,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.movie?.title ?? '영화 #${rating.movieId}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text('★ ${rating.score} / 5'),
                  if (rating.comment case final comment?) Text(comment),
                  Text('등록일 $date'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
