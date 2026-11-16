import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:movielog/main.dart';
import 'package:movielog/screens/movies_screen.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';
import 'package:movielog/widgets/movie_list_states.dart';
import 'package:movielog/widgets/movie_rating_input.dart';
import 'package:movielog/widgets/tmdb_poster_image.dart';

import 'support/tmdb_fixture.dart';

void main() {
  late GoRouter router;
  Future<void> pumpAt(WidgetTester tester, String location) async {
    tester.view.physicalSize = const Size(800, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    router = createAppRouter(initialLocation: location);
    final f = fixture();
    await tester.pumpWidget(MovieLogApp(router: router, service: f.service));
    await tester.pumpAndSettle();
    addTearDown(router.dispose);
  }

  testWidgets('시작하기 버튼으로 회원가입 화면에 이동한다', (tester) async {
    await pumpAt(tester, '/start');
    await tester.tap(find.byKey(const Key('startButton')));
    await tester.pumpAndSettle();
    expect(find.text('회원가입'), findsOneWidget);
    expect(router.state.uri.path, '/signup');
  });

  testWidgets('회원가입 완료 후 홈으로 이동한다', (tester) async {
    await pumpAt(tester, '/signup');
    await tester.enterText(find.byKey(const Key('nicknameField')), '무비러버');
    await tester.enterText(
      find.byKey(const Key('emailField')),
      'movie@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('passwordField')),
      'password123',
    );
    await tester.tap(find.byKey(const Key('termsCheckbox')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('signUpButton')));
    await tester.tap(find.byKey(const Key('signUpButton')));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/home');
    expect(find.byKey(const Key('mainNavigationBar')), findsOneWidget);
  });

  testWidgets('로그인 버튼을 누르면 테스트용 홈으로 바로 이동한다', (tester) async {
    await pumpAt(tester, '/signup');
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/home');
    expect(find.byKey(const Key('mainNavigationBar')), findsOneWidget);
  });

  testWidgets('영화 카드의 실제 TMDB ID가 상세와 평점 Dialog까지 전달된다', (tester) async {
    await pumpAt(tester, '/home');
    await tester.tap(find.byKey(const Key('featuredMovieCard')));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/movies/550');
    expect(find.text('Cinema Archive'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('줄거리 정보가 없어요.'),
      500,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('줄거리 정보가 없어요.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('openRatingDialog')));
    await tester.pumpAndSettle();
    final dialog = tester.widget<MovieRatingInput>(
      find.byType(MovieRatingInput),
    );
    expect(dialog.movieId, 550);
    expect(dialog.movieTitle, '영화 550');
    expect(find.byKey(const Key('ratingInput')), findsOneWidget);
  });

  testWidgets('장르 BottomSheet는 Genre API ID를 선택해 OR 조건으로 보낸다', (tester) async {
    final f = fixture();
    final vm = MovieListViewModel(
      f.service,
      preferenceStore: MemoryGenreStore(),
    );
    await tester.runAsync(vm.loadInitial);
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider.value(
          value: vm,
          child: const MoviesScreen(),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('openGenreFilter')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('genre-28')));
    await tester.tap(find.byKey(const ValueKey('genre-878')));
    await tester.tap(find.byKey(const Key('applyGenreFilter')));
    await tester.pumpAndSettle();
    expect(vm.selectedGenreIds, [28, 878]);
    expect(f.adapter.requests.last.queryParameters['with_genres'], '28|878');
    await tester.pumpWidget(const SizedBox());
    vm.dispose();
  });

  testWidgets('실패 Dialog에서 취소해도 최근 성공 목록을 유지한다', (tester) async {
    final f = fixture();
    final vm = MovieListViewModel(
      f.service,
      preferenceStore: MemoryGenreStore(),
    );
    await tester.runAsync(vm.loadInitial);
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider.value(
          value: vm,
          child: const MoviesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    f.adapter.respond = (_) async => FixtureAdapter.json({}, 503);
    await tester.tap(find.byKey(const Key('refreshMovies')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('confirmRetry')), findsOneWidget);
    expect(vm.movies, hasLength(30));
    await tester.tap(find.byKey(const Key('cancelRetry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('confirmRetry')), findsNothing);
    expect(find.text('최근 성공한 목록을 표시하고 있어요.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    vm.dispose();
  });

  testWidgets('빈 목록과 최초 요청 오류 화면을 구분한다', (tester) async {
    for (final fail in [false, true]) {
      final f = fixture(
        adapter: FixtureAdapter(
          respond: (options) async {
            if (fail) return FixtureAdapter.json({}, 401);
            if (options.path.contains('genre')) {
              return FixtureAdapter.json({'genres': []});
            }
            return FixtureAdapter.json(pageJson([]));
          },
        ),
      );
      final vm = MovieListViewModel(
        f.service,
        preferenceStore: MemoryGenreStore(),
      );
      await tester.runAsync(vm.loadInitial);
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: vm,
            child: const MoviesScreen(),
          ),
        ),
      );
      expect(
        find.byType(fail ? MovieErrorView : MovieEmptyView),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
    }
  });

  testWidgets('포스터 null/빈 경로는 placeholder를 표시한다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Row(
          children: [
            TmdbPosterImage(posterPath: null, width: 100, height: 150),
            TmdbPosterImage(posterPath: '', width: 100, height: 150),
          ],
        ),
      ),
    );
    expect(find.byKey(const Key('poster-placeholder')), findsNWidgets(2));
    expect(find.byType(Image), findsNothing);
  });
}
