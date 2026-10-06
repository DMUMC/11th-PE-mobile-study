import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/main.dart';
import 'package:movielog/movie/data/mock_movies.dart';
import 'package:movielog/movie/widgets/movie_rating_input.dart';
import 'package:movielog/router/app_router.dart';

void main() {
  test('findMovieById returns a movie or null', () {
    expect(findMovieById(1)?.title, '속삭이는 숲');
    expect(findMovieById(null), isNull);
    expect(findMovieById(999), isNull);
  });

  testWidgets('starts on /start and opens the featured movie from home', (
    tester,
  ) async {
    await tester.pumpWidget(const MovieLogApp());
    await tester.pumpAndSettle();
    expect(find.text('시작하기'), findsOneWidget);

    AppRouter.router.go('/home');
    await tester.pumpAndSettle();
    expect(find.text('오늘은 어떤\n영화를 볼까요?'), findsOneWidget);
    expect(find.text('별빛 아래 우리'), findsOneWidget);
    expect(find.text('MovieLog'), findsOneWidget);

    await tester.ensureVisible(find.text('상세보기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('상세보기'));
    await tester.pumpAndSettle();
    expect(find.text('Cinema Archive'), findsOneWidget);
    expect(find.text('별빛 아래 우리'), findsOneWidget);
    expect(find.text('2024 · 로맨스/드라마 · 124분'), findsOneWidget);
    expect(find.text('4.5 (1,245)'), findsOneWidget);
    expect(find.text('시놉시스'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('MovieLog'), findsOneWidget);

    AppRouter.router.go('/movies');
    await tester.pumpAndSettle();
    expect(find.text('우주의 끝에서'), findsOneWidget);
    expect(find.text('별빛 아래 우리'), findsNWidgets(2));

    AppRouter.router.go('/movies/2');
    await tester.pumpAndSettle();
    expect(find.text('공허의 메아리'), findsOneWidget);
    expect(find.text('2024 · SF'), findsOneWidget);

    AppRouter.router.go('/movies/42');
    await tester.pumpAndSettle();
    expect(find.text('영화를 찾을 수 없습니다.'), findsOneWidget);

    AppRouter.router.go('/movies/not-a-number');
    await tester.pumpAndSettle();
    expect(find.text('영화를 찾을 수 없습니다.'), findsOneWidget);

    AppRouter.router.go('/start');
    await tester.pumpAndSettle();
    expect(find.text('시작하기'), findsOneWidget);
  });

  testWidgets('home shows a horizontal popular list and opens its last card', (
    tester,
  ) async {
    AppRouter.router.go('/home');
    await tester.pumpWidget(const MovieLogApp());
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).first, const Offset(0, -800));
    await tester.pumpAndSettle();
    expect(find.text('인기 영화'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('네 번째 오후'));
    await tester.pumpAndSettle();

    expect(find.text('Cinema Archive'), findsOneWidget);
    expect(find.text('네 번째 오후'), findsOneWidget);
    expect(find.text('2025 · 드라마'), findsOneWidget);
  });

  testWidgets('home search and bottom tabs open their destinations', (
    tester,
  ) async {
    AppRouter.router.go('/home');
    await tester.pumpWidget(const MovieLogApp());
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);

    await tester.tap(find.byTooltip('영화 검색'));
    await tester.pumpAndSettle();
    expect(find.text('우주의 끝에서'), findsOneWidget);
    expect(find.byIcon(Icons.movie_rounded), findsOneWidget);

    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle();
    expect(find.text('내 프로필'), findsOneWidget);
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);

    await tester.tap(find.text('홈'));
    await tester.pumpAndSettle();
    expect(find.text('오늘은 어떤\n영화를 볼까요?'), findsOneWidget);
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
  });

  testWidgets('movie catalog filters, searches, and opens the selected movie', (
    tester,
  ) async {
    AppRouter.router.go('/movies');
    await tester.pumpWidget(const MovieLogApp());
    await tester.pumpAndSettle();

    expect(find.text('별빛 아래 우리'), findsNWidgets(2));
    expect(find.text('우주의 끝에서'), findsOneWidget);
    expect(find.text('기억의 숲'), findsOneWidget);
    await tester.tap(find.text('SF'));
    await tester.pumpAndSettle();
    expect(find.text('우주의 끝에서'), findsOneWidget);
    expect(find.text('별빛 아래 우리'), findsNothing);

    await tester.tap(find.text('전체'));
    await tester.tap(find.byTooltip('영화 검색'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '우주의');
    await tester.pumpAndSettle();
    expect(find.text('우주의 끝에서'), findsOneWidget);
    expect(find.text('기억의 숲'), findsNothing);

    await tester.tap(find.text('우주의 끝에서'));
    await tester.pumpAndSettle();
    expect(find.text('Cinema Archive'), findsOneWidget);
    expect(find.text('2024 · SF'), findsOneWidget);
  });

  testWidgets('movie detail actions work from a direct route', (tester) async {
    AppRouter.router.go('/movies/10');
    await tester.pumpWidget(const MovieLogApp());
    await tester.pumpAndSettle();

    expect(find.text('Cinema Archive'), findsOneWidget);
    expect(find.text('즐겨찾기'), findsOneWidget);
    expect(find.text('평점 남기기'), findsOneWidget);
    await tester.tap(find.text('즐겨찾기'));
    await tester.pumpAndSettle();
    expect(find.text('즐겨찾기 완료'), findsOneWidget);

    await tester.tap(find.text('평점 남기기'));
    await tester.pumpAndSettle();
    expect(find.text('영화는 어떠셨나요?'), findsOneWidget);
    expect(find.byType(MovieRatingInput), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text('평점 남기기'), findsOneWidget);

    await tester.tap(find.text('평점 남기기'));
    await tester.pumpAndSettle();
    expect(find.text('다시 선택하기'), findsOneWidget);
    expect(
      tester.widget<MovieRatingInput>(find.byType(MovieRatingInput)).enabled,
      isFalse,
    );
    await tester.tap(find.text('다시 선택하기'));
    await tester.pumpAndSettle();
    expect(find.text('다시 선택하기'), findsNothing);
    expect(
      tester.widget<MovieRatingInput>(find.byType(MovieRatingInput)).enabled,
      isTrue,
    );
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('공유'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('영화 링크를 복사했습니다.'), findsOneWidget);
    await tester.tap(find.byTooltip('뒤로 가기'));
    await tester.pumpAndSettle();
    expect(find.text('우주의 끝에서'), findsOneWidget);
  });

  testWidgets('movie detail keeps its actions visible on a phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    AppRouter.router.go('/movies/10');
    await tester.pumpWidget(const MovieLogApp());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('즐겨찾기'), findsOneWidget);
    expect(find.text('평점 남기기'), findsOneWidget);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();
    expect(find.text('시놉시스'), findsOneWidget);
    expect(find.text('평점 남기기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('start, register, and home do not return to prior screens', (
    tester,
  ) async {
    AppRouter.router.go('/start');
    await tester.pumpWidget(const MovieLogApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();
    final signUpButton = find.widgetWithText(ElevatedButton, '가입하기');
    expect(signUpButton, findsOneWidget);
    expect(tester.widget<ElevatedButton>(signUpButton).onPressed, isNull);
    expect(AppRouter.router.canPop(), isFalse);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(signUpButton, findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), '가');
    await tester.enterText(find.byType(TextField).at(1), 'invalid-email');
    await tester.enterText(find.byType(TextField).at(2), '123');
    await tester.pumpAndSettle();
    expect(find.text('닉네임은 2자 이상이어야 합니다.'), findsOneWidget);
    expect(find.text('올바른 이메일 형식이 아닙니다.'), findsOneWidget);
    expect(find.text('비밀번호는 8자 이상이어야 합니다.'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(signUpButton).onPressed, isNull);

    await tester.enterText(find.byType(TextField).at(0), '홍길동');
    await tester.enterText(find.byType(TextField).at(1), 'hong@example.com');
    await tester.enterText(find.byType(TextField).at(2), 'password123');
    expect(
      tester.widget<TextField>(find.byType(TextField).at(2)).obscureText,
      isTrue,
    );
    await tester.tap(find.byTooltip('비밀번호 표시'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).at(2)).obscureText,
      isFalse,
    );
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(signUpButton).onPressed, isNotNull);

    await tester.ensureVisible(signUpButton);
    await tester.tap(signUpButton);
    await tester.pumpAndSettle();
    expect(find.text('MovieLog'), findsOneWidget);
    expect(AppRouter.router.canPop(), isFalse);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('MovieLog'), findsOneWidget);
  });

  testWidgets('registration form uses the wide layout on a tablet', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    AppRouter.router.go('/register');
    await tester.pumpWidget(const MovieLogApp());
    await tester.pumpAndSettle();

    expect(find.text('환영합니다!'), findsOneWidget);
    expect(find.text('회원가입'), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
  });
}
