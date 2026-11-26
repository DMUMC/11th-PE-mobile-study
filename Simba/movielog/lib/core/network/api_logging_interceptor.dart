import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Client를 거치는 모든 요청/응답/오류를 같은 형식으로 기록한다.
/// TMDB와 MovieLog API Client가 [label]만 바꿔 함께 사용한다.
/// Authorization Header와 응답 body의 accessToken은 원문 대신 마스킹된 값만 남긴다.
/// 요청 body는 비밀번호가 들어 있을 수 있어 아예 기록하지 않는다.
class ApiLoggingInterceptor extends Interceptor {
  ApiLoggingInterceptor({required this.label});

  /// 로그 앞에 붙는 이름 (예: TMDB, MovieLog)
  final String label;

  static const _authorizationKey = 'Authorization';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('[$label 요청] ${options.method} ${options.uri}');
    debugPrint('[$label 요청 Header] ${_maskHeaders(options.headers)}');
    if (options.queryParameters.isNotEmpty) {
      debugPrint('[$label 요청 Query] ${options.queryParameters}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint(
      '[$label 응답] ${response.statusCode} ${response.requestOptions.uri}',
    );
    debugPrint('[$label 응답 Body] ${maskSensitive(response.data)}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
      '[$label 오류] ${err.requestOptions.method} ${err.requestOptions.uri}',
    );
    debugPrint(
      '[$label 오류 Header] ${_maskHeaders(err.requestOptions.headers)}',
    );
    debugPrint(
      '[$label 오류 내용] type=${err.type.name} '
      'status=${err.response?.statusCode} message=${err.message}',
    );
    if (err.response?.data != null) {
      debugPrint('[$label 오류 Body] ${maskSensitive(err.response?.data)}');
    }
    handler.next(err);
  }

  static const _sensitiveKeys = {'accessToken', 'refreshToken', 'password'};

  /// 로그인 응답의 result.accessToken처럼 민감한 값을 ***로 바꾼다.
  static Object? maskSensitive(Object? data) {
    if (data is Map) {
      return {
        for (final entry in data.entries)
          entry.key: _sensitiveKeys.contains(entry.key)
              ? '***'
              : maskSensitive(entry.value),
      };
    }
    if (data is List) return data.map(maskSensitive).toList();
    return data;
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
