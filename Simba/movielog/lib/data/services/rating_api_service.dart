import 'package:dio/dio.dart';

import '../models/common_response.dart';
import '../models/rating_dto.dart';
import '../models/rating_request.dart';

/// 워크북 v6 평점 API와 통신한다. 응답 형식이 API마다 다르다.
/// - 조회: 200 + 직접 배열
/// - 등록: 201 + CommonResponse (result 계약이 확정되지 않아 파싱하지 않음)
/// - 수정: 200 + CommonResponse (result null)
/// - 삭제: 204 + body 없음 (JSON 파싱 금지)
class RatingApiService {
  RatingApiService(this._dio);

  final Dio _dio;

  /// GET /v6/members/{memberId}/ratings
  /// 결과가 없으면 빈 배열(실패 아님), 없는 유저는 404.
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    final response = await _dio.get('/v6/members/$memberId/ratings');
    final list = response.data as List<dynamic>;
    return list
        .map((item) => RatingDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// POST /v6/members/{memberId}/ratings
  Future<void> createRating({
    required int memberId,
    required CreateRatingRequest request,
  }) async {
    final response = await _dio.post(
      '/v6/members/$memberId/ratings',
      data: request.toJson(),
    );
    // Swagger 설명(ratingId 숫자)과 예시(null)가 달라 result는 파싱하지 않는다.
    // 등록 뒤에는 GET으로 목록을 다시 확인한다.
    if (response.statusCode != 201) {
      throw StateError('예상하지 못한 등록 응답: ${response.statusCode}');
    }
  }

  /// PATCH /v6/members/{memberId}/ratings/{ratingId}
  Future<void> updateRating({
    required int memberId,
    required int ratingId,
    required UpdateRatingRequest request,
  }) async {
    final response = await _dio.patch(
      '/v6/members/$memberId/ratings/$ratingId',
      data: request.toJson(),
    );
    if (response.statusCode != 200) {
      throw StateError('예상하지 못한 수정 응답: ${response.statusCode}');
    }
  }

  /// DELETE /v6/members/{memberId}/ratings/{ratingId}
  Future<void> deleteRating({
    required int memberId,
    required int ratingId,
  }) async {
    // 204는 body가 없으므로 response.data를 Map으로 다루지 않는다.
    final response = await _dio.delete(
      '/v6/members/$memberId/ratings/$ratingId',
    );
    if (response.statusCode != 204) {
      throw StateError('예상하지 못한 삭제 응답: ${response.statusCode}');
    }
  }
}

/// 평점 조회 실패를 상태 코드별 안내 문구로 바꾼다.
String writeMyRatingsErrorMessage(DioException error) {
  final status = error.response?.statusCode;
  if (status == 400) return 'memberId 형식을 다시 확인해 주세요.';
  if (status == 404) return '존재하지 않는 회원입니다.';
  return '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
}

/// 쓰기 실패의 서버 message를 그대로 쓴다.
/// 같은 COMMON404라도 등록은 "유저", 수정·삭제는 "평점"을 가리키므로
/// code만 보고 문구를 새로 만들지 않는다.
String writeErrorMessage(DioException error) {
  return CommonResponse.tryParseError(error.response?.data)?.message ??
      '요청에 실패했습니다. 잠시 후 다시 시도해 주세요.';
}

/// code는 문구가 아니라 다음 UI 행동을 정하는 데만 쓴다.
/// 403·404는 화면의 목록이 서버 상태와 어긋났다는 뜻이라 다시 조회한다.
/// 400(값 오류)·409(중복)는 값만 고쳐 다시 시도하면 되므로 조회하지 않는다.
bool shouldRefreshAfterRatingError(DioException error) {
  final code = CommonResponse.tryParseError(error.response?.data)?.code;
  return code == 'COMMON403' || code == 'COMMON404';
}
