import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/models/rating_request.dart';
import '../data/models/rating_with_movie.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import 'auth_view_model.dart';
import 'session_ratings_store.dart';

/// 내가 등록한 평점 화면 ViewModel (수정·삭제).
///
/// v7 한계: 토큰 기반 "내 평점 목록 GET"이 없고 로그인 응답에 memberId도 없다.
/// 그래서 현재 로그인 세션에서 등록한 평점([SessionRatingsStore])만 보여주고,
/// 수정·삭제 응답으로 목록을 갱신한다. 재시작 뒤 전체 복원은 하지 않는다.
class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(
    this._service,
    this._movieService,
    this._store,
    this._auth,
  ) {
    _store.addListener(_onStoreChanged);
    _loadMissingMovies();
  }

  final RatingApiService _service;
  final TmdbMovieService _movieService;
  final SessionRatingsStore _store;
  final AuthViewModel _auth;

  /// 같은 movieId는 TMDB에 한 번만 묻는다. (404로 찾지 못한 영화는 null로 캐시)
  final Map<int, TmdbMovieDto?> _movieCache = {};
  final Set<int> _loadingMovieIds = {};
  bool _disposed = false;

  /// 평점(MovieLog)과 영화 정보(TMDB)를 movieId로 결합한다.
  /// TMDB에서 찾지 못해도 평점은 남기고 제목·포스터만 placeholder로 보여준다.
  List<RatingWithMovie> get ratings => [
    for (final rating in _store.ratings)
      RatingWithMovie(rating: rating, movie: _movieCache[rating.movieId]),
  ];

  bool get isEmpty => _store.isEmpty;

  void _onStoreChanged() {
    selectedRatingIds.retainAll(_store.ratings.map((r) => r.ratingId));
    if (_store.isEmpty) isEditMode = false;
    _loadMissingMovies();
    _notify();
  }

  Future<void> _loadMissingMovies() async {
    final missing = _store.ratings
        .map((r) => r.movieId)
        .where(
          (id) =>
              !_movieCache.containsKey(id) && !_loadingMovieIds.contains(id),
        )
        .toSet();
    for (final movieId in missing) {
      _loadingMovieIds.add(movieId);
      try {
        _movieCache[movieId] = await _movieService.findMovieById(movieId);
      } on DioException {
        // 일시적 네트워크 실패는 캐시하지 않는다. 다음 갱신에서 다시 시도한다.
      } finally {
        _loadingMovieIds.remove(movieId);
      }
      if (_disposed) return;
      _notify();
    }
  }

  /// 쓰기 실패 공통 처리. 처리 결과에 따라 화면 안내가 달라진다.
  /// - AUTH401_2/3/4: 세션 정리 → Router가 /login으로 이동
  /// - RATING404_1: 이미 없는 평점이므로 목록에서 뺀다
  /// - RATING403_1 등: 안내만 하고 로그아웃하지 않는다
  Future<void> _handleWriteError(
    DioException error,
    int version,
    int ratingId,
  ) async {
    final code = apiErrorCode(error);
    if (isSessionExpiredCode(code)) {
      await _auth.expireSession(sessionVersion: version);
    } else if (code == 'RATING404_1' && version == _auth.sessionVersion) {
      _store.remove(ratingId);
    }
  }

  // ── 수정 ──
  /// PATCH는 전체 교체라 score와 comment를 항상 함께 보낸다.
  Future<void> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    final version = _auth.sessionVersion;
    try {
      final updated = await _service.updateRating(
        ratingId: ratingId,
        request: UpdateRatingRequest(score: score, comment: comment),
      );
      if (_disposed || version != _auth.sessionVersion) return;
      _store.upsert(updated); // 수정 result(Rating 객체)로 갱신
    } on DioException catch (error) {
      await _handleWriteError(error, version, ratingId);
      rethrow; // Dialog가 실패 문구를 보여주고 입력을 유지한다.
    }
  }

  // ── 단일 삭제 ──
  Future<void> deleteRating(int ratingId) async {
    final version = _auth.sessionVersion;
    try {
      await _service.deleteRating(ratingId);
      if (_disposed || version != _auth.sessionVersion) return;
      _store.remove(ratingId);
    } on DioException catch (error) {
      await _handleWriteError(error, version, ratingId);
      rethrow;
    }
  }

  // ── 다중 선택 삭제 (Challenge) ──
  bool isEditMode = false;
  final Set<int> selectedRatingIds = {};
  bool isDeletingSelected = false;

  void enterEditMode() {
    isEditMode = true;
    selectedRatingIds.clear();
    _notify();
  }

  void exitEditMode() {
    isEditMode = false;
    selectedRatingIds.clear();
    _notify();
  }

  void toggleSelection(int ratingId) {
    if (isDeletingSelected) return;
    if (!selectedRatingIds.remove(ratingId)) selectedRatingIds.add(ratingId);
    _notify();
  }

  /// 선택된 평점을 하나씩 지운다. 실패한 항목은 선택 상태로 남긴다.
  /// 삭제하지 못한 개수를 돌려준다.
  Future<int> deleteSelectedRatings() async {
    if (isDeletingSelected || selectedRatingIds.isEmpty) return 0;
    final version = _auth.sessionVersion;
    isDeletingSelected = true;
    _notify();

    var failed = 0;
    try {
      // 원본 Set을 순회하며 remove하면 ConcurrentModificationError가 나므로 복사본을 돈다.
      for (final ratingId in selectedRatingIds.toList()) {
        if (_disposed || version != _auth.sessionVersion) return failed;
        try {
          await _service.deleteRating(ratingId);
          selectedRatingIds.remove(ratingId);
          _store.remove(ratingId);
        } on DioException catch (error) {
          final code = apiErrorCode(error);
          if (isSessionExpiredCode(code)) {
            // 세션이 끝났으면 남은 요청을 보내지 않는다.
            await _auth.expireSession(sessionVersion: version);
            return failed + selectedRatingIds.length;
          }
          if (code == 'RATING404_1') {
            selectedRatingIds.remove(ratingId); // 이미 없는 평점은 목록에서 뺀다
            _store.remove(ratingId);
          } else {
            failed++;
          }
        } on StateError {
          failed++;
        }
      }
    } finally {
      isDeletingSelected = false; // 예상하지 못한 오류에도 로딩을 해제한다.
      _notify();
    }
    if (failed == 0) exitEditMode();
    return failed;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }
}
