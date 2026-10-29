import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Credentials, raw exceptions, and request options are never printed.
class TmdbLoggingInterceptor extends Interceptor {
  TmdbLoggingInterceptor({void Function(String)? write})
    : _write = write ?? debugPrint;
  final void Function(String) _write;

  Uri _safeUri(RequestOptions options) {
    final query = Map<String, dynamic>.from(options.queryParameters);
    for (final key in query.keys.toList()) {
      if (RegExp(
        r'token|api_key|authorization',
        caseSensitive: false,
      ).hasMatch(key)) {
        query[key] = '***';
      }
    }
    return options.uri.replace(
      queryParameters: query.isEmpty
          ? null
          : query.map(
              (key, value) => MapEntry(
                key,
                value is Iterable
                    ? value.map((item) => '$item').toList()
                    : '$value',
              ),
            ),
    );
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      _write('[TMDB 요청] ${options.method} ${_safeUri(options)}');
      _write('[TMDB 인증] Authorization: Bearer ***');
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      _write(
        '[TMDB 응답] ${response.statusCode} ${_safeUri(response.requestOptions)}',
      );
      // Only known public TMDB fields; an arbitrary error body may echo credentials.
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final results = data['results'];
        _write(
          '[TMDB 응답 Body] ${{
            if (data['page'] != null) 'page': data['page'],
            if (data['total_pages'] != null) 'total_pages': data['total_pages'],
            if (data['total_results'] != null) 'total_results': data['total_results'],
            if (results is List) 'results': results.whereType<Map<String, dynamic>>().map((m) => {'id': m['id'], 'title': m['title'], 'poster_path': m['poster_path'], 'genre_ids': m['genre_ids']}).toList(),
            if (data['genres'] is List) 'genres': data['genres'],
          }}',
        );
      }
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      _write('[TMDB 오류] ${_safeUri(err.requestOptions)}');
      _write(
        '[TMDB 오류 내용] type=${err.type.name}, status=${err.response?.statusCode ?? '연결 실패'}',
      );
    }
    handler.next(err);
  }
}
