import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vector_week01/controllers/movies_controller.dart';
import 'package:vector_week01/models/movie.dart';
import 'package:vector_week01/services/movie_service.dart';

class ControlledService implements MovieService {
  final calls = <List<int>?>[];
  final pending = <Completer<List<Movie>>>[];
  @override
  Future<List<Movie>> fetchMovies({List<int>? genreIds}) {
    calls.add(genreIds);
    final completer = Completer<List<Movie>>();
    pending.add(completer);
    return completer.future;
  }
}

void main() {
  test('새로고침/실패 중 기존 목록 유지, 중복 차단, 같은 조건으로 재시도', () async {
    final service = ControlledService();
    final controller = MoviesController(service: service);
    addTearDown(controller.dispose);
    var request = controller.load(genreIds: [18, 878]);
    service.pending.last.complete([movies.first]);
    await request;
    request = controller.refresh();
    await controller.refresh();
    expect(service.calls.length, 2);
    expect(controller.loading, isTrue);
    expect(controller.movies, [movies.first]);
    service.pending.last.completeError(const MovieLoadException('offline'));
    await request;
    expect(controller.movies, [movies.first]);
    expect(controller.error, isA<MovieLoadException>());
    request = controller.refresh();
    expect(service.calls.last, [18, 878]);
    service.pending.last.complete([movies.last]);
    await request;
    expect(controller.movies, [movies.last]);
    expect(controller.error, isNull);
  });

  test('장르 변경 후 늦은 이전 응답이 최신 결과를 덮어쓰지 않는다', () async {
    final service = ControlledService();
    final controller = MoviesController(service: service);
    addTearDown(controller.dispose);
    final old = controller.load(genreIds: [18]);
    final latest = controller.load(genreIds: [878]);
    service.pending[1].complete([movies[1]]);
    await latest;
    service.pending[0].complete([movies[0]]);
    await old;
    expect(controller.movies, [movies[1]]);
    expect(controller.genreIds, [878]);
  });

  test('전체 장르, 빈 결과, 타임아웃과 dispose 후 응답', () async {
    final service = ControlledService();
    final controller = MoviesController(
      service: service,
      timeout: Duration.zero,
    );
    await controller.load(genreIds: []);
    expect(controller.error, isA<TimeoutException>());
    expect(service.calls.single, isNull);
    controller.dispose();
    service.pending.single.complete([]);
    final next = MoviesController(service: service);
    var request = next.load();
    service.pending.last.complete([]);
    await request;
    expect(next.hasSucceeded, isTrue);
    expect(next.movies, isEmpty);
    request = next.refresh();
    next.dispose();
    service.pending.last.complete(movies);
    await request;
  });
}
