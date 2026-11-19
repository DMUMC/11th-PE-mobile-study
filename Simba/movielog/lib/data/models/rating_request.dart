/// RatingBar가 돌려준 double을 서버 평점(1~5 정수)으로 바꾼다.
/// 반 점이나 범위 밖 값을 조용히 toInt()하지 않고 오류로 막는다.
int validateServerScore(double value) {
  if (value < 1 || value > 5 || value != value.roundToDouble()) {
    throw ArgumentError('서버 평점은 1~5 사이 정수여야 합니다.');
  }
  return value.toInt();
}

/// POST /v6/members/{memberId}/ratings 요청 body
class CreateRatingRequest {
  const CreateRatingRequest({
    required this.movieId,
    required this.score,
    this.comment,
  });

  /// TMDB 영화 id (`TmdbMovieDto.id`). 목록 index가 아니다.
  final int movieId;
  final int score;
  final String? comment;

  Map<String, dynamic> toJson() => {
    'movieId': movieId,
    'score': score,
    // 선택 항목이라 비어 있으면 빈 문자열 대신 생략한다.
    if (comment != null && comment!.trim().isNotEmpty)
      'comment': comment!.trim(),
  };
}

/// PATCH /v6/members/{memberId}/ratings/{ratingId} 요청 body
/// comment를 생략하면 서버가 기존 후기를 null로 덮으므로 항상 명시적으로 보낸다.
class UpdateRatingRequest {
  const UpdateRatingRequest({required this.score, required this.comment});

  final int score;

  /// null이면 후기를 지운다는 의도
  final String? comment;

  Map<String, dynamic> toJson() => {
    'score': score,
    'comment': (comment == null || comment!.trim().isEmpty)
        ? null
        : comment!.trim(),
  };
}
