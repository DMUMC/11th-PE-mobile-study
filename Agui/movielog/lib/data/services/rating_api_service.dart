import 'package:dio/dio.dart';

import '../models/rating_dto.dart';
import '../models/common_response.dart';
import '../models/rating_request.dart';

class RatingApiService {
  RatingApiService(this._dio);

  final Dio _dio;

  Future<void> createRating({
    required int memberId,
    required CreateRatingRequest request,
  }) async {
    final response = await _dio.post<dynamic>(
      '/v6/members/$memberId/ratings',
      data: request.toJson(),
    );
    if (response.statusCode != 201) {
      throw StateError('예상하지 못한 등록 응답: ${response.statusCode}');
    }
  }

  Future<void> updateRating({
    required int memberId,
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    validateServerScore(score.toDouble());
    final response = await _dio.patch<dynamic>(
      '/v6/members/$memberId/ratings/$ratingId',
      data: {'score': score, 'comment': comment},
    );
    final common = CommonResponse<Object?>.fromJson(
      response.data as Map<String, dynamic>,
      (value) => value,
    );
    if (response.statusCode != 200 || !common.isSuccess) {
      throw RatingWriteException(common.message);
    }
  }

  Future<void> deleteRating({
    required int memberId,
    required int ratingId,
  }) async {
    final response = await _dio.delete<dynamic>(
      '/v6/members/$memberId/ratings/$ratingId',
    );
    // 204는 응답 본문이 없으므로 JSON으로 파싱하지 않습니다.
    if (response.statusCode != 204) {
      throw const RatingWriteException('삭제 결과를 확인하지 못했습니다. 목록을 다시 조회해 주세요.');
    }
  }

  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    final response = await _dio.get<dynamic>('/v6/members/$memberId/ratings');
    final data = response.data;
    if (data is! List) throw const FormatException('Expected a rating array');
    return data.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Expected a rating object');
      }
      return RatingDto.fromJson(item);
    }).toList();
  }
}

String writeMyRatingsErrorMessage(DioException error) =>
    switch (error.response?.statusCode) {
      400 => 'memberId 형식을 다시 확인해 주세요.',
      404 => '존재하지 않는 회원입니다.',
      _ => '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.',
    };

class RatingWriteException implements Exception {
  const RatingWriteException(this.message);
  final String message;
  @override
  String toString() => message;
}

String writeRatingErrorMessage(DioException error, {String operation = '수정'}) {
  final data = error.response?.data;
  if (data is Map && data['message'] is String) {
    return data['message'] as String;
  }
  return switch (error.response?.statusCode) {
    400 => '별점과 코멘트 입력값을 확인해 주세요.',
    403 => '본인이 작성한 평점만 $operation할 수 있습니다.',
    404 => '존재하지 않는 평점입니다.',
    409 => '평점 상태가 변경됐습니다. 다시 확인해 주세요.',
    _ => '평점을 $operation하지 못했습니다. 잠시 후 다시 시도해 주세요.',
  };
}
