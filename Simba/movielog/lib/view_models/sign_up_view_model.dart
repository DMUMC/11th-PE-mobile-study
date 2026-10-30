import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/models/availability_dto.dart';
import '../data/services/movielog_member_service.dart';

enum DuplicateCheckStatus { idle, checking, available, duplicated, error }

/// 닉네임 또는 이메일 한 칸의 중복 확인 상태
class DuplicateCheckState {
  const DuplicateCheckState(this.status, [this.message]);

  static const idle = DuplicateCheckState(DuplicateCheckStatus.idle);

  final DuplicateCheckStatus status;
  final String? message;

  bool get isChecking => status == DuplicateCheckStatus.checking;
  bool get isAvailable => status == DuplicateCheckStatus.available;
  bool get hasError =>
      status == DuplicateCheckStatus.duplicated ||
      status == DuplicateCheckStatus.error;
}

/// 회원가입 화면 ViewModel.
/// 형식 검사(글자 수, 이메일 모양)는 화면에서, 중복 여부는 서버에서 확인한다.
class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel(
    MovieLogMemberService service, {
    Duration debounce = const Duration(milliseconds: 500),
  }) {
    _nickname = _DuplicateChecker(
      label: '닉네임',
      request: service.checkNickname,
      debounce: debounce,
      onChanged: notifyListeners,
    );
    _email = _DuplicateChecker(
      label: '이메일',
      request: service.checkEmail,
      debounce: debounce,
      onChanged: notifyListeners,
    );
  }

  late final _DuplicateChecker _nickname;
  late final _DuplicateChecker _email;

  DuplicateCheckState get nicknameCheck => _nickname.state;
  DuplicateCheckState get emailCheck => _email.state;

  /// 입력이 바뀔 때마다 호출한다. 형식이 맞을 때만 잠시 기다렸다가 서버에 확인한다.
  void onNicknameChanged(String nickname, {required bool isFormatValid}) {
    _nickname.update(nickname, isFormatValid: isFormatValid);
  }

  void onEmailChanged(String email, {required bool isFormatValid}) {
    _email.update(email, isFormatValid: isFormatValid);
  }

  @override
  void dispose() {
    _nickname.dispose();
    _email.dispose();
    super.dispose();
  }
}

/// 입력이 멈춘 뒤 [debounce]만큼 기다렸다가 한 번만 요청하고,
/// 늦게 도착한 이전 입력의 응답은 버전 번호로 무시한다.
class _DuplicateChecker {
  _DuplicateChecker({
    required this.label,
    required this.request,
    required this.debounce,
    required this.onChanged,
  });

  final String label;
  final Future<AvailabilityDto> Function(String value) request;
  final Duration debounce;
  final VoidCallback onChanged;

  DuplicateCheckState state = DuplicateCheckState.idle;

  Timer? _timer;
  String? _value;
  int _version = 0;
  bool _disposed = false;

  void update(String value, {required bool isFormatValid}) {
    if (!isFormatValid) {
      _cancel();
      _value = null;
      _setState(DuplicateCheckState.idle);
      return;
    }
    // 같은 값을 이미 확인했거나 확인 중이면 다시 요청하지 않는다.
    if (value == _value) return;

    _cancel();
    _value = value;
    final version = _version;
    _setState(const DuplicateCheckState(DuplicateCheckStatus.checking));
    _timer = Timer(debounce, () => _check(value, version));
  }

  Future<void> _check(String value, int version) async {
    try {
      final result = await request(value);
      if (_isStale(version)) return;
      _setState(
        result.available
            ? DuplicateCheckState(
                DuplicateCheckStatus.available,
                '사용 가능한 $label이에요.',
              )
            : DuplicateCheckState(
                DuplicateCheckStatus.duplicated,
                '이미 사용 중인 $label이에요.',
              ),
      );
    } on DioException catch (error) {
      if (_isStale(version)) return;
      final message = error.response?.statusCode == 400
          ? serverMessageOf(error) ?? '$label 형식을 확인해 주세요.'
          : isConnectionProblem(error)
          ? '서버에 연결할 수 없어 중복 확인을 하지 못했어요.'
          : '$label 중복 확인에 실패했어요.';
      // 같은 값으로 다시 시도할 수 있도록 마지막 값을 비운다.
      _value = null;
      _setState(DuplicateCheckState(DuplicateCheckStatus.error, message));
    }
  }

  bool _isStale(int version) => _disposed || version != _version;

  void _cancel() {
    _timer?.cancel();
    _timer = null;
    _version++;
  }

  void _setState(DuplicateCheckState next) {
    state = next;
    if (!_disposed) onChanged();
  }

  void dispose() {
    _disposed = true;
    _cancel();
  }
}
