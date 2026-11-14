import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_with_movie.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';

const int sampleMemberId = 1;

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._service, this._movieService, this.memberId);

  final RatingApiService _service;
  final TmdbMovieService _movieService;
  final int memberId;
  final Map<int, TmdbMovieDto?> _movieCache = {};
  int _requestVersion = 0;
  bool _disposed = false;

  List<RatingWithMovie> _ratings = const [];
  MyRatingsLoadStatus _status = MyRatingsLoadStatus.idle;
  String? _message;

  List<RatingWithMovie> get ratings => _ratings;
  MyRatingsLoadStatus get status => _status;
  String? get message => _message;

  bool _isCurrent(int version) => !_disposed && version == _requestVersion;

  Future<void> load() async {
    if (_disposed) return;
    final version = ++_requestVersion;
    _status = MyRatingsLoadStatus.loading;
    _message = null;
    notifyListeners();

    try {
      final rawRatings = await _service.fetchMyRatings(memberId);
      if (!_isCurrent(version)) return;
      final entries = <RatingWithMovie>[];
      var missingMovies = 0;

      for (final rating in rawRatings) {
        if (!_isCurrent(version)) return;
        if (!_movieCache.containsKey(rating.movieId)) {
          try {
            final movie = await _movieService.findMovieById(rating.movieId);
            if (!_isCurrent(version)) return;
            // A 404 is cached as null; transient failures are retried next load.
            _movieCache[rating.movieId] = movie;
          } on DioException {
            if (!_isCurrent(version)) return;
          } on FormatException {
            if (!_isCurrent(version)) return;
          }
        }
        final movie = _movieCache[rating.movieId];
        if (movie == null) missingMovies++;
        entries.add(RatingWithMovie(rating: rating, movie: movie));
      }

      if (!_isCurrent(version)) return;
      _ratings = List.unmodifiable(entries);
      _status = entries.isEmpty
          ? MyRatingsLoadStatus.empty
          : MyRatingsLoadStatus.success;
      if (missingMovies > 0) {
        _message = '일부 영화 정보를 가져오지 못했습니다. 평점 기록은 그대로 표시합니다.';
      }
    } on DioException catch (error) {
      if (!_isCurrent(version)) return;
      _status = MyRatingsLoadStatus.error;
      _message = writeMyRatingsErrorMessage(error);
    } on FormatException {
      if (!_isCurrent(version)) return;
      _status = MyRatingsLoadStatus.error;
      _message = '평점 정보를 읽지 못했습니다. 다시 시도해 주세요.';
    }

    if (_isCurrent(version)) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
