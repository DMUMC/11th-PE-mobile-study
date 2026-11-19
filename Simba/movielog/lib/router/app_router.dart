import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/config/movielog_config.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/movielog_member_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../screens/home_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/movie_list_screen.dart';
import '../screens/my_page_screen.dart';
import '../screens/sign_up_screen.dart';
import '../screens/start_screen.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';
import '../view_models/my_page_view_model.dart';
import '../view_models/sign_up_view_model.dart';

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    // 시작 화면 → 회원가입(닉네임/이메일 중복 체크) → 홈
    initialLocation: '/start',
    routes: [
      // 0주차 시작 화면
      GoRoute(
        path: '/start',
        builder: (context, state) => const StartScreen(),
      ),
      // 1주차 회원가입 화면 (뒤로가기 방지용 교체 진입)
      GoRoute(
        path: '/register',
        builder: (context, state) => ChangeNotifierProvider<SignUpViewModel>(
          create: (context) =>
              SignUpViewModel(context.read<MovieLogMemberService>()),
          child: const SignUpScreen(),
        ),
      ),
      // 탭 네비게이션 & 독립 스택 유지
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScreen(navigationShell: navigationShell);
        },
        branches: [
          // 탭 0: 홈 (인기 영화 5개)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                // ViewModel은 화면마다 따로 만들고, create는 한 번만 실행되어
                // 화면이 다시 빌드되어도 Popular 요청이 반복되지 않는다.
                builder: (context, state) =>
                    ChangeNotifierProvider<MovieHomeViewModel>(
                      create: (context) => MovieHomeViewModel(
                        context.read<TmdbMovieService>(),
                      )..loadPopular(),
                      child: const HomeScreen(),
                    ),
                routes: [
                  GoRoute(
                    path: 'movies/:movieId',
                    builder: _buildMovieDetail,
                  ),
                ],
              ),
            ],
          ),
          // 탭 1: 영화 목록(Discover 최대 30개) 및 상세
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/movies',
                builder: (context, state) =>
                    ChangeNotifierProvider<MovieListViewModel>(
                      create: (context) => MovieListViewModel(
                        context.read<TmdbMovieService>(),
                      )..loadInitial(),
                      child: const MovieListScreen(),
                    ),
                routes: [
                  GoRoute(
                    path: ':movieId',
                    builder: _buildMovieDetail,
                  ),
                ],
              ),
            ],
          ),
          // 탭 2: 마이페이지
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/my',
                builder: (context, state) =>
                    ChangeNotifierProvider<MyPageViewModel>(
                      create: (context) => MyPageViewModel(
                        memberService: context.read<MovieLogMemberService>(),
                        tmdbService: context.read<TmdbMovieService>(),
                        memberId: MovieLogConfig.demoMemberId,
                      )..loadRatings(),
                      child: const MyPageScreen(),
                    ),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  /// 경로의 movieId(TMDB id)와 extra로 받은 DTO로 상세 화면을 만든다.
  static Widget _buildMovieDetail(BuildContext context, GoRouterState state) {
    final movieId = int.tryParse(state.pathParameters['movieId'] ?? '');
    final extra = state.extra;
    return MovieDetailScreen(
      movieId: movieId,
      movie: extra is TmdbMovieDto ? extra : null,
    );
  }
}
