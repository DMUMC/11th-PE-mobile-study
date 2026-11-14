import 'package:dio/dio.dart';

// Pass the existing .env with --dart-define-from-file=.env when running.
Dio createTmdbClient() {
  const token = String.fromEnvironment('TMDB_ACCESS_TOKEN');
  return Dio(
    BaseOptions(
      baseUrl: 'https://api.themoviedb.org/3',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    ),
  );
}
