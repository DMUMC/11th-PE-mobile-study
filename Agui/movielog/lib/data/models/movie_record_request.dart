import 'rating_request.dart';

class CreateMovieRecordRequest {
  const CreateMovieRecordRequest({
    required this.movieId,
    required this.score,
    required this.addToFavorites,
    this.comment,
  });

  final int movieId;
  final int score;
  final String? comment;
  final bool addToFavorites;

  Map<String, dynamic> toJson() => {
    'movieId': movieId,
    'score': validateServerScore(score.toDouble()),
    if (comment != null && comment!.trim().isNotEmpty)
      'comment': comment!.trim(),
    'addToFavorites': addToFavorites,
  };
}
