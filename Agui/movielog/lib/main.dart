import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:movielog/core/storage/token_storage.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/view_models/learning_member_session.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:movielog/core/network/movie_log_client.dart';
import 'package:movielog/core/network/tmdb_client.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/theme/app_theme.dart';

import 'core/network/auth_interceptor.dart';
import 'core/session/auth_session_bridge.dart';
import 'core/session/session_guard.dart';
import 'data/services/favorite_api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const MovieLogApp());
}

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({
    super.key,
    this.memberCheckService,
    this.ratingApiService,
    this.tmdbMovieService,
  });

  final SignUpService? memberCheckService;
  final RatingApiService? ratingApiService;
  final TmdbMovieService? tmdbMovieService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<Dio>(
          create: (_) => createMovieLogClient(),
          dispose: (_, client) => client.close(force: true),
        ),
        Provider<TokenStorage>(
          create: (_) => SecureTokenStorage(const FlutterSecureStorage()),
        ),
        Provider<({Dio client})>(
          create: (context) =>
              (client: createAuthMovieLogClient(context.read<TokenStorage>())),
          dispose: (_, value) => value.client.close(force: true),
        ),
        Provider<AuthApiService>(
          create: (context) => AuthApiService(context.read<Dio>()),
        ),
        Provider<MemberApiService>(
          create: (context) =>
              MemberApiService(context.read<({Dio client})>().client),
        ),
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) {
            final auth = AuthViewModel(
              context.read<AuthApiService>(),
              context.read<MemberApiService>(),
              context.read<TokenStorage>(),
            );
            context
                .read<({Dio client})>()
                .client
                .interceptors
                .whereType<AuthInterceptor>()
                .single
                .bindSession(
                  sessionVersion: () => auth.sessionVersion,
                  onSessionExpired: auth.expireSessionIfCurrent,
                );
            return auth;
          },
        ),
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
        Provider<SessionGuard>(
          create: (context) => context.read<AuthSessionBridge>().guard,
        ),
        Provider<FavoriteApiService>(
          create: (context) =>
              FavoriteApiService(context.read<({Dio client})>().client),
        ),
        ChangeNotifierProvider(create: (_) => LearningMemberSession()),
        Provider<SignUpService>(
          create: (context) =>
              memberCheckService ?? SignUpService(context.read<Dio>()),
        ),
        Provider<RatingApiService>(
          create: (context) =>
              ratingApiService ??
              RatingApiService(
                context.read<Dio>(),
                context.read<({Dio client})>().client,
              ),
        ),
        Provider<TmdbMovieService>(
          create: (_) =>
              tmdbMovieService ?? TmdbMovieService(createTmdbClient()),
          dispose: (_, service) => service.close(),
        ),
      ],
      child: const _MovieLogRouterApp(),
    );
  }
}

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
    final auth = context.read<AuthViewModel>();
    _router = AppRouter.router = AppRouter.createRouter(auth);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) auth.restoreSession();
    });
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    debugShowCheckedModeBanner: false,
    title: 'MovieLog',
    theme: AppTheme.light,
    routerConfig: _router,
  );
}
