import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'auth_interceptor.dart';

Dio createMovieLogClient() => Dio(
  BaseOptions(
    baseUrl: const String.fromEnvironment(
      'MOVIE_LOG_BASE_URL',
      defaultValue: 'https://workbook.devnoco.com',
    ),
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ),
);

Dio createAuthMovieLogClient(TokenStorage storage) {
  final dio = createMovieLogClient();
  dio.interceptors.add(AuthInterceptor(storage));
  return dio;
}
