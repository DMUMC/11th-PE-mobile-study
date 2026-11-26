import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/session/session_guard.dart';
import 'package:movielog/core/utils/map_bounded.dart';
import 'package:movielog/data/models/favorite_response_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/favorite_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/favorites_view_model.dart';
import 'package:movielog/view_models/load_phase.dart';

FavoriteResponseDto _favorite(int movieId) => FavoriteResponseDto(
  favoriteId: movieId + 100,
  movieId: movieId,
  createdAt: DateTime(2026, 11, 26),
);

TmdbMovieDto _movie(int movieId) =>
    TmdbMovieDto(id: movieId, title: '영화 $movieId', posterPath: null);

class _Favorites extends FavoriteApiService {
  _Favorites() : super(Dio());
  var values = <FavoriteResponseDto>[];
  int requests = 0;
  Future<List<FavoriteResponseDto>> Function()? respond;

  @override
  Future<List<FavoriteResponseDto>> fetchMyFavorites() async {
    requests++;
    return respond == null ? List.of(values) : await respond!();
  }
}

class _Movies extends TmdbMovieService {
  _Movies() : super(Dio());
  final requestedIds = <int>[];
  Future<TmdbMovieDto> Function(int)? respond;

  @override
  Future<TmdbMovieDto> fetchMovieDetail(int movieId) async {
    requestedIds.add(movieId);
    return respond == null ? _movie(movieId) : await respond!(movieId);
  }
}

void main() {
  late _Favorites favorites;
  late _Movies movies;
  late SessionGuard guard;
  late FavoritesViewModel vm;

  setUp(() {
    favorites = _Favorites();
    movies = _Movies();
    guard = SessionGuard()..startSession('a@example.com');
    vm = FavoritesViewModel(
      favoriteApi: favorites,
      tmdbApi: movies,
      sessionGuard: guard,
      accountId: 'a@example.com',
    );
  });
  tearDown(() {
    if (!vm.isDisposed) vm.dispose();
    movies.close();
  });

  test(
    'joins movieId metadata in server order with at most five pending lookups',
    () async {
      favorites.values = List.generate(12, (i) => _favorite(12 - i));
      final firstBatch = Completer<void>(), release = Completer<void>();
      var active = 0, peak = 0;
      movies.respond = (id) async {
        active++;
        if (active > peak) peak = active;
        if (movies.requestedIds.length == 5) firstBatch.complete();
        try {
          await release.future;
          return _movie(id);
        } finally {
          active--;
        }
      };
      final pending = vm.refresh();
      await firstBatch.future;
      expect(vm.phase, LoadPhase.loading);
      expect(active, 5);
      expect(movies.requestedIds.length, 5);
      release.complete();
      await pending;
      expect(peak, 5);
      expect(active, 0);
      expect(vm.phase, LoadPhase.ready);
      expect(
        vm.items.map((item) => item.movie!.id).toList(),
        favorites.values.map((favorite) => favorite.movieId).toList(),
      );
      expect(vm.items.first.favorite.favoriteId, 112);
    },
  );

  test('an empty server list becomes empty without TMDB requests', () async {
    await vm.refresh();
    expect(vm.phase, LoadPhase.empty);
    expect(vm.items, isEmpty);
    expect(movies.requestedIds, isEmpty);
  });

  test('a list failure becomes error and can be retried', () async {
    favorites.respond = () async => throw StateError('list failed');
    await vm.refresh();
    expect(vm.phase, LoadPhase.error);
    expect(vm.errorMessage, isNotNull);
    expect(movies.requestedIds, isEmpty);
    favorites.respond = null;
    favorites.values = [_favorite(1)];
    await vm.refresh();
    expect(vm.phase, LoadPhase.ready);
    expect(vm.errorMessage, isNull);
    expect(vm.items.single.movie!.id, 1);
  });

  test(
    'one failed movie keeps the favorite and other successful cards',
    () async {
      favorites.values = [_favorite(1), _favorite(2)];
      movies.respond = (id) async {
        if (id == 2) throw StateError('movie failed');
        return _movie(id);
      };
      await vm.refresh();
      expect(vm.phase, LoadPhase.ready);
      expect(vm.items.length, 2);
      expect(vm.items.first.movie!.title, '영화 1');
      expect(vm.items.last.favorite.movieId, 2);
      expect(vm.items.last.movie, isNull);
      expect(vm.items.last.errorMessage, isNotNull);
      expect(vm.errorMessage, isNull);
    },
  );

  test(
    'all movie lookups failing is a list of failed cards, not an empty list',
    () async {
      favorites.values = [_favorite(1), _favorite(2)];
      movies.respond = (_) async => throw StateError('TMDB failed');
      await vm.refresh();
      expect(vm.phase, LoadPhase.ready);
      expect(vm.items.length, 2);
      expect(vm.items.every((item) => !item.hasMovie), isTrue);
    },
  );

  test(
    'retrying a failed card preserves other cards and blocks repeated taps',
    () async {
      favorites.values = [_favorite(1), _favorite(2)];
      movies.respond = (id) async {
        if (id == 2) throw StateError('movie failed');
        return _movie(id);
      };
      await vm.refresh();
      final unchanged = vm.items.first;
      final gate = Completer<TmdbMovieDto>();
      movies.respond = (_) => gate.future;
      final retry = vm.retryMovie(2);
      expect(vm.retryingMovieIds, {2});
      expect(vm.phase, LoadPhase.ready);
      await vm.retryMovie(2);
      expect(movies.requestedIds, [1, 2, 2]);
      gate.complete(_movie(2));
      await retry;
      expect(identical(vm.items.first, unchanged), isTrue);
      expect(vm.items.last.movie!.id, 2);
      expect(vm.retryingMovieIds, isEmpty);
      expect(favorites.requests, 1);
    },
  );

  test(
    'refresh after a server deletion removes the movie from the list',
    () async {
      favorites.values = [_favorite(1), _favorite(2)];
      await vm.refresh();
      favorites.values = [_favorite(1)];
      await vm.refresh();
      expect(vm.items.map((item) => item.favorite.movieId).toList(), [1]);
      expect(favorites.requests, 2);
    },
  );

  test('an older refresh cannot overwrite a newer refresh', () async {
    final entered = Completer<void>(), gate = Completer<TmdbMovieDto>();
    favorites.values = [_favorite(1)];
    movies.respond = (id) async {
      if (id == 1) {
        entered.complete();
        return gate.future;
      }
      return _movie(id);
    };
    final old = vm.refresh();
    await entered.future;
    favorites.values = [_favorite(2)];
    await vm.refresh();
    gate.complete(_movie(1));
    await old;
    expect(vm.items.single.movie!.id, 2);
    expect(vm.phase, LoadPhase.ready);
  });

  test(
    'an old card retry cannot reinsert a movie removed by refresh',
    () async {
      favorites.values = [_favorite(1), _favorite(2)];
      movies.respond = (id) async {
        if (id == 2) throw StateError('movie failed');
        return _movie(id);
      };
      await vm.refresh();
      final gate = Completer<TmdbMovieDto>();
      movies.respond = (id) => id == 2 ? gate.future : Future.value(_movie(id));
      final retry = vm.retryMovie(2);
      favorites.values = [_favorite(1)];
      await vm.refresh();
      gate.complete(_movie(2));
      await retry;
      expect(vm.items.single.movie!.id, 1);
      expect(vm.retryingMovieIds, isEmpty);
    },
  );

  for (final nextAccount in ['b@example.com', 'a@example.com']) {
    test(
      'previous-session responses and calls are ignored after login as $nextAccount',
      () async {
        final gate = Completer<List<FavoriteResponseDto>>();
        favorites.respond = () => gate.future;
        final pending = vm.refresh();
        guard.invalidate();
        guard.startSession(nextAccount);
        gate.complete([_favorite(1)]);
        await pending;
        expect(vm.items, isEmpty);
        expect(movies.requestedIds, isEmpty);
        await vm.refresh();
        expect(favorites.requests, 1);
      },
    );
  }

  test(
    'dispose during a lookup suppresses later updates and queued lookups',
    () async {
      favorites.values = List.generate(12, (i) => _favorite(i + 1));
      final entered = Completer<void>(), gate = Completer<void>();
      movies.respond = (id) async {
        if (movies.requestedIds.length == 5) entered.complete();
        await gate.future;
        return _movie(id);
      };
      var notifications = 0;
      vm.addListener(() => notifications++);
      final pending = vm.refresh();
      await entered.future;
      vm.dispose();
      final before = notifications;
      gate.complete();
      await pending;
      expect(notifications, before);
      expect(movies.requestedIds.length, 5);
    },
  );

  test('mapBounded rejects a nonpositive worker limit', () async {
    await expectLater(
      mapBounded<int, int>([], 0, (value) async => value),
      throwsArgumentError,
    );
  });
}
