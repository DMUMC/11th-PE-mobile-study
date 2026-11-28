import 'package:dio/dio.dart';

import '../models/member_info.dart';

class MemberApiService {
  MemberApiService(this._dio);
  final Dio _dio;
  Future<MemberInfo> fetchMe() async {
    final response = await _dio.get('/v8/members/me');
    return parseMemberInfo(response.data);
  }

  Future<MemberInfo> updateNickname(String nickname) async {
    final response = await _dio.patch(
      '/v8/members/me',
      data: {'nickname': nickname},
    );
    return parseMemberInfo(response.data);
  }
}
