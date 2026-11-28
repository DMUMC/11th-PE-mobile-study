import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';

import '../core/session/session_guard.dart';
import '../data/services/favorite_api_service.dart';
import '../data/services/movie_record_api_service.dart';
import '../view_models/favorite_detail_view_model.dart';
import '../widgets/movielog_button.dart';

import 'movie_detail_screen.dart';

class MovieDetailLoader extends StatefulWidget {
  const MovieDetailLoader({
    super.key,
    required this.movieId,
    this.initialMovie,
    this.imageAsset,
  });
  final int movieId;
  final TmdbMovieDto? initialMovie;
  final String? imageAsset;
  @override
  State<MovieDetailLoader> createState() => _MovieDetailLoaderState();
}

class _MovieDetailLoaderState extends State<MovieDetailLoader> {
  late final Future<({TmdbMovieDto movie, List<String> genreNames})>
  _movieFuture;
  @override
  void initState() {
    super.initState();
    _movieFuture = _loadMovie();
  }

  Future<({TmdbMovieDto movie, List<String> genreNames})> _loadMovie() async {
    final service = context.read<TmdbMovieService?>();
    final movie =
        widget.initialMovie ?? await service!.fetchMovieDetail(widget.movieId);
    var names = movie.genreNames;
    // List responses carry genre_ids; detail responses carry named genres.
    // Missing genre metadata must not prevent opening a valid movie.
    if (names.isEmpty && movie.genreIds.isNotEmpty && service != null) {
      try {
        final genres = await service.fetchGenres();
        final byId = {for (final genre in genres) genre.id: genre.name};
        names = [
          for (final id in movie.genreIds)
            if (byId[id] != null) byId[id]!,
        ];
      } catch (_) {}
    }
    return (movie: movie, genreNames: names);
  }

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<({TmdbMovieDto movie, List<String> genreNames})>(
    future: _movieFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasError || snapshot.data == null) {
        return Scaffold(
          appBar: AppBar(),
          body: const Center(child: Text('영화를 불러오지 못했습니다.')),
        );
      }
      final auth = context.watch<AuthViewModel>();
      final member = auth.member;
      final guard = context.read<SessionGuard>();
      if (member == null || guard.accountId != member.email) {
        return Scaffold(
          appBar: AppBar(title: const Text('영화 상세')),
          body: Center(
            child: auth.memberStatus == MemberLoadStatus.error
                ? MovieLogButton(
                    label: '내 정보 다시 조회',
                    onPressed: () => auth.loadMember(force: true),
                  )
                : const CircularProgressIndicator(),
          ),
        );
      }
      return MultiProvider(
        key: ValueKey('${widget.movieId}:${member.email}:${guard.generation}'),
        providers: [
          ChangeNotifierProvider(
            create: (context) => MovieDetailViewModel(
              context.read<RatingApiService>(),
              auth,
              snapshot.data!.movie,
              movieRecordApi: context.read<MovieRecordApiService>(),
            ),
          ),
          ChangeNotifierProvider(
            create: (context) => FavoriteDetailViewModel(
              movieId: widget.movieId,
              favoriteApi: context.read<FavoriteApiService>(),
              sessionGuard: guard,
              accountId: member.email,
            ),
          ),
        ],
        child: MovieDetailScreen(
          movieId: widget.movieId.toString(),
          movie: snapshot.data!.movie,
          genreNames: snapshot.data!.genreNames,
          imageAsset: widget.imageAsset,
        ),
      );
    },
  );
}
