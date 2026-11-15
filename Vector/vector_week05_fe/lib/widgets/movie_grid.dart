import 'package:flutter/material.dart';

import '../models/movie.dart';
import 'movie_card.dart';

class MovieGrid extends StatelessWidget {
  const MovieGrid({
    super.key,
    required this.movies,
    required this.onMovieTap,
    required this.onRefresh,
  });

  final List<Movie> movies;
  final ValueChanged<Movie> onMovieTap;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => RefreshIndicator(
      onRefresh: onRefresh,
      child: GridView.builder(
        key: const PageStorageKey('movies-scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 20,
          mainAxisExtent:
              (constraints.maxWidth - 48) / 2 * 1.5 +
              72 * MediaQuery.textScalerOf(context).scale(1),
        ),
        itemCount: movies.length,
        itemBuilder: (context, index) => MovieCard(
          movie: movies[index],
          onTap: () => onMovieTap(movies[index]),
        ),
      ),
    ),
  );
}
