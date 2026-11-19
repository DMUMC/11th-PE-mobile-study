import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vector_week01/main.dart';
import 'package:vector_week01/models/movie.dart';
import 'package:vector_week01/screens/movies_screen.dart';
import 'package:vector_week01/services/fake_movie_service.dart';
import 'package:vector_week01/services/movie_preferences.dart';
import 'package:vector_week01/theme/app_theme.dart';
import 'package:vector_week01/widgets/movie_card.dart';

void main() {
  Future<(GoRouter, MovieLogStore)> start(
    WidgetTester tester, {
    String location = '/home',
    Size size = const Size(390, 844),
    FakeMovieService service = const FakeMovieService(delay: Duration.zero),
    MoviePreferencesStore? preferences,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = MovieLogStore();
    final router = createAppRouter(
      store,
      initialLocation: location,
      movieService: service,
      moviePreferences: preferences ?? MemoryMoviePreferences(),
    );
    addTearDown(router.dispose);
    addTearDown(store.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();
    return (router, store);
  }

  testWidgets('홈, 상세, 뒤로 이동과 마이페이지 표시', (tester) async {
    await start(tester);
    expect(find.text('오늘은 어떤\n영화를 볼까요?'), findsOneWidget);
    await tester.ensureVisible(find.text('상세보기'));
    await tester.tap(find.text('상세보기'));
    await tester.pumpAndSettle();
    expect(find.text('Cinema Archive'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    await tester.tap(find.byTooltip('뒤로'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle();
    expect(find.text('무비러버'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('필터는 확인 시에만 적용되고 URL과 다중 선택이 일치한다', (tester) async {
    final (router, _) = await start(tester, location: '/movies');
    await tester.tap(find.byTooltip('장르 필터'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxListTile, '드라마'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.query, isEmpty);
    await tester.tap(find.byTooltip('필터 닫기'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.query, isEmpty);
    await tester.tap(find.byTooltip('장르 필터'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CheckboxListTile>(
            find.widgetWithText(CheckboxListTile, '드라마'),
          )
          .value,
      isFalse,
    );
    await tester.tap(find.widgetWithText(CheckboxListTile, '드라마'));
    await tester.tap(find.widgetWithText(CheckboxListTile, 'SF'));
    await tester.pump();
    await tester.tap(find.text('확인 · 2개 장르 적용'));
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.queryParametersAll['genre'],
      ['드라마', 'SF'],
    );
    expect(find.byType(GenreFilterSheet), findsNothing);
    for (final card in tester.widgetList<MovieCard>(find.byType(MovieCard))) {
      expect(card.movie.genres.any({'드라마', 'SF'}.contains), isTrue);
    }
    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('영화').last);
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.queryParametersAll['genre'],
      ['드라마', 'SF'],
    );
    await tester.tap(find.byTooltip('장르 필터'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('전체 해제'));
    await tester.pump();
    await tester.tap(find.text('확인 · 전체 영화 보기'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.queryParameters, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('쿼리 직접 진입, 상세 복귀, 탭별 탐색 스택과 스크롤을 보존한다', (tester) async {
    final (router, _) = await start(
      tester,
      location: Uri(
        path: '/movies',
        queryParameters: {
          'genre': ['SF'],
        },
      ).toString(),
    );
    expect(find.text('선택 장르: SF'), findsOneWidget);
    final card = find.byType(MovieCard).first;
    await tester.tap(card);
    await tester.pumpAndSettle();
    final detailUri = router.routeInformationProvider.value.uri;
    final shell = StatefulNavigationShell.of(
      tester.element(find.text('Cinema Archive')),
    );
    shell.goBranch(2);
    await tester.pumpAndSettle();
    expect(find.text('무비러버'), findsOneWidget);
    await tester.tap(find.text('영화'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri, detailUri);
    await tester.tap(find.byTooltip('뒤로'));
    await tester.pumpAndSettle();
    expect(find.text('선택 장르: SF'), findsOneWidget);
    router.go('/movies');
    await tester.pumpAndSettle();
    await tester.drag(find.byType(GridView), const Offset(0, -400));
    await tester.pumpAndSettle();
    final scroll = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(GridView),
        matching: find.byType(Scrollable),
      ),
    );
    final offset = scroll.position.pixels;
    expect(offset, greaterThan(0));
    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('영화'));
    await tester.pumpAndSettle();
    expect(scroll.position.pixels, offset);
    expect(tester.takeException(), isNull);
  });

  testWidgets('필터 시트 높이 조절, 긴 목록 스크롤과 확인 버튼 고정', (tester) async {
    await start(tester, location: '/movies');
    await tester.tap(find.byTooltip('장르 필터'));
    await tester.pumpAndSettle();
    final sheet = find.byType(GenreFilterSheet);
    final before = tester.getSize(sheet).height;
    final list = find.descendant(of: sheet, matching: find.byType(ListView));
    await tester.drag(list, const Offset(0, -250));
    await tester.pumpAndSettle();
    expect(tester.getSize(sheet).height, greaterThan(before));
    final button = find.text('확인 · 전체 영화 보기');
    final buttonY = tester.getCenter(button).dy;
    await tester.drag(list, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(tester.getCenter(button).dy, closeTo(buttonY, 1));
    expect(button.hitTestable(), findsOneWidget);
    await tester.drag(list, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(CheckboxListTile, '다큐멘터리').hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('평점 선택, 초기화, 재선택, 취소 및 즐겨찾기 상태', (tester) async {
    final (_, store) = await start(tester, location: '/movies/starlight');
    await tester.tap(find.text('평점 남기기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('4점'));
    await tester.tap(find.text('평점 초기화'));
    await tester.pump();
    expect(find.text('별점을 선택해주세요'), findsOneWidget);
    await tester.tap(find.byTooltip('5점'));
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(store.ratings['starlight'], 5);
    await tester.tap(find.text('평점 수정'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('2점'));
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(store.ratings['starlight'], 5);
    await tester.tap(find.text('평점 수정'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('평점 초기화'));
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(store.ratings.containsKey('starlight'), isFalse);
    await tester.tap(find.text('즐겨찾기'));
    await tester.pumpAndSettle();
    expect(store.favorites, contains('starlight'));
    await tester.tap(find.text('즐겨찾기 완료'));
    await tester.pumpAndSettle();
    expect(store.favorites, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('작은 화면, 검색 결과 없음, 잘못된 영화 ID도 정상 처리한다', (tester) async {
    final (router, _) = await start(
      tester,
      location: '/movies',
      size: const Size(320, 640),
    );
    await tester.tap(find.byTooltip('영화 검색'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '없는 영화');
    await tester.pumpAndSettle();
    expect(find.text('조건에 맞는 영화가 없습니다.'), findsOneWidget);
    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    router.go('/movies/missing');
    await tester.pumpAndSettle();
    expect(find.text('영화를 찾을 수 없습니다'), findsOneWidget);
  });

  testWidgets('저장된 장르와 정렬을 복원하고 변경값을 다시 저장한다', (tester) async {
    final preferences = MemoryMoviePreferences(
      genres: const ['SF'],
      sort: MovieSort.rating,
    );
    final (router, _) = await start(
      tester,
      location: '/movies',
      preferences: preferences,
    );

    expect(
      router.routeInformationProvider.value.uri.queryParametersAll['genre'],
      ['SF'],
    );
    final cards = tester.widgetList<MovieCard>(find.byType(MovieCard)).toList();
    expect(
      cards.first.movie.rating,
      greaterThanOrEqualTo(cards.last.movie.rating),
    );

    await tester.tap(find.byTooltip('정렬 방식'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('제목순'));
    await tester.pumpAndSettle();
    expect(preferences.sort, MovieSort.title);

    await tester.tap(find.widgetWithText(FilterChip, 'SF'));
    await tester.pumpAndSettle();
    expect(preferences.genres, isEmpty);
    expect(router.routeInformationProvider.value.uri.query, isEmpty);
  });
}
