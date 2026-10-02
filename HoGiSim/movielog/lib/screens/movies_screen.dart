import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_movies.dart';
import '../models/movie.dart';
import '../theme/app_colors.dart';
import '../widgets/movie_card.dart';

class MoviesScreen extends StatelessWidget {
  const MoviesScreen({required this.selectedGenres, super.key});

  final Set<String> selectedGenres;

  List<Movie> get _filteredMovies {
    if (selectedGenres.isEmpty) return mockMovies;
    return mockMovies
        .where((movie) => movie.genres.any(selectedGenres.contains))
        .toList();
  }

  Future<void> _openFilter(BuildContext context) async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GenreFilterSheet(initialGenres: selectedGenres),
    );
    if (result == null || !context.mounted) return;

    final uri = Uri(
      path: '/movies',
      queryParameters: result.isEmpty ? null : {'genre': result},
    );
    context.go(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final movies = _filteredMovies;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '영화',
          style: TextStyle(color: AppColors.primary, fontSize: 20),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final count = constraints.maxWidth >= 900
              ? 5
              : constraints.maxWidth >= 600
              ? 3
              : 2;
          return CustomScrollView(
            key: const PageStorageKey('movies-scroll'),
            slivers: [
              SliverToBoxAdapter(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 14, bottom: 4),
                    child: IconButton(
                      key: const Key('openGenreFilter'),
                      tooltip: '장르 필터',
                      onPressed: () => _openFilter(context),
                      color: AppColors.primary,
                      icon: Badge(
                        isLabelVisible: selectedGenres.isNotEmpty,
                        label: Text('${selectedGenres.length}'),
                        child: const Icon(Icons.filter_list_rounded),
                      ),
                    ),
                  ),
                ),
              ),
              if (movies.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Text('선택한 장르의 영화가 없습니다.')),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 28),
                  sliver: SliverGrid.builder(
                    itemCount: movies.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: count,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 22,
                      childAspectRatio: 0.57,
                    ),
                    itemBuilder: (context, index) {
                      final movie = movies[index];
                      return MovieCard(
                        movie: movie,
                        onTap: () => context.push('/movies/${movie.id}'),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
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
