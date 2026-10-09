import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/movie/movie_list_screen.dart';
import 'package:movielog/movie/widgets/movie_list_timeout.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('slow load shows timeout error and retry restores movies', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: MovieListScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('영화 로드 시간 초과 재현'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.text('응답 시간이 초과되었습니다. 다시 시도해 주세요.'), findsOneWidget);
    expect(find.byType(MovieListTimeout), findsOneWidget);
    await tester.tap(find.text('다시 시도'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('우주의 끝에서'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    expect(find.text('우주의 끝에서'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
