import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/movie/data/genre_preference.dart';
import 'package:movielog/movie/movie_list_screen.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('movie list remains usable when preferences are unavailable', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferencesAsyncPlatform.instance = null;

    await tester.pumpWidget(const MaterialApp(home: MovieListScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('우주의 끝에서'), findsOneWidget);
    await tester.tap(find.byTooltip('장르 필터'));
    await tester.pumpAndSettle();
    expect(find.text('여러 장르를 선택할 수 있어요'), findsOneWidget);
  });

  testWidgets('confirmed genre is restored when the movie route opens again', (
    tester,
  ) async {
    GoRouter createRouter() => GoRouter(
      initialLocation: '/movies',
      routes: [
        GoRoute(
          path: '/movies',
          builder: (context, state) => MovieListScreen(
            initialGenreQuery: state.uri.queryParameters['genre'],
          ),
        ),
      ],
    );

    final firstRouter = createRouter();
    addTearDown(firstRouter.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: firstRouter));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('장르 필터'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SF'));
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(await GenrePreference().read(), 'SF');

    await tester.pumpWidget(const SizedBox.shrink());
    final secondRouter = createRouter();
    addTearDown(secondRouter.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: secondRouter));
    await tester.pumpAndSettle();

    expect(find.text('우주의 끝에서'), findsOneWidget);
    expect(find.text('기억의 숲'), findsNothing);
  });
}
