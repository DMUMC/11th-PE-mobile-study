import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/models/rating_with_movie.dart';
import '../data/services/rating_api_service.dart';
import 'auth_view_model.dart';

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._service, this._auth) {
    _auth.addListener(_onAuthChanged);
  }
  final RatingApiService _service;
  final AuthViewModel _auth;
  bool _disposed = false;
  bool _isUpdating = false;
  bool isDeletingSelected = false;
  String? refreshWarning;
  String? get message => null;
  List<RatingWithMovie> get ratings => _auth.sessionRatings;
  MyRatingsLoadStatus get status =>
      ratings.isEmpty ? MyRatingsLoadStatus.empty : MyRatingsLoadStatus.success;
  void _onAuthChanged() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    if (!_disposed) notifyListeners();
  }

  bool _current(int version) =>
      !_disposed &&
      version == _auth.sessionVersion &&
      _auth.status == AuthStatus.signedIn;

  Future<void> _handleError(
    DioException error,
    int version,
    String operation,
  ) async {
    if (!_current(version)) throw const RatingWriteException('세션이 변경되었습니다.');
    if (const {
      'AUTH401_2',
      'AUTH401_3',
      'AUTH401_4',
    }.contains(apiErrorCode(error))) {
      await _auth.expireSession();
      throw const RatingWriteException('로그인이 만료됐어요. 다시 로그인해 주세요.');
    }
    throw RatingWriteException(
      writeRatingErrorMessage(error, operation: operation),
    );
  }

  Future<void> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    if (_disposed || _isUpdating || _auth.status != AuthStatus.signedIn) {
      throw const RatingWriteException('평점 요청을 처리할 수 없습니다.');
    }
    final version = _auth.sessionVersion;
    _isUpdating = true;
    try {
      final result = await _service.updateRating(
        ratingId: ratingId,
        score: score,
        comment: comment,
      );
      if (!_current(version)) throw const RatingWriteException('세션이 변경되었습니다.');
      _auth.saveSessionRating(result);
    } on DioException catch (error) {
      await _handleError(error, version, '수정');
    } finally {
      _isUpdating = false;
    }
  }

  Future<void> deleteRating(int ratingId) async {
    if (_disposed || _isUpdating || _auth.status != AuthStatus.signedIn) {
      throw const RatingWriteException('평점 요청을 처리할 수 없습니다.');
    }
    final version = _auth.sessionVersion;
    _isUpdating = true;
    try {
      await _service.deleteRating(ratingId);
      if (!_current(version)) throw const RatingWriteException('세션이 변경되었습니다.');
      _auth.removeSessionRating(ratingId);
    } on DioException catch (error) {
      await _handleError(error, version, '삭제');
    } finally {
      _isUpdating = false;
    }
  }

  Future<Set<int>> deleteSelectedRatings(Set<int> ids) async {
    if (_disposed || _isUpdating || isDeletingSelected || ids.isEmpty) {
      return Set.of(ids);
    }
    final version = _auth.sessionVersion;
    isDeletingSelected = true;
    notifyListeners();
    final failed = <int>{};
    try {
      for (final id in ids) {
        if (!_current(version)) {
          failed.add(id);
          continue;
        }
        try {
          await deleteRating(id);
        } catch (_) {
          failed.add(id);
        }
      }
      return failed;
    } finally {
      isDeletingSelected = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
