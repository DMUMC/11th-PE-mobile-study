import 'package:flutter/material.dart';
import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/movie/widgets/movie_card.dart';

class MovieGrid extends StatelessWidget {
  const MovieGrid({
    super.key,
    required this.movies,
    this.genres = const [],
    this.footer,
  });

  final List<TmdbMovieDto> movies;
  final List<TmdbGenreDto> genres;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final genreNamesById = {for (final genre in genres) genre.id: genre.name};
    return LayoutBuilder(
      builder: (context, constraints) => CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            sliver: SliverGrid.builder(
              itemCount: movies.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: constraints.maxWidth >= 700 ? 3 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 28,
                mainAxisExtent: 312,
              ),
              itemBuilder: (context, index) => MovieCard(
                movie: movies[index],
                genreNames: movies[index].genreIds
                    .map((id) => genreNamesById[id])
                    .whereType<String>()
                    .toList(),
              ),
            ),
          ),
          if (footer != null) SliverToBoxAdapter(child: footer!),
        ],
      ),
    );
  }
}
