import 'package:flutter/foundation.dart';

import '../core/utils/safe_notify.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/models/tmdb_movie_page.dart';
import '../data/services/tmdb_movie_service.dart';
import 'load_phase.dart';

class PagedMoviesViewModel extends ChangeNotifier with SafeNotify {
  PagedMoviesViewModel({required this.tmdbApi, this.searchOnly = false});

  final TmdbMovieService tmdbApi;
  final bool searchOnly;
  static const maxTmdbPage = 500;

  LoadPhase phase = LoadPhase.idle;
  final List<TmdbMovieDto> movies = [];
  int nextPage = 1;
  int totalPages = 1;
  bool isLoadingMore = false;
  String? errorMessage;
  String? loadMoreError;
  int _requestGeneration = 0;
  List<int>? _genreIds;
  String _query = '';

  List<int>? get selectedGenreIds => _genreIds;
  String get query => _query;
  bool get hasMore =>
      phase == LoadPhase.ready &&
      nextPage <= totalPages &&
      nextPage <= maxTmdbPage;

  bool _isCurrent(int generation) =>
      !isDisposed && generation == _requestGeneration;

  Future<void> loadInitial({List<int>? genreIds, String query = ''}) async {
    if (isDisposed) return;
    _genreIds = genreIds == null || genreIds.isEmpty
        ? null
        : List<int>.unmodifiable(genreIds.toSet());
    final requestedGenres = _genreIds;
    _query = query.trim();
    final requestedQuery = _query;
    final generation = ++_requestGeneration;
    phase = searchOnly && requestedQuery.isEmpty
        ? LoadPhase.idle
        : LoadPhase.loading;
    movies.clear();
    nextPage = 1;
    totalPages = 1;
    isLoadingMore = false;
    errorMessage = null;
    loadMoreError = null;
    notifyIfAlive();
    // Clearing a submitted query invalidates outstanding responses without
    // falling back to Discover in the dedicated search instance.
    if (phase == LoadPhase.idle) return;
    try {
      final page = await _fetchPage(1, requestedGenres, requestedQuery);
      if (!_isCurrent(generation)) return;
      _appendPage(page);
      phase = movies.isEmpty ? LoadPhase.empty : LoadPhase.ready;
    } catch (_) {
      if (!_isCurrent(generation)) return;
      phase = LoadPhase.error;
      errorMessage = requestedQuery.isEmpty
          ? '영화 목록을 불러오지 못했습니다.'
          : '검색 결과를 불러오지 못했습니다.';
    } finally {
      if (_isCurrent(generation)) notifyIfAlive();
    }
  }

  Future<void> loadNextPage() async {
    if (isDisposed || isLoadingMore || !hasMore) return;
    final generation = _requestGeneration;
    final pageToLoad = nextPage;
    final requestedGenres = _genreIds;
    final requestedQuery = _query;
    isLoadingMore = true;
    loadMoreError = null;
    notifyIfAlive();
    try {
      final page = await _fetchPage(
        pageToLoad,
        requestedGenres,
        requestedQuery,
      );
      if (!_isCurrent(generation)) return;
      _appendPage(page);
    } catch (_) {
      if (!_isCurrent(generation)) return;
      loadMoreError = '다음 페이지를 불러오지 못했습니다. 같은 페이지를 다시 요청합니다.';
    } finally {
      if (_isCurrent(generation)) {
        isLoadingMore = false;
        notifyIfAlive();
      }
    }
  }

  Future<TmdbMoviePageDto> _fetchPage(
    int page,
    List<int>? genreIds,
    String query,
  ) async {
    final result = query.isEmpty
        ? await tmdbApi.discoverMovies(page: page, genreIds: genreIds)
        : await tmdbApi.searchMovies(page: page, query: query);
    if (result.page != page ||
        result.page < 1 ||
        result.page > maxTmdbPage ||
        result.totalPages < 0 ||
        result.totalResults < 0) {
      throw const FormatException('TMDB page metadata is inconsistent.');
    }
    return result;
  }

  void _appendPage(TmdbMoviePageDto page) {
    final seen = movies.map((movie) => movie.id).toSet();
    movies.addAll(page.results.where((movie) => seen.add(movie.id)));
    totalPages = page.totalPages.clamp(0, maxTmdbPage);
    nextPage = page.page + 1;
  }
}
