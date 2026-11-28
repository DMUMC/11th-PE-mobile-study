import 'package:movielog/auth/login_screen.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/edit_profile_view_model.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/profile_screen/edit_profile_screen.dart';
import 'package:movielog/widgets/movielog_button.dart';
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
import 'package:movielog/profile_screen/favorites_screen.dart';
import 'package:movielog/start_screen.dart';
import 'package:movielog/view_models/movie_home_view_model.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';

import '../core/session/session_guard.dart';
import '../data/services/favorite_api_service.dart';
import '../view_models/favorites_view_model.dart';
import '../view_models/paged_movies_view_model.dart';
import '../movie/movie_search_screen.dart';

class AppRouter {
  AppRouter._();

  static late GoRouter router;

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

  static GoRouter createRouter(AuthViewModel auth) => GoRouter(
    refreshListenable: auth,
    redirect: (context, state) {
      final path = state.uri.path;
      final atStart = path == '/start';
      final atPublic = path == '/login' || path == '/register';
      return switch (auth.status) {
        AuthStatus.initializing ||
        AuthStatus.retryRequired => atStart ? null : '/start',
        AuthStatus.signedOut ||
        AuthStatus.authenticating => atPublic ? null : '/login',
        AuthStatus.signedIn => (atStart || atPublic) ? '/home' : null,
      };
    },
    navigatorKey: _rootNavigatorKey,
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/start', builder: (context, state) => const StartScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
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
                    path: 'search',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => ChangeNotifierProvider(
                      create: (context) => PagedMoviesViewModel(
                        tmdbApi: context.read<TmdbMovieService>(),
                        searchOnly: true,
                      ),
                      child: const MovieSearchScreen(),
                    ),
                  ),
                  GoRoute(
                    path: ':movieId',
                    parentNavigatorKey: _rootNavigatorKey,
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
                        key: ValueKey('movie:$id'),
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
                    path: 'favorites',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final auth = context.watch<AuthViewModel>();
                      final member = auth.member;
                      final guard = context.read<SessionGuard>();
                      if (member == null || guard.accountId != member.email) {
                        return Scaffold(
                          appBar: AppBar(
                            title: const Text('내 즐겨찾기'),
                            centerTitle: true,
                          ),
                          body: Center(
                            child: auth.memberStatus == MemberLoadStatus.error
                                ? MovieLogButton(
                                    label: '내 정보 다시 조회',
                                    onPressed: () =>
                                        auth.loadMember(force: true),
                                  )
                                : const CircularProgressIndicator(),
                          ),
                        );
                      }
                      return ChangeNotifierProvider(
                        key: ValueKey('${member.email}:${guard.generation}'),
                        create: (context) => FavoritesViewModel(
                          favoriteApi: context.read<FavoriteApiService>(),
                          tmdbApi: context.read<TmdbMovieService>(),
                          sessionGuard: guard,
                          accountId: member.email,
                        ),
                        child: const FavoritesPage(),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'profile/edit',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final auth = context.watch<AuthViewModel>();
                      if (auth.member == null) {
                        return Scaffold(
                          appBar: AppBar(
                            centerTitle: true,
                            title: const Text('프로필 수정'),
                          ),
                          body: Center(
                            child: auth.memberStatus == MemberLoadStatus.error
                                ? MovieLogButton(
                                    label: '다시 시도',
                                    onPressed: () =>
                                        auth.loadMember(force: true),
                                  )
                                : const CircularProgressIndicator(),
                          ),
                        );
                      }
                      return ChangeNotifierProvider<EditProfileViewModel>(
                        create: (context) => EditProfileViewModel(
                          context.read<MemberApiService>(),
                          auth,
                        ),
                        child: const EditProfileScreen(),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'ratings',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      return ChangeNotifierProvider(
                        create: (context) => MyRatingsViewModel(
                          context.read<RatingApiService>(),
                          context.read<AuthViewModel>(),
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
