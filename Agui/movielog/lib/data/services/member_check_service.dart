import 'package:dio/dio.dart';

import '../models/check_result.dart';

class MemberCheckService {
  MemberCheckService(this._dio);

  final Dio _dio;

  Future<bool> checkNickname(String nickname) =>
      _check('/v5/members/nickname', nickname);

  Future<bool> checkEmail(String email) => _check('/v5/members/email', email);

  Future<bool> _check(String path, String value) async {
    final encoded = Uri.encodeComponent(value.trim());
    final response = await _dio.get<dynamic>('$path/$encoded');
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Expected an availability object');
    }
    // v5 returns the object directly, without a result wrapper.
    return CheckResult.fromJson(data).available;
  }
}
