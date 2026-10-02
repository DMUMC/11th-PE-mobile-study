import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/auth/sign_up_screen.dart';
import 'package:movielog/home/app_shell.dart';
import 'package:movielog/home/home_screen.dart';
import 'package:movielog/movie/movie_detail_screen.dart';
import 'package:movielog/movie/movie_list_screen.dart';
import 'package:movielog/profile_screen/profile_screen.dart';
import 'package:movielog/start_screen.dart';

class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _homeNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'home',
  );
  static final _moviesNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'movies',
  );
  static final _profileNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'profile',
  );

  // Change this path to open a different screen when the app starts.
  static const initialLocation = '/start';

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/start', builder: (context, state) => const StartScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const SignUpScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _moviesNavigatorKey,
            routes: [
              GoRoute(
                path: '/movies',
                builder: (context, state) => MovieListScreen(
                  initialGenreQuery: state.uri.queryParameters['genre'],
                ),
                routes: [
                  GoRoute(
                    path: ':movieId',
                    builder: (context, state) => MovieDetailScreen(
                      movieId: state.pathParameters['movieId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _profileNavigatorKey,
            routes: [
              GoRoute(
                path: '/my',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
