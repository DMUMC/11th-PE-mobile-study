import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// 보호 API(내 정보, 평점 등록/수정/삭제)에만 `Authorization: Bearer {JWT}`를 붙인다.
/// 보호용 Client에만 등록하며, TMDB Client와 공개용 Client에는 등록하지 않는다.
/// 화면 이동·Snackbar 같은 UI 처리는 하지 않는다. (BuildContext를 모른다)
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);

  static const _host = 'workbook.devnoco.com';
  final TokenStorage _storage;

  /// host와 path를 모두 확인해 다른 서버(이미지 URL 등)로 토큰이 새지 않게 한다.
  static bool isProtected(Uri uri) {
    final path = uri.path;
    return uri.host == _host &&
        (path == '/v7/members/me' ||
            path == '/v7/ratings' ||
            path.startsWith('/v7/ratings/'));
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers.remove('Authorization'); // 이전 요청의 토큰을 재사용하지 않는다.
    if (!isProtected(options.uri)) {
      handler.next(options);
      return;
    }
    try {
      final token = await _storage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    } catch (_) {
      // 기기 저장소 실패는 서버 401과 다른 오류로 전달한다.
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.unknown,
          error: StateError('인증 저장소를 읽지 못했습니다.'),
        ),
      );
    }
  }
}
