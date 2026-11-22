import 'package:shared_preferences/shared_preferences.dart';

/// (Challenge) 로그인 화면의 "이메일 저장".
/// 이메일은 민감하지 않은 편의 정보라 shared_preferences에 둔다.
/// 비밀번호와 토큰은 여기에 절대 저장하지 않는다.
class EmailPreferences {
  EmailPreferences([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  static const _savedEmailKey = 'movielog.saved_email';
  final SharedPreferencesAsync _prefs;

  Future<String?> readSavedEmail() async {
    try {
      return await _prefs.getString(_savedEmailKey);
    } catch (_) {
      return null; // 편의 기능이라 실패해도 로그인은 막지 않는다.
    }
  }

  Future<void> saveEmail(String email) async {
    try {
      await _prefs.setString(_savedEmailKey, email.trim());
    } catch (_) {}
  }

  Future<void> clear() async {
    try {
      await _prefs.remove(_savedEmailKey);
    } catch (_) {}
  }
}
