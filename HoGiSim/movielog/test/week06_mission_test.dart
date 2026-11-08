import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/main.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/widgets/movielog_button.dart';

import 'support/tmdb_fixture.dart';

void main() {
  testWidgets('두 중복 확인 상태를 독립적으로 갱신하고 오래된 응답은 무시한다', (tester) async {
    final pending = Completer<ResponseBody>();
    final backend = FixtureAdapter(
      respond: (options) async {
        expect(options.method, 'GET');
        expect(options.headers.containsKey('Authorization'), isFalse);
        final value = Uri.decodeComponent(options.path.split('/').last);
        return switch (value) {
          '느린닉네임' => pending.future,
          '중복닉네임' => FixtureAdapter.json({'available': false}),
          'retry@example.com' => FixtureAdapter.json({}, 503),
          'used@example.com' => FixtureAdapter.json({'available': false}),
          _ => FixtureAdapter.json({'available': true}),
        };
      },
    );
    await pumpApp(tester, '/signup', backend);
    final nickname = find.byKey(const Key('nicknameField'));
    final email = find.byKey(const Key('emailField'));
    final nicknameButton = find.byKey(const Key('nicknameCheckButton'));
    final emailButton = find.byKey(const Key('emailCheckButton'));
    ElevatedButton button(Finder finder) => tester.widget<ElevatedButton>(
      find.descendant(of: finder, matching: find.byType(ElevatedButton)),
    );

    expect(button(nicknameButton).onPressed, isNull);
    await tester.enterText(nickname, '느린닉네임');
    await tester.pump();
    await tester.tap(nicknameButton);
    await tester.pump();
    expect(button(nicknameButton).onPressed, isNull);
    expect(
      button(nicknameButton).style!.backgroundColor!
          .resolve({WidgetState.disabled}),
      const Color(0xFF757575),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.enterText(nickname, '  중복닉네임  ');
    await tester.pump();
    await tester.tap(nicknameButton);
    await tester.pumpAndSettle();
    expect(find.text('이미 사용 중인 닉네임입니다.'), findsOneWidget);
    expect(button(nicknameButton).onPressed, isNull);
    pending.complete(FixtureAdapter.json({'available': true}));
    await tester.pumpAndSettle();
    expect(find.text('이미 사용 중인 닉네임입니다.'), findsOneWidget);

    await tester.enterText(nickname, '새닉네임');
    await tester.pump();
    expect(find.text('이미 사용 중인 닉네임입니다.'), findsNothing);
    expect(button(nicknameButton).onPressed, isNotNull);
    await tester.tap(nicknameButton);
    await tester.pumpAndSettle();
    expect(find.text('사용할 수 있는 닉네임입니다.'), findsOneWidget);

    await tester.enterText(nickname, '중복닉네임');
    await tester.pumpAndSettle();
    expect(find.text('사용할 수 있는 닉네임입니다.'), findsNothing);
    expect(find.text('이미 사용 중인 닉네임입니다.'), findsOneWidget);
    expect(button(nicknameButton).onPressed, isNull);

    await tester.enterText(email, 'retry@example.com');
    await tester.pump();
    expect(button(emailButton).onPressed, isNotNull);
    await tester.tap(
      find.descendant(of: emailButton, matching: find.byType(ElevatedButton)),
    );
    await tester.pumpAndSettle();
    expect(find.text('중복 확인에 실패했습니다. 다시 시도해 주세요.'), findsOneWidget);
    expect(button(emailButton).onPressed, isNotNull);

    await tester.enterText(email, 'used@example.com');
    await tester.pump();
    expect(button(emailButton).onPressed, isNotNull);
    await tester.tap(
      find.descendant(of: emailButton, matching: find.byType(ElevatedButton)),
    );
    await tester.pumpAndSettle();
    expect(find.text('이미 사용 중인 이메일입니다.'), findsOneWidget);
    await tester.enterText(email, 'fresh@example.com');
    await tester.pump();
    expect(button(emailButton).onPressed, isNotNull);
    await tester.tap(
      find.descendant(of: emailButton, matching: find.byType(ElevatedButton)),
    );
    await tester.pumpAndSettle();
    expect(find.text('사용할 수 있는 이메일입니다.'), findsOneWidget);
    await tester.enterText(email, 'used@example.com');
    await tester.pumpAndSettle();
    expect(button(emailButton).onPressed, isNull);
    expect(find.text('이미 사용 중인 이메일입니다.'), findsOneWidget);
    expect(backend.requests, hasLength(6));

    final form = find.byKey(const Key('signUpFormContent'));
    final submit = find.byKey(const Key('signUpButton'));
    expect(tester.getSize(submit).width, tester.getSize(form).width);
    expect(
      tester.getSize(nicknameButton).width,
      lessThan(tester.getSize(submit).width),
    );
  });

  testWidgets('마이에서 평점 조회, 실패 후 재시도, 빈 배열을 표시한다', (tester) async {
    final pending = Completer<ResponseBody>();
    final tmdb = fixture();
    final backend = FixtureAdapter(
      respond: (options) {
        expect(options.path, '/v5/members/1/ratings');
        expect(options.method, 'GET');
        return pending.future;
      },
    );
    await pumpApp(tester, '/my', backend, tmdb: tmdb.service);
    await tester.tap(find.text('내가 등록한 평점'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byKey(const Key('mainNavigationBar')), findsNothing);
    expect(find.byType(BackButton), findsOneWidget);

    pending.complete(FixtureAdapter.json({}, 404));
    await tester.pumpAndSettle();
    expect(find.text('존재하지 않는 회원입니다.'), findsOneWidget);
    final retry = find.widgetWithText(MovieLogButton, '다시 시도');
    expect(tester.getSize(retry).width, 96);

    backend.respond = (_) async => FixtureAdapter.json([
      ratingJson(1, 550, '최고의 영화!'),
      ratingJson(2, 550, null),
    ]);
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(find.text('영화 550'), findsNWidgets(2));
    expect(find.text('최고의 영화!'), findsOneWidget);
    expect(find.text('null'), findsNothing);
    expect(
      tmdb.adapter.requests.where((r) => r.path == '/movie/550'),
      hasLength(1),
    );

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mainNavigationBar')), findsOneWidget);
    backend.respond = (_) async => FixtureAdapter.json([]);
    await tester.tap(find.text('내가 등록한 평점'));
    await tester.pumpAndSettle();
    expect(find.text('등록된 평점이 없습니다.'), findsOneWidget);
  });

  testWidgets('TMDB 상세 요청 실패 시 평점과 후기 및 포스터 대체 표시를 유지한다', (tester) async {
    final tmdb = fixture(
      adapter: FixtureAdapter(
        respond: (_) async => FixtureAdapter.json({}, 503),
      ),
    );
    final backend = FixtureAdapter(
      respond: (_) async =>
          FixtureAdapter.json([ratingJson(1, 550, '최고의 영화!')]),
    );
    await pumpApp(tester, '/my/ratings', backend, tmdb: tmdb.service);
    expect(find.text('영화 #550'), findsOneWidget);
    expect(find.text('최고의 영화!'), findsOneWidget);
    expect(find.byKey(const Key('poster-placeholder')), findsOneWidget);
  });
}

Map<String, dynamic> ratingJson(int id, int movieId, String? comment) => {
  'ratingId': id,
  'movieId': movieId,
  'score': 5,
  'comment': comment,
  'createdAt': '2026-09-06T12:14:03.000Z',
};

Future<void> pumpApp(
  WidgetTester tester,
  String location,
  FixtureAdapter backend, {
  TmdbMovieService? tmdb,
}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = createAppRouter(initialLocation: location);
  addTearDown(router.dispose);
  final dio = Dio(BaseOptions(baseUrl: 'https://workbook.devnoco.com'))
    ..httpClientAdapter = backend;
  await tester.pumpWidget(
    MovieLogApp(
      router: router,
      service: tmdb ?? fixture().service,
      workbookClient: dio,
    ),
  );
  await tester.pumpAndSettle();
}
