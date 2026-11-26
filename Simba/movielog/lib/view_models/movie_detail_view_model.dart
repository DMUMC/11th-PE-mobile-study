import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/models/rating_request.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import 'auth_view_model.dart';
import 'session_ratings_store.dart';
import 'submit_status.dart';

export 'submit_status.dart';

/// 영화 상세 화면 ViewModel. 이 화면에서는 평점 "등록"만 한다.
/// v7: memberId 없이 Authorization 헤더(토큰)로 누구의 요청인지 서버가 판단한다.
class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(
    this._ratingService,
    this._auth,
    this._store,
    this.movie,
  );

  final RatingApiService _ratingService;
  final AuthViewModel _auth;
  final SessionRatingsStore _store;
  final TmdbMovieDto movie;

  SubmitStatus submitStatus = SubmitStatus.idle;
  String? submitMessage;
  bool _disposed = false;

  Future<void> createRating({required int score, String? comment}) async {
    if (submitStatus == SubmitStatus.submitting) return;
    final version = _auth.sessionVersion;
    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    _notify();

    // 로그아웃·계정 전환 뒤 늦게 도착한 응답은 반영하지 않는다.
    bool isStale() => _disposed || version != _auth.sessionVersion;

    try {
      final created = await _ratingService.createRating(
        // body에 memberId는 없다. movieId는 TMDB 영화 id 그대로.
        CreateRatingRequest(movieId: movie.id, score: score, comment: comment),
      );
      if (isStale()) return;
      _store.upsert(created); // 등록 result(Rating 객체)로 내 평점 목록을 갱신
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      if (isStale()) return;
      submitStatus = SubmitStatus.error;
      final code = apiErrorCode(error);
      if (isSessionExpiredCode(code)) {
        submitMessage = '로그인이 만료됐어요.';
        await _auth.expireSession(sessionVersion: version);
        return;
      }
      submitMessage = switch (code) {
        // 409는 로그아웃하지 않고 기존 기록을 확인하게 안내한다.
        'RATING409_1' => '이미 이 영화에 평점을 남기셨어요. 마이페이지에서 기존 기록을 확인해 주세요.',
        _ => writeErrorMessage(error),
      };
    } catch (_) {
      if (isStale()) return;
      submitStatus = SubmitStatus.error;
      submitMessage = '평점 응답을 확인하지 못했어요.';
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
