import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/movie/movie_list_screen.dart';
import 'package:movielog/movie/widgets/movie_grid.dart';
import 'package:movielog/movie/widgets/movie_list_empty.dart';
import 'package:movielog/movie/widgets/movie_list_error.dart';
import 'package:movielog/movie/widgets/movie_list_loading.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('Loading: 데이터를 기다리는 동안 스켈레톤을 표시한다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MovieListScreen()));

    expect(find.byType(MovieListLoading), findsOneWidget);
    expect(find.byType(MovieGrid), findsNothing);

    await tester.pumpAndSettle();
  });

  testWidgets('Success: 영화 카드를 표시한다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MovieListScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(MovieGrid), findsOneWidget);
    expect(find.text('우주의 끝에서'), findsOneWidget);
    expect(find.byType(MovieListLoading), findsNothing);
  });

  testWidgets('Empty: 빈 목록 안내를 표시한다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MovieListScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('빈 영화 목록 재현'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.byType(MovieListEmpty), findsOneWidget);
    expect(find.text('조건에 맞는 영화가 없습니다.'), findsOneWidget);
    expect(find.byType(MovieGrid), findsNothing);
  });

  testWidgets('Error: 오류 안내와 재시도 버튼을 표시한다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MovieListScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('영화 로드 오류 재현'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.byType(MovieListError), findsOneWidget);
    expect(find.text('영화를 불러오지 못했습니다.'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
    expect(find.byType(MovieGrid), findsNothing);
  });
}
