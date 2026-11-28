import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/common_response.dart';
import '../data/models/create_member_request.dart';
import '../data/services/sign_up_service.dart';

enum CheckStatus { idle, checking, available, duplicated, error }

enum SubmitStatus { idle, submitting, success, error }

class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel(SignUpService service)
    : _service = service,
      nickname = MemberFieldCheck('닉네임', service.checkNickname),
      email = MemberFieldCheck('이메일', service.checkEmail);

  final SignUpService _service;
  final MemberFieldCheck nickname;
  final MemberFieldCheck email;
  bool _disposed = false;

  SubmitStatus submitStatus = SubmitStatus.idle;
  int? createdMemberId;
  String? passwordErrorText;
  String? snackbarMessage;

  bool get isSubmitting => submitStatus == SubmitStatus.submitting;
  bool get canSubmit =>
      !isSubmitting &&
      passwordErrorText == null &&
      nickname.status == CheckStatus.available &&
      email.status == CheckStatus.available;

  void onNicknameChanged(String value) => _change(nickname, value);
  void onEmailChanged(String value) => _change(email, value);
  Future<void> checkNickname() => _check(nickname);
  Future<void> checkEmail() => _check(email);

  void onPasswordChanged() {
    if (_disposed || isSubmitting) return;
    _clearSubmitErrors();
    notifyListeners();
  }

  void _clearSubmitErrors() {
    passwordErrorText = null;
    snackbarMessage = null;
    submitStatus = SubmitStatus.idle;
  }

  void _change(MemberFieldCheck field, String value) {
    if (_disposed || isSubmitting) return;
    field._value = value.trim();
    field._version++;
    field._status = CheckStatus.idle;
    field._requestError = null;
    _clearSubmitErrors();
    notifyListeners();
  }

  Future<void> _check(MemberFieldCheck field) async {
    if (_disposed || isSubmitting || !field.canCheck) return;
    final version = ++field._version;
    field._status = CheckStatus.checking;
    field._requestError = null;
    notifyListeners();

    try {
      final available = await field._request(field._value);
      if (_disposed || version != field._version) return;
      field._status = available
          ? CheckStatus.available
          : CheckStatus.duplicated;
    } catch (error) {
      if (_disposed || version != field._version) return;
      field._status = CheckStatus.error;
      field._requestError = CommonResponse.errorFrom(error)?.message;
    }
    notifyListeners();
  }

  Future<void> submit(CreateMemberRequest request) async {
    if (_disposed ||
        !canSubmit ||
        nickname._value != request.nickname.trim() ||
        email._value != request.email.trim()) {
      return;
    }
    submitStatus = SubmitStatus.submitting;
    passwordErrorText = null;
    snackbarMessage = null;
    createdMemberId = null;
    notifyListeners();

    try {
      final response = await _service.signUp(request);
      if (_disposed) return;
      final id = response.result?.memberId;
      if (id == null) throw const FormatException('memberId가 없습니다.');
      createdMemberId = id;
      submitStatus = SubmitStatus.success;
    } catch (error) {
      if (_disposed) return;
      submitStatus = SubmitStatus.error;
      final message = CommonResponse.errorFrom(error)?.message;
      if (error is DioException &&
          error.response?.statusCode == 400 &&
          message != null &&
          (message.contains('비밀번호') ||
              message.toLowerCase().contains('password'))) {
        passwordErrorText = message;
      } else {
        snackbarMessage =
            message ??
            (error is FormatException
                ? '가입 결과를 확인하지 못했습니다. 새 요청 전에 가입 상태를 확인해 주세요.'
                : '회원가입에 실패했습니다. 잠시 후 다시 시도해 주세요.');
      }
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
  String? _requestError;
  int _version = 0;
  CheckStatus _status = CheckStatus.idle;

  CheckStatus get status => _status;
  bool get canCheck =>
      _value.isNotEmpty &&
      (status == CheckStatus.idle || status == CheckStatus.error);

  String? get errorText => switch (status) {
    CheckStatus.duplicated => '이미 사용 중인 $label입니다.',
    CheckStatus.error => _requestError ?? '중복 확인에 실패했습니다. 다시 시도해 주세요.',
    _ => null,
  };

  String? get successText =>
      status == CheckStatus.available ? '사용할 수 있는 $label입니다.' : null;
}
