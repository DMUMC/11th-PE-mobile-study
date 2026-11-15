import 'package:dio/dio.dart';

import '../models/check_result.dart';
import '../models/common_response.dart';
import '../models/create_member_request.dart';
import '../models/sign_up_models.dart';

/// 회원가입 화면이 쓰는 v6 API (6주차 MemberCheckService에서 이름 변경)
class SignUpService {
  SignUpService(this._dio);

  final Dio _dio;

  /// GET /v6/members/nickname/{nickname} — 성공은 직접 객체 { available }
  Future<bool> checkNickname(String nickname) async {
    // 한글·특수문자를 경로에 넣을 수 있도록 인코딩한다.
    final encoded = Uri.encodeComponent(nickname.trim());
    final response = await _dio.get('/v6/members/nickname/$encoded');
    return CheckResult.fromJson(response.data as Map<String, dynamic>)
        .available;
  }

  /// GET /v6/members/email/{email} — 성공은 직접 객체 { available }
  Future<bool> checkEmail(String email) async {
    final encoded = Uri.encodeComponent(email.trim());
    final response = await _dio.get('/v6/members/email/$encoded');
    return CheckResult.fromJson(response.data as Map<String, dynamic>)
        .available;
  }

  /// POST /v6/members — 201 + `CommonResponse<SignUpResult>`
  Future<CommonResponse<SignUpResult>> signUp(
    CreateMemberRequest request,
  ) async {
    final response = await _dio.post('/v6/members', data: request.toJson());
    return CommonResponse<SignUpResult>.fromJson(
      response.data as Map<String, dynamic>,
      (value) => SignUpResult.fromJson(value as Map<String, dynamic>),
    );
  }
}

/// 회원가입 실패(400 형식 위반, 409 중복)의 서버 message를 그대로 쓴다.
String writeSignUpErrorMessage(DioException error) {
  return CommonResponse.tryParseError(error.response?.data)?.message ??
      '회원가입에 실패했습니다. 잠시 후 다시 시도해 주세요.';
}
