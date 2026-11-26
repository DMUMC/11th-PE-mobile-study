import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/network/movie_log_client.dart';
import '../core/network/tmdb_client.dart';
import '../core/storage/email_preferences.dart';
import '../core/storage/token_storage.dart';
import '../data/services/auth_api_service.dart';
import '../data/services/member_api_service.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/sign_up_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/session_ratings_store.dart';

class MovieLogApp extends StatefulWidget {
  const MovieLogApp({super.key});

  @override
  State<MovieLogApp> createState() => _MovieLogAppState();
}

class _MovieLogAppState extends State<MovieLogApp> {
  // Client는 앱 수명 동안 한 번만 만든다.
  final TokenStorage _tokenStorage = SecureTokenStorage(
    const FlutterSecureStorage(),
  );
  late final _publicClient = createMovieLogClient(); // AuthInterceptor 없음
  late final _authClient = createAuthMovieLogClient(_tokenStorage); // 등록

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<TokenStorage>.value(value: _tokenStorage),
        Provider<EmailPreferences>(create: (_) => EmailPreferences()),
        // TMDB Client에는 MovieLog JWT를 절대 붙이지 않는다. (TMDB 토큰만)
        Provider<TmdbMovieService>(
          create: (_) => TmdbMovieService(createTmdbClient()),
        ),
        // 공개 Client
        Provider<AuthApiService>(create: (_) => AuthApiService(_publicClient)),
        Provider<SignUpService>(create: (_) => SignUpService(_publicClient)),
        // 보호 Client (RatingApiService는 공개 조회용 Client도 함께 받는다)
        Provider<MemberApiService>(
          create: (_) => MemberApiService(_authClient),
        ),
        Provider<RatingApiService>(
          create: (_) => RatingApiService(_publicClient, _authClient),
        ),
        // 현재 로그인 세션에서 등록한 평점 (세션이 바뀌면 비운다)
        ChangeNotifierProvider<SessionRatingsStore>(
          create: (_) => SessionRatingsStore(),
        ),
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) {
            final ratings = context.read<SessionRatingsStore>();
            return AuthViewModel(
              context.read<AuthApiService>(),
              context.read<MemberApiService>(),
              context.read<TokenStorage>(),
              onSessionReset: ratings.clear,
            );
          },
        ),
      ],
      child: const _MovieLogRouterApp(),
    );
  }
}

/// Router를 한 번만 만들고 첫 build 이후 세션 복원을 시작한다.
class _MovieLogRouterApp extends StatefulWidget {
  const _MovieLogRouterApp();

  @override
  State<_MovieLogRouterApp> createState() => _MovieLogRouterAppState();
}

class _MovieLogRouterAppState extends State<_MovieLogRouterApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authViewModel = context.read<AuthViewModel>();
    _router = AppRouter.createRouter(authViewModel);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) authViewModel.restoreSession();
    });
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'MovieLog',
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
