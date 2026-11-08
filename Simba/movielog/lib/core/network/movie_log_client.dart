import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_logging_interceptor.dart';

/// 워크북 자체 백엔드(`/v5`) 전용 Dio Client.
/// TMDB Client와 baseUrl·헤더가 다르므로 절대 하나로 합치지 않는다.
Dio createMovieLogClient() {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://workbook.devnoco.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'accept': 'application/json'},
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(ApiLoggingInterceptor(label: 'MovieLog'));
  }

  return dio;
}
