import 'package:movielog/movie/data/mock_movies.dart';
import 'package:movielog/movie/model/movie.dart';

class FakeMovieService {
  const FakeMovieService();

  Future<List<Movie>> fetchMovies() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    return movies;
  }
}
