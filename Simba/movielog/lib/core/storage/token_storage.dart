import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// accessToken 저장·조회·삭제 규칙을 인증 흐름에서 분리한다.
/// 인증 코드는 구체적인 저장소(FlutterSecureStorage)를 모르고 이 인터페이스만 쓴다.
/// (테스트에서는 메모리 저장소로 바꿔 끼운다)
abstract interface class TokenStorage {
  Future<void> saveAccessToken(String token);
  Future<String?> readAccessToken();
  Future<void> deleteAccessToken();
}

/// iOS Keychain / Android Keystore 기반으로 암호화해 저장한다.
/// 토큰은 민감 정보라 SharedPreferences(평문)에 두지 않는다.
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage(this._storage);

  static const _accessTokenKey = 'movielog.access_token';
  final FlutterSecureStorage _storage;

  @override
  Future<void> saveAccessToken(String token) {
    return _storage.write(key: _accessTokenKey, value: token);
  }

  @override
  Future<String?> readAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  @override
  Future<void> deleteAccessToken() {
    return _storage.delete(key: _accessTokenKey);
  }
}
