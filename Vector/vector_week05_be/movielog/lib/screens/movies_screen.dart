import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/movie.dart';
import '../controllers/movies_controller.dart';
import '../services/movie_service.dart';
import '../widgets/movie_retry_dialog.dart';
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
    this.onMoviesLoaded,
  });

  final List<int>? selectedGenres;
  final MovieService service;
  final MoviePreferencesStore? preferences;
  final ValueChanged<List<Movie>>? onMoviesLoaded;

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  final searchController = TextEditingController();
  late final MoviePreferencesStore _preferences;
  late MoviesController _controller;
  MovieSort _sort = MovieSort.recommended;
  bool searching = false;
  bool _restoring = true;
  bool _dialogOpen = false;
  int _shownFailure = 0;
  int _selectionRevision = 0;

  @override
  void initState() {
    super.initState();
    _preferences = widget.preferences ?? SharedMoviePreferences();
    _controller = MoviesController(service: widget.service)
      ..addListener(_onChanged);
    unawaited(_restorePreferences());
  }

  @override
  void didUpdateWidget(covariant MoviesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service != widget.service) {
      _controller.dispose();
      _controller = MoviesController(service: widget.service)
        ..addListener(_onChanged);
      _shownFailure = 0;
      if (!_restoring) {
        unawaited(_controller.load(genreIds: widget.selectedGenres));
      }
    }
    if (!listEquals(oldWidget.selectedGenres, widget.selectedGenres)) {
      _selectionRevision++;
      unawaited(_saveGenres(widget.selectedGenres));
      if (!_restoring &&
          !listEquals(_controller.genreIds, widget.selectedGenres)) {
        unawaited(_controller.load(genreIds: widget.selectedGenres));
      }
    }
  }

  void _onChanged() {
    if (!mounted) return;
    if (_controller.hasSucceeded) {
      widget.onMoviesLoaded?.call(_controller.movies);
    }
    setState(() {});
    if (_controller.error != null &&
        _shownFailure < _controller.failureVersion &&
        !_dialogOpen) {
      _shownFailure = _controller.failureVersion;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.error != null && !_dialogOpen) {
          unawaited(_showRetryDialog());
        }
      });
    }
  }

  String get _errorMessage => switch (_controller.error) {
    TimeoutException() => '요청 시간이 초과되었습니다.\n잠시 후 다시 시도해주세요.',
    MovieLoadException(:final message) => message,
    _ => '네트워크 상태를 확인하고\n다시 시도해 주세요.',
  };

  Future<void> _showRetryDialog() async {
    _dialogOpen = true;
    final retry = await showDialog<bool>(
      context: context,
      builder: (_) => MovieRetryDialog(message: _errorMessage),
    );
    if (!mounted) return;
    _dialogOpen = false;
    if (retry == true) unawaited(_controller.refresh());
  }

  @override
  void dispose() {
    _controller.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _restorePreferences() async {
    List<int>? savedGenres;
    var savedSort = MovieSort.recommended;
    try {
      savedGenres = await _preferences.loadGenres();
      savedSort = await _preferences.loadSort();
    } on Object {
      // 로컬 저장소 오류가 영화 요청을 막지 않도록 기본값을 사용합니다.
    }
    if (!mounted) return;
    final ids =
        widget.selectedGenres ?? (_selectionRevision == 0 ? savedGenres : null);
    setState(() {
      _sort = savedSort;
      _restoring = false;
    });
    if (widget.selectedGenres == null && ids != null) _goToGenres(ids);
    if (widget.selectedGenres != null) {
      unawaited(_saveGenres(widget.selectedGenres));
    }
    unawaited(_controller.load(genreIds: ids));
  }

  Future<void> _saveGenres(List<int>? ids) async {
    try {
      await _preferences.saveGenres(ids);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('장르 설정을 저장하지 못했습니다.')));
      }
    }
  }

  void _goToGenres(List<int>? selected) {
    final ordered = normalizeGenreIds(selected);
    context.go(
      Uri(
        path: '/movies',
        queryParameters: ordered == null
            ? null
            : {'genre': ordered.map((id) => '$id').toList()},
      ).toString(),
    );
  }

  void _applyGenres(List<int>? selected) => _goToGenres(selected);

  Future<void> _showFilters() async {
    final selected = await showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => GenreFilterSheet(selected: widget.selectedGenres),
    );
    if (!mounted || selected == null) return;
    _applyGenres(selected);
  }

  Future<void> _changeSort(MovieSort sort) async {
    setState(() => _sort = sort);
    try {
      await _preferences.saveSort(sort);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('정렬 설정을 저장하지 못했습니다.')));
      }
    }
  }

  List<Movie> _visibleMovies(List<Movie> source) {
    final result = source
        .where(
          (movie) => movie.title.toLowerCase().contains(
            searchController.text.trim().toLowerCase(),
          ),
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
    context.go(
      '/movies/${movie.id}${query.isEmpty ? '' : '?$query'}',
      extra: movie,
    );
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
            isLabelVisible: (widget.selectedGenres?.isNotEmpty ?? false),
            label: Text('${widget.selectedGenres?.length ?? 0}'),
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
          onChanged: _applyGenres,
        ),
        if ((widget.selectedGenres?.isNotEmpty ?? false))
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '선택 장르: ${widget.selectedGenres!.map((id) => movieGenreNames[id]).join(' · ')}',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ),
        Expanded(child: _buildMovieBody()),
      ],
    ),
  );

  Widget _buildMovieBody() {
    if (_restoring || (_controller.loading && !_controller.hasSucceeded)) {
      return const MovieLoadingView();
    }
    if (_controller.error != null && !_controller.hasSucceeded) {
      return MovieErrorView(
        message: _errorMessage,
        onRetry: _controller.refresh,
      );
    }
    final visible = _visibleMovies(_controller.movies);
    return Stack(
      children: [
        Positioned.fill(
          child: visible.isEmpty
              ? MovieEmptyView(
                  message: _controller.movies.isEmpty
                      ? '아직 등록된 영화가 없습니다.'
                      : '조건에 맞는 영화가 없습니다.',
                  onRefresh: _controller.refresh,
                  refreshEnabled: !_controller.loading,
                )
              : MovieGrid(
                  movies: visible,
                  onMovieTap: _openMovie,
                  onRefresh: _controller.refresh,
                  refreshEnabled: !_controller.loading,
                ),
        ),
        if (_controller.loading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              minHeight: 2,
              semanticsLabel: '영화 새로고침 중',
            ),
          ),
      ],
    );
  }
}

class _GenreChips extends StatelessWidget {
  const _GenreChips({required this.selectedGenres, required this.onChanged});

  final List<int>? selectedGenres;
  final ValueChanged<List<int>?> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      children: [
        ChoiceChip(
          label: const Text('전체'),
          selected: selectedGenres == null || selectedGenres!.isEmpty,
          onSelected: (_) => onChanged(null),
        ),
        const SizedBox(width: 8),
        for (final genre in movieGenreNames.entries) ...[
          FilterChip(
            label: Text(genre.value),
            selected: selectedGenres?.contains(genre.key) ?? false,
            onSelected: (selected) {
              final next = {...?selectedGenres};
              selected ? next.add(genre.key) : next.remove(genre.key);
              onChanged(normalizeGenreIds(next));
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
  final List<int>? selected;
  @override
  State<GenreFilterSheet> createState() => _GenreFilterSheetState();
}

class _GenreFilterSheetState extends State<GenreFilterSheet> {
  late final Set<int> draft = {...?widget.selected};
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
                          '장르 필터',
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
            child: Scrollbar(
              controller: scrollController,
              thumbVisibility: true,
              child: ListView.builder(
                controller: scrollController,
                itemCount: movieGenreNames.length,
                itemBuilder: (context, index) {
                  final genre = movieGenreNames.entries.elementAt(index);
                  return CheckboxListTile(
                    title: Text(genre.value),
                    value: draft.contains(genre.key),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (checked) => setState(() {
                      checked == true
                          ? draft.add(genre.key)
                          : draft.remove(genre.key);
                    }),
                  );
                },
              ),
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
                  onPressed: () => Navigator.pop(context, draft.toList()),
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
