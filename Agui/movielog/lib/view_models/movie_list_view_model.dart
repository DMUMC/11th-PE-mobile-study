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
  MovieListLoadStatus status = MovieListLoadStatus.idle;
  String? message;
  String? movieMessage;
  bool _disposed = false;

  Future<void> loadGenres() async {
    status = MovieListLoadStatus.loading;
    notifyListeners();

    try {
      final result = await _service.fetchGenres();
      if (_disposed) return;
      genres = result;
      status = genres.isEmpty
          ? MovieListLoadStatus.empty
          : MovieListLoadStatus.success;
    } on DioException {
      if (_disposed) return;
      status = MovieListLoadStatus.error;
      message = '장르를 불러오지 못했어요.';
    }

    notifyListeners();
  }

  Future<void> loadMovies() async {
    movieMessage = null;

    try {
      final page = await _service.discoverMovies(page: 1);
      if (_disposed) return;
      movies = page.results;
    } on DioException {
      if (_disposed) return;
      movieMessage = '영화를 불러오지 못했어요.';
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
