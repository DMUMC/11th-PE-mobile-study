import 'package:dio/dio.dart';

import '../models/common_response.dart';
import '../models/login_models.dart';

class AuthApiService {
  AuthApiService(this._dio);
  final Dio _dio;
  Future<LoginResult> login(LoginRequest request) async {
    final response = await _dio.post('/v8/auth/login', data: request.toJson());
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw StateError('로그인 응답 형식이 올바르지 않습니다.');
    }
    final common = CommonResponse<LoginResult>.fromJson(
      data,
      (value) => LoginResult.fromJson(value as Map<String, dynamic>),
    );
    return common.result ?? (throw StateError('로그인 result가 없습니다.'));
  }
}
