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
        ChangeNotifierProvider(create: (_) => LearningMemberSession()),
        Provider<Dio>(
          create: (_) => createMovieLogClient(),
          dispose: (_, client) => client.close(force: true),
        ),
        Provider<SignUpService>(
          create: (context) =>
              memberCheckService ?? SignUpService(context.read<Dio>()),
        ),
        Provider<RatingApiService>(
          create: (context) =>
              ratingApiService ?? RatingApiService(context.read<Dio>()),
        ),
        Provider<TmdbMovieService>(
          create: (_) =>
              tmdbMovieService ?? TmdbMovieService(createTmdbClient()),
          dispose: (_, service) => service.close(),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'MovieLog',
        theme: AppTheme.light,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
