import 'package:flutter_test/flutter_test.dart';
import 'package:vector_week01/models/movie.dart';
import 'package:vector_week01/services/fake_movie_service.dart';

void main() {
  group('FakeMovieService', () {
    test('성공 모드는 영화 목록을 반환한다', () async {
      const service = FakeMovieService(delay: Duration.zero);

      expect(await service.fetchMovies(), movies);
    });

    test('빈 목록 모드는 빈 목록을 반환한다', () async {
      const service = FakeMovieService(
        mode: FakeMovieMode.empty,
        delay: Duration.zero,
      );

      expect(await service.fetchMovies(), isEmpty);
    });

    test('실패 모드는 오류를 반환한다', () async {
      const service = FakeMovieService(
        mode: FakeMovieMode.failure,
        delay: Duration.zero,
      );

      expect(service.fetchMovies(), throwsA(isA<MovieLoadException>()));
    });
  });
}
