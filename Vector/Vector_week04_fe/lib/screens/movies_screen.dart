import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/movie.dart';
import '../services/fake_movie_service.dart';
import '../services/movie_preferences.dart';
import '../widgets/movie_grid.dart';
import '../widgets/movie_state_views.dart';

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({
    super.key,
    required this.selectedGenres,
    this.service = const FakeMovieService(),
    this.preferences,
  });

  final Set<String> selectedGenres;
  final FakeMovieService service;
  final MoviePreferencesStore? preferences;

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  static const _requestTimeout = Duration(seconds: 4);

  final searchController = TextEditingController();
  late final MoviePreferencesStore _preferences;
  late Future<List<Movie>> _moviesFuture;
  MovieSort _sort = MovieSort.recommended;
  bool searching = false;

  @override
  void initState() {
    super.initState();
    _preferences = widget.preferences ?? SharedMoviePreferences();
    _moviesFuture = _fetchMovies();
    unawaited(_restorePreferences());
  }

  @override
  void didUpdateWidget(covariant MoviesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service != widget.service) {
      _moviesFuture = _fetchMovies();
    }
    if (!setEquals(oldWidget.selectedGenres, widget.selectedGenres)) {
      unawaited(_preferences.saveGenres(_ordered(widget.selectedGenres)));
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<List<Movie>> _fetchMovies() => widget.service.fetchMovies().timeout(
    _requestTimeout,
    onTimeout: () => throw TimeoutException('영화 요청 시간이 초과되었습니다.'),
  );

  Future<void> _restorePreferences() async {
    final savedGenres = (await _preferences.loadGenres())
        .where(movieGenres.contains)
        .toSet();
    final savedSort = await _preferences.loadSort();
    if (!mounted) return;

    setState(() => _sort = savedSort);
    if (widget.selectedGenres.isEmpty && savedGenres.isNotEmpty) {
      _goToGenres(savedGenres);
    } else if (widget.selectedGenres.isNotEmpty) {
      await _preferences.saveGenres(_ordered(widget.selectedGenres));
    }
  }

  List<String> _ordered(Iterable<String> genres) =>
      movieGenres.where(genres.toSet().contains).toList();

  void _goToGenres(Set<String> selected) {
    final ordered = _ordered(selected);
    context.go(
      Uri(
        path: '/movies',
        queryParameters: ordered.isEmpty ? null : {'genre': ordered},
      ).toString(),
    );
  }

  Future<void> _applyGenres(Set<String> selected) async {
    await _preferences.saveGenres(_ordered(selected));
    if (mounted) _goToGenres(selected);
  }

  Future<void> _showFilters() async {
    final selected = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => GenreFilterSheet(selected: widget.selectedGenres),
    );
    if (!mounted || selected == null) return;
    await _applyGenres(selected);
  }

  Future<void> _changeSort(MovieSort sort) async {
    setState(() => _sort = sort);
    await _preferences.saveSort(sort);
  }

  Future<void> _reload() async {
    final future = _fetchMovies();
    setState(() {
      _moviesFuture = future;
    });
    try {
      await future;
    } on Object {
      // FutureBuilder가 오류 상태를 표시합니다.
    }
  }

  List<Movie> _visibleMovies(List<Movie> source) {
    final result = source
        .where(
          (movie) =>
              (widget.selectedGenres.isEmpty ||
                  movie.genres.any(widget.selectedGenres.contains)) &&
              movie.title.contains(searchController.text.trim()),
        )
        .toList();

    switch (_sort) {
      case MovieSort.recommended:
        break;
      case MovieSort.rating:
        result.sort((a, b) => b.rating.compareTo(a.rating));
      case MovieSort.newest:
        result.sort((a, b) {
          final year = b.year.compareTo(a.year);
          return year == 0 ? b.rating.compareTo(a.rating) : year;
        });
      case MovieSort.title:
        result.sort((a, b) => a.title.compareTo(b.title));
    }
    return result;
  }

  void _openMovie(Movie movie) {
    final query = GoRouterState.of(context).uri.query;
    context.go('/movies/${movie.id}${query.isEmpty ? '' : '?$query'}');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('영화'),
      actions: [
        IconButton(
          tooltip: searching ? '검색 닫기' : '영화 검색',
          onPressed: () => setState(() {
            searching = !searching;
            if (!searching) searchController.clear();
          }),
          icon: Icon(searching ? Icons.close : Icons.search),
        ),
        PopupMenuButton<MovieSort>(
          tooltip: '정렬 방식',
          initialValue: _sort,
          onSelected: _changeSort,
          icon: const Icon(Icons.sort),
          itemBuilder: (_) => [
            for (final sort in MovieSort.values)
              PopupMenuItem(value: sort, child: Text(sort.label)),
          ],
        ),
        IconButton(
          tooltip: '장르 필터',
          onPressed: _showFilters,
          icon: Badge(
            isLabelVisible: widget.selectedGenres.isNotEmpty,
            label: Text('${widget.selectedGenres.length}'),
            child: const Icon(Icons.filter_list),
          ),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: Column(
      children: [
        if (searching)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: searchController,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: '영화 제목을 검색하세요',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
        _GenreChips(
          selectedGenres: widget.selectedGenres,
          onChanged: (genres) => unawaited(_applyGenres(genres)),
        ),
        if (widget.selectedGenres.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '선택 장르: ${_ordered(widget.selectedGenres).join(' · ')}',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ),
        Expanded(
          child: FutureBuilder<List<Movie>>(
            future: _moviesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const MovieLoadingView();
              }
              if (snapshot.hasError) {
                final timedOut = snapshot.error is TimeoutException;
                return MovieErrorView(
                  message: timedOut
                      ? '요청 시간이 초과되었습니다.\n잠시 후 다시 시도해주세요.'
                      : '영화 목록을 불러오지 못했습니다.\n잠시 후 다시 시도해주세요.',
                  onRetry: _reload,
                );
              }

              final loaded = snapshot.data ?? const <Movie>[];
              if (loaded.isEmpty) {
                return MovieEmptyView(
                  message: '아직 등록된 영화가 없습니다.',
                  onRefresh: _reload,
                );
              }

              final visible = _visibleMovies(loaded);
              if (visible.isEmpty) {
                return MovieEmptyView(
                  message: '조건에 맞는 영화가 없습니다.',
                  onRefresh: _reload,
                );
              }

              return MovieGrid(
                movies: visible,
                onMovieTap: _openMovie,
                onRefresh: _reload,
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _GenreChips extends StatelessWidget {
  const _GenreChips({required this.selectedGenres, required this.onChanged});

  final Set<String> selectedGenres;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      children: [
        ChoiceChip(
          label: const Text('전체'),
          selected: selectedGenres.isEmpty,
          onSelected: (_) => onChanged(<String>{}),
        ),
        const SizedBox(width: 8),
        for (final genre in movieGenres) ...[
          FilterChip(
            label: Text(genre),
            selected: selectedGenres.contains(genre),
            onSelected: (selected) {
              final next = {...selectedGenres};
              selected ? next.add(genre) : next.remove(genre);
              onChanged(next);
            },
          ),
          const SizedBox(width: 8),
        ],
      ],
    ),
  );
}

class GenreFilterSheet extends StatefulWidget {
  const GenreFilterSheet({super.key, required this.selected});
  final Set<String> selected;
  @override
  State<GenreFilterSheet> createState() => _GenreFilterSheetState();
}

class _GenreFilterSheetState extends State<GenreFilterSheet> {
  late final Set<String> draft = {...widget.selected};
  final sheetController = DraggableScrollableController();
  @override
  void dispose() {
    sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => DraggableScrollableSheet(
      controller: sheetController,
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: (details) => sheetController.jumpTo(
              (sheetController.size - details.delta.dy / constraints.maxHeight)
                  .clamp(0.35, 0.9),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCAC4D0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 12, 4),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '장르 선택',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(draft.clear),
                        child: const Text('전체 해제'),
                      ),
                      IconButton(
                        tooltip: '필터 닫기',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('여러 장르를 선택할 수 있어요.'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: movieGenres.length,
              itemBuilder: (context, index) {
                final genre = movieGenres[index];
                return CheckboxListTile(
                  title: Text(genre),
                  value: draft.contains(genre),
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (checked) => setState(() {
                    checked == true ? draft.add(genre) : draft.remove(genre);
                  }),
                );
              },
            ),
          ),
          const Divider(),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, draft),
                  child: Text(
                    draft.isEmpty
                        ? '확인 · 전체 영화 보기'
                        : '확인 · ${draft.length}개 장르 적용',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
