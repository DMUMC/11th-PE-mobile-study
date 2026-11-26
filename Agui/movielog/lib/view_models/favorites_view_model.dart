import 'package:flutter/foundation.dart';

import '../core/session/session_guard.dart';
import '../core/utils/map_bounded.dart';
import '../core/utils/safe_notify.dart';
import '../data/models/favorite_list_item.dart';
import '../data/models/favorite_response_dto.dart';
import '../data/services/favorite_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import 'load_phase.dart';

class FavoritesViewModel extends ChangeNotifier with SafeNotify {
  FavoritesViewModel({
    required this.favoriteApi,
    required this.tmdbApi,
    required this.sessionGuard,
    required this.accountId,
  }) : _sessionGeneration = sessionGuard.generation;

  final FavoriteApiService favoriteApi;
  final TmdbMovieService tmdbApi;
  final SessionGuard sessionGuard;
  final String accountId;
  final int _sessionGeneration;

  LoadPhase phase = LoadPhase.idle;
  List<FavoriteListItem> items = const [];
  String? errorMessage;
  int _refreshGeneration = 0;
  final _retryingMovieIds = <int>{};

  Set<int> get retryingMovieIds => Set.unmodifiable(_retryingMovieIds);

  bool get _isCurrentSession =>
      !isDisposed && sessionGuard.isCurrent(_sessionGeneration, accountId);

  bool _isCurrent(int refreshGeneration) =>
      _isCurrentSession && refreshGeneration == _refreshGeneration;

  Future<void> refresh() async {
    if (!_isCurrentSession) return;
    final generation = ++_refreshGeneration;
    phase = LoadPhase.loading;
    items = const [];
    errorMessage = null;
    _retryingMovieIds.clear();
    notifyIfAlive();
    try {
      final favorites = await favoriteApi.fetchMyFavorites();
      if (!_isCurrent(generation)) return;
      final enriched = await mapBounded(favorites, 5, (favorite) async {
        if (!_isCurrent(generation)) {
          return FavoriteListItem(favorite: favorite);
        }
        return _fetchMovie(favorite);
      });
      if (!_isCurrent(generation)) return;
      items = enriched;
      phase = items.isEmpty ? LoadPhase.empty : LoadPhase.ready;
    } catch (_) {
      if (!_isCurrent(generation)) return;
      phase = LoadPhase.error;
      errorMessage = '즐겨찾기를 불러오지 못했습니다.';
    } finally {
      if (_isCurrent(generation)) notifyIfAlive();
    }
  }

  Future<FavoriteListItem> _fetchMovie(FavoriteResponseDto favorite) async {
    try {
      final movie = await tmdbApi.fetchMovieDetail(favorite.movieId);
      return FavoriteListItem(favorite: favorite, movie: movie);
    } catch (_) {
      return FavoriteListItem(
        favorite: favorite,
        errorMessage: '영화 정보를 불러오지 못했습니다.',
      );
    }
  }

  // Retry only the failed card; keep the rest of the list visible.
  Future<void> retryMovie(int movieId) async {
    if (!_isCurrentSession ||
        phase != LoadPhase.ready ||
        _retryingMovieIds.contains(movieId)) {
      return;
    }
    final failed = items.where(
      (item) => item.favorite.movieId == movieId && !item.hasMovie,
    );
    if (failed.isEmpty) return;
    final favorite = failed.first.favorite;
    final generation = _refreshGeneration;
    _retryingMovieIds.add(movieId);
    notifyIfAlive();
    try {
      final retried = await _fetchMovie(favorite);
      if (!_isCurrent(generation)) return;
      items = [
        for (final item in items)
          if (item.favorite.movieId == movieId) retried else item,
      ];
    } finally {
      if (_isCurrent(generation)) {
        _retryingMovieIds.remove(movieId);
        notifyIfAlive();
      }
    }
  }
}
