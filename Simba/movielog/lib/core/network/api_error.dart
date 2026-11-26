import 'package:dio/dio.dart';

/// v7 공통 오류 응답 { isSuccess, code, message, result }에서 code를 꺼낸다.
String? apiErrorCode(DioException error) {
  final data = error.response?.data;
  if (data is! Map<String, dynamic>) return null;
  final code = data['code'];
  return code is String ? code : null;
}

/// v7 공통 오류 응답에서 사용자에게 보여줄 message를 꺼낸다.
String? apiErrorMessage(DioException error) {
  final data = error.response?.data;
  if (data is! Map<String, dynamic>) return null;
  final message = data['message'];
  return message is String ? message : null;
}

/// 보호 요청에서 토큰이 없음/무효/만료인 경우. 현재 세션을 정리할 후보다.
/// (로그인 실패 AUTH401_1은 로그인 Form 오류라 여기에 포함하지 않는다)
bool isSessionExpiredCode(String? code) =>
    code == 'AUTH401_2' || code == 'AUTH401_3' || code == 'AUTH401_4';
