import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:movielog/main.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/screens/movie_detail_screen.dart';
import 'package:movielog/widgets/movie/movie_card.dart';
import 'package:movielog/widgets/movie/movie_rating_input.dart';
import 'package:movielog/widgets/movie/rating_dialog.dart';

void main() {
  Future<void> openApp(
    WidgetTester tester,
    String route, {
    Size size = const Size(390, 844),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    AppRouter.router.go(route);
    await tester.pumpWidget(const MovieLogApp());
    await tester.pumpAndSettle();
  }

  testWidgets('시작 → 회원가입 → 홈으로 이동하고 이전 화면으로 돌아가지 않는다', (tester) async {
    await openApp(tester, '/start');
    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();
    expect(find.text('회원가입'), findsOneWidget);
    expect(AppRouter.router.canPop(), isFalse);
    for (final entry in [
      '무비러버',
      'movie@example.com',
      'password123',
    ].asMap().entries) {
      await tester.enterText(
        find.byType(TextFormField).at(entry.key),
        entry.value,
      );
    }
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('가입하기'));
    await tester.tap(find.text('가입하기'));
    await tester.pumpAndSettle();
    expect(find.text('MovieLog'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(AppRouter.router.canPop(), isFalse);

    await tester.ensureVisible(find.text('상세보기'));
    await tester.tap(find.text('상세보기'));
    await tester.pumpAndSettle();
    expect(find.text('Cinema Archive'), findsOneWidget);
    expect(AppRouter.router.canPop(), isTrue);
    expect(find.byType(NavigationBar), findsNothing);
    await tester.tap(find.byTooltip('뒤로가기'));
    await tester.pumpAndSettle();
    expect(find.text('MovieLog'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('탭과 장르를 선택하고 해당 영화 ID의 상세에서 목록으로 돌아온다', (tester) async {
    await openApp(tester, '/home');
    await tester.tap(find.byType(NavigationDestination).at(1));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
    await tester.tap(find.widgetWithText(ChoiceChip, 'SF'));
    await tester.pumpAndSettle();
    expect(find.byType(MovieCard), findsOneWidget);
    expect(find.text('우주의 끝에서'), findsOneWidget);
    await tester.tap(find.byType(MovieCard));
    await tester.pumpAndSettle();
    expect(find.text('Cinema Archive'), findsOneWidget);
    expect(
      tester.widget<MovieDetailScreen>(find.byType(MovieDetailScreen)).movieId,
      2,
    );
    expect(find.text('우주의 끝에서'), findsOneWidget);
    await tester.tap(find.byTooltip('뒤로가기'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'SF')).selected,
      isTrue,
    );
    await tester.tap(find.byType(NavigationDestination).at(2));
    await tester.pumpAndSettle();
    expect(find.text('내 프로필'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('평점 Dialog의 선택값을 저장하고 즐겨찾기 추가·삭제를 안내한다', (tester) async {
    await openApp(tester, '/movies/1');
    final indicator = tester.widget<RatingBarIndicator>(
      find.byType(RatingBarIndicator),
    );
    expect(indicator.rating, 4.5);
    await tester.tap(find.text('평점 남기기'));
    await tester.pumpAndSettle();
    expect(find.byType(RatingDialog), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, '확인'))
          .onPressed,
      isNull,
    );
    final input = tester.getRect(find.byType(MovieRatingInput));
    await tester.tapAt(Offset(input.left + 44 * 3 - 4, input.center.dy));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, '확인'))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.byType(RatingDialog), findsNothing);
    expect(find.textContaining('점의 평점을 남겼습니다.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.text('즐겨찾기'));
    await tester.pumpAndSettle();
    expect(find.text('즐겨찾기에 추가했습니다.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.text('즐겨찾기'));
    await tester.pumpAndSettle();
    expect(find.text('즐겨찾기에서 삭제했습니다.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('작은 화면에서도 목록·프로필·평점 Dialog가 넘치지 않고 잘못된 ID를 안내한다', (tester) async {
    await openApp(tester, '/movies', size: const Size(320, 568));
    expect(tester.takeException(), isNull);
    AppRouter.router.go('/my');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    AppRouter.router.go('/movies/1');
    await tester.pumpAndSettle();
    await tester.tap(find.text('평점 남기기'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    Navigator.of(tester.element(find.byType(RatingDialog))).pop();
    await tester.pumpAndSettle();
    AppRouter.router.go('/movies/invalid');
    await tester.pumpAndSettle();
    expect(find.text('영화를 찾을 수 없습니다.'), findsOneWidget);
    await tester.tap(find.byTooltip('뒤로가기'));
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
