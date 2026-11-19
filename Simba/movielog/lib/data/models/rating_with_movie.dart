import 'rating_dto.dart';
import 'tmdb_movie_dto.dart';

/// 평점 한 건 + 그 평점의 movieId로 조회한 TMDB 영화 정보.
class RatingWithMovie {
  const RatingWithMovie({
    required this.rating,
    this.movie,
  });

  final RatingDto rating;

  /// TMDB에서 찾지 못했거나 조회에 실패했으면 null. (평점 자체는 그대로 보여준다)
  final TmdbMovieDto? movie;
}
