/// v5 유저별 평점 조회 응답의 평점 한 건.
/// `movieId`는 TMDB 영화 id라서 TMDB API로 영화 정보를 다시 조회할 수 있다.
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

  /// Swagger에서 `nullable: true` → 값이 없을 수 있다.
  final String? comment;
  final DateTime createdAt;

  factory RatingDto.fromJson(Map<String, dynamic> json) => RatingDto(
    ratingId: (json['ratingId'] as num).toInt(),
    movieId: (json['movieId'] as num).toInt(),
    score: (json['score'] as num).toInt(),
    comment: json['comment'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
