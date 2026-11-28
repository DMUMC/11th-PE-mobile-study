import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/load_phase.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';
import 'package:movielog/view_models/paged_movies_view_model.dart';

TmdbMoviePageDto _page(int page, List<int> ids, {int totalPages = 3}) =>
    TmdbMoviePageDto(
      page: page,
      results: [
        for (final id in ids)
          TmdbMovieDto(id: id, title: '영화 $id', posterPath: null),
      ],
      totalPages: totalPages,
      totalResults: ids.length,
    );

class _Movies extends TmdbMovieService {
  _Movies() : super(Dio());
  final requests = <({int page, List<int>? genres})>[];
  Future<TmdbMoviePageDto> Function(int page, List<int>? genres)? respond;
  Future<List<TmdbGenreDto>> Function()? genreResponse;

  @override
  Future<TmdbMoviePageDto> discoverMovies({
    required int page,
    List<int>? genreIds,
  }) async {
    requests.add((
      page: page,
      genres: genreIds == null ? null : List.of(genreIds),
    ));
    return respond == null
        ? _page(page, [page])
        : await respond!(page, genreIds);
  }

  @override
  Future<List<TmdbGenreDto>> fetchGenres() async => genreResponse == null
      ? const [
          TmdbGenreDto(id: 28, name: '액션'),
          TmdbGenreDto(id: 18, name: '드라마'),
        ]
      : await genreResponse!();
}

void main() {
  late _Movies api;
  late PagedMoviesViewModel vm;

  setUp(() {
    api = _Movies();
    vm = PagedMoviesViewModel(tmdbApi: api);
  });
  tearDown(() {
    if (!vm.isDisposed) vm.dispose();
    api.close();
  });

  test(
    'initial load fetches one page and deduplicates its movie IDs',
    () async {
      api.respond = (page, _) async => _page(page, [1, 1, 2]);
      await vm.loadInitial();
      expect(api.requests.map((request) => request.page).toList(), [1]);
      expect(vm.movies.map((movie) => movie.id).toList(), [1, 2]);
      expect(vm.nextPage, 2);
      expect(vm.phase, LoadPhase.ready);
      expect(vm.hasMore, isTrue);
    },
  );

  test(
    'next-page loading preserves cards and prevents duplicate requests',
    () async {
      api.respond = (page, _) async => _page(page, [1, 2]);
      await vm.loadInitial();
      final entered = Completer<void>(), gate = Completer<TmdbMoviePageDto>();
      api.respond = (_, _) {
        entered.complete();
        return gate.future;
      };
      final loading = vm.loadNextPage();
      await entered.future;
      expect(vm.phase, LoadPhase.ready);
      expect(vm.isLoadingMore, isTrue);
      expect(vm.movies.map((movie) => movie.id).toList(), [1, 2]);
      await vm.loadNextPage();
      expect(api.requests.length, 2);
      gate.complete(_page(2, [2, 3, 3]));
      await loading;
      expect(vm.movies.map((movie) => movie.id).toList(), [1, 2, 3]);
      expect(vm.nextPage, 3);
      expect(vm.isLoadingMore, isFalse);
    },
  );

  test('a failed append retains cards and retries the same page', () async {
    await vm.loadInitial();
    api.respond = (_, _) async => throw StateError('page failed');
    await vm.loadNextPage();
    expect(vm.movies.single.id, 1);
    expect(vm.phase, LoadPhase.ready);
    expect(vm.nextPage, 2);
    expect(vm.loadMoreError, isNotNull);
    expect(vm.errorMessage, isNull);
    api.respond = null;
    await vm.loadNextPage();
    expect(api.requests.map((request) => request.page).toList(), [1, 2, 2]);
    expect(vm.movies.map((movie) => movie.id).toList(), [1, 2]);
    expect(vm.nextPage, 3);
    expect(vm.loadMoreError, isNull);
  });

  test('first-page error is separate and retry restarts at page one', () async {
    api.respond = (_, _) async => throw StateError('initial failed');
    await vm.loadInitial(genreIds: [28, 18]);
    expect(vm.phase, LoadPhase.error);
    expect(vm.nextPage, 1);
    expect(vm.movies, isEmpty);
    expect(vm.hasMore, isFalse);
    await vm.loadNextPage();
    expect(api.requests.length, 1);
    api.respond = null;
    await vm.loadInitial(genreIds: vm.selectedGenreIds);
    expect(api.requests.last.page, 1);
    expect(api.requests.last.genres, [28, 18]);
    expect(vm.phase, LoadPhase.ready);
  });

  test('last page stops further requests', () async {
    api.respond = (page, _) async => _page(page, [page], totalPages: 2);
    await vm.loadInitial();
    await vm.loadNextPage();
    expect(vm.hasMore, isFalse);
    await vm.loadNextPage();
    expect(api.requests.map((request) => request.page).toList(), [1, 2]);
  });

  test(
    'TMDB totals greater than 500 never cause a request for page 501',
    () async {
      api.respond = (page, _) async => _page(page, [page], totalPages: 900);
      await vm.loadInitial();
      while (vm.hasMore) {
        await vm.loadNextPage();
      }
      expect(vm.totalPages, 500);
      expect(vm.nextPage, 501);
      expect(api.requests.length, 500);
      expect(api.requests.last.page, 500);
      await vm.loadNextPage();
      expect(api.requests.length, 500);
    },
  );

  test('an empty first page does not fetch additional pages', () async {
    api.respond = (page, _) async => _page(page, [], totalPages: 0);
    await vm.loadInitial();
    expect(vm.phase, LoadPhase.empty);
    expect(vm.hasMore, isFalse);
    await vm.loadNextPage();
    expect(api.requests.length, 1);
  });

  test(
    'genre changes clear previous cards and start page one with a snapshot',
    () async {
      await vm.loadInitial();
      await vm.loadNextPage();
      final genres = [28, 18, 28];
      final entered = Completer<void>(), gate = Completer<TmdbMoviePageDto>();
      api.respond = (_, _) {
        entered.complete();
        return gate.future;
      };
      final loading = vm.loadInitial(genreIds: genres);
      await entered.future;
      genres.clear();
      expect(vm.movies, isEmpty);
      expect(vm.nextPage, 1);
      expect(vm.phase, LoadPhase.loading);
      expect(vm.selectedGenreIds, [28, 18]);
      expect(api.requests.last.page, 1);
      expect(api.requests.last.genres, [28, 18]);
      gate.complete(_page(1, [7]));
      await loading;
      expect(vm.movies.single.id, 7);
    },
  );

  test(
    'a late first-page result cannot overwrite new genre data or loading flags',
    () async {
      final oldEntered = Completer<void>(), old = Completer<TmdbMoviePageDto>();
      final appendEntered = Completer<void>(),
          append = Completer<TmdbMoviePageDto>();
      api.respond = (page, genres) async {
        if (genres!.contains(28)) {
          oldEntered.complete();
          return old.future;
        }
        if (page == 2) {
          appendEntered.complete();
          return append.future;
        }
        return _page(1, [18]);
      };
      final oldRequest = vm.loadInitial(genreIds: [28]);
      await oldEntered.future;
      await vm.loadInitial(genreIds: [18]);
      final appending = vm.loadNextPage();
      await appendEntered.future;
      old.complete(_page(1, [28]));
      await oldRequest;
      expect(vm.movies.single.id, 18);
      expect(vm.isLoadingMore, isTrue);
      append.complete(_page(2, [19]));
      await appending;
      expect(vm.movies.map((movie) => movie.id).toList(), [18, 19]);
    },
  );

  test('a late append error cannot affect a new genre request', () async {
    await vm.loadInitial(genreIds: [28]);
    final oldEntered = Completer<void>(), old = Completer<TmdbMoviePageDto>();
    final newEntered = Completer<void>(), fresh = Completer<TmdbMoviePageDto>();
    api.respond = (page, _) {
      if (page == 2) {
        oldEntered.complete();
        return old.future;
      }
      newEntered.complete();
      return fresh.future;
    };
    final oldRequest = vm.loadNextPage();
    await oldEntered.future;
    final newRequest = vm.loadInitial(genreIds: [18]);
    await newEntered.future;
    old.completeError(StateError('old request failed'));
    await oldRequest;
    expect(vm.phase, LoadPhase.loading);
    expect(vm.loadMoreError, isNull);
    expect(vm.errorMessage, isNull);
    fresh.complete(_page(1, [18]));
    await newRequest;
    expect(vm.movies.single.id, 18);
  });

  test(
    'refresh discards a pending append even when genres stay the same',
    () async {
      await vm.loadInitial(genreIds: [28]);
      final entered = Completer<void>(), old = Completer<TmdbMoviePageDto>();
      api.respond = (_, _) {
        entered.complete();
        return old.future;
      };
      final pending = vm.loadNextPage();
      await entered.future;
      api.respond = (_, _) async => _page(1, [9]);
      await vm.loadInitial(genreIds: vm.selectedGenreIds);
      old.complete(_page(2, [2]));
      await pending;
      expect(vm.movies.single.id, 9);
      expect(vm.nextPage, 2);
      expect(vm.isLoadingMore, isFalse);
    },
  );

  test('inconsistent page metadata does not advance the next page', () async {
    await vm.loadInitial();
    api.respond = (_, _) async => _page(1, [9]);
    await vm.loadNextPage();
    expect(vm.nextPage, 2);
    expect(vm.movies.single.id, 1);
    expect(vm.loadMoreError, isNotNull);
  });

  test(
    'dispose suppresses late responses, notifications, and new requests',
    () async {
      final entered = Completer<void>(), gate = Completer<TmdbMoviePageDto>();
      api.respond = (_, _) {
        entered.complete();
        return gate.future;
      };
      var notifications = 0;
      vm.addListener(() => notifications++);
      final pending = vm.loadInitial();
      await entered.future;
      vm.dispose();
      final before = notifications;
      gate.complete(_page(1, [1]));
      await pending;
      await vm.loadInitial();
      await vm.loadNextPage();
      expect(notifications, before);
      expect(api.requests.length, 1);
    },
  );

  test(
    'existing genre ViewModel uses paged state and keeps multiple selections',
    () async {
      final catalog = MovieListViewModel(api);
      addTearDown(catalog.dispose);
      await catalog.loadGenres();
      expect(catalog.genreStatus, MovieListLoadStatus.success);
      expect(catalog.genres.map((genre) => genre.name).toList(), ['액션', '드라마']);
      await catalog.selectGenres([28, 18]);
      expect(catalog.phase, LoadPhase.ready);
      await catalog.loadNextPage();
      expect(api.requests.map((request) => request.page).toList(), [1, 2]);
      expect(
        api.requests.every((request) => request.genres!.length == 2),
        isTrue,
      );
      await catalog.selectGenres(null);
      expect(api.requests.last, (page: 1, genres: null));
      expect(catalog.nextPage, 2);
    },
  );
}
