import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/movie/model/movie.dart';
import 'package:movielog/movie/movie_list_screen.dart';
import 'package:movielog/movie/widgets/movie_list_empty.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('pulling the movie grid and empty state reloads the list', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: MovieListScreen()));
    await tester.pumpAndSettle();

    final initialFuture = tester
        .widget<FutureBuilder<List<Movie>>>(
          find.byType(FutureBuilder<List<Movie>>),
        )
        .future;
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(GridView)),
    );
    await gesture.moveBy(const Offset(0, 300));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 300));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    await tester.pumpAndSettle();
    final refreshedFuture = tester
        .widget<FutureBuilder<List<Movie>>>(
          find.byType(FutureBuilder<List<Movie>>),
        )
        .future;

    expect(refreshedFuture, isNot(same(initialFuture)));
    expect(find.byType(GridView), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('우주의 끝에서'), findsOneWidget);

    await tester.tap(find.byTooltip('빈 영화 목록 재현'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(MovieListEmpty), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 500));
    await tester.pumpAndSettle();
    expect(find.text('우주의 끝에서'), findsOneWidget);
  });
}
