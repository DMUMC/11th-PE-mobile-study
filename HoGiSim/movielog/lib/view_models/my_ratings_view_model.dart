import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_with_movie.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';

const sampleMemberId = 1;

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._service, this._movieService);

  final RatingApiService _service;
  final TmdbMovieService _movieService;
  final _movieCache = <int, TmdbMovieDto?>{};
  CancelToken? _request;
  bool _disposed = false;

  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;
  List<RatingWithMovie> ratings = const [];
  String? message;

  Future<void> load() async {
    if (_disposed) return;
    _request?.cancel();
    final request = _request = CancelToken();
    status = MyRatingsLoadStatus.loading;
    message = null;
    notifyListeners();

    try {
      final records = await _service.fetchMyRatings(
        sampleMemberId,
        cancelToken: request,
      );
      if (request.isCancelled) return;
      final movies = <int, TmdbMovieDto?>{};
      for (final id in records.map((rating) => rating.movieId).toSet()) {
        if (_movieCache.containsKey(id)) {
          movies[id] = _movieCache[id];
          continue;
        }
        try {
          final movie = await _movieService.fetchMovie(
            id,
            cancelToken: request,
          );
          if (request.isCancelled) return;
          movies[id] = _movieCache[id] = movie;
        } on DioException catch (error) {
          if (request.isCancelled) return;
          if (error.response?.statusCode == 404) _movieCache[id] = null;
        }
      }

      ratings = List.unmodifiable(
        records.map(
          (rating) =>
              RatingWithMovie(rating: rating, movie: movies[rating.movieId]),
        ),
      );
      status = ratings.isEmpty
          ? MyRatingsLoadStatus.empty
          : MyRatingsLoadStatus.success;
    } on DioException catch (error) {
      if (request.isCancelled) return;
      status = MyRatingsLoadStatus.error;
      message = writeMyRatingsErrorMessage(error);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _request?.cancel();
    super.dispose();
  }
}
