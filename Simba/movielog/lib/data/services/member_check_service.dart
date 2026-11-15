import 'package:dio/dio.dart';

import '../models/check_result.dart';

/// 워크북 v5 닉네임/이메일 중복 체크 API와 통신한다.
class MemberCheckService {
  MemberCheckService(this._dio);

  final Dio _dio;

  /// GET /v5/members/nickname/{nickname}
  Future<bool> checkNickname(String nickname) async {
    // 한글·특수문자를 경로에 넣을 수 있도록 인코딩한다. ('영화광' → '%EC%98%81...')
    final encoded = Uri.encodeComponent(nickname.trim());
    final response = await _dio.get('/v5/members/nickname/$encoded');
    return CheckResult.fromJson(response.data as Map<String, dynamic>).available;
  }

  /// GET /v5/members/email/{email}
  Future<bool> checkEmail(String email) async {
    final encoded = Uri.encodeComponent(email.trim());
    final response = await _dio.get('/v5/members/email/$encoded');
    return CheckResult.fromJson(response.data as Map<String, dynamic>).available;
  }
}
