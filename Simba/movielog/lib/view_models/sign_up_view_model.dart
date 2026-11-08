import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/services/member_check_service.dart';

enum CheckStatus { idle, checking, available, duplicated, error }

/// 회원가입 화면 ViewModel.
/// 형식 검사(글자 수, 이메일 모양)는 화면의 validator가, 중복 여부는 서버가 판단한다.
/// 닉네임과 이메일은 서로 영향을 주지 않도록 상태를 필드별로 따로 관리한다.
class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel(this._service) {
    _nickname = _DuplicateCheck(
      label: '닉네임',
      request: _service.checkNickname,
      isDisposed: () => _disposed,
      notify: notifyListeners,
    );
    _email = _DuplicateCheck(
      label: '이메일',
      request: _service.checkEmail,
      isDisposed: () => _disposed,
      notify: notifyListeners,
    );
  }

  final MemberCheckService _service;
  late final _DuplicateCheck _nickname;
  late final _DuplicateCheck _email;
  bool _disposed = false;

  // ── 닉네임 ──
  CheckStatus get nicknameCheckStatus => _nickname.status;
  String? get nicknameErrorText => _nickname.errorText;
  bool get canCheckNickname => _nickname.canCheck;
  void onNicknameChanged(String value) => _nickname.onChanged(value);
  Future<void> checkNickname(String value) => _nickname.check(value);

  // ── 이메일 ──
  CheckStatus get emailCheckStatus => _email.status;
  String? get emailErrorText => _email.errorText;
  bool get canCheckEmail => _email.canCheck;
  void onEmailChanged(String value) => _email.onChanged(value);
  Future<void> checkEmail(String value) => _email.check(value);

  @override
  void dispose() {
    _disposed = true;
    _nickname.invalidate();
    _email.invalidate();
    super.dispose();
  }
}

/// 입력란 하나(닉네임 또는 이메일)의 중복 확인 상태.
class _DuplicateCheck {
  _DuplicateCheck({
    required this.label,
    required this.request,
    required this.isDisposed,
    required this.notify,
  });

  final String label;
  final Future<bool> Function(String value) request;
  final bool Function() isDisposed;
  final VoidCallback notify;

  CheckStatus status = CheckStatus.idle;
  String? errorText;

  /// 서버가 "중복"이라고 답한 값들. 같은 문자열을 다시 입력하면 재요청 없이 바로 에러로 되돌린다.
  /// (서버 상태는 바뀔 수 있으므로 최종 기준은 6주차 이후 회원가입 POST의 409)
  final Set<String> _duplicatedValues = {};
  String _current = '';
  int _requestVersion = 0;

  String get _duplicatedMessage => '이미 사용 중인 $label입니다.';

  /// 통신 중이거나, 중복으로 확인된 값을 그대로 두고 있으면 다시 누를 수 없다.
  bool get canCheck =>
      status != CheckStatus.checking && status != CheckStatus.duplicated;

  void onChanged(String value) {
    final trimmed = value.trim();
    _current = trimmed;
    _requestVersion++; // 기다리던 이전 요청의 응답을 무효화한다.

    if (_duplicatedValues.contains(trimmed)) {
      status = CheckStatus.duplicated;
      errorText = _duplicatedMessage;
    } else {
      status = CheckStatus.idle;
      errorText = null;
    }
    if (!isDisposed()) notify();
  }

  Future<void> check(String value) async {
    final requested = value.trim();
    if (requested.isEmpty || requested != _current || !canCheck) return;

    final version = ++_requestVersion;
    status = CheckStatus.checking;
    errorText = null;
    notify();

    bool isStale() =>
        isDisposed() || version != _requestVersion || _current != requested;

    try {
      final available = await request(requested);
      if (isStale()) return;
      if (available) {
        status = CheckStatus.available;
        errorText = null;
      } else {
        // 정상 응답이지만 이미 사용 중인 값
        _duplicatedValues.add(requested);
        status = CheckStatus.duplicated;
        errorText = _duplicatedMessage;
      }
    } on DioException {
      if (isStale()) return;
      // 통신 자체가 실패한 경우. 중복과 다른 문구를 쓰고, 다시 시도할 수 있다.
      status = CheckStatus.error;
      errorText = '$label 중복 확인에 실패했습니다. 다시 시도해 주세요.';
    }
    notify();
  }

  void invalidate() => _requestVersion++;
}
