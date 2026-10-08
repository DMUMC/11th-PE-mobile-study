import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/fake_movie_service.dart';
import 'package:movielog/data/genre_preference_store.dart';
import 'package:movielog/data/mock_movies.dart';
import 'package:movielog/screens/movies_screen.dart';
import 'package:movielog/widgets/movie_list_states.dart';

class MemoryGenreStore implements GenrePreferenceStore {
  List<String> genres = [];
  String sort = 'latest';
  @override
  Future<List<String>> readGenres() async => genres;
  @override
  Future<void> writeGenres(List<String> value) async => genres = value;
  @override
  Future<String> readSortOrder() async => sort;
  @override
  Future<void> writeSortOrder(String value) async => sort = value;
}

void main() {
  group('FakeMovieService', () {
    test('성공하면 Mock 영화를 반환한다', () async {
      final movies = await const FakeMovieService(delay: Duration.zero).fetchMovies();
      expect(movies, mockMovies);
    });

    test('빈 목록 모드를 반환한다', () async {
      final movies = await const FakeMovieService(mode: MovieFetchMode.empty, delay: Duration.zero).fetchMovies();
      expect(movies, isEmpty);
    });

    test('실패 모드는 예외를 발생시킨다', () async {
      expect(
        const FakeMovieService(mode: MovieFetchMode.failure, delay: Duration.zero).fetchMovies(),
        throwsException,
      );
    });

    test('선택한 장르의 영화만 반환한다', () async {
      final movies = await const FakeMovieService(delay: Duration.zero).fetchMovies(genres: {'SF'});
      expect(movies.map((movie) => movie.id), ['edge-of-space']);
    });
  });

  Future<void> pumpScreen(WidgetTester tester, {
    required FakeMovieService service,
    MemoryGenreStore? store,
  }) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(MaterialApp(home: MoviesScreen(
      selectedGenres: const {}, movieService: service,
      preferenceStore: store ?? MemoryGenreStore(),
    )));
  }

  testWidgets('로딩 뒤 성공 Grid를 표시한다', (tester) async {
    await pumpScreen(tester, service: const FakeMovieService(delay: Duration(milliseconds: 900)));
    expect(find.byType(MovieSkeletonGrid), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 950));
    await tester.pump();
    expect(find.text('별빛 아래 우리'), findsOneWidget);
  });

  testWidgets('빈 목록이면 안내 문구를 표시한다', (tester) async {
    await pumpScreen(tester, service: const FakeMovieService(mode: MovieFetchMode.empty, delay: Duration.zero));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.byType(MovieEmptyView), findsOneWidget);
    expect(find.text('표시할 영화가 없습니다.'), findsOneWidget);
  });

  testWidgets('실패하면 내부 오류 대신 재시도 화면을 표시한다', (tester) async {
    await pumpScreen(tester, service: const FakeMovieService(mode: MovieFetchMode.failure, delay: Duration.zero));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.byType(MovieErrorView), findsOneWidget);
    expect(find.text('Fake service failure'), findsNothing);
    expect(find.byKey(const Key('retryMovies')), findsOneWidget);
  });

  testWidgets('장르와 정렬 선택값을 저장한다', (tester) async {
    final store = MemoryGenreStore();
    await pumpScreen(tester, service: const FakeMovieService(delay: Duration.zero), store: store);
    await tester.pump();
    await tester.tap(find.byKey(const Key('genreChip-SF')));
    await tester.pump();
    await tester.pump();
    expect(store.genres, ['SF']);
    await tester.tap(find.byKey(const Key('movieSortOrder')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('평점순').last);
    await tester.pumpAndSettle();
    expect(store.sort, 'rating');
  });

  testWidgets('저장된 장르를 복원해 목록을 필터링한다', (tester) async {
    final store = MemoryGenreStore()..genres = ['SF'];
    await pumpScreen(tester, service: const FakeMovieService(delay: Duration.zero), store: store);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.byKey(const Key('genreChip-SF')), findsOneWidget);
    expect(find.byKey(const ValueKey('movie-card-edge-of-space')), findsOneWidget);
    expect(find.byKey(const ValueKey('movie-card-spring-coffee')), findsNothing);
  });
}
