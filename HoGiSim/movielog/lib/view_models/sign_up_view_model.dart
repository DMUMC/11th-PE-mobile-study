import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/services/member_check_service.dart';

enum CheckStatus { idle, checking, available, duplicated, error }

class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel(MemberCheckService service)
    : nickname = MemberFieldCheck('닉네임', service.checkNickname),
      email = MemberFieldCheck('이메일', service.checkEmail);

  final MemberFieldCheck nickname;
  final MemberFieldCheck email;
  bool _disposed = false;

  void onNicknameChanged(String value) => _change(nickname, value);
  void onEmailChanged(String value) => _change(email, value);
  Future<void> checkNickname() => _check(nickname);
  Future<void> checkEmail() => _check(email);

  void _change(MemberFieldCheck field, String value) {
    if (_disposed) return;
    field._value = value.trim();
    field._version++;
    field._status = field._value == field._lastDuplicate
        ? CheckStatus.duplicated
        : CheckStatus.idle;
    notifyListeners();
  }

  Future<void> _check(MemberFieldCheck field) async {
    if (_disposed || !field.canCheck) return;
    final value = field._value;
    final version = ++field._version;
    field._status = CheckStatus.checking;
    notifyListeners();

    try {
      final available = await field._request(value);
      if (_disposed || version != field._version) return;
      field._status = available
          ? CheckStatus.available
          : CheckStatus.duplicated;
      if (!available) field._lastDuplicate = value;
    } on DioException {
      if (_disposed || version != field._version) return;
      field._status = CheckStatus.error;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class MemberFieldCheck {
  MemberFieldCheck(this.label, this._request);

  final String label;
  final Future<bool> Function(String) _request;
  String _value = '';
  String? _lastDuplicate;
  int _version = 0;
  CheckStatus _status = CheckStatus.idle;

  CheckStatus get status => _status;
  bool get canCheck =>
      _value.isNotEmpty &&
      status != CheckStatus.checking &&
      status != CheckStatus.duplicated;

  String? get errorText => switch (status) {
    CheckStatus.duplicated => '이미 사용 중인 $label입니다.',
    CheckStatus.error => '중복 확인에 실패했습니다. 다시 시도해 주세요.',
    _ => null,
  };

  String? get successText =>
      status == CheckStatus.available ? '사용할 수 있는 $label입니다.' : null;
}
