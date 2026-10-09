import 'package:movielog/movie/data/mock_movies.dart';
import 'package:movielog/movie/model/movie.dart';

enum MovieLoadMode { success, empty, failure, slow }

class MovieLoadException implements Exception {
  const MovieLoadException(this.message);

  final String message;
}

class FakeMovieService {
  const FakeMovieService();

  Future<List<Movie>> fetchMovies({
    MovieLoadMode mode = MovieLoadMode.success,
  }) async {
    await Future<void>.delayed(
      mode == MovieLoadMode.slow
          ? const Duration(seconds: 4)
          : const Duration(seconds: 1),
    );

    return switch (mode) {
      MovieLoadMode.success => movies,
      MovieLoadMode.empty => const <Movie>[],
      MovieLoadMode.failure => throw const MovieLoadException(
        '영화를 불러오지 못했습니다.',
      ),
      MovieLoadMode.slow => movies,
    };
  }
}
