import 'package:flutter_dotenv/flutter_dotenv.dart';

/// .env에서 TMDB 설정값을 읽는 코드를 한 곳에 모은다.
abstract final class TmdbConfig {
  static const _accessTokenKey = 'TMDB_ACCESS_TOKEN';

  static String get accessToken => dotenv.env[_accessTokenKey] ?? '';

  static bool get hasAccessToken => accessToken.trim().isNotEmpty;
}
