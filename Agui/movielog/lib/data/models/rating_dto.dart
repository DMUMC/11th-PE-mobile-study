class RatingDto {
  const RatingDto({
    required this.ratingId,
    required this.movieId,
    required this.score,
    required this.comment,
    required this.createdAt,
  });

  final int ratingId;
  final int movieId;
  final int score;
  final String? comment;
  final DateTime createdAt;

  factory RatingDto.fromJson(Map<String, dynamic> json) {
    final ratingId = json['ratingId'];
    final movieId = json['movieId'];
    final score = json['score'];
    final comment = json['comment'];
    final createdAt = json['createdAt'];
    if (ratingId is! num ||
        movieId is! num ||
        score is! num ||
        (comment != null && comment is! String) ||
        createdAt is! String) {
      throw const FormatException('Invalid rating response');
    }
    return RatingDto(
      ratingId: ratingId.toInt(),
      movieId: movieId.toInt(),
      score: score.toInt(),
      comment: comment as String?,
      createdAt: DateTime.parse(createdAt),
    );
  }
}
