import 'package:flutter/material.dart';
import 'package:movielog/movie/model/movie.dart';
import 'package:movielog/movie/widgets/movie_card.dart';

class MovieGrid extends StatelessWidget {
  const MovieGrid({super.key, required this.movies});

  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: movies.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: constraints.maxWidth >= 700 ? 3 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 28,
          mainAxisExtent: 312,
        ),
        itemBuilder: (context, index) => MovieCard(movie: movies[index]),
      ),
    );
  }
}
