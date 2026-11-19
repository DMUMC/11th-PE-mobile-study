import 'package:movielog/view_models/learning_member_session.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/auth/sign_up_screen.dart';
import 'package:movielog/home/app_shell.dart';
import 'package:movielog/home/home_screen.dart';
import 'package:movielog/movie/movie_detail_loader.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/movie/movie_list_screen.dart';
import 'package:movielog/profile_screen/profile_screen.dart';
import 'package:movielog/profile_screen/my_ratings_screen.dart';
import 'package:movielog/start_screen.dart';
import 'package:movielog/view_models/movie_home_view_model.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';

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
        builder: (context, state) => ChangeNotifierProvider(
          create: (context) => SignUpViewModel(
            context.read<SignUpService>(),
            initialNickname: SignUpScreen.initialNickname,
            initialEmail: SignUpScreen.initialEmail,
          ),
          child: const SignUpScreen(),
        ),
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
                builder: (context, state) =>
                    ChangeNotifierProvider<MovieHomeViewModel>(
                      create: (context) =>
                          MovieHomeViewModel(context.read<TmdbMovieService>())
                            ..loadPopular(),
                      child: const HomeScreen(),
                    ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _moviesNavigatorKey,
            routes: [
              GoRoute(
                path: '/movies',
                builder: (context, state) =>
                    ChangeNotifierProvider<MovieListViewModel>(
                      create: (context) =>
                          MovieListViewModel(context.read<TmdbMovieService>())
                            ..loadGenres(),
                      child: MovieListScreen(
                        initialGenreQuery: state.uri.queryParameters['genre'],
                      ),
                    ),
                routes: [
                  GoRoute(
                    path: ':movieId',
                    builder: (context, state) {
                      final id = int.tryParse(
                        state.pathParameters['movieId'] ?? '',
                      );
                      if (id == null || id < 1) {
                        return const Scaffold(
                          body: Center(child: Text('영화 ID가 올바르지 않습니다.')),
                        );
                      }
                      final extra = state.extra;
                      return MovieDetailLoader(
                        movieId: id,
                        initialMovie: extra is TmdbMovieDto && extra.id == id
                            ? extra
                            : null,
                      );
                    },
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
                routes: [
                  GoRoute(
                    path: 'ratings',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final id = context.read<LearningMemberSession>().memberId;
                      if (id == null) {
                        return Scaffold(
                          appBar: AppBar(title: const Text('내가 등록한 평점')),
                          body: const Center(child: Text('학습용 회원가입이 필요합니다.')),
                        );
                      }
                      return ChangeNotifierProvider(
                        create: (context) => MyRatingsViewModel(
                          context.read<RatingApiService>(),
                          context.read<TmdbMovieService>(),
                          id,
                        )..load(),
                        child: const MyRatingsScreen(),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
