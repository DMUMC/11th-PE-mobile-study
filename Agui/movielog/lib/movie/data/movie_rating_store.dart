/// Backend 연결 전까지 영화별 사용자 평점을 앱 메모리에 보관합니다.
abstract final class MovieRatingStore {
  static final Map<int, double> _ratings = {};

  static final Map<int, String> _comments = {};

  static String? commentFor(int movieId) => _comments[movieId];

  static double? ratingFor(int movieId) => _ratings[movieId];

  static void save(int movieId, double rating, {String? comment}) {
    _ratings[movieId] = rating;
    if (comment == null) {
      _comments.remove(movieId);
    } else {
      _comments[movieId] = comment;
    }
  }

  static void clear(int movieId) {
    _ratings.remove(movieId);
    _comments.remove(movieId);
  }
}
