import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'api_error.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);
  final TokenStorage _storage;
  static const _versionKey = 'movielog.requestSessionVersion';
  int Function()? _sessionVersion;
  Future<void> Function(int version)? _onSessionExpired;

  // Bind after AuthViewModel is created, before any protected request starts.
  void bindSession({
    required int Function() sessionVersion,
    required Future<void> Function(int version) onSessionExpired,
  }) {
    _sessionVersion = sessionVersion;
    _onSessionExpired = onSessionExpired;
  }

  bool _isProtected(RequestOptions options) {
    if (options.uri.host != 'workbook.devnoco.com') return false;
    final path = options.uri.path;
    final method = options.method.toUpperCase();
    final authenticated =
        path == '/v8/members/me' ||
        path == '/v8/ratings' ||
        path.startsWith('/v8/ratings/');
    final favorites =
        (path == '/v8/favorites' && (method == 'GET' || method == 'POST')) ||
        (RegExp(r'^/v8/favorites/[1-9]\d*$').hasMatch(path) &&
            (method == 'GET' || method == 'DELETE'));
    final movieRecord = path == '/v8/movie-records' && method == 'POST';
    return authenticated || favorites || movieRecord;
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isProtected(options)) {
      handler.next(options);
      return;
    }
    options.headers.remove('Authorization');
    final version = _sessionVersion?.call();
    if (version != null) options.extra[_versionKey] = version;
    try {
      final token = await _storage.readAccessToken();
      if (version != null && version != _sessionVersion?.call()) {
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
            message: '세션이 변경되어 요청을 보내지 않았습니다.',
          ),
        );
        return;
      }
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    } catch (_) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.unknown,
          error: StateError('인증 저장소를 읽지 못했습니다.'),
        ),
      );
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final version = err.requestOptions.extra[_versionKey];
    if (_isProtected(err.requestOptions) &&
        err.response?.statusCode == 401 &&
        const {
          'AUTH401_2',
          'AUTH401_3',
          'AUTH401_4',
        }.contains(apiErrorCode(err)) &&
        version is int &&
        version == _sessionVersion?.call()) {
      await _onSessionExpired?.call(version);
    }
    handler.next(err);
  }
}
