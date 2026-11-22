import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../theme/app_colors.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/movie_detail_view_model.dart';
import '../view_models/session_ratings_store.dart';
import 'movie_detail_screen.dart';

/// 영화 상세의 시작점. 목록에서 온 extra가 없으면(직접 접근·Deep Link)
/// TMDB GET /movie/{movie_id}로 다시 조회한다.
class MovieDetailLoader extends StatefulWidget {
  const MovieDetailLoader({
    super.key,
    required this.movieId,
    this.initialMovie,
  });

  final int movieId;
  final TmdbMovieDto? initialMovie;

  @override
  State<MovieDetailLoader> createState() => _MovieDetailLoaderState();
}

class _MovieDetailLoaderState extends State<MovieDetailLoader> {
  // build마다 새 Future를 만들지 않도록 State에서 한 번만 만든다.
  late final Future<TmdbMovieDto> _movieFuture;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialMovie;
    _movieFuture = initial != null
        ? Future.value(initial)
        : context.read<TmdbMovieService>().fetchMovieDetail(widget.movieId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TmdbMovieDto>(
      future: _movieFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.violet),
            ),
          );
        }
        final movie = snapshot.data;
        if (snapshot.hasError || movie == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('영화를 불러오지 못했습니다.')),
          );
        }
        return ChangeNotifierProvider<MovieDetailViewModel>(
          create: (context) => MovieDetailViewModel(
            context.read<RatingApiService>(),
            context.read<AuthViewModel>(),
            context.read<SessionRatingsStore>(),
            movie,
          ),
          child: const MovieDetailScreen(),
        );
      },
    );
  }
}
