// Offline UI preview. Not imported by the regular app.
// flutter run -t lib/dev/favorites_ui_main.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/storage/token_storage.dart';
import '../data/models/favorite_list_item.dart';
import '../data/models/favorite_response_dto.dart';
import '../data/models/member_info.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/auth_api_service.dart';
import '../data/services/member_api_service.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/movie_record_api_service.dart';
import '../movie/movie_detail_loader.dart';
import '../profile_screen/favorites_screen.dart';
import '../profile_screen/profile_screen.dart';
import '../theme/app_theme.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/load_phase.dart';
import '../core/session/auth_session_bridge.dart';
import '../core/session/session_guard.dart';
import '../data/models/favorite_check_dto.dart';
import '../data/services/favorite_api_service.dart';
import 'favorite_detail_preview.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final dio = Dio();
  final rootKey = GlobalKey<NavigatorState>();
  final router = GoRouter(
    navigatorKey: rootKey,
    initialLocation: '/tools',
    routes: [
      GoRoute(
        path: '/tools',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('즐겨찾기 화면 확인')),
          body: ListView(
            children: [
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('화면 확인용 예시 데이터입니다. API 요청은 하지 않습니다.'),
              ),
              for (final item in const [
                ('마이페이지 → 내 즐겨찾기', '/my'),
                ('즐겨찾기 목록', '/preview/ready'),
                ('즐겨찾기 빈 결과', '/preview/empty'),
                ('즐겨찾기 조회 실패 → 재시도', '/preview/error'),
                ('즐겨찾기 로딩', '/preview/loading'),
                ('영화 정보 일부 실패', '/preview/partial'),
                ('상세: 즐겨찾기 등록·해제', '/guided/normal'),
                ('상세: 첫 조회 실패 → 재시도', '/guided/statusError'),
                ('상세: 저장 실패·기존 상태 유지', '/guided/saveError'),
                ('상세: 중복 등록 → 상태 동기화', '/guided/conflict'),
                ('상세: timeout·자동 재전송 방지', '/guided/timeout'),
              ])
                ListTile(
                  title: Text(item.$1),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(item.$2),
                ),
            ],
          ),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => Scaffold(
          body: child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: 2,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                label: '홈',
              ),
              NavigationDestination(
                icon: Icon(Icons.movie_outlined),
                label: '영화',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                label: '마이',
              ),
            ],
          ),
        ),
        routes: [
          GoRoute(
            path: '/my',
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'favorites',
                parentNavigatorKey: rootKey,
                builder: (context, state) => const _FavoritesPreview(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/preview/:phase',
        builder: (context, state) =>
            _FavoritesPreview(scenario: state.pathParameters['phase']!),
      ),
      GoRoute(
        path: '/guided/:scenario',
        builder: (context, state) =>
            FavoriteDetailPreview(scenario: state.pathParameters['scenario']!),
      ),
      GoRoute(
        path: '/movies/:movieId',
        builder: (context, state) => MovieDetailLoader(
          movieId: int.parse(state.pathParameters['movieId']!),
          initialMovie: state.extra! as TmdbMovieDto,
        ),
      ),
    ],
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              AuthViewModel(
                  AuthApiService(dio),
                  MemberApiService(dio),
                  _PreviewTokenStorage(),
                )
                ..status = AuthStatus.signedIn
                ..memberStatus = MemberLoadStatus.success
                ..member = MemberInfo(
                  email: 'movie@example.com',
                  nickname: '무비러버',
                  createdAt: DateTime(2026, 9, 1),
                ),
        ),
        Provider(create: (_) => RatingApiService(dio, dio)),
        Provider(create: (_) => MovieRecordApiService(dio)),
        Provider<AuthSessionBridge>(
          lazy: false,
          create: (context) {
            final auth = context.read<AuthViewModel>();
            return AuthSessionBridge(
              authSignals: auth,
              sessionVersion: () => auth.sessionVersion,
              verifiedEmail: () => auth.status == AuthStatus.signedIn
                  ? auth.member?.email
                  : null,
            );
          },
          dispose: (_, bridge) => bridge.dispose(),
        ),
        ListenableProvider<SessionGuard>(
          create: (context) => context.read<AuthSessionBridge>().guard,
        ),
        Provider<FavoriteApiService>(create: (_) => _PreviewFavoriteApi()),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: router,
      ),
    ),
  );
}

class _FavoritesPreview extends StatefulWidget {
  const _FavoritesPreview({this.scenario = 'ready'});
  final String scenario;

  @override
  State<_FavoritesPreview> createState() => _FavoritesPreviewState();
}

class _FavoritesPreviewState extends State<_FavoritesPreview> {
  late LoadPhase phase;
  bool recovered = false;

  @override
  void initState() {
    super.initState();
    phase = switch (widget.scenario) {
      'empty' => LoadPhase.empty,
      'error' => LoadPhase.error,
      'loading' => LoadPhase.loading,
      _ => LoadPhase.ready,
    };
  }

  Future<void> refresh() async {
    setState(() => phase = LoadPhase.loading);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      recovered = true;
      phase = LoadPhase.ready;
    });
  }

  @override
  Widget build(BuildContext context) => FavoritesScreen(
    phase: phase,
    items: [
      for (var index = 0; index < _movies.length; index++)
        FavoriteListItem(
          favorite: FavoriteResponseDto(
            favoriteId: index + 1,
            movieId: _movies[index].id,
            createdAt: DateTime(2026, 9, 6),
          ),
          movie: widget.scenario == 'partial' && index == 1 && !recovered
              ? null
              : _movies[index],
        ),
    ],
    posterAssets: {
      10: 'assets/images/posters/poster_under_the_starlight.png',
      if (widget.scenario != 'partial' || recovered)
        11: 'assets/images/posters/poster_night_shadows.jpg',
    },
    onRefresh: refresh,
  );
}

const _movies = [
  TmdbMovieDto(
    id: 10,
    title: '별빛 아래 우리',
    posterPath: null,
    releaseDate: '2025-01-01',
  ),
  TmdbMovieDto(
    id: 11,
    title: '달빛 산책',
    posterPath: null,
    releaseDate: '2024-01-01',
  ),
];

class _PreviewTokenStorage implements TokenStorage {
  @override
  Future<String?> readAccessToken() async => null;
  @override
  Future<void> saveAccessToken(String token) async {}
  @override
  Future<void> deleteAccessToken() async {}
}

class _PreviewFavoriteApi extends FavoriteApiService {
  _PreviewFavoriteApi() : super(Dio());
  final _favoriteIds = <int>{10, 11};

  @override
  Future<FavoriteCheckDto> checkFavorite({required int movieId}) async =>
      FavoriteCheckDto(
        movieId: movieId,
        isFavorite: _favoriteIds.contains(movieId),
      );

  @override
  Future<FavoriteResponseDto> addFavorite({required int movieId}) async {
    _favoriteIds.add(movieId);
    return FavoriteResponseDto(
      favoriteId: movieId,
      movieId: movieId,
      createdAt: DateTime(2026),
    );
  }

  @override
  Future<void> deleteFavorite({required int movieId}) async {
    _favoriteIds.remove(movieId);
  }
}
