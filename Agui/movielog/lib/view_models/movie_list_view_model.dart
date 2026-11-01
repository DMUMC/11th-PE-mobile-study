import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';

enum MovieListLoadStatus { idle, loading, success, empty, error }

class MovieListViewModel extends ChangeNotifier {
  MovieListViewModel(this._service);
  final TmdbMovieService _service;

  List<TmdbGenreDto> genres = const [];
  List<TmdbMovieDto> movies = const [];
  List<int>? selectedGenreIds;
  MovieListLoadStatus genreStatus = MovieListLoadStatus.idle;
  MovieListLoadStatus status = MovieListLoadStatus.idle;
  String? genreMessage;
  String? message;
  bool isRefreshing = false;
  bool isRetrying = false;
  bool get isLoading =>
      status == MovieListLoadStatus.loading || isRefreshing || isRetrying;
  int failureVersion = 0;
  List<TmdbMovieDto>? _lastSuccessfulMovies;
  List<int>? _failedGenreIds;
  int _requestVersion = 0;
  bool _disposed = false;

  Future<void> loadGenres() async {
    genreStatus = MovieListLoadStatus.loading;
    notifyListeners();

    try {
      final result = await _service.fetchGenres();
      if (_disposed) return;
      genres = result;
      genreStatus = genres.isEmpty
          ? MovieListLoadStatus.empty
          : MovieListLoadStatus.success;
    } on DioException {
      if (_disposed) return;
      genreStatus = MovieListLoadStatus.error;
      genreMessage = '장르를 불러오지 못했어요.';
    }

    notifyListeners();
  }

  Future<List<TmdbMovieDto>> fetchUpToThirtyMovies({
    List<int>? genreIds,
  }) async {
    final byId = <int, TmdbMovieDto>{};
    var pageNumber = 1;
    var hasNextPage = true;

    while (byId.length < 30 && hasNextPage) {
      final page = await _service.discoverMovies(
        page: pageNumber,
        genreIds: genreIds,
      );

      for (final movie in page.results) {
        byId[movie.id] = movie;
        if (byId.length == 30) break;
      }

      hasNextPage = pageNumber < page.totalPages && page.results.isNotEmpty;
      pageNumber++;
    }

    return byId.values.take(30).toList();
  }

  Future<void> loadMovies() => _loadMovies(refresh: false);

  Future<void> refreshMovies() => _loadMovies(refresh: true);

  Future<void> retryMovies() => _loadMovies(refresh: false, retry: true);

  Future<void> _loadMovies({required bool refresh, bool retry = false}) async {
    if (isLoading) return;

    final version = ++_requestVersion;
    final genreIds = retry ? _failedGenreIds : selectedGenreIds;
    isRefreshing = refresh;
    isRetrying = retry;
    if ((refresh || retry) && _lastSuccessfulMovies != null) {
      movies = _lastSuccessfulMovies!;
      status = movies.isEmpty
          ? MovieListLoadStatus.empty
          : MovieListLoadStatus.success;
    } else {
      status = MovieListLoadStatus.loading;
    }
    message = null;
    notifyListeners();

    try {
      final result = await fetchUpToThirtyMovies(genreIds: genreIds);
      if (_disposed || version != _requestVersion) return;
      movies = result;
      _lastSuccessfulMovies = result;
      status = movies.isEmpty
          ? MovieListLoadStatus.empty
          : MovieListLoadStatus.success;
    } on DioException {
      if (_disposed || version != _requestVersion) return;
      _failedGenreIds = genreIds;
      if (_lastSuccessfulMovies != null) {
        movies = _lastSuccessfulMovies!;
        status = movies.isEmpty
            ? MovieListLoadStatus.empty
            : MovieListLoadStatus.success;
      } else {
        status = MovieListLoadStatus.error;
      }
      message = '영화를 불러오지 못했어요. 네트워크 연결을 확인하고 다시 시도해 주세요.';
      failureVersion++;
    }

    isRefreshing = false;
    isRetrying = false;
    notifyListeners();
  }

  Future<void> selectGenres(List<int>? genreIds) async {
    if (isLoading) return;

    final nextIds = genreIds == null || genreIds.isEmpty
        ? null
        : List<int>.unmodifiable(genreIds.toSet());
    if (listEquals(selectedGenreIds, nextIds) &&
        status != MovieListLoadStatus.idle) {
      return;
    }
    selectedGenreIds = nextIds;
    movies = const [];
    await loadMovies();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
