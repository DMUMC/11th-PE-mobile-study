import 'package:dio/dio.dart';

import '../models/common_response.dart';
import '../models/rating_dto.dart';
import '../models/rating_request.dart';

class RatingApiService {
  RatingApiService(this._publicDio, this._authDio);
  final Dio _publicDio;
  final Dio _authDio;

  RatingDto _parseRating(Object? data) {
    if (data is! Map<String, dynamic>) {
      throw const FormatException('평점 응답 형식이 올바르지 않습니다.');
    }
    final common = CommonResponse<RatingDto>.fromJson(
      data,
      (value) => RatingDto.fromJson(value as Map<String, dynamic>),
    );
    return common.result ?? (throw const FormatException('평점 result가 없습니다.'));
  }

  Future<RatingDto> createRating(CreateRatingRequest request) async {
    final response = await _authDio.post<dynamic>(
      '/v7/ratings',
      data: request.toJson(),
    );
    return _parseRating(response.data);
  }

  Future<RatingDto> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    validateServerScore(score.toDouble());
    final response = await _authDio.patch<dynamic>(
      '/v7/ratings/$ratingId',
      data: {'score': score, 'comment': comment},
    );
    return _parseRating(response.data);
  }

  Future<void> deleteRating(int ratingId) async {
    final response = await _authDio.delete<dynamic>('/v7/ratings/$ratingId');
    if (response.statusCode != 200) {
      throw const RatingWriteException('삭제 결과를 확인하지 못했습니다.');
    }
  }

  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    final response = await _publicDio.get<dynamic>(
      '/v7/members/$memberId/ratings',
    );
    final data = response.data;
    if (data is! List) throw const FormatException('Expected a rating array');
    return data
        .map((item) => RatingDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

class RatingWriteException implements Exception {
  const RatingWriteException(this.message);
  final String message;
  @override
  String toString() => message;
}

String writeRatingErrorMessage(DioException error, {String operation = '수정'}) {
  final data = error.response?.data;
  final code = data is Map ? data['code'] : null;
  return switch (code) {
    'RATING403_1' => '본인이 작성한 평점만 $operation할 수 있습니다.',
    'RATING404_1' => '존재하지 않는 평점입니다.',
    'RATING409_1' => '이미 이 영화에 평점을 남겼어요. 기존 기록을 확인해 주세요.',
    'COMMON400' =>
      data is Map && data['message'] is String
          ? data['message'] as String
          : '별점과 코멘트 입력값을 확인해 주세요.',
    _ => '평점을 $operation하지 못했습니다. 잠시 후 다시 시도해 주세요.',
  };
}
