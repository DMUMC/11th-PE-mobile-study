import 'package:movielog/movie/data/mock_movies.dart';
import 'package:movielog/movie/model/movie.dart';

enum MovieLoadMode { success, failure }

class MovieLoadException implements Exception {
  const MovieLoadException(this.message);

  final String message;
}

class FakeMovieService {
  const FakeMovieService();

  Future<List<Movie>> fetchMovies({
    MovieLoadMode mode = MovieLoadMode.success,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 1));

    if (mode == MovieLoadMode.failure) {
      throw const MovieLoadException('영화를 불러오지 못했습니다.');
    }

    return movies;
  }
}
