import 'package:dio/dio.dart';

import '../models/common_response.dart';
import '../models/rating_dto.dart';
import '../models/rating_request.dart';

class RatingApiService {
  RatingApiService(this._dio);
  final Dio _dio;

  String _ratingsPath(int memberId) => '/v6/members/$memberId/ratings';

  Future<List<RatingDto>> fetchMyRatings(
    int memberId, {
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get(
      _ratingsPath(memberId),
      cancelToken: cancelToken,
    );
    return (response.data as List<dynamic>)
        .map((item) => RatingDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> createRating({
    required int memberId,
    required CreateRatingRequest request,
  }) async {
    final response = await _dio.post(
      _ratingsPath(memberId),
      data: request.toJson(),
    );
    CommonResponse.requireSuccess(response, 201, (value) => value);
  }

  Future<void> updateRating({
    required int memberId,
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    final response = await _dio.patch(
      '${_ratingsPath(memberId)}/$ratingId',
      data: {
        'score': validateServerScore(score.toDouble()),
        'comment': comment,
      },
    );
    CommonResponse.requireSuccess(response, 200, (value) => value);
  }

  Future<void> deleteRating({
    required int memberId,
    required int ratingId,
  }) async {
    final response = await _dio.delete('${_ratingsPath(memberId)}/$ratingId');
    if (response.statusCode != 204) {
      throw const FormatException('삭제 응답을 확인하지 못했습니다.');
    }
  }
}

String writeRatingErrorMessage(Object error) =>
    CommonResponse.errorFrom(error)?.message ??
    switch (error is DioException ? error.response?.statusCode : null) {
      400 => '별점과 코멘트 형식을 확인해 주세요.',
      403 => '본인이 작성한 평점만 수정하거나 삭제할 수 있습니다.',
      404 => '요청한 회원 또는 평점이 존재하지 않습니다.',
      409 => '이미 이 영화에 평점을 남기셨습니다.',
      _ => '평점 요청에 실패했습니다. 잠시 후 다시 시도해 주세요.',
    };

bool shouldRefreshAfterRatingError(Object error) =>
    switch (CommonResponse.errorFrom(error)?.code) {
      'COMMON403' || 'COMMON404' => true,
      _ =>
        error is DioException &&
            (error.response?.statusCode == 403 ||
                error.response?.statusCode == 404),
    };

String writeMyRatingsErrorMessage(Object error) =>
    CommonResponse.errorFrom(error)?.message ??
    switch (error is DioException ? error.response?.statusCode : null) {
      400 => '회원 ID 형식을 다시 확인해 주세요.',
      404 => '존재하지 않는 회원입니다.',
      _ => '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.',
    };
