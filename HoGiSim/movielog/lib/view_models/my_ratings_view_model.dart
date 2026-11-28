import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_with_movie.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._service, this._movieService, this.memberId);

  final RatingApiService _service;
  final TmdbMovieService _movieService;
  final int memberId;
  final _movieCache = <int, TmdbMovieDto?>{};
  final _selectedRatingIds = <int>{};
  CancelToken? _request;
  bool _disposed = false;

  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;
  List<RatingWithMovie> ratings = const [];
  String? message;
  String? _refreshWarning;
  bool isWriting = false;
  bool isSelecting = false;
  bool isDeletingSelected = false;

  int get selectedCount => _selectedRatingIds.length;
  bool isSelected(int ratingId) => _selectedRatingIds.contains(ratingId);

  Future<void> load() async {
    if (isWriting || status == MyRatingsLoadStatus.loading) return;
    await _load();
  }

  Future<void> _load() async {
    if (_disposed) return;
    final request = _request = CancelToken();
    status = MyRatingsLoadStatus.loading;
    message = null;
    notifyListeners();

    try {
      final records = await _service.fetchMyRatings(
        memberId,
        cancelToken: request,
      );
      if (_disposed) return;
      for (final id in records.map((rating) => rating.movieId).toSet()) {
        if (_movieCache.containsKey(id)) continue;
        try {
          final movie = await _movieService.fetchMovie(
            id,
            cancelToken: request,
          );
          if (_disposed) return;
          _movieCache[id] = movie;
        } catch (error) {
          if (_disposed) return;
          if (error is DioException && error.response?.statusCode == 404) {
            _movieCache[id] = null;
          }
        }
      }

      ratings = List.unmodifiable(
        records.map(
          (rating) => RatingWithMovie(
            rating: rating,
            movie: _movieCache[rating.movieId],
          ),
        ),
      );
      final ratingIds = records.map((rating) => rating.ratingId).toSet();
      _selectedRatingIds.retainAll(ratingIds);
      if (ratings.isEmpty) isSelecting = false;
      _refreshWarning = null;
      status = ratings.isEmpty
          ? MyRatingsLoadStatus.empty
          : MyRatingsLoadStatus.success;
    } catch (error) {
      if (_disposed) return;
      status = MyRatingsLoadStatus.error;
      message = _refreshWarning ?? writeMyRatingsErrorMessage(error);
    }
    notifyListeners();
  }

  void toggleSelectionMode() {
    if (isWriting || status != MyRatingsLoadStatus.success) return;
    isSelecting = !isSelecting;
    _selectedRatingIds.clear();
    notifyListeners();
  }

  void toggleSelection(int ratingId) {
    if (isWriting || !isSelecting || !_owns(ratingId)) return;
    if (!_selectedRatingIds.remove(ratingId)) _selectedRatingIds.add(ratingId);
    notifyListeners();
  }

  bool _owns(int ratingId) =>
      ratings.any((entry) => entry.rating.ratingId == ratingId);

  Future<void> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) => _writeRating(
    ratingId,
    () => _service.updateRating(
      memberId: memberId,
      ratingId: ratingId,
      score: score,
      comment: comment,
    ),
  );

  Future<void> deleteRating(int ratingId) => _writeRating(ratingId, () async {
    await _service.deleteRating(memberId: memberId, ratingId: ratingId);
    if (!_disposed) _removeRating(ratingId);
  });

  Future<void> _writeRating(int ratingId, Future<void> Function() write) async {
    if (_disposed ||
        isWriting ||
        status != MyRatingsLoadStatus.success ||
        !_owns(ratingId)) {
      throw StateError('이 평점을 수정하거나 삭제할 수 없습니다.');
    }
    isWriting = true;
    notifyListeners();
    try {
      await write();
      await _refreshAfterWrite();
    } catch (error) {
      if (shouldRefreshAfterRatingError(error)) await _load();
      rethrow;
    } finally {
      isWriting = false;
      if (!_disposed) notifyListeners();
    }
  }

  void _removeRating(int ratingId) {
    ratings = List.unmodifiable(
      ratings.where((entry) => entry.rating.ratingId != ratingId),
    );
    _selectedRatingIds.remove(ratingId);
  }

  Future<void> _refreshAfterWrite() async {
    if (_disposed) return;
    _refreshWarning = '저장은 완료됐지만 목록을 불러오지 못했습니다. 조회만 다시 시도해 주세요.';
    await _load();
  }

  Future<int> deleteSelectedRatings() async {
    if (_disposed ||
        isWriting ||
        !isSelecting ||
        status != MyRatingsLoadStatus.success ||
        _selectedRatingIds.isEmpty) {
      return 0;
    }
    final ids = _selectedRatingIds.toList();
    var failed = 0;
    isWriting = true;
    isDeletingSelected = true;
    notifyListeners();
    try {
      for (final id in ids) {
        if (_disposed) break;
        try {
          await _service.deleteRating(memberId: memberId, ratingId: id);
          if (!_disposed) _removeRating(id);
        } catch (_) {
          failed++;
        }
      }
      if (!_disposed) {
        if (_selectedRatingIds.isEmpty) isSelecting = false;
        if (failed < ids.length) {
          await _refreshAfterWrite();
        } else {
          await _load();
        }
      }
    } finally {
      isDeletingSelected = false;
      isWriting = false;
      if (!_disposed) notifyListeners();
    }
    return failed;
  }

  @override
  void dispose() {
    _disposed = true;
    _request?.cancel();
    super.dispose();
  }
}
