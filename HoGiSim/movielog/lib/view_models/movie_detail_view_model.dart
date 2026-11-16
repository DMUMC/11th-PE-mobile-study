import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/models/tmdb_genre_dto.dart';
import '../data/services/tmdb_movie_service.dart';
import 'movie_load_status.dart';

class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(this._service, this.movieId, {this.movie});
  final TmdbMovieService _service;
  final int movieId;
  TmdbMovieDto? movie;
  List<TmdbGenreDto> genres = const [];
  MovieLoadStatus status = MovieLoadStatus.idle;
  String? message;
  bool _disposed = false;
  final _token = CancelToken();

  Future<void> load() async {
    if (_disposed || status == MovieLoadStatus.loading) return;
    status = MovieLoadStatus.loading;
    notifyListeners();
    try {
      final loaded =
          movie ?? await _service.fetchMovie(movieId, cancelToken: _token);
      final loadedGenres = await _service.fetchGenres(cancelToken: _token);
      if (_disposed) return;
      movie = loaded;
      genres = loadedGenres;
      status = MovieLoadStatus.success;
    } catch (error) {
      if (_disposed) return;
      if (movie != null) {
        status = MovieLoadStatus.success;
      } else {
        status = MovieLoadStatus.error;
        message = movieLoadMessage(error);
      }
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _token.cancel();
    super.dispose();
  }
}
