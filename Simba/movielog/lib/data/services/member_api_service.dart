import 'package:dio/dio.dart';

import '../models/member_info.dart';

/// 내 정보 (보호 Client 사용 — AuthInterceptor가 Bearer 토큰을 붙인다)
class MemberApiService {
  MemberApiService(this._authDio);

  final Dio _authDio;

  /// GET /v7/members/me
  Future<MemberInfo> fetchMe() async {
    final response = await _authDio.get('/v7/members/me');
    return parseMemberInfo(response.data);
  }

  /// PATCH /v7/members/me — 성공 result가 최신 내 정보다.
  Future<MemberInfo> updateNickname(String nickname) async {
    final response = await _authDio.patch(
      '/v7/members/me',
      data: {'nickname': nickname},
    );
    return parseMemberInfo(response.data);
  }
}
