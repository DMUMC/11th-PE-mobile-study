import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';

enum MovieListLoadStatus { idle, loading, success, empty, error }

class MovieListViewModel extends ChangeNotifier {
  MovieListViewModel(this._service);
  final TmdbMovieService _service;

  List<TmdbGenreDto> genres = const [];
  MovieListLoadStatus status = MovieListLoadStatus.idle;
  String? message;
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

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
