import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/services/member_api_service.dart';
import 'auth_view_model.dart';

enum EditProfileStatus { idle, saving, success, failure }

/// 프로필(닉네임) 수정. 오류는 보여줄 위치에 따라 나눈다.
/// - 입력칸 문제(길이, 중복): [nicknameError] → 필드 아래
/// - 입력과 무관한 문제(네트워크 등): [message] → Snackbar (로그아웃하지 않음)
class EditProfileViewModel extends ChangeNotifier {
  EditProfileViewModel(this._memberApi, this._auth);

  final MemberApiService _memberApi;
  final AuthViewModel _auth;

  EditProfileStatus status = EditProfileStatus.idle;
  String? nicknameError;
  String? message;
  bool _disposed = false;

  bool get isSaving => status == EditProfileStatus.saving;

  /// 서버에 보내기 전에 확인할 수 있는 규칙은 먼저 검사해 불필요한 통신을 줄인다.
  String? validateNickname(String value) {
    final nickname = value.trim();
    if (nickname.length < 2 || nickname.length > 12) {
      return '닉네임은 2~12자로 입력해 주세요.';
    }
    return null;
  }

  /// 현재 닉네임과 다르게 입력했는지 (Challenge: 뒤로가기 확인 Dialog)
  bool isDirty(String input) => input.trim() != (_auth.member?.nickname ?? '');

  void onNicknameChanged() {
    if (nicknameError == null) return;
    nicknameError = null;
    _notify();
  }

  Future<bool> save(String input) async {
    if (isSaving) return false; // 중복 탭 방지
    final version = _auth.sessionVersion;
    if (_disposed || !_auth.isSignedIn || _auth.member == null) return false;

    final nickname = input.trim();
    nicknameError = validateNickname(nickname);
    message = null;
    if (nicknameError != null) {
      _notify();
      return false;
    }

    // 내 현재 닉네임과 같으면 요청 없이 완료한다. (자기 닉네임은 409가 아니지만 보낼 이유가 없다)
    if (nickname == _auth.member?.nickname) {
      status = EditProfileStatus.success;
      _notify();
      return true;
    }

    status = EditProfileStatus.saving;
    _notify();

    bool isStale() =>
        _disposed || version != _auth.sessionVersion || !_auth.isSignedIn;

    try {
      final updated = await _memberApi.updateNickname(nickname);
      if (isStale()) return false;
      _auth.updateMember(updated); // 마이페이지가 바로 새 닉네임을 보여준다.
      status = EditProfileStatus.success;
      _notify();
      return true;
    } on DioException catch (error) {
      if (isStale()) return false;
      status = EditProfileStatus.failure;
      final code = apiErrorCode(error);
      if (isSessionExpiredCode(code)) {
        // 세션 만료: 안내와 이동은 로그인 화면과 Router가 처리한다.
        await _auth.expireSession(sessionVersion: version);
        return false;
      }
      switch (code) {
        case 'MEMBER409_1':
          nicknameError = '이미 사용 중인 닉네임이에요.'; // 입력값은 유지
        case 'COMMON400':
          nicknameError = apiErrorMessage(error) ?? '닉네임 형식을 확인해 주세요.';
        case 'MEMBER404_1':
          message = '회원 정보를 찾을 수 없어요.';
        default:
          message = '네트워크 상태를 확인하고 다시 시도해 주세요.';
      }
    } catch (_) {
      if (isStale()) return false;
      status = EditProfileStatus.failure;
      message = '알 수 없는 오류가 발생했어요.';
    }
    _notify();
    return false;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
