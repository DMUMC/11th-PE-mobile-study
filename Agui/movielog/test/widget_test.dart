import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/main.dart';
import 'package:movielog/movie/data/mock_movies.dart';
import 'package:movielog/router/app_router.dart';

void main() {
  test('findMovieById returns a movie or null', () {
    expect(findMovieById(1)?.title, '속삭이는 숲');
    expect(findMovieById(null), isNull);
    expect(findMovieById(999), isNull);
  });

  testWidgets('starts on /start and shows the movie grid', (tester) async {
    await tester.pumpWidget(const MovieLogApp());
    await tester.pumpAndSettle();
    expect(find.text('시작하기'), findsOneWidget);

    AppRouter.router.go('/home');
    await tester.pumpAndSettle();
    expect(find.text('추천 영화'), findsOneWidget);
    expect(find.text('속삭이는 숲'), findsOneWidget);

    await tester.tap(find.text('속삭이는 숲'));
    await tester.pumpAndSettle();
    expect(find.text('영화 상세'), findsOneWidget);
    expect(find.text('속삭이는 숲'), findsOneWidget);
    expect(find.text('판타지 · 2024'), findsOneWidget);

    AppRouter.router.go('/movies');
    await tester.pumpAndSettle();
    expect(find.text('영화 목록'), findsWidgets);
    expect(find.text('속삭이는 숲'), findsOneWidget);

    AppRouter.router.go('/movies/2');
    await tester.pumpAndSettle();
    expect(find.text('공허의 메아리'), findsOneWidget);
    expect(find.text('SF · 2024'), findsOneWidget);

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
}
