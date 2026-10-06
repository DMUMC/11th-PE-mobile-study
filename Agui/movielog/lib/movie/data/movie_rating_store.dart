/// Backend 연결 전까지 영화별 사용자 평점을 앱 메모리에 보관합니다.
abstract final class MovieRatingStore {
  static final Map<int, double> _ratings = {};

  static double? ratingFor(int movieId) => _ratings[movieId];

  static void save(int movieId, double rating) {
    _ratings[movieId] = rating;
  }

  static void clear(int movieId) {
    _ratings.remove(movieId);
  }
}
