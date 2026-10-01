import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/main.dart';

void main() {
  Future<void> pumpAt(
    WidgetTester tester,
    String location, {
    Size size = const Size(800, 900),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    appRouter.go(location);
    await tester.pumpWidget(const MovieLogApp());
    await tester.pumpAndSettle();
  }

  tearDown(() {
    appRouter.go('/start');
  });

  testWidgets('시작하기 버튼으로 회원가입 화면에 이동한다', (tester) async {
    await pumpAt(tester, '/start');

    await tester.tap(find.byKey(const Key('startButton')));
    await tester.pumpAndSettle();

    expect(find.text('회원가입'), findsOneWidget);
    expect(appRouter.state.uri.path, '/signup');
  });

  testWidgets('회원가입 완료 후 홈으로 이동한다', (tester) async {
    await pumpAt(tester, '/signup', size: const Size(800, 1100));

    await tester.enterText(find.byKey(const Key('nicknameField')), '무비러버');
    await tester.enterText(
      find.byKey(const Key('emailField')),
      'movie@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('passwordField')),
      'password123',
    );
    await tester.tap(find.byKey(const Key('termsCheckbox')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('signUpButton')));
    await tester.tap(find.byKey(const Key('signUpButton')));
    await tester.pumpAndSettle();

    expect(appRouter.state.uri.path, '/home');
    expect(find.byKey(const Key('mainNavigationBar')), findsOneWidget);
  });

  testWidgets('영화 카드를 누르면 ID가 포함된 상세 화면으로 이동한다', (tester) async {
    await pumpAt(tester, '/home');

    await tester.tap(find.byKey(const Key('featuredMovieCard')));
    await tester.pumpAndSettle();

    expect(appRouter.state.uri.path, '/movies/under-the-starlight');
    expect(find.text('Cinema Archive'), findsOneWidget);
  });

  testWidgets('장르 BottomSheet의 확인 버튼을 누르면 필터가 적용된다', (tester) async {
    await pumpAt(tester, '/movies');

    await tester.tap(find.byKey(const Key('openGenreFilter')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('genre-SF')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('applyGenreFilter')));
    await tester.pumpAndSettle();

    expect(appRouter.state.uri.queryParametersAll['genre'], contains('SF'));
    expect(
      find.byKey(const ValueKey('movie-card-edge-of-space')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('movie-card-spring-coffee')),
      findsNothing,
    );
  });

  testWidgets('즐겨찾기와 평점 Dialog가 동작한다', (tester) async {
    await pumpAt(tester, '/movies/edge-of-space');

    await tester.tap(find.byKey(const Key('favoriteButton')));
    await tester.pump();
    expect(find.text('즐겨찾기에 추가했습니다.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('openRatingDialog')));
    await tester.pumpAndSettle();
    expect(find.text('평점 남기기'), findsWidgets);
    expect(find.byKey(const Key('ratingInput')), findsOneWidget);
  });
}
