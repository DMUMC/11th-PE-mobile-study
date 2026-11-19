import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/fake_movie_service.dart';
import '../data/genre_preference_store.dart';
import '../data/mock_movies.dart';
import '../models/movie.dart';
import '../theme/app_colors.dart';
import '../widgets/movie_card.dart';
import '../widgets/movie_list_states.dart';

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({required this.selectedGenres, super.key,
    this.movieService = const FakeMovieService(),
    this.preferenceStore,
  });

  final Set<String> selectedGenres;
  final FakeMovieService movieService;
  final GenrePreferenceStore? preferenceStore;

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  static const _timeout = Duration(seconds: 8);
  late Set<String> _selectedGenres = {...widget.selectedGenres};
  late Future<List<Movie>> _moviesFuture;
  late final GenrePreferenceStore _store =
      widget.preferenceStore ?? SharedPreferencesGenreStore();
  String _sortOrder = 'latest';

  @override
  void initState() {
    super.initState();
    _moviesFuture = _restorePreferencesAndFetch();
  }

  Future<List<Movie>> _restorePreferencesAndFetch() async {
    try {
      final savedGenres = await _store.readGenres();
      final savedSortOrder = await _store.readSortOrder();
      if (mounted) {
        setState(() {
          _sortOrder = savedSortOrder;
          if (widget.selectedGenres.isEmpty && savedGenres.isNotEmpty) {
            _selectedGenres = savedGenres.toSet();
          }
        });
      }
    } catch (_) {
      // A local preference failure should not prevent the movie list from loading.
    }
    return widget.movieService
        .fetchMovies(genres: _selectedGenres)
        .timeout(_timeout);
  }

  Future<void> _loadMovies() async {
    setState(() {
      _moviesFuture = widget.movieService
          .fetchMovies(genres: _selectedGenres)
          .timeout(_timeout);
    });
  }

  Future<void> _selectGenre(String? genre) async {
    final next = genre == null ? <String>{} : <String>{genre};
    setState(() {
      _selectedGenres = next;
      _moviesFuture = widget.movieService.fetchMovies(genres: next).timeout(_timeout);
    });
    try {
      await _store.writeGenres(next.toList());
    } catch (_) {
      // Keep the current screen usable if local storage is unavailable.
    }
    if (!mounted) return;
    final uri = Uri(path: '/movies', queryParameters: next.isEmpty ? null : {'genre': next.toList()});
    GoRouter.maybeOf(context)?.go(uri.toString());
  }

  Future<void> _changeSort(String? order) async {
    if (order == null) return;
    setState(() => _sortOrder = order);
    try {
      await _store.writeSortOrder(order);
    } catch (_) {}
  }

  Future<void> _openFilter(BuildContext context) async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GenreFilterSheet(initialGenres: _selectedGenres),
    );
    if (result == null || !context.mounted) return;

    final next = result.toSet();
    setState(() {
      _selectedGenres = next;
      _moviesFuture = widget.movieService.fetchMovies(genres: next).timeout(_timeout);
    });
    try { await _store.writeGenres(result); } catch (_) {}
    if (!context.mounted) return;
    GoRouter.maybeOf(context)?.go(Uri(path: '/movies', queryParameters: result.isEmpty ? null : {'genre': result}).toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '영화',
          style: TextStyle(color: AppColors.primary, fontSize: 20),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          IconButton(key: const Key('openGenreFilter'), tooltip: '여러 장르 선택', onPressed: () => _openFilter(context), icon: const Icon(Icons.tune)),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(children: [
        SizedBox(height: 54, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [
          _genreChip('전체', null),
          ...movieGenres.map((genre) => _genreChip(genre, genre)),
        ])),
        Align(alignment: Alignment.centerRight, child: Padding(padding: const EdgeInsets.only(right: 14), child: DropdownButton<String>(
          key: const Key('movieSortOrder'), value: _sortOrder, underline: const SizedBox.shrink(),
          items: const [DropdownMenuItem(value: 'latest', child: Text('최신순')), DropdownMenuItem(value: 'rating', child: Text('평점순')), DropdownMenuItem(value: 'title', child: Text('제목순'))],
          onChanged: _changeSort,
        ))),
        Expanded(child: LayoutBuilder(builder: (context, constraints) {
          final count = constraints.maxWidth >= 900 ? 5 : constraints.maxWidth >= 600 ? 3 : 2;
          return FutureBuilder<List<Movie>>(
            future: _moviesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const MovieSkeletonGrid(count: 6);
              if (snapshot.hasError) return RefreshIndicator(onRefresh: _loadMovies, child: ListView(physics: const AlwaysScrollableScrollPhysics(), children: [SizedBox(height: constraints.maxHeight, child: MovieErrorView(onRetry: _loadMovies))]));
              final movies = [...?snapshot.data];
              if (_sortOrder == 'rating') movies.sort((a,b) => b.averageRating.compareTo(a.averageRating));
              if (_sortOrder == 'title') movies.sort((a,b) => a.title.compareTo(b.title));
              if (_sortOrder == 'latest') movies.sort((a,b) => b.year.compareTo(a.year));
              if (movies.isEmpty) return RefreshIndicator(onRefresh: _loadMovies, child: ListView(physics: const AlwaysScrollableScrollPhysics(), children: [SizedBox(height: constraints.maxHeight, child: const MovieEmptyView())]));
              return RefreshIndicator(onRefresh: _loadMovies, child: GridView.builder(
                key: const PageStorageKey('movies-scroll'), padding: const EdgeInsets.fromLTRB(14, 0, 14, 28),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: count, crossAxisSpacing: 14, mainAxisSpacing: 22, childAspectRatio: .57),
                itemCount: movies.length, itemBuilder: (context, index) { final movie = movies[index]; return MovieCard(movie: movie, onTap: () => context.push('/movies/${movie.id}')); },
              ));
            },
          );
        })),
      ]),
    );
  }

  Widget _genreChip(String label, String? genre) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
    child: ChoiceChip(key: Key('genreChip-${genre ?? 'all'}'), label: Text(label), selected: genre == null ? _selectedGenres.isEmpty : _selectedGenres.length == 1 && _selectedGenres.contains(genre), onSelected: (_) => _selectGenre(genre)),
  );
}

class GenreFilterSheet extends StatefulWidget {
  const GenreFilterSheet({required this.initialGenres, super.key});

  final Set<String> initialGenres;

  @override
  State<GenreFilterSheet> createState() => _GenreFilterSheetState();
}

class _GenreFilterSheetState extends State<GenreFilterSheet> {
  late final Set<String> _draftGenres = {...widget.initialGenres};

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.48,
      minChildSize: 0.32,
      maxChildSize: 0.88,
      expand: false,
      builder: (context, scrollController) {
        return Material(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '장르 필터',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '여러 장르를 선택할 수 있어요',
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: movieGenres.length,
                  itemBuilder: (context, index) {
                    final genre = movieGenres[index];
                    return CheckboxListTile(
                      key: ValueKey('genre-$genre'),
                      title: Text(genre),
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _draftGenres.contains(genre),
                      onChanged: (checked) {
                        setState(() {
                          if (checked ?? false) {
                            _draftGenres.add(genre);
                          } else {
                            _draftGenres.remove(genre);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    key: const Key('applyGenreFilter'),
                    onPressed: () =>
                        Navigator.pop(context, _draftGenres.toList()),
                    child: const Text('확인'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
