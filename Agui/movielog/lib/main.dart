import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:movielog/core/network/movie_log_client.dart';
import 'package:movielog/core/network/tmdb_client.dart';
import 'package:movielog/data/services/member_check_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/theme/app_theme.dart';

void main() {
  runApp(const MovieLogApp());
}

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({
    super.key,
    this.memberCheckService,
    this.ratingApiService,
    this.tmdbMovieService,
  });

  final MemberCheckService? memberCheckService;
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
        Provider<MemberCheckService>(
          create: (context) =>
              memberCheckService ?? MemberCheckService(context.read<Dio>()),
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
