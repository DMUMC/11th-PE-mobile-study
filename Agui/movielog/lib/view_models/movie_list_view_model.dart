import 'package:flutter/foundation.dart';

import '../data/models/tmdb_genre_dto.dart';
import '../data/services/tmdb_movie_service.dart';
import 'load_phase.dart';
import 'paged_movies_view_model.dart';

enum MovieListLoadStatus { idle, loading, success, empty, error }

// Keep the existing genre/filter integration; page state is shared with
// PagedMoviesViewModel instead of collecting thirty movies in advance.
class MovieListViewModel extends PagedMoviesViewModel {
  MovieListViewModel(TmdbMovieService service) : super(tmdbApi: service);

  List<TmdbGenreDto> genres = const [];
  MovieListLoadStatus genreStatus = MovieListLoadStatus.idle;
  String? genreMessage;

  MovieListLoadStatus get status => switch (phase) {
    LoadPhase.idle => MovieListLoadStatus.idle,
    LoadPhase.loading => MovieListLoadStatus.loading,
    LoadPhase.ready => MovieListLoadStatus.success,
    LoadPhase.empty => MovieListLoadStatus.empty,
    LoadPhase.error => MovieListLoadStatus.error,
  };
  String? get message => errorMessage;
  bool get isLoading => phase == LoadPhase.loading;

  Future<void> loadGenres() async {
    if (isDisposed || genreStatus == MovieListLoadStatus.loading) return;
    genreStatus = MovieListLoadStatus.loading;
    genreMessage = null;
    notifyIfAlive();
    try {
      final result = await tmdbApi.fetchGenres();
      if (isDisposed) return;
      genres = result;
      genreStatus = genres.isEmpty
          ? MovieListLoadStatus.empty
          : MovieListLoadStatus.success;
    } catch (_) {
      if (isDisposed) return;
      genreStatus = MovieListLoadStatus.error;
      genreMessage = '장르를 불러오지 못했어요.';
    } finally {
      if (!isDisposed) notifyIfAlive();
    }
  }

  Future<void> loadMovies() => loadInitial(genreIds: selectedGenreIds);
  Future<void> refreshMovies() => loadMovies();
  Future<void> retryMovies() => loadMovies();

  Future<void> selectGenres(List<int>? genreIds) async {
    if (isDisposed) return;
    final nextIds = genreIds == null || genreIds.isEmpty
        ? null
        : List<int>.unmodifiable(genreIds.toSet());
    if (listEquals(selectedGenreIds, nextIds) && phase != LoadPhase.idle) {
      return;
    }
    await loadInitial(genreIds: nextIds);
  }
}
