import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_movies.dart';
import '../theme/app_colors.dart';
import '../widgets/home/featured_movie_card.dart';
import '../widgets/movie/movie_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final popularMovies = movies.where((movie) => movie.isPopular).toList();
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Text(
          'MovieLog',
          style: textTheme.headlineMedium?.copyWith(
            color: AppColors.primary600,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.all(16),
            child: Icon(Icons.search, color: AppColors.primary600),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('오늘은 어떤\n영화를 볼까요?', style: textTheme.headlineLarge),
              const SizedBox(height: 16),
              FeaturedMovieCard(movie: movies.first),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '인기 영화',
                    style: textTheme.headlineMedium?.copyWith(fontSize: 20),
                  ),
                  TextButton(
                    onPressed: () => context.go('/movies'),
                    child: const Text('전체보기 ›'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 278,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: popularMovies.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 16),
                  itemBuilder: (context, index) => SizedBox(
                    width: 140,
                    child: MovieCard(
                      movie: popularMovies[index],
                      rank: index + 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
