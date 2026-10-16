import 'movie.dart';

class MovieListInitialData {
  const MovieListInitialData({
    required this.movies,
    required this.selectedGenre,
  });

  final List<Movie> movies;
  final String selectedGenre;
}
