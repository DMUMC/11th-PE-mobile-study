import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// TMDB Client를 거치는 모든 요청/응답/오류를 같은 형식으로 기록한다.
/// Authorization Header는 원문 대신 마스킹된 값만 남긴다.
class TmdbLoggingInterceptor extends Interceptor {
  static const _authorizationKey = 'Authorization';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('[TMDB 요청] ${options.method} ${options.uri}');
    debugPrint('[TMDB 요청 Header] ${_maskHeaders(options.headers)}');
    if (options.queryParameters.isNotEmpty) {
      debugPrint('[TMDB 요청 Query] ${options.queryParameters}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint(
      '[TMDB 응답] ${response.statusCode} ${response.requestOptions.uri}',
    );
    debugPrint('[TMDB 응답 Body] ${response.data}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('[TMDB 오류] ${err.requestOptions.method} ${err.requestOptions.uri}');
    debugPrint('[TMDB 오류 Header] ${_maskHeaders(err.requestOptions.headers)}');
    debugPrint(
      '[TMDB 오류 내용] type=${err.type.name} '
      'status=${err.response?.statusCode} message=${err.message}',
    );
    if (err.response?.data != null) {
      debugPrint('[TMDB 오류 Body] ${err.response?.data}');
    }
    handler.next(err);
  }

  Map<String, dynamic> _maskHeaders(Map<String, dynamic> headers) {
    final masked = Map<String, dynamic>.from(headers);
    for (final key in masked.keys.toList()) {
      if (key.toLowerCase() == _authorizationKey.toLowerCase()) {
        masked[key] = 'Bearer ***';
      }
    }
    return masked;
  }
}
