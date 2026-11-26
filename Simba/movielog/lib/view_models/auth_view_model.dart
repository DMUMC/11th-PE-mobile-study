import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../core/storage/token_storage.dart';
import '../data/models/login_models.dart';
import '../data/models/member_info.dart';
import '../data/services/auth_api_service.dart';
import '../data/services/member_api_service.dart';

enum AuthStatus {
  initializing,
  signedOut,
  authenticating,
  signedIn,
  retryRequired,
}

enum MemberLoadStatus { idle, loading, success, error }

/// 로그인 세션 상태. Router는 [status]만 보고 화면을 정한다.
///
/// - 토큰이 저장돼 있다는 사실만으로 signedIn을 확정하지 않는다. (재시작 시 GET me 검증)
/// - 네트워크 실패로는 토큰을 지우지 않는다. (retryRequired)
/// - [sessionVersion]이 바뀐 뒤 늦게 도착한 응답은 반영하지 않는다.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel(
    this._authApi,
    this._memberApi,
    this._storage, {
    this.onSessionReset,
  });

  final AuthApiService _authApi;
  final MemberApiService _memberApi;
  final TokenStorage _storage;

  /// 세션이 바뀔 때(로그인·로그아웃·만료) 이전 세션 데이터(평점 등)를 비우는 콜백
  final VoidCallback? onSessionReset;

  AuthStatus status = AuthStatus.initializing;
  MemberInfo? member;
  MemberLoadStatus memberStatus = MemberLoadStatus.idle;
  String? message;

  /// 만료로 로그아웃된 경우에만 켜진다. 로그인 화면이 Snackbar로 한 번 안내한다.
  bool sessionExpired = false;
  bool storageCleanupInProgress = false;

  int _sessionVersion = 0;
  int get sessionVersion => _sessionVersion;
  bool _disposed = false;
  Future<void>? _tokenWrite;

  bool get isSignedIn => status == AuthStatus.signedIn;

  bool _isCurrent(int version) => !_disposed && version == _sessionVersion;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  // ── 앱 시작: 세션 복원 ──
  Future<void> restoreSession() async {
    if (storageCleanupInProgress || _disposed) return;
    final version = ++_sessionVersion;
    status = AuthStatus.initializing;
    message = null;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    _notify();

    try {
      final token = await _storage.readAccessToken();
      if (!_isCurrent(version)) return;
      if (token == null || token.isEmpty) {
        status = AuthStatus.signedOut;
      } else {
        // 서버가 토큰을 검증해 줘야만 로그인 상태로 확정한다.
        final verified = await _memberApi.fetchMe();
        if (!_isCurrent(version)) return;
        member = verified;
        memberStatus = MemberLoadStatus.success;
        status = AuthStatus.signedIn;
      }
    } on DioException catch (error) {
      if (!_isCurrent(version)) return;
      if (isSessionExpiredCode(apiErrorCode(error))) {
        await _clearCurrentSession(expired: true);
        return;
      }
      // 네트워크 실패는 토큰을 지우지 않고 재시도하게 한다.
      status = AuthStatus.retryRequired;
      message = '로그인 상태를 확인하지 못했어요. 다시 시도해 주세요.';
    } catch (_) {
      if (!_isCurrent(version)) return;
      status = AuthStatus.retryRequired;
      message = '인증 저장소를 읽지 못했어요. 다시 시도해 주세요.';
    }
    if (_isCurrent(version)) _notify();
  }

  // ── 로그인 ──
  Future<void> login(String email, String password) async {
    if (_disposed ||
        storageCleanupInProgress ||
        status == AuthStatus.authenticating) {
      return;
    }
    status = AuthStatus.authenticating;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    sessionExpired = false;
    message = null;
    final version = ++_sessionVersion;
    onSessionReset?.call(); // 다른 계정의 이전 세션 데이터를 남기지 않는다.
    _notify();

    try {
      final result = await _authApi.login(
        LoginRequest(email: email, password: password),
      );
      if (!_isCurrent(version)) return;
      final writing = _storage.saveAccessToken(result.accessToken);
      _tokenWrite = writing;
      try {
        await writing;
      } finally {
        if (identical(_tokenWrite, writing)) _tokenWrite = null;
      }
      if (!_isCurrent(version)) return;
      // 신규 로그인: 토큰 저장 → signedIn → MainScreen이 loadMember()로 내 정보를 불러온다.
      status = AuthStatus.signedIn;
    } on DioException catch (error) {
      if (!_isCurrent(version)) return;
      status = AuthStatus.signedOut;
      // 로그인 실패(AUTH401_1)는 Form 오류다. 만료 안내(sessionExpired)를 켜지 않는다.
      message = apiErrorCode(error) == 'AUTH401_1'
          ? '이메일 또는 비밀번호를 확인해 주세요.'
          : apiErrorCode(error) == 'COMMON400'
          ? (apiErrorMessage(error) ?? '입력값을 확인해 주세요.')
          : '로그인 요청에 실패했어요. 잠시 후 다시 시도해 주세요.';
    } catch (_) {
      if (!_isCurrent(version)) return;
      status = AuthStatus.signedOut;
      message = '로그인 정보를 안전하게 저장하지 못했어요.';
    }
    _notify();
  }

  // ── 내 정보 ──
  Future<void> loadMember({bool force = false}) async {
    if (status != AuthStatus.signedIn) return;
    if (memberStatus == MemberLoadStatus.loading) return;
    if (member != null && !force) return; // 재시작 복원 때 이미 채워졌으면 다시 부르지 않는다.

    final version = _sessionVersion;
    memberStatus = MemberLoadStatus.loading;
    _notify();

    try {
      final me = await _memberApi.fetchMe();
      if (!_isCurrent(version)) return; // 로그아웃·계정 전환 뒤 늦게 온 응답 무시
      member = me;
      memberStatus = MemberLoadStatus.success;
    } on DioException catch (error) {
      if (!_isCurrent(version)) return;
      if (isSessionExpiredCode(apiErrorCode(error))) {
        await _clearCurrentSession(expired: true);
        return;
      }
      memberStatus = MemberLoadStatus.error; // 네트워크 실패: 로그아웃하지 않고 재시도
    } catch (_) {
      if (!_isCurrent(version)) return;
      memberStatus = MemberLoadStatus.error;
    }
    _notify();
  }

  /// 프로필 수정 성공 응답으로 메모리의 내 정보를 교체한다.
  void updateMember(MemberInfo updated) {
    if (_disposed || status != AuthStatus.signedIn) return;
    member = updated;
    memberStatus = MemberLoadStatus.success;
    _notify();
  }

  /// 다른 ViewModel이 보호 요청에서 AUTH401_2/3/4를 받았을 때 부르는 진입점.
  /// [sessionVersion]을 넘기면, 그 사이 새로 로그인한 세션을 이전 401이 지우지 않는다.
  Future<void> expireSession({int? sessionVersion}) async {
    if (sessionVersion != null && sessionVersion != _sessionVersion) return;
    if (status != AuthStatus.signedIn) return; // 동시 401은 한 번만 처리
    await _clearCurrentSession(expired: true);
  }

  /// 직접 로그아웃: 만료 Snackbar는 켜지 않는다.
  /// 클라이언트 저장소·메모리만 비우며 서버에서 토큰이 폐기됐다고 보장하지 않는다.
  Future<void> logout() => _clearCurrentSession(expired: false);

  void consumeSessionExpired() {
    sessionExpired = false;
  }

  Future<void> _clearCurrentSession({bool expired = true}) async {
    if (_disposed || storageCleanupInProgress) return;
    final version = ++_sessionVersion;
    storageCleanupInProgress = true;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    sessionExpired = expired;
    status = AuthStatus.signedOut;
    message = null;
    onSessionReset?.call();
    _notify();
    try {
      // 진행 중이던 토큰 저장을 기다린 뒤 삭제한다. 정리 중에는 새 로그인을 막는다.
      try {
        await _tokenWrite;
      } catch (_) {}
      await _storage.deleteAccessToken();
    } catch (_) {
      if (_isCurrent(version)) {
        message = '저장된 인증 정보를 지우지 못했어요. 앱 재실행 전에 저장소 상태를 확인해 주세요.';
      }
    } finally {
      storageCleanupInProgress = false;
      if (_isCurrent(version)) _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _sessionVersion++;
    super.dispose();
  }
}
