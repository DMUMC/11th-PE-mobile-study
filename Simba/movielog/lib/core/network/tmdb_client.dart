import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/tmdb_config.dart';
import 'tmdb_logging_interceptor.dart';

/// TMDB 전용 Dio Client.
/// MovieLog 자체 API와 인증 방식이 다르므로 별도의 Client로 분리한다.
Dio createTmdbClient() {
  if (!TmdbConfig.hasAccessToken) {
    debugPrint('[TMDB 설정] TMDB_ACCESS_TOKEN이 비어 있어요. .env 파일을 확인해 주세요.');
  }

  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.themoviedb.org/3',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Authorization': 'Bearer ${TmdbConfig.accessToken}',
        'accept': 'application/json',
      },
    ),
  );

  // 로그는 개발 중 확인 용도이므로 debug 모드에서만 등록한다.
  if (kDebugMode) {
    dio.interceptors.add(TmdbLoggingInterceptor());
  }

  return dio;
}
