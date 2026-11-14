import 'dart:async';

import '../models/movie.dart';
import 'movie_service.dart';
export 'movie_service.dart' show MovieLoadException;

enum FakeMovieMode { success, empty, failure, timeout }

class FakeMovieService implements MovieService {
  const FakeMovieService({
    this.mode = FakeMovieMode.success,
    this.delay = const Duration(seconds: 1),
  });

  final FakeMovieMode mode;
  final Duration delay;

  @override
  Future<List<Movie>> fetchMovies({List<int>? genreIds}) async {
    await Future<void>.delayed(delay);

    return switch (mode) {
      FakeMovieMode.success => List<Movie>.unmodifiable(
        movies.where(
          (movie) =>
              genreIds == null ||
              genreIds.isEmpty ||
              movie.genres.any(
                genreIds.map((id) => movieGenreNames[id]).contains,
              ),
        ),
      ),
      FakeMovieMode.empty => const <Movie>[],
      FakeMovieMode.failure => throw const MovieLoadException(
        '영화 목록을 불러오지 못했습니다.',
      ),
      FakeMovieMode.timeout => await Completer<List<Movie>>().future,
    };
  }
}
