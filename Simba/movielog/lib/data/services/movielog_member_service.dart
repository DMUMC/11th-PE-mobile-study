import 'package:dio/dio.dart';

import '../models/availability_dto.dart';
import '../models/rating_dto.dart';

/// MovieLog 자체 API(회원/평점)와 통신하고 응답을 DTO로 바꾸는 일만 담당한다.
class MovieLogMemberService {
  MovieLogMemberService(this._dio);

  final Dio _dio;

  /// GET /members/nickname/{nickname}
  Future<AvailabilityDto> checkNickname(String nickname) async {
    // 한글, 공백 같은 문자를 경로에 넣을 수 있도록 인코딩한다. ('수현' → '%EC%88%98%ED%98%84')
    final response = await _dio.get<Map<String, dynamic>>(
      '/members/nickname/${Uri.encodeComponent(nickname)}',
    );
    return AvailabilityDto.fromJson(response.data ?? const {});
  }

  /// GET /members/email/{email}
  Future<AvailabilityDto> checkEmail(String email) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/members/email/${Uri.encodeComponent(email)}',
    );
    return AvailabilityDto.fromJson(response.data ?? const {});
  }

  /// GET /members/{memberId}/ratings (최신순)
  Future<List<RatingDto>> fetchMemberRatings(int memberId) async {
    final response = await _dio.get<List<dynamic>>('/members/$memberId/ratings');
    return (response.data ?? const [])
        .map((item) => RatingDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
