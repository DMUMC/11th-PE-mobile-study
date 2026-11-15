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
  bool _isUpdating = false;
  bool isDeletingSelected = false;
  String? refreshWarning;

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
      refreshWarning = null;
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
    } catch (_) {
      if (!_isCurrent(version)) return;
      _status = MyRatingsLoadStatus.error;
      _message = '평점 정보를 불러오지 못했습니다. 조회를 다시 시도해 주세요.';
    }

    if (_isCurrent(version)) notifyListeners();
  }

  Future<void> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    if (_disposed || _isUpdating) {
      throw const RatingWriteException('수정 요청을 처리 중입니다.');
    }
    _isUpdating = true;
    try {
      await _service.updateRating(
        memberId: memberId,
        ratingId: ratingId,
        score: score,
        comment: comment,
      );
    } on DioException catch (error) {
      if (_disposed) return;
      final message = writeRatingErrorMessage(error);
      if (error.response?.statusCode == 403 ||
          error.response?.statusCode == 404) {
        await load();
      }
      throw RatingWriteException(message);
    } on RatingWriteException {
      rethrow;
    } catch (_) {
      if (_disposed) return;
      throw const RatingWriteException('수정 결과를 확인하지 못했습니다. 목록을 다시 조회해 주세요.');
    } finally {
      _isUpdating = false;
    }
    if (_disposed) return;
    await load();
    if (_disposed) return;
    if (_status == MyRatingsLoadStatus.error) {
      refreshWarning = '수정은 완료됐지만 목록을 불러오지 못했습니다. 조회만 다시 시도해 주세요.';
      notifyListeners();
    }
  }

  Future<void> deleteRating(int ratingId) async {
    if (_disposed || _isUpdating) {
      throw const RatingWriteException('평점 요청을 처리 중입니다.');
    }
    _isUpdating = true;
    try {
      await _service.deleteRating(memberId: memberId, ratingId: ratingId);
    } on DioException catch (error) {
      if (_disposed) return;
      final message = writeRatingErrorMessage(error, operation: '삭제');
      if (error.response?.statusCode == 403 ||
          error.response?.statusCode == 404) {
        await load();
      }
      throw RatingWriteException(message);
    } on RatingWriteException {
      rethrow;
    } catch (_) {
      if (_disposed) return;
      throw const RatingWriteException('삭제 결과를 확인하지 못했습니다. 목록을 다시 조회해 주세요.');
    } finally {
      _isUpdating = false;
    }
    if (_disposed) return;
    await load();
    if (_disposed) return;
    if (_status == MyRatingsLoadStatus.error) {
      refreshWarning = '삭제는 완료됐지만 목록을 불러오지 못했습니다. 조회만 다시 시도해 주세요.';
      notifyListeners();
    }
  }

  Future<Set<int>> deleteSelectedRatings(Set<int> ratingIds) async {
    if (_disposed || _isUpdating || isDeletingSelected || ratingIds.isEmpty) {
      return Set.of(ratingIds);
    }
    isDeletingSelected = true;
    _isUpdating = true;
    refreshWarning = null;
    notifyListeners();
    final failed = <int>{};
    final deleted = <int>{};
    try {
      for (final id in ratingIds.toList()) {
        if (_disposed) break;
        try {
          await _service.deleteRating(memberId: memberId, ratingId: id);
          deleted.add(id);
        } catch (_) {
          failed.add(id);
        }
      }
      if (_disposed) return failed;
      // 재조회가 실패하더라도 삭제 성공 항목은 다시 선택하지 않습니다.
      _ratings = List.unmodifiable(
        _ratings.where((entry) => !deleted.contains(entry.rating.ratingId)),
      );
      await load();
      if (_disposed) return failed;
      if (_status == MyRatingsLoadStatus.error) {
        refreshWarning = '삭제 요청이 완료됐지만 목록을 불러오지 못했습니다. 조회만 다시 시도해 주세요.';
      }
      return failed;
    } finally {
      _isUpdating = false;
      isDeletingSelected = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
