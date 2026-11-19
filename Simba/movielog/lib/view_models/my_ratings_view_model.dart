import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_request.dart';
import '../data/models/rating_with_movie.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

/// 내가 등록한 평점 화면 ViewModel (조회·수정·삭제).
/// [memberId]는 회원가입 결과의 학습용 ID다. 인증은 아니다.
class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._service, this._movieService, this.memberId);

  final RatingApiService _service;
  final TmdbMovieService _movieService;
  final int memberId;

  /// 같은 movieId는 TMDB에 한 번만 묻는다. (404로 찾지 못한 영화는 null로 캐시)
  final Map<int, TmdbMovieDto?> _movieCache = {};
  int _requestVersion = 0;
  bool _disposed = false;

  List<RatingWithMovie> ratings = const [];
  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;
  String? message;

  /// 쓰기는 성공했는데 그 뒤 목록 GET만 실패한 경우의 안내.
  /// 저장 실패와 구분해서 "조회만" 다시 시도하게 한다.
  String? refreshWarning;

  // ── 조회 ──
  Future<void> load() async {
    final version = ++_requestVersion;
    status = MyRatingsLoadStatus.loading;
    message = null;
    _notify();

    bool isStale() => _disposed || version != _requestVersion;

    try {
      final rawRatings = await _service.fetchMyRatings(memberId);
      if (isStale()) return;

      final entries = <RatingWithMovie>[];
      var missingMovies = 0;
      // 영화 조회 실패가 평점 목록을 지우지 않는다. 평점은 MovieLog 백엔드가 진짜 주인이다.
      for (final rating in rawRatings) {
        if (isStale()) return;
        if (!_movieCache.containsKey(rating.movieId)) {
          try {
            _movieCache[rating.movieId] = await _movieService.findMovieById(
              rating.movieId,
            );
          } on DioException {
            // 일시적 네트워크 실패는 캐시하지 않는다. 다음 로딩에서 다시 시도한다.
          }
        }
        final movie = _movieCache[rating.movieId];
        if (movie == null) missingMovies++;
        entries.add(RatingWithMovie(rating: rating, movie: movie));
      }
      if (isStale()) return;

      ratings = entries;
      refreshWarning = null;
      status = entries.isEmpty
          ? MyRatingsLoadStatus.empty
          : MyRatingsLoadStatus.success;
      if (entries.isEmpty) exitEditMode(notify: false);
      // 목록에서 사라진 평점은 선택에서도 뺀다.
      selectedRatingIds.retainAll(entries.map((e) => e.rating.ratingId));
      if (missingMovies > 0) {
        message = '일부 영화 정보를 가져오지 못해 제목·포스터를 대신 표시합니다.';
      }
    } on DioException catch (error) {
      if (isStale()) return;
      status = MyRatingsLoadStatus.error;
      message = writeMyRatingsErrorMessage(error);
    }

    if (!isStale()) _notify();
  }

  /// 쓰기 성공 뒤 목록을 다시 읽는다. GET 실패는 저장 실패로 던지지 않는다.
  Future<void> _refreshAfterWrite() async {
    await load();
    if (_disposed) return;
    if (status == MyRatingsLoadStatus.error) {
      refreshWarning = '저장은 완료됐지만 목록을 불러오지 못했습니다. 조회만 다시 시도해 주세요.';
      _notify();
    }
  }

  /// 쓰기 실패 처리: 403·404면 목록을 서버 상태와 맞추고, 실패를 호출한 쪽(Dialog)에 다시 던진다.
  Future<Never> _handleWriteError(DioException error) async {
    if (shouldRefreshAfterRatingError(error)) await load();
    throw error;
  }

  // ── 수정 ──
  /// score는 항상 보내고, comment도 명시적으로 보낸다. (생략하면 서버가 후기를 null로 덮는다)
  Future<void> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    try {
      await _service.updateRating(
        memberId: memberId,
        ratingId: ratingId,
        request: UpdateRatingRequest(score: score, comment: comment),
      );
    } on DioException catch (error) {
      await _handleWriteError(error); // 쓰기 실패일 때만 Dialog가 실패로 처리한다.
    }
    await _refreshAfterWrite();
  }

  // ── 단일 삭제 ──
  Future<void> deleteRating(int ratingId) async {
    try {
      await _service.deleteRating(memberId: memberId, ratingId: ratingId);
    } on DioException catch (error) {
      await _handleWriteError(error);
    }
    await _refreshAfterWrite();
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

  void exitEditMode({bool notify = true}) {
    isEditMode = false;
    selectedRatingIds.clear();
    if (notify) _notify();
  }

  void toggleSelection(int ratingId) {
    if (isDeletingSelected) return;
    if (!selectedRatingIds.remove(ratingId)) selectedRatingIds.add(ratingId);
    _notify();
  }

  /// 선택된 평점을 하나씩 지운다. 실패한 항목은 선택 상태로 남겨 다시 시도할 수 있게 한다.
  /// 삭제하지 못한 개수를 돌려준다.
  Future<int> deleteSelectedRatings() async {
    if (isDeletingSelected || selectedRatingIds.isEmpty) return 0;
    isDeletingSelected = true;
    _notify();

    var failed = 0;
    try {
      // 원본 Set을 순회하며 remove하면 ConcurrentModificationError가 나므로 복사본을 돈다.
      for (final ratingId in selectedRatingIds.toList()) {
        if (_disposed) return failed;
        try {
          await _service.deleteRating(memberId: memberId, ratingId: ratingId);
          selectedRatingIds.remove(ratingId);
        } on DioException {
          failed++;
        } on StateError {
          failed++;
        }
      }
    } finally {
      isDeletingSelected = false; // 예상하지 못한 오류에도 로딩을 해제한다.
      _notify();
    }

    await _refreshAfterWrite(); // GET 실패는 삭제 성공 여부와 분리한다.
    if (failed == 0) exitEditMode();
    return failed;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
