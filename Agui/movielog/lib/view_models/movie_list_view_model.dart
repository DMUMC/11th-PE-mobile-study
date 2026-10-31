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
  int? selectedGenreId;
  MovieListLoadStatus genreStatus = MovieListLoadStatus.idle;
  MovieListLoadStatus status = MovieListLoadStatus.idle;
  String? genreMessage;
  String? message;
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

  Future<List<TmdbMovieDto>> fetchUpToThirtyMovies({int? genreId}) async {
    final byId = <int, TmdbMovieDto>{};
    var pageNumber = 1;
    var hasNextPage = true;

    while (byId.length < 30 && hasNextPage) {
      final page = await _service.discoverMovies(
        page: pageNumber,
        genreId: genreId,
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

  Future<void> loadMovies() async {
    final version = ++_requestVersion;
    status = MovieListLoadStatus.loading;
    message = null;
    notifyListeners();

    try {
      final result = await fetchUpToThirtyMovies(genreId: selectedGenreId);
      if (_disposed || version != _requestVersion) return;
      movies = result;
      status = movies.isEmpty
          ? MovieListLoadStatus.empty
          : MovieListLoadStatus.success;
    } on DioException {
      if (_disposed || version != _requestVersion) return;
      status = MovieListLoadStatus.error;
      message = '영화를 불러오지 못했어요. 다시 시도해 주세요.';
    }

    notifyListeners();
  }

  Future<void> selectGenre(int? genreId) async {
    if (selectedGenreId == genreId && status != MovieListLoadStatus.idle) {
      return;
    }
    selectedGenreId = genreId;
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
