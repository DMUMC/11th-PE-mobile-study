import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/movie/data/fake_movie_service.dart';
import 'package:movielog/movie/data/mock_movies.dart';

void main() {
  const service = FakeMovieService();

  test('성공 모드는 영화 목록을 반환한다', () async {
    final result = await service.fetchMovies(mode: MovieLoadMode.success);

    expect(result, orderedEquals(movies));
  });

  test('빈 목록 모드는 빈 리스트를 반환한다', () async {
    final result = await service.fetchMovies(mode: MovieLoadMode.empty);

    expect(result, isEmpty);
  });

  test('실패 모드는 MovieLoadException을 던진다', () async {
    await expectLater(
      service.fetchMovies(mode: MovieLoadMode.failure),
      throwsA(
        isA<MovieLoadException>().having(
          (error) => error.message,
          'message',
          '영화를 불러오지 못했습니다.',
        ),
      ),
    );
  });
}
