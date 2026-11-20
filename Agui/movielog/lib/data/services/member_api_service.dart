import 'package:dio/dio.dart';

import '../models/member_info.dart';

class MemberApiService {
  MemberApiService(this._dio);
  final Dio _dio;
  Future<MemberInfo> fetchMe() async {
    final response = await _dio.get('/v7/members/me');
    return parseMemberInfo(response.data);
  }
}
