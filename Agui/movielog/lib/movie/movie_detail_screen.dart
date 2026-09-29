import 'package:flutter/material.dart';
import 'package:movielog/movie/data/mock_movies.dart';

class MovieDetailScreen extends StatelessWidget {
  const MovieDetailScreen({super.key, required this.movieId});

  final String movieId;

  @override
  Widget build(BuildContext context) {
    final movie = findMovieById(int.tryParse(movieId));

    return Scaffold(
      appBar: AppBar(title: const Text('영화 상세')),
      body: movie == null
          ? const Center(child: Text('영화를 찾을 수 없습니다.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: 220,
                      height: 320,
                      child: Image.asset(movie.posterAsset, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      movie.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text('${movie.genre} · ${movie.year}'),
                  ],
                ),
              ),
            ),
    );
  }
}
