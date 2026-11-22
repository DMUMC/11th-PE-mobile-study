import 'package:dio/dio.dart';

import '../models/common_response.dart';
import '../models/rating_dto.dart';
import '../models/rating_request.dart';

/// v7 평점 API. 메서드마다 쓰는 Client가 다르다.
/// - 유저별 평점 조회: 공개 Client (토큰 없음), 200 + 직접 배열
/// - 등록/수정/삭제: 보호 Client (Bearer 토큰), memberId는 요청 어디에도 없다
///   - 등록 201 / 수정 200: CommonResponse, result는 Rating 객체
///   - 삭제 200: CommonResponse, result null (v6의 204가 아님)
class RatingApiService {
  RatingApiService(this._publicDio, this._authDio);

  final Dio _publicDio;
  final Dio _authDio;

  /// GET /v7/members/{memberId}/ratings (공개)
  Future<List<RatingDto>> fetchMemberRatings(int memberId) async {
    final response = await _publicDio.get('/v7/members/$memberId/ratings');
    return parseRatingList(response.data);
  }

  /// POST /v7/ratings
  Future<RatingDto> createRating(CreateRatingRequest request) async {
    final response = await _authDio.post('/v7/ratings', data: request.toJson());
    return parseRatingResult(response.data);
  }

  /// PATCH /v7/ratings/{ratingId}
  /// 부분 수정이 아니라 전체 교체라 comment를 항상 함께 보낸다. (생략하면 null로 덮인다)
  Future<RatingDto> updateRating({
    required int ratingId,
    required UpdateRatingRequest request,
  }) async {
    final response = await _authDio.patch(
      '/v7/ratings/$ratingId',
      data: request.toJson(),
    );
    return parseRatingResult(response.data);
  }

  /// DELETE /v7/ratings/{ratingId}
  Future<void> deleteRating(int ratingId) async {
    final response = await _authDio.delete('/v7/ratings/$ratingId');
    if (response.statusCode != 200) {
      throw StateError('예상하지 못한 삭제 응답: ${response.statusCode}');
    }
  }
}

RatingDto parseRatingResult(Object? data) {
  if (data is! Map<String, dynamic>) {
    throw StateError('평점 응답 형식이 올바르지 않습니다.');
  }
  final common = CommonResponse<RatingDto>.fromJson(
    data,
    (value) => RatingDto.fromJson(value as Map<String, dynamic>),
  );
  final rating = common.result;
  if (rating == null) throw StateError('평점 result가 없습니다.');
  return rating;
}

List<RatingDto> parseRatingList(Object? data) {
  if (data is! List) throw StateError('평점 목록 응답은 배열이어야 합니다.');
  return data
      .map((value) => RatingDto.fromJson(value as Map<String, dynamic>))
      .toList();
}

/// 쓰기 실패의 서버 message를 그대로 쓴다.
String writeErrorMessage(DioException error) {
  return CommonResponse.tryParseError(error.response?.data)?.message ??
      '요청에 실패했습니다. 잠시 후 다시 시도해 주세요.';
}
