import 'package:dio/dio.dart';

import '../models/check_result.dart';
import '../models/common_response.dart';
import '../models/create_member_request.dart';
import '../models/sign_up_models.dart';

class SignUpService {
  SignUpService(this._dio);
  final Dio _dio;

  Future<bool> checkNickname(String nickname) => _check('nickname', nickname);
  Future<bool> checkEmail(String email) => _check('email', email);

  Future<bool> _check(String field, String value) async {
    final encoded = Uri.encodeComponent(value.trim());
    final response = await _dio.get('/v6/members/$field/$encoded');
    if (response.data case final Map<String, dynamic> data
        when data['available'] is bool) {
      return CheckResult.fromJson(data).available;
    }
    throw const FormatException('중복 확인 응답 형식이 올바르지 않습니다.');
  }

  Future<CommonResponse<SignUpResult>> signUp(
    CreateMemberRequest request,
  ) async {
    final response = await _dio.post('/v6/members', data: request.toJson());
    return CommonResponse.requireSuccess(response, 201, SignUpResult.fromJson);
  }
}
