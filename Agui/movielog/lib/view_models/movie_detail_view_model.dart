import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/models/rating_request.dart';
import '../data/models/movie_record_request.dart';
import '../data/services/movie_record_api_service.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import 'auth_view_model.dart';
import 'sign_up_view_model.dart';

class RatingSubmissionException implements Exception {
  const RatingSubmissionException(this.message, {this.closeDialog = false});
  final String message;
  final bool closeDialog;
  @override
  String toString() => message;
}

class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(
    this._service,
    this._auth,
    this.movie, {
    this.movieRecordApi,
  });
  final MovieRecordApiService? movieRecordApi;
  final RatingApiService _service;
  final AuthViewModel _auth;
  final TmdbMovieDto movie;
  SubmitStatus submitStatus = SubmitStatus.idle;
  String? submitMessage;
  bool _disposed = false;

  Future<void> createRating({required int score, String? comment}) =>
      _save(score: score, comment: comment);

  Future<void> createMovieRecord({
    required int score,
    String? comment,
    required bool addToFavorites,
  }) => _save(score: score, comment: comment, addToFavorites: addToFavorites);

  Future<void> _save({
    required int score,
    String? comment,
    bool? addToFavorites,
  }) async {
    if (_disposed || submitStatus == SubmitStatus.submitting) {
      throw const RatingSubmissionException('현재 요청을 처리할 수 없습니다.');
    }
    if (_auth.status != AuthStatus.signedIn) {
      throw const RatingSubmissionException('로그인이 필요합니다.');
    }
    final version = _auth.sessionVersion;
    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    notifyListeners();
    try {
      final rating = addToFavorites == null
          ? await _service.createRating(
              CreateRatingRequest(
                movieId: movie.id,
                score: validateServerScore(score.toDouble()),
                comment: comment,
              ),
            )
          : (await movieRecordApi!.createMovieRecord(
              CreateMovieRecordRequest(
                movieId: movie.id,
                score: score,
                comment: comment,
                addToFavorites: addToFavorites,
              ),
            )).rating;
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
      if (error.response?.statusCode == 401 &&
          const {'AUTH401_2', 'AUTH401_3', 'AUTH401_4'}.contains(code)) {
        await _auth.expireSessionIfCurrent(version);
        throw const RatingSubmissionException('로그인이 만료됐어요. 다시 로그인해 주세요.');
      }
      submitMessage = switch (code) {
        'FAVORITE409_1' => '이미 즐겨찾기한 영화입니다. 현재 상태를 확인해 주세요.',
        'MEMBER404_1' => '회원 정보를 찾을 수 없습니다.',
        _ => writeRatingErrorMessage(error, operation: '등록'),
      };
      submitStatus = SubmitStatus.error;
      throw RatingSubmissionException(
        submitMessage!,
        closeDialog: const {
          'RATING409_1',
          'FAVORITE409_1',
          'MEMBER404_1',
        }.contains(code),
      );
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
