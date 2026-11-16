import 'dart:async';

import '../models/movie.dart';

enum FakeMovieMode { success, empty, failure, timeout }

class FakeMovieService {
  const FakeMovieService({
    this.mode = FakeMovieMode.success,
    this.delay = const Duration(seconds: 1),
  });

  final FakeMovieMode mode;
  final Duration delay;

  Future<List<Movie>> fetchMovies() async {
    await Future<void>.delayed(delay);

    return switch (mode) {
      FakeMovieMode.success => List<Movie>.unmodifiable(movies),
      FakeMovieMode.empty => const <Movie>[],
      FakeMovieMode.failure => throw const MovieLoadException(
        '영화 목록을 불러오지 못했습니다.',
      ),
      FakeMovieMode.timeout => await Completer<List<Movie>>().future,
    };
  }
}

class MovieLoadException implements Exception {
  const MovieLoadException(this.message);

  final String message;

  @override
  String toString() => message;
}
