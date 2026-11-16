import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class TmdbDebugNetworkInterceptor extends Interceptor {
  static bool isBlocked = false;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode && isBlocked && options.path == '/discover/movie') {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          message: '[DEBUG] Discover 네트워크 차단 재현',
        ),
        true,
      );
      return;
    }
    handler.next(options);
  }
}
