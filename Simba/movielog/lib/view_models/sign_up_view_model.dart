import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/create_member_request.dart';
import '../data/services/sign_up_service.dart';
import 'submit_status.dart';

export 'submit_status.dart';

enum CheckStatus { idle, checking, available, duplicated, error }

/// 회원가입 화면 ViewModel.
/// 형식 검사(글자 수, 이메일 모양)는 화면의 validator가, 중복 여부는 서버가 판단한다.
/// 닉네임과 이메일은 서로 영향을 주지 않도록 상태를 필드별로 따로 관리한다.
/// 7주차: 실제 회원가입 POST(/v6/members)를 보내고 memberId를 받는다.
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

  final SignUpService _service;
  late final _DuplicateCheck _nickname;
  late final _DuplicateCheck _email;
  bool _disposed = false;

  // ── 닉네임 ──
  CheckStatus get nicknameCheckStatus => _nickname.status;
  String? get nicknameErrorText => _nickname.errorText;
  bool get canCheckNickname => _nickname.canCheck;
  void onNicknameChanged(String value) {
    _clearSubmitError();
    _nickname.onChanged(value);
  }

  Future<void> checkNickname(String value) => _nickname.check(value);

  // ── 이메일 ──
  CheckStatus get emailCheckStatus => _email.status;
  String? get emailErrorText => _email.errorText;
  bool get canCheckEmail => _email.canCheck;
  void onEmailChanged(String value) {
    _clearSubmitError();
    _email.onChanged(value);
  }

  Future<void> checkEmail(String value) => _email.check(value);

  // ── 회원가입 제출 ──
  SubmitStatus submitStatus = SubmitStatus.idle;

  /// 가입 성공 응답의 result.memberId. 이 값을 학습용 세션에 보관한다.
  int? createdMemberId;

  /// 비밀번호 칸에 붙이는 서버 오류 (400 비밀번호 형식 위반)
  String? passwordErrorText;

  /// 어느 칸에도 붙일 수 없는 화면 단위 오류 (409 중복, 그 외 400 등)
  String? snackbarMessage;

  bool get isSubmitting => submitStatus == SubmitStatus.submitting;

  /// 중복 확인 직후에도 다른 사람이 먼저 가입할 수 있으므로,
  /// 최종 판단은 POST의 409다. 여기서는 둘 다 available이어야 제출할 수 있다.
  bool get areDuplicatesChecked =>
      nicknameCheckStatus == CheckStatus.available &&
      emailCheckStatus == CheckStatus.available;

  void onPasswordChanged() {
    if (passwordErrorText == null) return;
    passwordErrorText = null;
    notifyListeners();
  }

  void _clearSubmitError() {
    if (submitStatus == SubmitStatus.error) submitStatus = SubmitStatus.idle;
    snackbarMessage = null;
  }

  Future<void> submit(CreateMemberRequest request) async {
    if (isSubmitting) return; // 연속 탭 방지
    submitStatus = SubmitStatus.submitting;
    createdMemberId = null;
    passwordErrorText = null;
    snackbarMessage = null;
    notifyListeners();

    try {
      final response = await _service.signUp(request);
      final id = response.result?.memberId;
      if (id == null) throw StateError('회원가입 결과에 memberId가 없습니다.');
      if (_disposed) return;
      createdMemberId = id;
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      if (_disposed) return;
      submitStatus = SubmitStatus.error;
      final message = writeSignUpErrorMessage(error);
      // 비밀번호가 명시된 400만 비밀번호 칸으로, 나머지(409 등)는 Snackbar로.
      if (error.response?.statusCode == 400 && message.contains('비밀번호')) {
        passwordErrorText = message;
      } else {
        snackbarMessage = message;
      }
      if (error.response?.statusCode == 409) _markDuplicated(message);
    } catch (_) {
      // 계약 오류(memberId 없음, 예상 밖 응답 형식)
      if (_disposed) return;
      submitStatus = SubmitStatus.error;
      snackbarMessage = '가입 결과를 확인하지 못했습니다. 새 요청 전에 서버 상태를 확인해 주세요.';
    }
    if (!_disposed) notifyListeners();
  }

  /// 409로 최종 중복이 확인되면 해당 칸을 중복 상태로 되돌려 다시 확인하게 한다.
  void _markDuplicated(String message) {
    if (message.contains('이메일')) _email.markDuplicated();
    if (message.contains('닉네임')) _nickname.markDuplicated();
  }

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

  /// 회원가입 POST가 409로 현재 값을 중복이라고 알려준 경우
  void markDuplicated() {
    if (_current.isEmpty) return;
    _requestVersion++;
    _duplicatedValues.add(_current);
    status = CheckStatus.duplicated;
    errorText = _duplicatedMessage;
  }
}
