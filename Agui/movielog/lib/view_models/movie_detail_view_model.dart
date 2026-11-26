import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/models/rating_request.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import 'auth_view_model.dart';
import 'sign_up_view_model.dart';

class RatingSubmissionException implements Exception {
  const RatingSubmissionException(this.message);
  final String message;
  @override
  String toString() => message;
}

class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(this._service, this._auth, this.movie);
  final RatingApiService _service;
  final AuthViewModel _auth;
  final TmdbMovieDto movie;
  SubmitStatus submitStatus = SubmitStatus.idle;
  String? submitMessage;
  bool _disposed = false;

  Future<void> createRating({required int score, String? comment}) async {
    if (submitStatus == SubmitStatus.submitting) return;
    if (_auth.status != AuthStatus.signedIn) {
      throw const RatingSubmissionException('로그인이 필요합니다.');
    }
    final version = _auth.sessionVersion;
    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    notifyListeners();
    try {
      final rating = await _service.createRating(
        CreateRatingRequest(
          movieId: movie.id,
          score: validateServerScore(score.toDouble()),
          comment: comment,
        ),
      );
      if (_disposed ||
          version != _auth.sessionVersion ||
          _auth.status != AuthStatus.signedIn) {
        throw const RatingSubmissionException('세션이 변경되어 요청 결과를 반영하지 않았습니다.');
      }
      _auth.saveSessionRating(rating, movie: movie);
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      if (_disposed ||
          version != _auth.sessionVersion ||
          _auth.status != AuthStatus.signedIn) {
        throw const RatingSubmissionException('세션이 변경되어 요청 결과를 반영하지 않았습니다.');
      }
      final code = apiErrorCode(error);
      if (const {'AUTH401_2', 'AUTH401_3', 'AUTH401_4'}.contains(code)) {
        await _auth.expireSession();
        throw const RatingSubmissionException('로그인이 만료됐어요. 다시 로그인해 주세요.');
      }
      submitMessage = writeRatingErrorMessage(error, operation: '등록');
      submitStatus = SubmitStatus.error;
      throw RatingSubmissionException(submitMessage!);
    } on RatingSubmissionException {
      rethrow;
    } catch (_) {
      if (_disposed || version != _auth.sessionVersion) {
        throw const RatingSubmissionException('세션이 변경되어 요청 결과를 반영하지 않았습니다.');
      }
      submitMessage = '평점을 저장하지 못했습니다. 잠시 후 다시 시도해 주세요.';
      submitStatus = SubmitStatus.error;
      throw RatingSubmissionException(submitMessage!);
    } finally {
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
