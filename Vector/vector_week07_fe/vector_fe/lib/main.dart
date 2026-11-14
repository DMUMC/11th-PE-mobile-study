import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import 'models/movie.dart';
import 'profile_screen.dart';
import 'screens/home_screen.dart';
import 'screens/button_widths_screen.dart';
import 'screens/my_ratings_screen.dart';
import 'services/member_api.dart';
import 'screens/movie_detail_screen.dart';
import 'screens/movies_screen.dart';
import 'services/fake_movie_service.dart';
import 'services/movie_service.dart';
import 'services/tmdb_movie_service.dart';
import 'services/movie_preferences.dart';
import 'signup_screen.dart';
import 'theme/app_theme.dart';

void main() => runApp(const MovieLogApp());

GoRouter createAppRouter(
  MovieLogStore store, {
  required MemberApi memberApi,
  required MovieLookup movieLookup,
  String initialLocation = '/home',
  MovieService movieService = const FakeMovieService(),
  MoviePreferencesStore? moviePreferences,
  int? initialMemberId = 1,
}) {
  var memberId = initialMemberId;

  GoRoute detailRoute() => GoRoute(
    path: ':id',
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      final extra = state.extra;
      final movie = extra is Movie && extra.id == id
          ? extra
          : store.findMovie(id);
      return movie == null
          ? Scaffold(
              appBar: AppBar(title: const Text('영화를 찾을 수 없습니다')),
              body: Center(
                child: TextButton(
                  onPressed: () => context.go('/movies'),
                  child: const Text('영화 목록으로'),
                ),
              ),
            )
          : MovieDetailScreen(
              movie: movie,
              store: store,
              memberApi: memberApi,
              memberId: memberId,
            );
    },
  );

  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/home'),
      GoRoute(
        path: '/signup',
        builder: (_, _) =>
            SignupScreen(api: memberApi, onSignup: (id) => memberId = id),
      ),
      GoRoute(
        path: '/button-widths',
        builder: (_, _) => const ButtonWidthsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => Scaffold(
          body: shell,
          // 상세 화면은 참고 이미지처럼 자체 하단 액션 버튼을 사용합니다.
          bottomNavigationBar: state.uri.pathSegments.length > 1
              ? null
              : NavigationBar(
                  selectedIndex: shell.currentIndex,
                  onDestinationSelected: (index) => shell.goBranch(index),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: '홈',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.movie_outlined),
                      selectedIcon: Icon(Icons.movie),
                      label: '영화',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: '마이',
                    ),
                  ],
                ),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, _) => const HomeScreen(),
                routes: [detailRoute()],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/movies',
                builder: (_, state) => MoviesScreen(
                  selectedGenres: parseGenreIds(
                    state.uri.queryParametersAll['genre'] ?? [],
                  ),
                  onMoviesLoaded: store.rememberMovies,
                  service: movieService,
                  preferences: moviePreferences,
                ),
                routes: [detailRoute()],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, _) => ProfileScreen(store: store),
                routes: [
                  GoRoute(
                    path: 'ratings',
                    builder: (_, _) => MyRatingsScreen(
                      api: memberApi,
                      lookup: movieLookup,
                      memberId: memberId,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('페이지를 찾을 수 없습니다')),
      body: Center(
        child: FilledButton(
          onPressed: () => context.go('/home'),
          child: const Text('홈으로'),
        ),
      ),
    ),
  );
}

class MovieLogApp extends StatefulWidget {
  const MovieLogApp({super.key});
  @override
  State<MovieLogApp> createState() => _MovieLogAppState();
}

class _MovieLogAppState extends State<MovieLogApp> {
  final store = MovieLogStore();
  final _memberClient = http.Client();
  final _tmdb = TmdbMovieService(
    token: const String.fromEnvironment('TMDB_READ_ACCESS_TOKEN'),
  );
  late final router = createAppRouter(
    store,
    movieService: const bool.fromEnvironment('USE_FAKE_MOVIES')
        ? const FakeMovieService()
        : _tmdb,
    memberApi: HttpMemberApi(client: _memberClient),
    movieLookup: _tmdb.fetchMovie,
  );
  @override
  void dispose() {
    router.dispose();
    _tmdb.close();
    _memberClient.close();
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'MovieLog',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    routerConfig: router,
  );
}
