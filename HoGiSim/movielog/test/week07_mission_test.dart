import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/widgets/movie_rating_input.dart';
import 'package:movielog/widgets/rating_dialog.dart';

import 'support/tmdb_fixture.dart';
import 'week06_mission_test.dart' show pumpApp, ratingJson;

const _memberId = 42;
const _ratingsPath = '/v6/members/42/ratings';
const _password = 'Testpass1!';

Map<String, dynamic> _envelope(
  int status, {
  String message = '완료',
  Object? result,
}) => {
  'isSuccess': status < 400,
  'code': 'COMMON$status',
  'message': message,
  'result': result,
};

Future<void> _tap(
  WidgetTester tester,
  Finder finder, {
  bool wait = true,
}) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  if (wait) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Finder _key(String value) => find.byKey(ValueKey(value));
Finder _button(String key) =>
    find.descendant(of: _key(key), matching: find.byType(ElevatedButton));

Future<void> _fillAndCheckSignup(WidgetTester tester) async {
  await tester.enterText(_key('nicknameField'), ' 영화팬 ');
  await tester.enterText(_key('emailField'), 'fan@example.com');
  await tester.enterText(_key('passwordField'), _password);
  await _tap(tester, _key('termsCheckbox'));
  expect(
    tester.widget<ElevatedButton>(_button('signUpButton')).onPressed,
    isNull,
  );
  await _tap(tester, _button('nicknameCheckButton'));
  expect(
    tester.widget<ElevatedButton>(_button('signUpButton')).onPressed,
    isNull,
  );
  await _tap(tester, _button('emailCheckButton'));
  expect(
    tester.widget<ElevatedButton>(_button('signUpButton')).onPressed,
    isNotNull,
  );
}

void main() {
  testWidgets('학습용 회원 없이 마이페이지를 열면 서버를 호출하지 않는다', (tester) async {
    final backend = FixtureAdapter();
    await pumpApp(tester, '/my/ratings', backend);
    expect(find.text('학습용 회원가입이 필요합니다.'), findsOneWidget);
    expect(backend.requests, isEmpty);
  });

  testWidgets('평점 수정 400, 403, 404의 메시지와 목록 갱신을 구분한다', (tester) async {
    const ratingId = 71;
    var status = 400;
    final messages = {
      400: '별점 형식을 확인해 주세요.',
      403: '본인이 작성한 평점만 수정하거나 삭제할 수 있습니다.',
      404: '존재하지 않는 평점입니다.',
    };
    final backend = FixtureAdapter(
      respond: (options) async {
        if (options.method == 'GET') {
          return FixtureAdapter.json([
            if (status != 404) ratingJson(ratingId, 550, '기존 코멘트'),
          ]);
        }
        expect(options.method, 'PATCH');
        expect(options.path, '$_ratingsPath/$ratingId');
        expect(options.data, {'score': 5, 'comment': '수정 중인 코멘트'});
        return FixtureAdapter.json(
          _envelope(status, message: messages[status]!),
          status,
        );
      },
    );
    await pumpApp(tester, '/my/ratings', backend, memberId: _memberId);
    await _tap(tester, _key('editRating-$ratingId'));
    await tester.enterText(_key('ratingCommentField'), '수정 중인 코멘트');
    for (final code in [400, 403, 404]) {
      status = code;
      await _tap(tester, _button('submitRatingButton'));
      expect(find.text(messages[code]!), findsOneWidget);
      final field = tester.widget<TextField>(_key('ratingCommentField'));
      expect(field.controller!.text, '수정 중인 코멘트');
      expect(backend.requests.last.method, code == 400 ? 'PATCH' : 'GET');
    }
    await _tap(tester, find.text('취소'));
    expect(find.text('등록된 평점이 없습니다.'), findsOneWidget);
  });

  testWidgets('가입 제출 중 이탈을 차단하고 비밀번호 400, 기타 400, 최종 409를 구분한다', (
    tester,
  ) async {
    final pending = Completer<ResponseBody>();
    var submits = 0;
    final backend = FixtureAdapter(
      respond: (options) async {
        if (options.method == 'GET') {
          return FixtureAdapter.json({'available': true});
        }
        submits++;
        return switch (submits) {
          1 => pending.future,
          2 => FixtureAdapter.json(
            _envelope(400, message: '이메일 형식을 확인해 주세요.'),
            400,
          ),
          _ => FixtureAdapter.json(
            _envelope(409, message: '이미 사용 중인 이메일입니다.'),
            409,
          ),
        };
      },
    );
    await pumpApp(tester, '/start', backend);
    await _tap(tester, _key('startButton'));
    await _fillAndCheckSignup(tester);

    await _tap(tester, _button('signUpButton'), wait: false);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.tap(_button('signUpButton'));
    expect(find.text('회원가입'), findsOneWidget);
    expect(submits, 1);
    pending.complete(
      FixtureAdapter.json(_envelope(400, message: '비밀번호 형식을 확인해 주세요.'), 400),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextFormField>(_key('passwordField')).forceErrorText,
      '비밀번호 형식을 확인해 주세요.',
    );

    await tester.enterText(_key('passwordField'), 'Changed1!');
    await tester.pump();
    expect(
      tester.widget<TextFormField>(_key('passwordField')).forceErrorText,
      isNull,
    );
    await _tap(tester, _button('signUpButton'));
    expect(find.widgetWithText(SnackBar, '이메일 형식을 확인해 주세요.'), findsOneWidget);
    await _tap(tester, _button('signUpButton'));
    expect(find.widgetWithText(SnackBar, '이미 사용 중인 이메일입니다.'), findsOneWidget);
    expect(
      tester.widget<TextFormField>(_key('passwordField')).forceErrorText,
      isNull,
    );
    await tester.enterText(_key('emailField'), 'other@example.com');
    await tester.pumpAndSettle();
    expect(
      tester.widget<ElevatedButton>(_button('signUpButton')).onPressed,
      isNull,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(_key('startButton'), findsOneWidget);
  });

  testWidgets('가입 ID와 TMDB ID로 등록하고 수정, GET 재시도, 삭제까지 이어진다', (tester) async {
    const ratingId = 71;
    const movieId = 550;
    const comment = '좋았어요';
    const unavailable = '저장은 완료됐지만 목록을 불러오지 못했습니다. 조회만 다시 시도해 주세요.';
    final pendingCreate = Completer<ResponseBody>();
    final pendingDelete = Completer<ResponseBody>();
    Map<String, dynamic>? rating;
    var posts = 0;
    var patches = 0;
    var deletes = 0;
    var failRead = false;
    final backend = FixtureAdapter(
      respond: (options) async {
        expect(options.headers.containsKey('Authorization'), isFalse);
        if (options.path.startsWith('/v6/members/nickname/') ||
            options.path.startsWith('/v6/members/email/')) {
          return FixtureAdapter.json({'available': true});
        }
        if (options.path == '/v6/members') {
          expect(options.method, 'POST');
          expect(options.data, {
            'nickname': '영화팬',
            'email': 'fan@example.com',
            'password': _password,
          });
          return FixtureAdapter.json(
            _envelope(
              201,
              result: {
                'memberId': _memberId,
                'email': 'fan@example.com',
                'nickname': '영화팬',
              },
            ),
            201,
          );
        }
        switch (options.method) {
          case 'POST':
            expect(options.path, _ratingsPath);
            expect(options.data, {
              'movieId': movieId,
              'score': 4,
              'comment': comment,
            });
            if (++posts == 1) return pendingCreate.future;
            rating = {...ratingJson(ratingId, movieId, comment), 'score': 4};
            return FixtureAdapter.json(_envelope(201), 201);
          case 'GET':
            expect(options.path, _ratingsPath);
            if (failRead) return FixtureAdapter.json(_envelope(503), 503);
            return FixtureAdapter.json([?rating]);
          case 'PATCH':
            expect(options.path, '$_ratingsPath/$ratingId');
            expect(options.data, {'score': 4, 'comment': null});
            patches++;
            rating!['comment'] = null;
            failRead = true;
            return FixtureAdapter.json(_envelope(200));
          case 'DELETE':
            expect(options.path, '$_ratingsPath/$ratingId');
            deletes++;
            rating = null;
            return pendingDelete.future;
          default:
            throw StateError('Unexpected request');
        }
      },
    );

    await pumpApp(tester, '/signup', backend);
    await _fillAndCheckSignup(tester);
    await _tap(tester, _button('signUpButton'));
    expect(find.text('회원가입을 완료했습니다. 회원 ID 42'), findsOneWidget);
    final router = GoRouter.of(tester.element(_key('mainNavigationBar')));
    expect(router.state.uri.path, '/movies');

    router.push<void>('/movies/$movieId');
    await tester.pumpAndSettle();
    await _tap(tester, _key('openRatingDialog'));
    final confirm = _button('submitRatingButton');
    expect(tester.widget<ElevatedButton>(confirm).onPressed, isNull);
    await tester.enterText(_key('ratingCommentField'), ' $comment ');
    await tester.pump();
    expect(tester.widget<ElevatedButton>(confirm).onPressed, isNull);
    final stars = _key('ratingInput');
    await tester.tapAt(
      tester.getTopLeft(stars) + Offset(tester.getSize(stars).width * .7, 20),
    );
    await tester.pumpAndSettle();
    await _tap(tester, confirm, wait: false);
    await tester.binding.handlePopRoute();
    await tester.tap(confirm);
    expect(find.byType(RatingDialog), findsOneWidget);
    expect(posts, 1);
    pendingCreate.complete(
      FixtureAdapter.json(_envelope(409, message: '이미 이 영화에 평점을 남기셨습니다.'), 409),
    );
    await tester.pumpAndSettle();
    expect(find.text('이미 이 영화에 평점을 남기셨습니다.'), findsOneWidget);
    expect(
      tester.widget<TextField>(_key('ratingCommentField')).controller!.text,
      ' $comment ',
    );
    expect(
      tester.widget<MovieRatingInput>(find.byType(MovieRatingInput)).rating,
      4,
    );

    await _tap(tester, confirm);
    expect(find.byType(RatingDialog), findsNothing);
    expect(find.textContaining('평점을 등록했습니다.'), findsOneWidget);
    expect(router.state.uri.path, '/movies/$movieId');
    expect(
      backend.requests.where(
        (request) => request.path == _ratingsPath && request.method == 'GET',
      ),
      isEmpty,
    );
    router.go('/my');
    await tester.pumpAndSettle();
    await _tap(tester, find.text('내가 등록한 평점'));
    expect(find.text('학습용 회원 42의 평점'), findsOneWidget);
    expect(find.text('영화 $movieId'), findsOneWidget);
    expect(find.text(comment), findsOneWidget);
    expect(_key('mainNavigationBar'), findsNothing);

    await _tap(tester, _key('editRating-$ratingId'));
    expect(
      tester.widget<MovieRatingInput>(find.byType(MovieRatingInput)).rating,
      4,
    );
    expect(
      tester.widget<TextField>(_key('ratingCommentField')).controller!.text,
      comment,
    );
    await tester.enterText(_key('ratingCommentField'), '   ');
    await _tap(tester, confirm);
    expect(find.byType(RatingDialog), findsNothing);
    expect(find.text(unavailable), findsOneWidget);
    expect(patches, 1);
    failRead = false;
    await _tap(tester, find.text('다시 시도'));
    expect(backend.requests.last.method, 'GET');
    expect(patches, 1);
    expect(find.text(comment), findsNothing);

    await _tap(tester, _key('deleteRating-$ratingId'));
    await _tap(tester, find.text('취소'));
    expect(deletes, 0);
    await _tap(tester, _key('deleteRating-$ratingId'));
    await _tap(tester, find.text('삭제'), wait: false);
    expect(find.text('평점을 삭제할까요?'), findsOneWidget);
    await tester.binding.handlePopRoute();
    expect(find.text('평점을 삭제할까요?'), findsOneWidget);
    pendingDelete.complete(ResponseBody.fromString('', 204));
    await tester.pumpAndSettle();
    expect(deletes, 1);
    expect(backend.requests.last.method, 'GET');
    expect(find.text('등록된 평점이 없습니다.'), findsOneWidget);
  });

  testWidgets('다중 삭제 중 오버레이를 유지하고 실패한 항목만 다시 선택할 수 있다', (tester) async {
    final pending = Completer<ResponseBody>();
    final ratings = [ratingJson(71, 550, null), ratingJson(72, 551, '유지할 후기')];
    var failed = true;
    final backend = FixtureAdapter(
      respond: (options) async {
        if (options.method == 'GET') return FixtureAdapter.json(ratings);
        if (options.path.endsWith('/71')) {
          final response = await pending.future;
          ratings.removeAt(0);
          return response;
        }
        if (failed) {
          return FixtureAdapter.json(
            _envelope(403, message: '삭제 권한이 없습니다.'),
            403,
          );
        }
        ratings.clear();
        return ResponseBody.fromString('', 204);
      },
    );
    await pumpApp(tester, '/my', backend, memberId: _memberId);
    await _tap(tester, find.text('내가 등록한 평점'));
    await _tap(tester, find.text('편집'));
    expect(find.byTooltip('평점 수정'), findsNothing);
    await _tap(tester, _key('selectRating-71'));
    await _tap(tester, _key('selectRating-72'));
    expect(find.text('2개 선택'), findsOneWidget);
    await _tap(tester, find.text('선택한 2개 삭제'));
    await _tap(tester, find.text('삭제'), wait: false);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.bySemanticsLabel('평점 삭제 중'), findsOneWidget);
    await tester.binding.handlePopRoute();
    expect(find.bySemanticsLabel('평점 삭제 중'), findsOneWidget);
    pending.complete(ResponseBody.fromString('', 204));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('평점 삭제 중'), findsNothing);
    expect(_key('selectRating-71'), findsNothing);
    expect(tester.widget<Checkbox>(_key('selectRating-72')).value, isTrue);
    expect(find.textContaining('1개를 삭제했고 1개를 삭제하지 못했습니다.'), findsOneWidget);
    failed = false;
    await _tap(tester, find.text('선택한 1개 삭제'));
    await _tap(tester, find.text('삭제'));
    expect(find.text('등록된 평점이 없습니다.'), findsOneWidget);
  });
}
