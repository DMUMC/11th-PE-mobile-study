import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/movielog_config.dart';
import 'api_logging_interceptor.dart';

/// MovieLog 자체 API 전용 Dio Client.
/// TMDB Client와 baseUrl, 인증 방식이 다르므로 분리한다. (7주차에 JWT 헤더가 여기에 추가된다)
Dio createMovieLogClient() {
  final dio = Dio(
    BaseOptions(
      baseUrl: MovieLogConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      headers: {'accept': 'application/json'},
    ),
  );

  if (kDebugMode) {
    debugPrint('[MovieLog 설정] baseUrl=${MovieLogConfig.apiBaseUrl}');
    dio.interceptors.add(ApiLoggingInterceptor(label: 'MovieLog'));
  }

  return dio;
}
