import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/token_storage.dart';
import 'api_logging_interceptor.dart';
import 'auth_interceptor.dart';

/// 워크북 자체 백엔드 전용 Dio Client.
/// TMDB Client와 baseUrl·헤더가 다르므로 절대 하나로 합치지 않는다.
BaseOptions _movieLogOptions() {
  return BaseOptions(
    baseUrl: 'https://workbook.devnoco.com',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'accept': 'application/json'},
  );
}

/// 공개 요청용: 로그인, 회원가입, 중복 체크, 유저별 평점 조회 / AuthInterceptor 없음
Dio createMovieLogClient() {
  final dio = Dio(_movieLogOptions());
  if (kDebugMode) {
    dio.interceptors.add(ApiLoggingInterceptor(label: 'MovieLog'));
  }
  return dio;
}

/// 보호 요청용(8주차): 내 정보, 평점 등록/수정/삭제 / AuthInterceptor 등록
Dio createAuthMovieLogClient(TokenStorage storage) {
  final dio = Dio(_movieLogOptions());
  // 토큰을 붙인 뒤에 로그를 남기도록 AuthInterceptor를 먼저 등록한다.
  // (로그는 Authorization을 마스킹한다)
  dio.interceptors.add(AuthInterceptor(storage));
  if (kDebugMode) {
    dio.interceptors.add(ApiLoggingInterceptor(label: 'MovieLog(auth)'));
  }
  return dio;
}
