import '../data/mock_movies.dart';
import '../models/movie.dart';

enum MovieFetchMode { success, empty, failure }

class FakeMovieService {
  const FakeMovieService({
    this.mode = MovieFetchMode.success,
    this.delay = const Duration(milliseconds: 900),
  });

  final MovieFetchMode mode;
  final Duration delay;

  Future<List<Movie>> fetchMovies({Set<String> genres = const {}}) async {
    await Future<void>.delayed(delay);
    switch (mode) {
      case MovieFetchMode.success:
        // TODO(5주차 유저별 평점 조회 API): 실제 사용자별 목록 조회로 교체합니다.
        return mockMovies
            .where((movie) => genres.isEmpty || movie.genres.any(genres.contains))
            .toList();
      case MovieFetchMode.empty:
        return const [];
      case MovieFetchMode.failure:
        throw Exception('Fake service failure');
    }
  }
}
