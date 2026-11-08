import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';
import 'package:movielog/view_models/movie_home_view_model.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';
import 'package:movielog/view_models/movie_load_status.dart';

import 'support/tmdb_fixture.dart';

void main() {
  test('DTO는 snake_case, null, num을 변환한다', () {
    final dto = TmdbMovieDto.fromJson(movieJson(550)..['genre_ids'] = null);
    expect(dto.id, 550);
    expect(dto.title, '영화 550');
    expect(dto.posterPath, isNull);
    expect(dto.overview, '');
    expect(dto.releaseDate, isNull);
    expect(dto.genreIds, isEmpty);
    expect(dto.voteAverage, 8.0);
    expect(dto.popularity, 12.0);
    expect(TmdbMoviePageDto.fromJson(pageJson([])).results, isEmpty);
  });

  test('Popular는 화면 정책 없이 원본 DTO를 반환하고 ViewModel은 최대 5개', () async {
    final f = fixture();
    expect((await f.service.fetchPopular()).results, hasLength(8));
    final vm = MovieHomeViewModel(f.service);
    addTearDown(vm.dispose);
    final load = vm.loadPopular();
    expect(vm.status, MovieLoadStatus.loading);
    await load;
    expect(vm.popularMovies.map((movie) => movie.id), [
      550,
      551,
      552,
      553,
      554,
    ]);
    expect(vm.status, MovieLoadStatus.success);
  });

  test('Popular 2개/빈 응답도 안전하게 처리한다', () async {
    for (final count in [2, 0]) {
      final f = fixture(
        adapter: FixtureAdapter(
          respond: (_) async =>
              FixtureAdapter.json(pageJson(List.generate(count, movieJson))),
        ),
      );
      final vm = MovieHomeViewModel(f.service);
      await vm.loadPopular();
      expect(vm.popularMovies, hasLength(count));
      expect(
        vm.status,
        count == 0 ? MovieLoadStatus.empty : MovieLoadStatus.success,
      );
      vm.dispose();
    }
  });

  test('Discover는 중복을 제거해 최대 30개를 만들며 page 1부터 요청한다', () async {
    final f = fixture(
      adapter: FixtureAdapter(
        respond: (options) async {
          if (options.path.contains('genre')) {
            return FixtureAdapter.json({'genres': []});
          }
          final page = options.queryParameters['page'] as int;
          return FixtureAdapter.json(
            pageJson(
              List.generate(20, (i) => movieJson((page - 1) * 15 + i + 1)),
              page: page,
              totalPages: 5,
            ),
          );
        },
      ),
    );
    final vm = MovieListViewModel(
      f.service,
      preferenceStore: MemoryGenreStore(),
    );
    addTearDown(vm.dispose);
    await vm.loadInitial();
    expect(vm.movies, hasLength(30));
    expect(vm.movies.map((movie) => movie.id).toSet(), hasLength(30));
    expect(
      f.adapter.requests
          .where((r) => r.path == '/discover/movie')
          .map((r) => r.queryParameters['page']),
      [1, 2],
    );
  });

  test('30개 미만 또는 빈 페이지면 요청을 종료한다', () async {
    for (final empty in [false, true]) {
      final f = fixture(
        adapter: FixtureAdapter(
          respond: (options) async {
            if (options.path.contains('genre')) {
              return FixtureAdapter.json({'genres': []});
            }
            return FixtureAdapter.json(
              pageJson(empty ? [] : [movieJson(1)], totalPages: empty ? 99 : 1),
            );
          },
        ),
      );
      final vm = MovieListViewModel(
        f.service,
        preferenceStore: MemoryGenreStore(),
      );
      await vm.loadInitial();
      expect(vm.movies.length, empty ? 0 : 1);
      expect(
        vm.status,
        empty ? MovieLoadStatus.empty : MovieLoadStatus.success,
      );
      expect(
        f.adapter.requests.where((r) => r.path == '/discover/movie'),
        hasLength(1),
      );
      vm.dispose();
    }
  });

  test('장르 ID를 OR로 전송하고 전체 선택은 with_genres를 생략한다', () async {
    final f = fixture();
    final store = MemoryGenreStore();
    final vm = MovieListViewModel(f.service, preferenceStore: store);
    addTearDown(vm.dispose);
    await vm.loadInitial();
    await vm.selectGenres([878, 28]);
    final filtered = f.adapter.requests
        .where((r) => r.path == '/discover/movie')
        .last;
    expect(filtered.queryParameters['with_genres'], '28|878');
    expect(store.genres, ['28', '878']);
    await vm.selectGenres(null);
    final all = f.adapter.requests
        .where((r) => r.path == '/discover/movie')
        .last;
    expect(all.queryParameters.containsKey('with_genres'), isFalse);
  });

  test('새로고침은 현재 장르와 기존 목록을 유지하고 1페이지부터 재요청한다', () async {
    final f = fixture();
    final vm = MovieListViewModel(
      f.service,
      preferenceStore: MemoryGenreStore(),
    );
    addTearDown(vm.dispose);
    await vm.loadInitial();
    await vm.selectGenres([878]);
    final gate = Completer<ResponseBody>();
    final started = Completer<void>();
    f.adapter.respond = (options) {
      if (!started.isCompleted) started.complete();
      return gate.future;
    };
    final prior = vm.movies;
    final refreshing = vm.refresh();
    await started.future;
    expect(vm.isRefreshing, isTrue);
    expect(vm.movies, same(prior));
    final requestCount = f.adapter.requests.length;
    await vm.selectGenres([28]);
    await vm.refresh();
    expect(vm.selectedGenreIds, [878]);
    expect(f.adapter.requests.length, requestCount);
    expect(f.adapter.requests.last.queryParameters['page'], 1);
    expect(f.adapter.requests.last.queryParameters['with_genres'], '878');
    gate.complete(FixtureAdapter.json(pageJson([movieJson(999)])));
    await refreshing;
    expect(vm.movies.single.id, 999);
    expect(vm.isBusy, isFalse);
  });

  test('실패 후 기존 목록 유지 및 재시도는 같은 장르 1페이지부터', () async {
    final f = fixture();
    final vm = MovieListViewModel(
      f.service,
      preferenceStore: MemoryGenreStore(),
    );
    addTearDown(vm.dispose);
    await vm.loadInitial();
    await vm.selectGenres([878]);
    final prior = vm.movies;
    f.adapter.respond = (options) async =>
        FixtureAdapter.json({'status_message': 'unavailable'}, 503);
    await vm.refresh();
    expect(vm.movies, same(prior));
    expect(vm.failureVersion, 1);
    expect(vm.showingPreviousResults, isTrue);
    f.adapter.respond = null;
    final count = f.adapter.requests.length;
    await vm.retry();
    expect(f.adapter.requests[count].queryParameters['page'], 1);
    expect(f.adapter.requests[count].queryParameters['with_genres'], '878');
    expect(vm.showingPreviousResults, isFalse);
  });

  test('최초 요청 실패는 Error이며 재시도로 회복한다', () async {
    final f = fixture(
      adapter: FixtureAdapter(
        respond: (_) async => FixtureAdapter.json({}, 401),
      ),
    );
    final vm = MovieListViewModel(
      f.service,
      preferenceStore: MemoryGenreStore(),
    );
    addTearDown(vm.dispose);
    await vm.loadInitial();
    expect(vm.status, MovieLoadStatus.error);
    expect(vm.message, contains('인증'));
    f.adapter.respond = null;
    await vm.retry();
    expect(vm.status, MovieLoadStatus.success);
  });

  test('저장한 ID 복원, 이전 주차 장르 이름과 알 수 없는 ID 무시', () async {
    final f = fixture();
    final store = MemoryGenreStore()..genres = ['SF', '878', '999999'];
    final vm = MovieListViewModel(f.service, preferenceStore: store);
    addTearDown(vm.dispose);
    await vm.loadInitial();
    expect(vm.selectedGenreIds, [878]);
    expect(f.adapter.requests.last.queryParameters['with_genres'], '878');
  });

  test('dispose 후 늦은 응답은 상태 갱신/후속 페이지 요청을 하지 않는다', () async {
    final gate = Completer<ResponseBody>();
    final started = Completer<void>();
    final f = fixture(
      adapter: FixtureAdapter(
        respond: (options) async {
          if (options.path.contains('genre')) {
            return FixtureAdapter.json({'genres': []});
          }
          started.complete();
          return gate.future;
        },
      ),
    );
    final vm = MovieListViewModel(
      f.service,
      preferenceStore: MemoryGenreStore(),
    );
    final load = vm.loadInitial();
    await started.future;
    vm.dispose();
    gate.complete(
      FixtureAdapter.json(pageJson([movieJson(1)], totalPages: 10)),
    );
    await load;
    expect(
      f.adapter.requests.where((r) => r.path == '/discover/movie'),
      hasLength(1),
    );
  });
}
