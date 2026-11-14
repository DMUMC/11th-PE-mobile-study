import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/check_result.dart';
import 'package:movielog/data/services/member_check_service.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';

void main() {
  test('v5 parses a direct boolean object and rejects a result wrapper', () {
    expect(CheckResult.fromJson({'available': true}).available, isTrue);
    expect(CheckResult.fromJson({'available': false}).available, isFalse);
    expect(
      () => CheckResult.fromJson({
        'result': {'available': true},
      }),
      throwsFormatException,
    );
  });

  test(
    'service trims and encodes path components, preserving false as a result',
    () async {
      final adapter = _ResponseAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://workbook.devnoco.com'))
        ..httpClientAdapter = adapter;
      addTearDown(() => dio.close());
      final service = MemberCheckService(dio);
      expect(await service.checkNickname(' 영화/광? '), isFalse);
      expect(adapter.uri!.pathSegments.last, '영화/광?');
      expect(adapter.uri.toString(), contains('%2F'));
      expect(await service.checkEmail(' movie+qa@example.com '), isFalse);
      expect(adapter.uri!.pathSegments.last, 'movie+qa@example.com');
    },
  );

  test('seeded nickname can be checked on the first press; duplicate is remembered', () async {
    final service = _PendingService();
    final vm = SignUpViewModel(service, initialNickname: '영화광');
    addTearDown(vm.dispose);
    expect(vm.nicknameCheckStatus, CheckStatus.idle);
    final request = vm.checkNickname('영화광');
    expect(vm.nicknameCheckStatus, CheckStatus.checking);
    expect(vm.canCheckNickname, isFalse);
    await vm.checkNickname('영화광');
    expect(service.nicknames, ['영화광']);
    service.nicknameResults.single.complete(false);
    await request;
    expect(vm.nicknameCheckStatus, CheckStatus.duplicated);
    expect(vm.canCheckNickname, isFalse);
    vm.onNicknameChanged('새영화광');
    expect(vm.nicknameCheckStatus, CheckStatus.idle);
    expect(vm.nicknameErrorText, isNull);
    vm.onNicknameChanged(' 영화광 ');
    expect(vm.nicknameCheckStatus, CheckStatus.duplicated);
    expect(service.nicknames, ['영화광']);
  });

  test('editing invalidates availability and a late older response cannot replace the new result', () async {
    final service = _PendingService();
    final vm = SignUpViewModel(service, initialNickname: '이전닉네임');
    addTearDown(vm.dispose);
    final oldRequest = vm.checkNickname('이전닉네임');
    vm.onNicknameChanged('새닉네임');
    final newRequest = vm.checkNickname('새닉네임');
    service.nicknameResults[1].complete(true);
    await newRequest;
    service.nicknameResults[0].complete(false);
    await oldRequest;
    expect(vm.nicknameCheckStatus, CheckStatus.available);
    expect(vm.nicknameErrorText, isNull);
    vm.onNicknameChanged('다른닉네임');
    expect(vm.nicknameCheckStatus, CheckStatus.idle);
    expect(vm.checksPassed, isFalse);
  });

  test(
    'nickname and email requests have independent versions and results',
    () async {
      final service = _PendingService();
      final vm = SignUpViewModel(
        service,
        initialNickname: '닉네임',
        initialEmail: 'test@example.com',
      );
      addTearDown(vm.dispose);
      final nicknameRequest = vm.checkNickname('닉네임');
      final emailRequest = vm.checkEmail('test@example.com');
      vm.onNicknameChanged('변경닉네임');
      service.emailResults.single.complete(true);
      await emailRequest;
      service.nicknameResults.single.complete(false);
      await nicknameRequest;
      expect(vm.emailCheckStatus, CheckStatus.available);
      expect(vm.nicknameCheckStatus, CheckStatus.idle);
      vm.onEmailChanged('other@example.com');
      expect(vm.emailCheckStatus, CheckStatus.idle);
    },
  );

  test(
    'transport failure stays retryable and is distinct from duplicated',
    () async {
      final service = _PendingService();
      final vm = SignUpViewModel(service, initialNickname: '닉네임');
      addTearDown(vm.dispose);
      final request = vm.checkNickname('닉네임');
      service.nicknameResults.single.completeError(
        DioException(
          requestOptions: RequestOptions(path: '/v5/members/nickname/닉네임'),
          type: DioExceptionType.connectionError,
        ),
      );
      await request;
      expect(vm.nicknameCheckStatus, CheckStatus.error);
      expect(vm.nicknameErrorText, contains('실패'));
      expect(vm.canCheckNickname, isTrue);
      final retry = vm.checkNickname('닉네임');
      service.nicknameResults.last.complete(true);
      await retry;
      expect(vm.nicknameCheckStatus, CheckStatus.available);
    },
  );

  test('malformed response exits checking and can be retried', () async {
    final service = _PendingService();
    final vm = SignUpViewModel(service, initialEmail: 'test@example.com');
    addTearDown(vm.dispose);
    final request = vm.checkEmail('test@example.com');
    service.emailResults.single.completeError(
      const FormatException('bad body'),
    );
    await request;
    expect(vm.emailCheckStatus, CheckStatus.error);
    expect(vm.canCheckEmail, isTrue);
  });

  test('responses after dispose do not notify listeners', () async {
    final service = _PendingService();
    final vm = SignUpViewModel(service, initialNickname: '닉네임');
    var notifications = 0;
    vm.addListener(() => notifications++);
    final request = vm.checkNickname('닉네임');
    vm.dispose();
    service.nicknameResults.single.complete(true);
    await request;
    expect(notifications, 1);
  });
}

class _ResponseAdapter implements HttpClientAdapter {
  Uri? uri;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    uri = options.uri;
    return ResponseBody.fromString(
      jsonEncode({'available': false}),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _PendingService extends MemberCheckService {
  _PendingService() : super(Dio());
  final nicknames = <String>[];
  final nicknameResults = <Completer<bool>>[];
  final emailResults = <Completer<bool>>[];

  @override
  Future<bool> checkNickname(String nickname) {
    nicknames.add(nickname);
    final result = Completer<bool>();
    nicknameResults.add(result);
    return result.future;
  }

  @override
  Future<bool> checkEmail(String email) {
    final result = Completer<bool>();
    emailResults.add(result);
    return result.future;
  }
}
