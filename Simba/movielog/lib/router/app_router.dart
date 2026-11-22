import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/member_api_service.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/sign_up_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_detail_loader.dart';
import '../screens/movie_list_screen.dart';
import '../screens/my_page_screen.dart';
import '../screens/my_ratings_screen.dart';
import '../screens/sign_up_screen.dart';
import '../screens/splash_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/edit_profile_view_model.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';
import '../view_models/my_ratings_view_model.dart';
import '../view_models/session_ratings_store.dart';
import '../view_models/sign_up_view_model.dart';
import '../widgets/movielog_button.dart';

/// 인증 상태별로 갈 수 있는 화면을 한곳에서 정한다.
/// redirect 안에서는 상태만 읽고 판단한다. (API 호출 같은 비동기 작업 금지)
String? authRedirect(AuthStatus status, String location) {
  const publicPaths = {'/login', '/register'};
  final atStart = location == '/start';
  final atPublic = publicPaths.contains(location);

  return switch (status) {
    // 토큰 확인 중 또는 확인 실패(재시도 버튼): 스플래시 유지
    AuthStatus.initializing ||
    AuthStatus.retryRequired => atStart ? null : '/start',
    // 로그아웃 또는 로그인 요청 중: 공개 화면만 허용
    AuthStatus.signedOut ||
    AuthStatus.authenticating => atPublic ? null : '/login',
    // 로그인됨: 스플래시와 로그인·회원가입은 홈으로
    AuthStatus.signedIn => (atStart || atPublic) ? '/home' : null,
  };
}

class AppRouter {
  AppRouter._();

  // root Navigator를 가리키는 키. 하단 탭을 가려야 하는 자식 화면이 이 키로 push된다.
  static final rootNavigatorKey = GlobalKey<NavigatorState>();

  /// Router는 앱이 살아있는 동안 한 번만 만든다. (build에서 만들면 위치가 초기화된다)
  static GoRouter createRouter(AuthViewModel authViewModel) {
    return GoRouter(
      initialLocation: '/start',
      navigatorKey: rootNavigatorKey,
      // 인증 상태가 바뀌면 redirect를 다시 실행한다.
      refreshListenable: authViewModel,
      redirect: (context, state) =>
          authRedirect(authViewModel.status, state.uri.path),
      routes: [
        // 스플래시: 토큰 확인 중 / 확인 실패 시 재시도
        GoRoute(
          path: '/start',
          builder: (context, state) {
            final auth = context.watch<AuthViewModel>();
            return SplashScreen(
              message: auth.message,
              onRetry: auth.status == AuthStatus.retryRequired
                  ? auth.restoreSession
                  : null,
            );
          },
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) {
            final extra = state.extra;
            return LoginScreen(initialEmail: extra is String ? extra : null);
          },
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => ChangeNotifierProvider<SignUpViewModel>(
            create: (context) => SignUpViewModel(context.read<SignUpService>()),
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
                  builder: (context, state) =>
                      ChangeNotifierProvider<MovieHomeViewModel>(
                        create: (context) =>
                            MovieHomeViewModel(context.read<TmdbMovieService>())
                              ..loadPopular(),
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
                        create: (context) =>
                            MovieListViewModel(context.read<TmdbMovieService>())
                              ..loadInitial(),
                        child: const MovieListScreen(),
                      ),
                  routes: [
                    GoRoute(path: ':movieId', builder: _buildMovieDetail),
                  ],
                ),
              ],
            ),
            // 탭 2: 마이페이지
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/my',
                  builder: (context, state) => const MyPageScreen(),
                  routes: [
                    GoRoute(
                      path: 'ratings', // 최종 경로: /my/ratings
                      // 지정하지 않으면 Shell의 Navigator를 써서 하단 NavigationBar가 남는다.
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) =>
                          ChangeNotifierProvider<MyRatingsViewModel>(
                            create: (context) => MyRatingsViewModel(
                              context.read<RatingApiService>(),
                              context.read<TmdbMovieService>(),
                              context.read<SessionRatingsStore>(),
                              context.read<AuthViewModel>(),
                            ),
                            child: const MyRatingsScreen(),
                          ),
                    ),
                    GoRoute(
                      path: 'profile/edit', // 최종 경로: /my/profile/edit
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) {
                        final auth = context.watch<AuthViewModel>();
                        if (auth.member == null) {
                          return _MemberLoadingScreen(auth: auth);
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
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// movieId는 URL 식별자, 실제 DTO는 extra에서 꺼낸다.
  /// extra가 없으면(직접 접근·Deep Link) Loader가 TMDB에서 다시 조회한다.
  static Widget _buildMovieDetail(BuildContext context, GoRouterState state) {
    final id = int.tryParse(state.pathParameters['movieId'] ?? '');
    if (id == null || id < 1) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('영화 ID가 올바르지 않습니다.')),
      );
    }
    final extra = state.extra;
    return MovieDetailLoader(
      movieId: id,
      initialMovie: extra is TmdbMovieDto && extra.id == id ? extra : null,
    );
  }
}

/// 프로필 수정에 들어왔는데 내 정보가 아직 없을 때
class _MemberLoadingScreen extends StatelessWidget {
  const _MemberLoadingScreen({required this.auth});

  final AuthViewModel auth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('프로필 수정', style: AppTextStyles.appBarTitle),
      ),
      body: Center(
        child: auth.memberStatus == MemberLoadStatus.error
            ? MovieLogButton(
                label: '다시 시도',
                onPressed: () => auth.loadMember(force: true),
              )
            : const CircularProgressIndicator(color: AppColors.violet),
      ),
    );
  }
}
