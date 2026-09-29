import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/main.dart';
import 'package:movielog/router/app_router.dart';

void main() {
  testWidgets('starts on /my and resolves movie routes', (tester) async {
    await tester.pumpWidget(const MovieLogApp());
    await tester.pumpAndSettle();
    expect(find.text('내 프로필'), findsOneWidget);

    AppRouter.router.go('/home');
    await tester.pumpAndSettle();
    expect(find.text('홈'), findsWidgets);

    AppRouter.router.go('/movies');
    await tester.pumpAndSettle();
    expect(find.text('영화 목록'), findsWidgets);

    AppRouter.router.go('/movies/42');
    await tester.pumpAndSettle();
    expect(find.text('영화 ID: 42'), findsOneWidget);

    AppRouter.router.go('/start');
    await tester.pumpAndSettle();
    expect(find.text('시작하기'), findsOneWidget);
  });
}
