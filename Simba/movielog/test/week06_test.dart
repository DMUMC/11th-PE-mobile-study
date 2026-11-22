import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';
import 'package:movielog/widgets/movielog_button.dart';

/// 응답을 테스트에서 직접 완료시킬 수 있는 가짜 Service
class FakeMemberCheckService implements SignUpService {
  final calls = <String>[];
  final pending = <Completer<bool>>[];

  @override
  Future<bool> checkNickname(String nickname) {
    calls.add(nickname);
    final completer = Completer<bool>();
    pending.add(completer);
    return completer.future;
  }

  @override
  Future<bool> checkEmail(String email) => checkNickname(email);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

DioException dioError([int? status]) {
  final options = RequestOptions(path: '/');
  return DioException(
    requestOptions: options,
    response: status == null
        ? null
        : Response(requestOptions: options, statusCode: status),
    type: status == null
        ? DioExceptionType.connectionError
        : DioExceptionType.badResponse,
  );
}

void main() {
  group('RatingDto', () {
    test('comment가 null이어도 파싱된다', () {
      final dto = RatingDto.fromJson({
        'ratingId': 3,
        'movieId': 13,
        'score': 3,
        'comment': null,
        'createdAt': '2026-11-07T19:00:16.676Z',
        'updatedAt': '2026-11-07T19:00:16.676Z',
      });
      expect(dto.comment, isNull);
      expect(dto.movieId, 13);
      expect(dto.createdAt.isUtc, isTrue);
    });
  });

  group('SignUpViewModel', () {
    late FakeMemberCheckService service;
    late SignUpViewModel vm;

    setUp(() {
      service = FakeMemberCheckService();
      vm = SignUpViewModel(service);
    });

    test('확인 전 → 통신 중 → 사용 가능', () async {
      vm.onNicknameChanged('심바');
      expect(vm.nicknameCheckStatus, CheckStatus.idle);

      final future = vm.checkNickname('심바');
      expect(vm.nicknameCheckStatus, CheckStatus.checking);
      expect(vm.canCheckNickname, isFalse);

      service.pending.single.complete(true);
      await future;
      expect(vm.nicknameCheckStatus, CheckStatus.available);
      expect(vm.nicknameErrorText, isNull);
    });

    test('중복 → 버튼 비활성, 수정하면 idle, 같은 값 재입력은 재요청 없이 즉시 중복', () async {
      vm.onNicknameChanged('영화광');
      final future = vm.checkNickname('영화광');
      service.pending.single.complete(false);
      await future;
      expect(vm.nicknameCheckStatus, CheckStatus.duplicated);
      expect(vm.nicknameErrorText, '이미 사용 중인 닉네임입니다.');
      expect(vm.canCheckNickname, isFalse);

      vm.onNicknameChanged('영화');
      expect(vm.nicknameCheckStatus, CheckStatus.idle);
      expect(vm.nicknameErrorText, isNull);
      expect(vm.canCheckNickname, isTrue);

      vm.onNicknameChanged(' 영화광 '); // trim 후 같은 문자열
      expect(vm.nicknameCheckStatus, CheckStatus.duplicated);
      expect(vm.canCheckNickname, isFalse);
      expect(service.calls, ['영화광']); // API는 한 번만
    });

    test('통신 실패는 중복과 다른 문구 + 다시 시도 가능', () async {
      vm.onNicknameChanged('심바');
      final future = vm.checkNickname('심바');
      service.pending.single.completeError(dioError());
      await future;
      expect(vm.nicknameCheckStatus, CheckStatus.error);
      expect(vm.nicknameErrorText, '닉네임 중복 확인에 실패했습니다. 다시 시도해 주세요.');
      expect(vm.canCheckNickname, isTrue);
    });

    test('통신 중에 입력을 바꾸면 늦게 온 이전 응답은 무시된다', () async {
      vm.onNicknameChanged('심바');
      final future = vm.checkNickname('심바');
      vm.onNicknameChanged('심바2');
      service.pending.single.complete(true);
      await future;
      expect(vm.nicknameCheckStatus, CheckStatus.idle);
    });

    test('닉네임과 이메일 상태는 서로 영향을 주지 않는다', () async {
      vm.onNicknameChanged('영화광');
      final future = vm.checkNickname('영화광');
      service.pending.single.complete(false);
      await future;
      vm.onEmailChanged('a@b.com');
      expect(vm.nicknameCheckStatus, CheckStatus.duplicated);
      expect(vm.emailCheckStatus, CheckStatus.idle);
    });
  });

  group('MovieLogButton', () {
    testWidgets('isLoading이면 비활성 + 인디케이터만 보인다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MovieLogButton(
              label: '중복 확인',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('중복 확인'), findsNothing);
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('width null / infinity / 고정 값의 너비가 다르다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MovieLogButton(
                    key: const Key('null'),
                    label: '확인',
                    onPressed: () {},
                  ),
                  MovieLogButton(
                    key: const Key('inf'),
                    label: '확인',
                    width: double.infinity,
                    onPressed: () {},
                  ),
                  MovieLogButton(
                    key: const Key('fixed'),
                    label: '확인',
                    width: 96,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      final nullWidth = tester.getSize(find.byKey(const Key('null'))).width;
      expect(nullWidth, lessThan(360));
      expect(tester.getSize(find.byKey(const Key('inf'))).width, 360);
      expect(tester.getSize(find.byKey(const Key('fixed'))).width, 96);
    });
  });
}
