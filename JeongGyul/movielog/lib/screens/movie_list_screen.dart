import 'package:flutter/material.dart';

import '../data/mock_movies.dart';
import '../theme/app_colors.dart';
import '../widgets/movie/genre_filter.dart';
import '../widgets/movie/movie_card.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});
  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  String _selectedGenre = '전체';

  @override
  Widget build(BuildContext context) {
    final filteredMovies = movies
        .where(
          (movie) =>
              !movie.isPopular &&
              (_selectedGenre == '전체' || movie.genre == _selectedGenre),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Text(
          '영화',
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(color: AppColors.primary600),
        ),
        actions: const [
          Padding(padding: EdgeInsets.all(16), child: Icon(Icons.search)),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            children: [
              GenreFilter(
                selectedGenre: _selectedGenre,
                onChanged: (genre) => setState(() => _selectedGenre = genre),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: filteredMovies.isEmpty
                    ? const Center(child: Text('선택한 장르의 영화가 없습니다.'))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final cardWidth = (constraints.maxWidth - 12) / 2;
                          return GridView.builder(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: filteredMovies.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 24,
                                  childAspectRatio:
                                      cardWidth / (cardWidth * 1.5 + 64),
                                ),
                            itemBuilder: (context, index) =>
                                MovieCard(movie: filteredMovies[index]),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
