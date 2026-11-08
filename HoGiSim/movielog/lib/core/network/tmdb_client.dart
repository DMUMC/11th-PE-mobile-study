import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/tmdb_config.dart';
import 'tmdb_logging_interceptor.dart';

Dio createTmdbClient() {
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
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (TmdbConfig.accessToken.isEmpty) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.unknown,
              error: const TmdbConfigurationException(),
            ),
          );
          return;
        }
        handler.next(options);
      },
    ),
  );
  if (kDebugMode) dio.interceptors.add(TmdbLoggingInterceptor());
  return dio;
}

class TmdbConfigurationException implements Exception {
  const TmdbConfigurationException();
}
