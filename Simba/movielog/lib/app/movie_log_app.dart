import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/network/movielog_client.dart';
import '../core/network/tmdb_client.dart';
import '../data/services/movielog_member_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 상태가 없는 Service는 앱 전체에서 하나의 인스턴스를 공유한다.
        Provider<TmdbMovieService>(
          create: (_) => TmdbMovieService(createTmdbClient()),
        ),
        // MovieLog 자체 API(회원/평점). TMDB와 다른 Client를 쓴다.
        Provider<MovieLogMemberService>(
          create: (_) => MovieLogMemberService(createMovieLogClient()),
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
