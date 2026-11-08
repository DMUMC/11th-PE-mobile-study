import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/genre_preference_store.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/models/tmdb_genre_dto.dart';
import '../data/services/tmdb_movie_service.dart';
import 'movie_load_status.dart';

class MovieListViewModel extends ChangeNotifier {
  MovieListViewModel(
    this._service, {
    GenrePreferenceStore? preferenceStore,
    this._initialGenres,
  }) : _store = preferenceStore ?? SharedPreferencesGenreStore();

  final TmdbMovieService _service;
  final GenrePreferenceStore _store;
  final List<int>? _initialGenres;
  List<TmdbMovieDto> _movies = const [];
  List<TmdbMovieDto> _lastSuccess = const [];
  List<TmdbGenreDto> _genres = const [];
  List<int>? _selectedGenreIds;
  List<TmdbMovieDto> get movies => _movies;
  List<TmdbGenreDto> get genres => _genres;
  List<int>? get selectedGenreIds => _selectedGenreIds;
  MovieLoadStatus status = MovieLoadStatus.idle;
  String? message;
  String sortOrder = 'popular';
  bool isBusy = false;
  bool isRefreshing = false;
  bool showingPreviousResults = false;
  int failureVersion = 0;
  int _requestVersion = 0;
  bool _disposed = false;
  CancelToken? _cancelToken;

  List<TmdbMovieDto> get sortedMovies {
    final result = [..._movies];
    switch (sortOrder) {
      case 'rating':
        result.sort((a, b) => b.voteAverage.compareTo(a.voteAverage));
      case 'title':
        result.sort((a, b) => a.title.compareTo(b.title));
      case 'latest':
        result.sort(
          (a, b) => (b.releaseDate ?? '').compareTo(a.releaseDate ?? ''),
        );
      default:
        break;
    }
    return result;
  }

  Future<void> loadInitial() async {
    if (_disposed || isBusy) return;
    await _load(restore: true);
  }

  Future<void> retry() async {
    if (_disposed || isBusy) return;
    await _load();
  }

  Future<void> refresh() async {
    if (_disposed || isBusy) return;
    await _load(refresh: true);
  }

  Future<void> selectGenres(List<int>? ids) async {
    if (_disposed || isBusy) return;
    final validIds =
        (ids ?? const <int>[])
            .where((id) => _genres.any((genre) => genre.id == id))
            .toSet()
            .toList()
          ..sort();
    final next = validIds.isEmpty ? null : List<int>.unmodifiable(validIds);
    if (listEquals(next, _selectedGenreIds)) return;
    _selectedGenreIds = next;
    // Start immediately so a second tap cannot race the preference write.
    final request = _load();
    try {
      await _store.writeGenres(next?.map((id) => '$id').toList() ?? []);
    } catch (_) {}
    await request;
  }

  Future<void> changeSort(String value) async {
    if (_disposed || !['popular', 'rating', 'title', 'latest'].contains(value)) {
      return;
    }
    sortOrder = value;
    notifyListeners();
    try {
      await _store.writeSortOrder(value);
    } catch (_) {}
  }

  Future<List<TmdbMovieDto>> _fetchThirty(
    List<int>? genreIds,
    int version,
    CancelToken token,
  ) async {
    final byId = <int, TmdbMovieDto>{};
    var pageNumber = 1;
    while (byId.length < 30) {
      if (_disposed || version != _requestVersion || token.isCancelled) {
        return const [];
      }
      final page = await _service.discoverMovies(
        page: pageNumber,
        genreIds: genreIds,
        cancelToken: token,
      );
      if (_disposed || version != _requestVersion || token.isCancelled) {
        return const [];
      }
      for (final movie in page.results) {
        byId.putIfAbsent(movie.id, () => movie);
        if (byId.length == 30) break;
      }
      if (page.results.isEmpty || pageNumber >= page.totalPages) break;
      pageNumber++;
    }
    return List.unmodifiable(byId.values.take(30));
  }

  Future<void> _load({bool restore = false, bool refresh = false}) async {
    final version = ++_requestVersion;
    final token = _cancelToken = CancelToken();
    isBusy = true;
    isRefreshing = refresh && _movies.isNotEmpty;
    message = null;
    showingPreviousResults = false;
    if (!isRefreshing) {
      status = MovieLoadStatus.loading;
      _movies = const [];
    }
    notifyListeners();
    try {
      if (restore) {
        try {
          final stored = await _store.readGenres();
          final sort = await _store.readSortOrder();
          if (_disposed || version != _requestVersion) return;
          _selectedGenreIds =
              _initialGenres ??
              stored.map(int.tryParse).whereType<int>().toList();
          if (['popular', 'rating', 'title', 'latest'].contains(sort)) {
            sortOrder = sort;
          }
        } catch (_) {
          _selectedGenreIds = _initialGenres;
        }
      }
      final genres = _genres.isEmpty
          ? await _service.fetchGenres(cancelToken: token)
          : _genres;
      if (_disposed || version != _requestVersion) return;
      _genres = List.unmodifiable(genres);
      final selected =
          (_selectedGenreIds ?? const <int>[])
              .where((id) => genres.any((genre) => genre.id == id))
              .toSet()
              .toList()
            ..sort();
      _selectedGenreIds = selected.isEmpty ? null : List.unmodifiable(selected);
      final result = await _fetchThirty(_selectedGenreIds, version, token);
      if (_disposed || version != _requestVersion) return;
      _movies = result;
      _lastSuccess = result;
      status = result.isEmpty ? MovieLoadStatus.empty : MovieLoadStatus.success;
    } catch (error) {
      if (_disposed || version != _requestVersion || token.isCancelled) return;
      message = movieLoadMessage(error);
      if (_lastSuccess.isNotEmpty) {
        _movies = _lastSuccess;
        showingPreviousResults = true;
        status = MovieLoadStatus.success;
        failureVersion++;
      } else {
        status = MovieLoadStatus.error;
      }
    } finally {
      if (!_disposed && version == _requestVersion) {
        isBusy = false;
        isRefreshing = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    _cancelToken?.cancel();
    super.dispose();
  }
}
