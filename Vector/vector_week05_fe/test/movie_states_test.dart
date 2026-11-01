import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_week01/screens/movies_screen.dart';
import 'package:vector_week01/services/fake_movie_service.dart';
import 'package:vector_week01/services/movie_preferences.dart';
import 'package:vector_week01/theme/app_theme.dart';
import 'package:vector_week01/widgets/movie_card.dart';
import 'package:vector_week01/widgets/movie_state_views.dart';

void main() {
  Future<void> pumpMovies(WidgetTester tester, FakeMovieService service) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MoviesScreen(
          selectedGenres: const {},
          service: service,
          preferences: MemoryMoviePreferences(),
        ),
      ),
    );
  }

  testWidgets('Loading 후 Success 영화 목록을 표시한다', (tester) async {
    await pumpMovies(
      tester,
      const FakeMovieService(delay: Duration(seconds: 1)),
    );

    expect(find.byType(MovieLoadingView), findsOneWidget);
    expect(find.byType(MovieCard), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.byType(MovieLoadingView), findsNothing);
    expect(find.byType(MovieCard), findsNWidgets(6));
  });

  testWidgets('Empty 상태는 안내 문구를 표시한다', (tester) async {
    await pumpMovies(
      tester,
      const FakeMovieService(mode: FakeMovieMode.empty, delay: Duration.zero),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MovieEmptyView), findsOneWidget);
    expect(find.text('아직 등록된 영화가 없습니다.'), findsOneWidget);
  });

  testWidgets('Error 상태는 오류와 다시 시도 버튼을 표시한다', (tester) async {
    await pumpMovies(
      tester,
      const FakeMovieService(mode: FakeMovieMode.failure, delay: Duration.zero),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MovieErrorView), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);

    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.byType(MovieErrorView), findsOneWidget);
  });

  testWidgets('Future timeout을 오류 화면으로 처리한다', (tester) async {
    await pumpMovies(
      tester,
      const FakeMovieService(mode: FakeMovieMode.timeout, delay: Duration.zero),
    );

    await tester.pump(const Duration(seconds: 4));
    await tester.pump();

    expect(find.byType(MovieErrorView), findsOneWidget);
    expect(find.textContaining('요청 시간이 초과되었습니다.'), findsOneWidget);
  });
}
