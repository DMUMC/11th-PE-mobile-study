import '../models/movie.dart';

abstract interface class MovieService {
  /// 선택된 장르의 OR 조건으로 page 1부터 최대 30개를 불러옵니다.
  Future<List<Movie>> fetchMovies({List<int>? genreIds});
}

class MovieLoadException implements Exception {
  const MovieLoadException(this.message);
  final String message;
  @override
  String toString() => message;
}
