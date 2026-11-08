import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/network/movie_log_client.dart';
import 'core/network/tmdb_client.dart';
import 'data/models/tmdb_movie_dto.dart';
import 'data/services/member_check_service.dart';
import 'data/services/rating_api_service.dart';
import 'data/services/tmdb_movie_service.dart';
import 'screens/home_screen.dart';
import 'screens/movie_detail_screen.dart';
import 'screens/movies_screen.dart';
import 'screens/my_screen.dart';
import 'screens/my_ratings_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/start_screen.dart';
import 'theme/app_theme.dart';
import 'view_models/movie_home_view_model.dart';
import 'view_models/movie_list_view_model.dart';
import 'view_models/movie_detail_view_model.dart';
import 'view_models/my_ratings_view_model.dart';
import 'view_models/sign_up_view_model.dart';

GoRouter createAppRouter({String initialLocation = '/start'}) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/start', builder: (_, _) => const StartScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, _) => ChangeNotifierProvider(
          create: (_) => SignUpViewModel(context.read<MemberCheckService>()),
          child: const SignUpScreen(),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, _) => ChangeNotifierProvider(
                  create: (_) =>
                      MovieHomeViewModel(context.read<TmdbMovieService>())
                        ..loadPopular(),
                  child: const HomeScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/movies',
                builder: (context, state) => ChangeNotifierProvider(
                  create: (_) => MovieListViewModel(
                    context.read<TmdbMovieService>(),
                    initialGenres:
                        state.uri.queryParametersAll.containsKey('genre')
                        ? state.uri.queryParametersAll['genre']!
                              .map(int.tryParse)
                              .whereType<int>()
                              .toList()
                        : null,
                  )..loadInitial(),
                  child: const MoviesScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/my',
                builder: (_, _) => const MyScreen(),
                routes: [
                  GoRoute(
                    path: 'ratings',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, _) => ChangeNotifierProvider(
                      create: (_) => MyRatingsViewModel(
                        context.read<RatingApiService>(),
                        context.read<TmdbMovieService>(),
                      )..load(),
                      child: const MyRatingsScreen(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/movies/:movieId',
        builder: (context, state) {
          final movieId = int.tryParse(state.pathParameters['movieId'] ?? '');
          if (movieId == null || movieId <= 0) {
            return const MovieNotFoundScreen();
          }
          final extra = state.extra;
          final initial = extra is TmdbMovieDto && extra.id == movieId
              ? extra
              : null;
          return ChangeNotifierProvider(
            create: (_) => MovieDetailViewModel(
              context.read<TmdbMovieService>(),
              movieId,
              movie: initial,
            )..load(),
            child: const MovieDetailPage(),
          );
        },
      ),
    ],
  );
}

final appRouter = createAppRouter();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const MovieLogApp());
}

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({
    this.service,
    this.router,
    this.workbookClient,
    super.key,
  });
  final TmdbMovieService? service;
  final GoRouter? router;
  final Dio? workbookClient;

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      Provider<Dio>(
        create: (_) => workbookClient ?? createMovieLogClient(),
        dispose: (_, dio) => dio.close(force: true),
      ),
      Provider<MemberCheckService>(
        create: (context) => MemberCheckService(context.read<Dio>()),
      ),
      Provider<RatingApiService>(
        create: (context) => RatingApiService(context.read<Dio>()),
      ),
      Provider<TmdbMovieService>(
        create: (_) => service ?? TmdbMovieService(createTmdbClient()),
        dispose: (_, service) {
          if (this.service == null) service.close();
        },
      ),
    ],
    child: MaterialApp.router(
      title: 'MovieLog',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router ?? appRouter,
    ),
  );
}

class MainShell extends StatelessWidget {
  const MainShell({required this.navigationShell, super.key});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        key: const Key('mainNavigationBar'),
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
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
  );
}
