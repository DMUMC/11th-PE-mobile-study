import '../models/common_response.dart';
import '../models/create_member_request.dart';
import '../models/sign_up_models.dart';

import 'package:dio/dio.dart';

import '../models/check_result.dart';

class SignUpService {
  SignUpService(this._dio);

  final Dio _dio;

  Future<CommonResponse<SignUpResult>> signUp(
    CreateMemberRequest request,
  ) async {
    final response = await _dio.post<dynamic>(
      '/v6/members',
      data: request.toJson(),
    );
    return CommonResponse.fromJson(
      response.data as Map<String, dynamic>,
      (value) => SignUpResult.fromJson(value as Map<String, dynamic>),
    );
  }

  Future<bool> checkNickname(String nickname) =>
      _check('/v6/members/nickname', nickname);

  Future<bool> checkEmail(String email) => _check('/v6/members/email', email);

  Future<bool> _check(String path, String value) async {
    final encoded = Uri.encodeComponent(value.trim());
    final response = await _dio.get<dynamic>('$path/$encoded');
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Expected an availability object');
    }
    // v6 returns the object directly, without a result wrapper.
    return CheckResult.fromJson(data).available;
  }
}
