import 'package:dio/dio.dart';

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
