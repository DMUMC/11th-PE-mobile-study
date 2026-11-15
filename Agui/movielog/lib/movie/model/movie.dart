import 'package:movielog/data/models/tmdb_movie_dto.dart';

class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.genre,
    required this.year,
    required this.posterAsset,
    this.rating,
    this.tmdbMovie,
  });

  final int id;
  final String title;
  final String genre;
  final int year;
  final String posterAsset;
  final double? rating;
  final TmdbMovieDto? tmdbMovie;
}
