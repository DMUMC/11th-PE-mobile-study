import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../models/movie_list_initial_data.dart';
import '../services/fake_movie_service.dart';
import '../services/genre_preference.dart';
import '../theme/app_colors.dart';
import '../widgets/movie/genre_filter.dart';
import '../widgets/movie/movie_grid.dart';
import '../widgets/movie/movie_list_empty.dart';
import '../widgets/movie/movie_list_error.dart';
import '../widgets/movie/movie_list_loading.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key, this.loadMode = MovieLoadMode.success});

  // Empty·Error 재현은 이 값으로 설정하고, 재시도에서는 성공 모드를 요청합니다.
  final MovieLoadMode loadMode;
  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  final _movieService = const FakeMovieService();
  final _genrePreference = GenrePreference();
  late Future<MovieListInitialData> _moviesFuture;
  String? _selectedGenre;

  @override
  void initState() {
    super.initState();
    _moviesFuture = _loadInitialData(mode: widget.loadMode);
  }

  Future<MovieListInitialData> _loadInitialData({
    MovieLoadMode mode = MovieLoadMode.success,
  }) async {
    final results = await Future.wait([
      _movieService.fetchMovies(mode: mode),
      _genrePreference.read(),
    ]);
    final savedGenre = results[1] as String;
    return MovieListInitialData(
      movies: results[0] as List<Movie>,
      selectedGenre: GenreFilter.genres.contains(savedGenre)
          ? savedGenre
          : '전체',
    );
  }

  void _retry() {
    setState(() {
      _moviesFuture = _loadInitialData();
    });
  }

  Future<void> _changeGenre(String genre) async {
    setState(() => _selectedGenre = genre);
    try {
      await _genrePreference.save(genre);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('장르를 저장하지 못했습니다. 다시 선택해주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: FutureBuilder<MovieListInitialData>(
            future: _moviesFuture,
            builder: (context, snapshot) {
              final isLoading =
                  snapshot.connectionState != ConnectionState.done;
              final selectedGenre =
                  _selectedGenre ?? snapshot.data?.selectedGenre ?? '전체';
              final filteredMovies = (snapshot.data?.movies ?? const <Movie>[])
                  .where(
                    (movie) =>
                        selectedGenre == '전체' || movie.genre == selectedGenre,
                  )
                  .toList();

              Widget content;
              if (isLoading) {
                content = const MovieListLoading();
              } else if (snapshot.hasError) {
                content = MovieListError(onRetry: _retry);
              } else if (filteredMovies.isEmpty) {
                content = const MovieListEmpty();
              } else {
                content = MovieGrid(movies: filteredMovies);
              }

              return Column(
                children: [
                  GenreFilter(
                    selectedGenre: selectedGenre,
                    onChanged: isLoading ? null : _changeGenre,
                  ),
                  const SizedBox(height: 24),
                  Expanded(child: content),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
