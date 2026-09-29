import 'package:flutter/material.dart';
import 'package:movielog/movie/data/mock_movies.dart';
import 'package:movielog/movie/widgets/movie_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('홈')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('추천 영화', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              width: 180,
              height: 280,
              child: MovieCard(movie: movies.first),
            ),
          ],
        ),
      ),
    );
  }
}
