import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_week01/models/movie.dart';
import 'package:vector_week01/screens/movies_screen.dart';
import 'package:vector_week01/services/movie_preferences.dart';
import 'package:vector_week01/services/movie_service.dart';
import 'package:vector_week01/theme/app_theme.dart';
import 'package:vector_week01/widgets/movie_card.dart';
import 'package:vector_week01/widgets/movie_retry_dialog.dart';
import 'package:vector_week01/widgets/movie_state_views.dart';

import 'movies_controller_test.dart' show ControlledService;

void main() {
  testWidgets('당겨서 갱신 중/실패/취소 목록 유지 후 같은 장르로 재시도', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = ControlledService();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MoviesScreen(
          selectedGenres: const [18, 878],
          service: service,
          preferences: MemoryMoviePreferences(),
        ),
      ),
    );
    await tester.pump();
    // 초기 Loading에서는 새로고침 위젯 자체가 없습니다.
    expect(find.byType(RefreshIndicator), findsNothing);
    service.pending.last.complete([movies.first]);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(GridView), const Offset(0, 500));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(service.calls.length, 2);
    expect(find.byType(MovieCard), findsOneWidget);
    expect(find.byType(MovieLoadingView), findsNothing);
    final refresh = tester.widget<RefreshIndicator>(
      find.byType(RefreshIndicator),
    );
    expect(
      refresh.notificationPredicate(
        ScrollUpdateNotification(
          metrics: FixedScrollMetrics(
            minScrollExtent: 0,
            maxScrollExtent: 0,
            pixels: 0,
            viewportDimension: 400,
            axisDirection: AxisDirection.down,
            devicePixelRatio: 1,
          ),
          context: tester.element(find.byType(GridView)),
        ),
      ),
      isFalse,
    );
    service.pending.last.completeError(
      const MovieLoadException('네트워크 연결을 확인해주세요.'),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MovieRetryDialog), findsOneWidget);
    expect(find.text(movies.first.title), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(service.calls.length, 2);
    expect(find.byType(MovieCard), findsOneWidget);
    await tester.drag(find.byType(GridView), const Offset(0, 500));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    service.pending.last.completeError(const MovieLoadException('offline'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다시 시도'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(service.calls.last, [18, 878]);
    expect(service.calls.length, 4);
    expect(find.byType(MovieRetryDialog), findsNothing);
    expect(find.text(movies.first.title), findsOneWidget);
    service.pending.last.complete([movies[1]]);
    await tester.pumpAndSettle();
    expect(find.text(movies.first.title), findsNothing);
    expect(find.text(movies[1].title), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
