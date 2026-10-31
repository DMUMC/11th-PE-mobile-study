import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/movie/data/genre_preference.dart';
import 'package:movielog/movie/data/movie_sort_preference.dart';
import 'package:movielog/movie/widgets/movie_genre_filter_sheet.dart';
import 'package:movielog/movie/widgets/movie_grid.dart';
import 'package:movielog/movie/widgets/movie_list_empty.dart';
import 'package:movielog/movie/widgets/movie_list_error.dart';
import 'package:movielog/movie/widgets/movie_list_loading.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';
import 'package:provider/provider.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key, this.initialGenreQuery});

  final String? initialGenreQuery;

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  late final _genrePreference = GenrePreference();
  late final _sortPreference = MovieSortPreference();

  List<String> get _genres => context
      .read<MovieListViewModel>()
      .genres
      .map((genre) => genre.name)
      .toList();

  late Set<String> _selectedGenres;
  late bool _isRestoringGenres;
  late final MovieListViewModel _viewModel;
  bool _hasAppliedInitialGenre = false;
  int _genreSelectionRevision = 0;
  MovieSortOrder _sortOrder = MovieSortOrder.catalog;
  int _sortSelectionRevision = 0;
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _selectedGenres = _genresFromQuery(widget.initialGenreQuery);
    _isRestoringGenres = widget.initialGenreQuery == null;
    _viewModel = context.read<MovieListViewModel>();
    _viewModel.addListener(_applyInitialGenre);
    if (_isRestoringGenres) unawaited(_restoreSelectedGenres());
    unawaited(_restoreSortOrder());
    scheduleMicrotask(_applyInitialGenre);
  }

  @override
  void didUpdateWidget(covariant MovieListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialGenreQuery != widget.initialGenreQuery) {
      _genreSelectionRevision++;
      _hasAppliedInitialGenre = false;
      if (widget.initialGenreQuery == null) {
        _isRestoringGenres = true;
        unawaited(_restoreSelectedGenres());
      } else {
        _selectedGenres = _genresFromQuery(widget.initialGenreQuery);
        _isRestoringGenres = false;
        scheduleMicrotask(_applyInitialGenre);
      }
    }
  }

  Set<String> _genresFromQuery(String? query) => query == null
      ? <String>{}
      : query
            .split(',')
            .where((genre) => genre.isNotEmpty && genre != '전체')
            .take(1)
            .toSet();

  void _applyInitialGenre() {
    if (!mounted ||
        _hasAppliedInitialGenre ||
        _isRestoringGenres ||
        _viewModel.genreStatus == MovieListLoadStatus.idle ||
        _viewModel.genreStatus == MovieListLoadStatus.loading) {
      return;
    }

    _hasAppliedInitialGenre = true;
    int? genreId;
    for (final genre in _viewModel.genres) {
      if (_selectedGenres.contains(genre.name)) {
        genreId = genre.id;
        break;
      }
    }
    unawaited(_viewModel.selectGenre(genreId));
  }

  Future<void> _restoreSelectedGenres() async {
    final revision = _genreSelectionRevision;

    try {
      final storedGenres = await _genrePreference.read();
      if (!mounted ||
          widget.initialGenreQuery != null ||
          revision != _genreSelectionRevision) {
        return;
      }

      setState(() {
        _selectedGenres = _genresFromQuery(storedGenres);
        _isRestoringGenres = false;
      });
      _applyInitialGenre();
    } catch (error, stackTrace) {
      debugPrint('장르 설정 읽기 실패: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted || revision != _genreSelectionRevision) return;
      setState(() => _isRestoringGenres = false);
      _applyInitialGenre();
    }
  }

  Future<void> _restoreSortOrder() async {
    final revision = _sortSelectionRevision;
    try {
      final savedOrder = await _sortPreference.read();
      if (!mounted || revision != _sortSelectionRevision) return;
      setState(() => _sortOrder = savedOrder);
    } catch (error, stackTrace) {
      debugPrint('정렬 설정 읽기 실패: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _changeSortOrder(MovieSortOrder order) async {
    if (_sortOrder == order) return;
    _sortSelectionRevision++;
    setState(() => _sortOrder = order);

    try {
      await _sortPreference.save(order);
    } catch (error, stackTrace) {
      debugPrint('정렬 설정 저장 실패: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('정렬 방식을 저장하지 못했습니다.')));
      }
    }
  }

  void _sortMovies(List<TmdbMovieDto> movies) {
    final original = context.read<MovieListViewModel>().movies;
    int catalogOrder(TmdbMovieDto a, TmdbMovieDto b) =>
        original.indexOf(a).compareTo(original.indexOf(b));

    switch (_sortOrder) {
      case MovieSortOrder.catalog:
        return;
      case MovieSortOrder.newest:
        movies.sort((a, b) {
          final byDate = (b.releaseDate ?? '').compareTo(a.releaseDate ?? '');
          return byDate != 0 ? byDate : catalogOrder(a, b);
        });
      case MovieSortOrder.highestRated:
        movies.sort((a, b) {
          final byRating = b.voteAverage.compareTo(a.voteAverage);
          return byRating != 0 ? byRating : catalogOrder(a, b);
        });
    }
  }

  void _retry() {
    unawaited(context.read<MovieListViewModel>().loadMovies());
  }

  Future<void> _refreshMovies() =>
      context.read<MovieListViewModel>().loadMovies();

  Future<void> _showGenreFilter() async {
    final selectedGenres = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MovieGenreFilterSheet(
        genres: _genres,
        selectedGenres: _selectedGenres,
      ),
    );

    if (selectedGenres == null || !mounted) return;
    int? genreId;
    for (final genre in _viewModel.genres) {
      if (selectedGenres.contains(genre.name)) {
        genreId = genre.id;
        break;
      }
    }
    await _selectGenre(genreId);
  }

  Future<void> _selectGenre(int? genreId) async {
    final appliedGenres = _viewModel.genres
        .where((genre) => genre.id == genreId)
        .map((genre) => genre.name)
        .toSet();
    final revision = ++_genreSelectionRevision;
    _hasAppliedInitialGenre = true;
    setState(() {
      _selectedGenres = appliedGenres;
      _isRestoringGenres = false;
    });
    final request = _viewModel.selectGenre(genreId);

    final genreQuery = appliedGenres.join(',');
    try {
      await _genrePreference.save(genreQuery);
    } catch (error, stackTrace) {
      debugPrint('장르 설정 저장 실패: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('장르 선택을 저장하지 못했습니다.')));
    }

    if (!mounted || revision != _genreSelectionRevision) return;
    final location = Uri(
      path: '/movies',
      queryParameters: genreQuery.isEmpty ? null : {'genre': genreQuery},
    );
    context.go(location.toString());
    await request;
  }

  @override
  void dispose() {
    _viewModel.removeListener(_applyInitialGenre);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        centerTitle: false,
        titleSpacing: 16,
        title: _isSearching
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '영화 제목 검색',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              )
            : const Text(
                '영화',
                style: TextStyle(
                  color: AppColors.primary600,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
        actions: [
          IconButton(
            tooltip: _isSearching ? '검색 닫기' : '영화 검색',
            onPressed: () => setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) _searchQuery = '';
            }),
            icon: _isSearching
                ? const Icon(Icons.close)
                : SvgPicture.asset(
                    'assets/icons/search.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      AppColors.onSurface,
                      BlendMode.srcIn,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.surfaceContainer),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    PopupMenuButton<MovieSortOrder>(
                      tooltip: '영화 정렬',
                      initialValue: _sortOrder,
                      onSelected: _changeSortOrder,
                      itemBuilder: (context) => [
                        for (final order in MovieSortOrder.values)
                          PopupMenuItem(value: order, child: Text(order.label)),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_sortOrder.label),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    Consumer<MovieListViewModel>(
                      builder: (context, viewModel, child) => IconButton(
                        tooltip: '장르 필터',
                        onPressed:
                            _isRestoringGenres ||
                                viewModel.genreStatus !=
                                    MovieListLoadStatus.success
                            ? null
                            : _showGenreFilter,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.filter_list),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 48,
              child: Consumer<MovieListViewModel>(
                builder: (context, viewModel, child) {
                  return switch (viewModel.genreStatus) {
                    MovieListLoadStatus.idle ||
                    MovieListLoadStatus.loading => const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    MovieListLoadStatus.error => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(viewModel.genreMessage ?? '장르를 불러오지 못했어요.'),
                        TextButton(
                          onPressed: () =>
                              context.read<MovieListViewModel>().loadGenres(),
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                    MovieListLoadStatus.empty => const Center(
                      child: Text('장르가 없습니다.'),
                    ),
                    MovieListLoadStatus.success => ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: viewModel.genres.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return ChoiceChip(
                            key: const ValueKey('all'),
                            label: const Text('전체'),
                            selected: viewModel.selectedGenreId == null,
                            onSelected: (selected) {
                              if (selected) unawaited(_selectGenre(null));
                            },
                          );
                        }
                        final genre = viewModel.genres[index - 1];
                        return ChoiceChip(
                          key: ValueKey(genre.id),
                          label: Text(genre.name),
                          selected: viewModel.selectedGenreId == genre.id,
                          onSelected: (selected) {
                            if (selected) unawaited(_selectGenre(genre.id));
                          },
                        );
                      },
                    ),
                  };
                },
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshMovies,
                child: Consumer<MovieListViewModel>(
                  builder: (context, viewModel, child) {
                    switch (viewModel.status) {
                      case MovieListLoadStatus.idle:
                      case MovieListLoadStatus.loading:
                        return const MovieListLoading();
                      case MovieListLoadStatus.error:
                        return MovieListError(
                          message: viewModel.message,
                          onRetry: _retry,
                        );
                      case MovieListLoadStatus.empty:
                        return const MovieListEmpty();
                      case MovieListLoadStatus.success:
                        break;
                    }

                    final visibleMovies = viewModel.movies.where((movie) {
                      final matchesSearch =
                          _searchQuery.isEmpty ||
                          movie.title.contains(_searchQuery.trim());
                      return matchesSearch;
                    }).toList();
                    _sortMovies(visibleMovies);

                    return visibleMovies.isEmpty
                        ? const CustomScrollView(
                            physics: AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: MovieListEmpty(),
                              ),
                            ],
                          )
                        : MovieGrid(
                            movies: visibleMovies,
                            genres: viewModel.genres,
                          );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
