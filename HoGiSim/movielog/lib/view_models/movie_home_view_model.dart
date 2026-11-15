import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';
import 'movie_load_status.dart';

class MovieHomeViewModel extends ChangeNotifier {
  MovieHomeViewModel(this._service);
  final TmdbMovieService _service;
  List<TmdbMovieDto> _popularMovies = const [];
  List<TmdbMovieDto> get popularMovies => _popularMovies;
  MovieLoadStatus status = MovieLoadStatus.idle;
  String? message;
  bool _disposed = false;
  CancelToken? _cancelToken;

  Future<void> loadPopular() async {
    if (_disposed || status == MovieLoadStatus.loading) return;
    status = MovieLoadStatus.loading;
    message = null;
    final token = _cancelToken = CancelToken();
    notifyListeners();
    try {
      final page = await _service.fetchPopular(cancelToken: token);
      if (_disposed || token.isCancelled) return;
      _popularMovies = List.unmodifiable(page.results.take(5));
      status = _popularMovies.isEmpty
          ? MovieLoadStatus.empty
          : MovieLoadStatus.success;
    } catch (error) {
      if (_disposed || token.isCancelled) return;
      status = MovieLoadStatus.error;
      message = movieLoadMessage(error);
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelToken?.cancel();
    super.dispose();
  }
}
