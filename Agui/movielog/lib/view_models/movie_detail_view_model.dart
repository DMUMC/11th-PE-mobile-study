import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_request.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import 'sign_up_view_model.dart';

class RatingSubmissionException implements Exception {
  const RatingSubmissionException(this.message);
  final String message;
  @override
  String toString() => message;
}

class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(this._service, this.memberId, this.movie);
  final RatingApiService _service;
  final int? memberId;
  final TmdbMovieDto movie;
  SubmitStatus submitStatus = SubmitStatus.idle;
  String? submitMessage;
  bool _disposed = false;

  Future<void> createRating({required int score, String? comment}) async {
    if (submitStatus == SubmitStatus.submitting) return;
    if (memberId == null) {
      throw const RatingSubmissionException('먼저 회원가입을 완료해 주세요.');
    }
    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    notifyListeners();
    try {
      await _service.createRating(
        memberId: memberId!,
        request: CreateRatingRequest(
          movieId: movie.id,
          score: validateServerScore(score.toDouble()),
          comment: comment,
        ),
      );
      if (_disposed) return;
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      if (_disposed) return;
      final data = error.response?.data;
      submitMessage = data is Map && data['message'] is String
          ? data['message'] as String
          : '평점을 저장하지 못했습니다. 잠시 후 다시 시도해 주세요.';
      submitStatus = SubmitStatus.error;
      throw RatingSubmissionException(submitMessage!);
    } catch (_) {
      if (_disposed) return;
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
