import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/validation/sign_up_validators.dart';
import '../data/services/member_check_service.dart';

enum CheckStatus { idle, checking, available, duplicated, error }

class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel(
    this._service, {
    String initialNickname = '',
    String initialEmail = '',
  }) : _currentNickname = initialNickname.trim(),
       _currentEmail = initialEmail.trim();

  final MemberCheckService _service;
  bool _disposed = false;

  CheckStatus _nicknameCheckStatus = CheckStatus.idle;
  CheckStatus _emailCheckStatus = CheckStatus.idle;
  String? _nicknameErrorText;
  String? _emailErrorText;
  String? _duplicatedNickname;
  String? _duplicatedEmail;
  String _currentNickname;
  String _currentEmail;
  int _nicknameRequestVersion = 0;
  int _emailRequestVersion = 0;

  CheckStatus get nicknameCheckStatus => _nicknameCheckStatus;
  CheckStatus get emailCheckStatus => _emailCheckStatus;
  String? get nicknameErrorText => _nicknameErrorText;
  String? get emailErrorText => _emailErrorText;

  bool get canCheckNickname =>
      !_disposed &&
      validateNickname(_currentNickname) == null &&
      _nicknameCheckStatus != CheckStatus.checking &&
      _nicknameCheckStatus != CheckStatus.duplicated;

  bool get canCheckEmail =>
      !_disposed &&
      validateEmail(_currentEmail) == null &&
      _emailCheckStatus != CheckStatus.checking &&
      _emailCheckStatus != CheckStatus.duplicated;

  bool get checksPassed =>
      _nicknameCheckStatus == CheckStatus.available &&
      _emailCheckStatus == CheckStatus.available;

  void onNicknameChanged(String value) {
    if (_disposed) return;
    _currentNickname = value.trim();
    _nicknameRequestVersion++;
    final duplicated = _currentNickname == _duplicatedNickname;
    _nicknameCheckStatus = duplicated
        ? CheckStatus.duplicated
        : CheckStatus.idle;
    _nicknameErrorText = duplicated ? '이미 사용 중인 닉네임입니다.' : null;
    notifyListeners();
  }

  void onEmailChanged(String value) {
    if (_disposed) return;
    _currentEmail = value.trim();
    _emailRequestVersion++;
    final duplicated = _currentEmail == _duplicatedEmail;
    _emailCheckStatus = duplicated ? CheckStatus.duplicated : CheckStatus.idle;
    _emailErrorText = duplicated ? '이미 사용 중인 이메일입니다.' : null;
    notifyListeners();
  }

  Future<void> checkNickname(String value) async {
    final requested = value.trim();
    if (!canCheckNickname || requested != _currentNickname) return;

    final version = ++_nicknameRequestVersion;
    _nicknameCheckStatus = CheckStatus.checking;
    _nicknameErrorText = null;
    notifyListeners();

    try {
      final available = await _service.checkNickname(requested);
      if (!_isCurrentNickname(version, requested)) return;
      _nicknameCheckStatus = available
          ? CheckStatus.available
          : CheckStatus.duplicated;
      _nicknameErrorText = available ? null : '이미 사용 중인 닉네임입니다.';
      if (!available) _duplicatedNickname = requested;
    } on DioException {
      if (!_isCurrentNickname(version, requested)) return;
      _nicknameCheckStatus = CheckStatus.error;
      _nicknameErrorText = '중복 확인에 실패했습니다. 다시 시도해 주세요.';
    } on FormatException {
      if (!_isCurrentNickname(version, requested)) return;
      _nicknameCheckStatus = CheckStatus.error;
      _nicknameErrorText = '확인 결과를 읽지 못했습니다. 다시 시도해 주세요.';
    }
    if (_isCurrentNickname(version, requested)) notifyListeners();
  }

  Future<void> checkEmail(String value) async {
    final requested = value.trim();
    if (!canCheckEmail || requested != _currentEmail) return;

    final version = ++_emailRequestVersion;
    _emailCheckStatus = CheckStatus.checking;
    _emailErrorText = null;
    notifyListeners();

    try {
      final available = await _service.checkEmail(requested);
      if (!_isCurrentEmail(version, requested)) return;
      _emailCheckStatus = available
          ? CheckStatus.available
          : CheckStatus.duplicated;
      _emailErrorText = available ? null : '이미 사용 중인 이메일입니다.';
      if (!available) _duplicatedEmail = requested;
    } on DioException {
      if (!_isCurrentEmail(version, requested)) return;
      _emailCheckStatus = CheckStatus.error;
      _emailErrorText = '중복 확인에 실패했습니다. 다시 시도해 주세요.';
    } on FormatException {
      if (!_isCurrentEmail(version, requested)) return;
      _emailCheckStatus = CheckStatus.error;
      _emailErrorText = '확인 결과를 읽지 못했습니다. 다시 시도해 주세요.';
    }
    if (_isCurrentEmail(version, requested)) notifyListeners();
  }

  bool _isCurrentNickname(int version, String value) =>
      !_disposed &&
      version == _nicknameRequestVersion &&
      value == _currentNickname;

  bool _isCurrentEmail(int version, String value) =>
      !_disposed && version == _emailRequestVersion && value == _currentEmail;

  @override
  void dispose() {
    _disposed = true;
    _nicknameRequestVersion++;
    _emailRequestVersion++;
    super.dispose();
  }
}
