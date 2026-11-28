import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/load_phase.dart';
import 'package:movielog/view_models/paged_movies_view_model.dart';

TmdbMoviePageDto _page(int page, List<int> ids) => TmdbMoviePageDto(
  page: page,
  results: [
    for (final id in ids) TmdbMovieDto(id: id, title: '$id', posterPath: null),
  ],
  totalPages: ids.isEmpty ? 0 : 3,
  totalResults: ids.length,
);

class _Movies extends TmdbMovieService {
  _Movies() : super(Dio());
  final searches = <({int page, String query})>[];
  int discoverCalls = 0;
  Future<TmdbMoviePageDto> Function(int page, String query)? respond;

  @override
  Future<TmdbMoviePageDto> searchMovies({
    required int page,
    required String query,
  }) async {
    searches.add((page: page, query: query));
    return respond == null ? _page(page, [page]) : await respond!(page, query);
  }

  @override
  Future<TmdbMoviePageDto> discoverMovies({
    required int page,
    List<int>? genreIds,
  }) async {
    discoverCalls++;
    return _page(page, [100 + page]);
  }
}

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode({
        'page': 2,
        'results': [
          {'id': 42, 'title': '검색 결과', 'poster_path': null},
        ],
        'total_pages': 3,
        'total_results': 41,
      }),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _Movies api;
  late PagedMoviesViewModel vm;
  setUp(() {
    api = _Movies();
    vm = PagedMoviesViewModel(tmdbApi: api, searchOnly: true);
  });
  tearDown(() {
    if (!vm.isDisposed) vm.dispose();
    api.close();
  });

  test(
    'search starts idle and blank submissions never call either endpoint',
    () async {
      expect(vm.phase, LoadPhase.idle);
      expect(api.searches, isEmpty);
      await vm.loadInitial(query: '  \n ');
      await vm.loadNextPage();
      expect(vm.phase, LoadPhase.idle);
      expect(api.searches, isEmpty);
      expect(api.discoverCalls, 0);
    },
  );

  test('submitted query is trimmed and pagination keeps that query', () async {
    api.respond = (page, _) async => _page(page, page == 1 ? [1, 2] : [2, 3]);
    await vm.loadInitial(query: '  어벤져스  ');
    await vm.loadNextPage();
    expect(api.searches, [(page: 1, query: '어벤져스'), (page: 2, query: '어벤져스')]);
    expect(vm.movies.map((movie) => movie.id), [1, 2, 3]);
    expect(vm.nextPage, 3);
    expect(api.discoverCalls, 0);
  });

  test(
    'new query clears results and pagination before its response arrives',
    () async {
      await vm.loadInitial(query: 'old');
      await vm.loadNextPage();
      final gate = Completer<TmdbMoviePageDto>();
      api.respond = (_, _) => gate.future;
      final loading = vm.loadInitial(query: 'new');
      expect(vm.phase, LoadPhase.loading);
      expect(vm.movies, isEmpty);
      expect(vm.nextPage, 1);
      expect(vm.isLoadingMore, isFalse);
      expect(api.searches.last, (page: 1, query: 'new'));
      gate.complete(_page(1, [9]));
      await loading;
      expect(vm.movies.single.id, 9);
    },
  );

  for (final fails in [false, true]) {
    test(
      'late first-page ${fails ? 'failure' : 'success'} cannot replace new query',
      () async {
        final old = Completer<TmdbMoviePageDto>();
        api.respond = (_, query) =>
            query == 'old' ? old.future : Future.value(_page(1, [9]));
        final pending = vm.loadInitial(query: 'old');
        await vm.loadInitial(query: 'new');
        if (fails) {
          old.completeError(StateError('old failed'));
        } else {
          old.complete(_page(1, [1]));
        }
        await pending;
        expect(vm.phase, LoadPhase.ready);
        expect(vm.query, 'new');
        expect(vm.movies.single.id, 9);
        expect(vm.errorMessage, isNull);
      },
    );

    test(
      'late append ${fails ? 'failure' : 'success'} cannot affect new append state',
      () async {
        await vm.loadInitial(query: 'old');
        final old = Completer<TmdbMoviePageDto>();
        final current = Completer<TmdbMoviePageDto>();
        api.respond = (page, query) => query == 'old'
            ? old.future
            : page == 1
            ? Future.value(_page(1, [9]))
            : current.future;
        final pending = vm.loadNextPage();
        await vm.loadInitial(query: 'new');
        final currentPending = vm.loadNextPage();
        if (fails) {
          old.completeError(StateError('old failed'));
        } else {
          old.complete(_page(2, [2]));
        }
        await pending;
        expect(vm.movies.single.id, 9);
        expect(vm.isLoadingMore, isTrue);
        expect(vm.loadMoreError, isNull);
        current.complete(_page(2, [10]));
        await currentPending;
        expect(vm.movies.map((movie) => movie.id), [9, 10]);
      },
    );
  }

  test(
    'blank submission clears results and invalidates a pending response',
    () async {
      final gate = Completer<TmdbMoviePageDto>();
      api.respond = (_, _) => gate.future;
      final pending = vm.loadInitial(query: 'old');
      await vm.loadInitial(query: ' ');
      gate.complete(_page(1, [1]));
      await pending;
      expect(vm.phase, LoadPhase.idle);
      expect(vm.movies, isEmpty);
      expect(api.searches.length, 1);
      expect(api.discoverCalls, 0);
    },
  );

  test('empty results differ from idle and disable pagination', () async {
    api.respond = (page, _) async => _page(page, []);
    await vm.loadInitial(query: 'missing');
    expect(vm.phase, LoadPhase.empty);
    expect(vm.hasMore, isFalse);
  });

  test('first-page failure supports retry with the submitted query', () async {
    api.respond = (_, _) async => throw StateError('offline');
    await vm.loadInitial(query: 'search');
    expect(vm.phase, LoadPhase.error);
    expect(vm.errorMessage, '검색 결과를 불러오지 못했습니다.');
    api.respond = null;
    await vm.loadInitial(query: vm.query);
    expect(api.searches, [
      (page: 1, query: 'search'),
      (page: 1, query: 'search'),
    ]);
    expect(vm.phase, LoadPhase.ready);
    expect(vm.errorMessage, isNull);
  });

  test(
    'append failure retains cards and retries same page and query',
    () async {
      await vm.loadInitial(query: 'search');
      api.respond = (_, _) async => throw StateError('offline');
      await vm.loadNextPage();
      expect(vm.movies.single.id, 1);
      expect(vm.nextPage, 2);
      expect(vm.loadMoreError, isNotNull);
      api.respond = null;
      await vm.loadNextPage();
      expect(api.searches.skip(1), [
        (page: 2, query: 'search'),
        (page: 2, query: 'search'),
      ]);
      expect(vm.loadMoreError, isNull);
    },
  );

  test(
    'search instance leaves discover results and filters untouched',
    () async {
      final list = PagedMoviesViewModel(tmdbApi: api);
      addTearDown(list.dispose);
      await list.loadInitial(genreIds: [28]);
      await vm.loadInitial(query: 'search');
      await vm.loadNextPage();
      expect(list.movies.single.id, 101);
      expect(list.selectedGenreIds, [28]);
      expect(list.nextPage, 2);
      expect(list.query, isEmpty);
      expect(api.discoverCalls, 1);
    },
  );

  test(
    'disposed search ignores pending response and further requests',
    () async {
      final gate = Completer<TmdbMoviePageDto>();
      api.respond = (_, _) => gate.future;
      final pending = vm.loadInitial(query: 'search');
      vm.dispose();
      gate.complete(_page(1, [1]));
      await pending;
      await vm.loadInitial(query: 'new');
      expect(vm.movies, isEmpty);
      expect(api.searches.length, 1);
    },
  );

  test('Search Movie request encodes query and parses page metadata', () async {
    final adapter = _Adapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.themoviedb.org/3'))
      ..httpClientAdapter = adapter;
    final service = TmdbMovieService(dio);
    addTearDown(service.close);
    final page = await service.searchMovies(page: 2, query: '  영화 & A/B?  ');
    final request = adapter.requests.single;
    expect(request.method, 'GET');
    expect(request.uri.path, '/3/search/movie');
    expect(request.uri.queryParameters, {
      'query': '영화 & A/B?',
      'page': '2',
      'language': 'ko-KR',
      'include_adult': 'false',
    });
    expect(page.page, 2);
    expect(page.totalPages, 3);
    expect(page.results.single.id, 42);
    await expectLater(
      service.searchMovies(page: 1, query: '  '),
      throwsArgumentError,
    );
    expect(adapter.requests.length, 1);
  });
}
