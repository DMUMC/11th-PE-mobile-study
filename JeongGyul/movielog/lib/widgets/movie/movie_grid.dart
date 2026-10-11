import 'package:flutter/material.dart';

import '../../models/movie.dart';
import 'movie_card.dart';

class MovieGrid extends StatelessWidget {
  const MovieGrid({super.key, required this.movies});

  final List<Movie> movies;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final cardWidth = (constraints.maxWidth - 12) / 2;
      return GridView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: movies.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 24,
          childAspectRatio: cardWidth / (cardWidth * 1.5 + 64),
        ),
        itemBuilder: (context, index) => MovieCard(movie: movies[index]),
      );
    },
  );
}
